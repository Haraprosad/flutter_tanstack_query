import 'dart:async';
import 'package:flutter/foundation.dart';
import 'core/query_state.dart';
import 'core/query_config.dart';
import 'core/types.dart';
import 'query_cache.dart';
import 'network_policy.dart';

typedef QueryFetcher<T> = Future<T> Function();

/// Manages the state and lifecycle of a single data query.
///
/// This class handles fetching, caching, stale-while-revalidate,
/// retries, and background refetching.
class Query<T> {
  /// A unique key identifying this query.
  final List<Object> queryKey;

  /// The function responsible for fetching the data.
  final QueryFetcher<T> fetcher;

  /// Configuration options for this specific query.
  final QueryConfig config;

  final QueryCache _cache;
  final NetworkPolicy _networkPolicy;

  /// The stream controller for emitting [QueryState] changes.
  final StreamController<QueryState<T>> _stateController =
      StreamController<QueryState<T>>.broadcast();

  /// The current state of the query.
  QueryState<T> _state;

  StreamSubscription? _networkSubscription;
  bool _disposed = false;

  /// Creates a [Query] instance.
  Query({
    required this.queryKey,
    required this.fetcher,
    required QueryCache cache,
    required NetworkPolicy networkPolicy,
    this.config = const QueryConfig(),
  })  : _cache = cache,
        _networkPolicy = networkPolicy,
        _state = QueryState.idle() {
    _initialize();
  }

  /// Exposes the stream of query state changes.
  Stream<QueryState<T>> get stateStream => _stateController.stream;

  /// Gets the current state of the query.
  QueryState<T> get state => _state;

  /// Updates the internal state and emits it through the stream.
  void _updateState(QueryState<T> newState) {
    if (_disposed) return;
    _state = newState;
    if (!_stateController.isClosed) {
      _stateController.add(_state);
    }
  }

  /// Initializes the query by loading from cache and setting up listeners.
  void _initialize() async {
    // Attempt to load from cache immediately
    final cachedData = await _cache.get<T>(queryKey.toString());
    if (cachedData != null) {
      final isStale = _isStale(cachedData);
      _updateState(QueryState.success(cachedData, isStale: isStale));
      // If cached data is stale, trigger a background refetch
      if (isStale && config.enabled) {
        _fetchInBackground();
      }
    } else {
      // If no cached data, and enabled, fetch immediately
      if (config.enabled) {
        fetch();
      }
    }

    // Listen to network changes for refetch on reconnect
    if (config.refetchOnReconnect) {
      _networkSubscription = _networkPolicy.statusStream.listen((status) {
        if (status == NetworkStatus.online && state.hasData && _isStale(state.data!)) {
          debugPrint('Refetching ${queryKey.toString()} on reconnect.');
          refetch();
        }
      });
    }

    // TODO: Implement refetchOnWindowFocus (requires AppLifecycleObserver)
  }

  /// Fetches data for the query.
  ///
  /// [force] set to true will bypass cache and force a network fetch.
  Future<void> fetch({bool force = false}) async {
    if (_disposed || !config.enabled) return;

    // Prevent multiple concurrent fetches unless forced
    if (state.status == QueryStatus.loading && !force) {
      return;
    }

    // If we have data and it's not stale, and not forced, do nothing.
    // This check is mainly for initial load. Subsequent fetches will be handled by `_isStale`.
    if (!force && state.hasData && !state.isStale) {
      return;
    }

    // Set loading state (keep previous data if exists)
    _updateState(QueryState.loading(state.data));

    try {
      final data = await _fetchWithRetry();

      // Cache and update state
      await _cache.set(queryKey.toString(), data, ttl: config.cacheTime);
      if (!_disposed) {
        _updateState(QueryState.success(data));
      }
    } catch (error) {
      debugPrint('Error fetching ${queryKey.toString()}: $error');
      if (!_disposed) {
        _updateState(QueryState.error(error, state.data));
      }
    }
  }

  /// Forces a refetch of the query, bypassing cache.
  Future<void> refetch() => fetch(force: true);

  /// Executes the [fetcher] with retry logic.
  Future<T> _fetchWithRetry() async {
    int attempts = 0;
    late Object lastError;

    while (attempts <= config.retryCount) {
      try {
        return await fetcher();
      } catch (error) {
        lastError = error;
        attempts++;
        debugPrint('Fetch failed for ${queryKey.toString()}. Attempt ${attempts}/${config.retryCount + 1}. Error: $error');
        if (attempts <= config.retryCount) {
          await Future.delayed(config.retryDelay * attempts); // Exponential backoff
        }
      }
    }
    throw lastError; // Re-throw if all retries fail
  }

  /// Fetches data in the background without changing the loading state.
  void _fetchInBackground() async {
    if (!config.enabled) return;
    debugPrint('Background refetching ${queryKey.toString()}...');
    try {
      final data = await _fetchWithRetry();
      await _cache.set(queryKey.toString(), data, ttl: config.cacheTime);
      if (!_disposed) {
        // Update state to success, but keep current loading status if it's loading from foreground
        if (state.status != QueryStatus.loading) {
          _updateState(QueryState.success(data));
        } else {
          // If already loading, just update data and mark as not stale
          _updateState(state.copyWith(data: data, isStale: false));
        }
      }
    } catch (error) {
      // Silent fail for background refetch, only log the error
      debugPrint('Background refetch failed for ${queryKey.toString()}: $error');
      if (!_disposed) {
        _updateState(state.copyWith(isStale: true)); // Keep stale if background fetch fails
      }
    }
  }

  /// Checks if the data is stale based on `staleTime`.
  bool _isStale(T data) {
    // If lastFetched is null, data is always stale (e.g., first fetch or cache miss)
    if (state.lastFetched == null) return true;
    return DateTime.now().difference(state.lastFetched!) > config.staleTime;
  }

  /// Invalidates the query, forcing a refetch on next access.
  /// Optionally removes data from cache.
  void invalidate({bool removeCache = true}) {
    if (removeCache) {
      _cache.remove(queryKey.toString());
    }
    _updateState(QueryState.idle()); // Reset state to force re-fetch
    if (config.enabled) {
      fetch(); // Trigger immediate fetch if enabled
    }
    debugPrint('Query ${queryKey.toString()} invalidated.');
  }

  /// Manually sets the data for this query and updates the cache.
  void setData(T data) {
    _updateState(QueryState.success(data));
    _cache.set(queryKey.toString(), data, ttl: config.cacheTime);
    debugPrint('Query ${queryKey.toString()} data manually set.');
  }

  /// Disposes the query's resources.
  void dispose() {
    _disposed = true;
    _networkSubscription?.cancel();
    _stateController.close();
    debugPrint('Query ${queryKey.toString()} disposed.');
  }
}