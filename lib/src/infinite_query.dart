import 'dart:async';
import 'package:flutter/foundation.dart';
import 'core/query_state.dart';
import 'core/query_config.dart';
import 'core/types.dart';
import 'query_cache.dart';
import 'network_policy.dart';

// Represents a page of data for an infinite query.
class QueryPage<T> {
  final T data;
  final dynamic pageParam; // The parameter used to fetch this page

  QueryPage({required this.data, this.pageParam});
}

// The state for an infinite query, containing multiple pages.
@immutable
class InfiniteQueryState<T> {
  final List<QueryPage<T>> pages;
  final Object? error;
  final QueryStatus status;
  final bool isStale;
  final DateTime? lastFetched;
  final bool isFetchingNextPage;
  final bool hasNextPage;

  const InfiniteQueryState._({
    this.pages = const [],
    this.error,
    required this.status,
    required this.isStale,
    this.lastFetched,
    this.isFetchingNextPage = false,
    this.hasNextPage = false,
  });

  factory InfiniteQueryState.idle() =>
      const InfiniteQueryState._(status: QueryStatus.idle, isStale: false);

  factory InfiniteQueryState.loading([List<QueryPage<T>>? previousPages]) =>
      InfiniteQueryState._(
        pages: previousPages ?? [],
        status: QueryStatus.loading,
        isStale: previousPages != null,
      );

  factory InfiniteQueryState.success(
    List<QueryPage<T>> pages, {
    bool isStale = false,
    bool hasNextPage = false,
  }) => InfiniteQueryState._(
    pages: pages,
    status: QueryStatus.success,
    isStale: isStale,
    lastFetched: DateTime.now(),
    hasNextPage: hasNextPage,
  );

  factory InfiniteQueryState.error(
    Object error, [
    List<QueryPage<T>>? previousPages,
  ]) => InfiniteQueryState._(
    pages: previousPages ?? [],
    error: error,
    status: QueryStatus.error,
    isStale: previousPages != null,
  );

  InfiniteQueryState<T> copyWith({
    List<QueryPage<T>>? pages,
    Object? error,
    QueryStatus? status,
    bool? isStale,
    DateTime? lastFetched,
    bool? isFetchingNextPage,
    bool? hasNextPage,
  }) {
    return InfiniteQueryState._(
      pages: pages ?? this.pages,
      error: error ?? this.error,
      status: status ?? this.status,
      isStale: isStale ?? this.isStale,
      lastFetched: lastFetched ?? this.lastFetched,
      isFetchingNextPage: isFetchingNextPage ?? this.isFetchingNextPage,
      hasNextPage: hasNextPage ?? this.hasNextPage,
    );
  }

  bool get isLoading => status == QueryStatus.loading;
  bool get isSuccess => status == QueryStatus.success;
  bool get isError => status == QueryStatus.error;
  bool get hasData => pages.isNotEmpty;

  // Flattens all pages into a single list of data.
  List<T> get flatData => pages.expand((page) => [page.data]).toList();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InfiniteQueryState<T> &&
        listEquals(other.pages, pages) && // Requires listEquals
        other.error == error &&
        other.status == status &&
        other.isStale == isStale &&
        other.lastFetched == lastFetched &&
        other.isFetchingNextPage == isFetchingNextPage &&
        other.hasNextPage == hasNextPage;
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(pages),
    error,
    status,
    isStale,
    lastFetched,
    isFetchingNextPage,
    hasNextPage,
  );

  @override
  String toString() {
    return 'InfiniteQueryState(pages: ${pages.length}, error: $error, status: $status, isStale: $isStale, isFetchingNextPage: $isFetchingNextPage, hasNextPage: $hasNextPage)';
  }
}

/// Manages the state and lifecycle of an infinite (paginated) data query.
class InfiniteQuery<T, PageParam> {
  final List<Object> queryKey;
  final InfiniteQueryFetcher<T, PageParam> fetcher;
  final GetNextPageParam<T, PageParam>? getNextPageParam;
  final GetPreviousPageParam<T, PageParam>? getPreviousPageParam;
  final QueryConfig config;

  final QueryCache _cache;
  final NetworkPolicy _networkPolicy;

  final StreamController<InfiniteQueryState<T>> _stateController =
      StreamController<InfiniteQueryState<T>>.broadcast();

  InfiniteQueryState<T> _state;

  StreamSubscription? _networkSubscription;
  bool _disposed = false;

  InfiniteQuery({
    required this.queryKey,
    required this.fetcher,
    required QueryCache cache,
    required NetworkPolicy networkPolicy,
    this.getNextPageParam,
    this.getPreviousPageParam,
    this.config = const QueryConfig(),
  }) : _cache = cache,
       _networkPolicy = networkPolicy,
       _state = InfiniteQueryState.idle() {
    _initialize();
  }

  Stream<InfiniteQueryState<T>> get stateStream => _stateController.stream;
  InfiniteQueryState<T> get state => _state;

  void _updateState(InfiniteQueryState<T> newState) {
    if (_disposed) return;
    _state = newState;
    if (!_stateController.isClosed) {
      _stateController.add(_state);
    }
  }

  void _initialize() async {
    // Attempt to load from cache immediately
    final cachedData = await _cache.get<List<QueryPage<T>>>(
      queryKey.toString(),
    );
    if (cachedData != null && cachedData.isNotEmpty) {
      final isStale = _isStale(cachedData);
      _updateState(
        InfiniteQueryState.success(
          cachedData,
          isStale: isStale,
          hasNextPage: _calculateHasNextPage(cachedData),
        ),
      );
      if (isStale && config.enabled) {
        _fetchInBackground();
      }
    } else {
      if (config.enabled) {
        fetch();
      }
    }

    if (config.refetchOnReconnect) {
      _networkSubscription = _networkPolicy.statusStream.listen((status) {
        if (status == NetworkStatus.online &&
            state.hasData &&
            _isStale(state.pages)) {
          debugPrint('Refetching ${queryKey.toString()} on reconnect.');
          refetch();
        }
      });
    }
  }

  Future<void> fetch({bool force = false, PageParam? initialPageParam}) async {
    if (_disposed || !config.enabled) return;

    if (state.status == QueryStatus.loading && !force) {
      return;
    }

    if (!force && state.hasData && !state.isStale) {
      return;
    }

    _updateState(InfiniteQueryState.loading(state.pages));

    try {
      final firstPageData = await _fetchWithRetry(pageParam: initialPageParam);
      final newPages = [
        QueryPage(data: firstPageData, pageParam: initialPageParam),
      ];

      await _cache.set(queryKey.toString(), newPages, ttl: config.cacheTime);
      if (!_disposed) {
        _updateState(
          InfiniteQueryState.success(
            newPages,
            hasNextPage: _calculateHasNextPage(newPages),
          ),
        );
      }
    } catch (error) {
      debugPrint('Error fetching ${queryKey.toString()}: $error');
      if (!_disposed) {
        _updateState(InfiniteQueryState.error(error, state.pages));
      }
    }
  }

  Future<void> fetchNextPage() async {
    if (_disposed ||
        !config.enabled ||
        state.isFetchingNextPage ||
        !state.hasNextPage) {
      return;
    }

    final lastPage = state.pages.last.data;
    final allPagesData = state.pages.map((p) => p.data).toList();
    final nextPageParam = getNextPageParam?.call(lastPage, allPagesData);

    if (nextPageParam == null) {
      _updateState(state.copyWith(hasNextPage: false));
      return;
    }

    _updateState(state.copyWith(isFetchingNextPage: true));

    try {
      final newPageData = await _fetchWithRetry(pageParam: nextPageParam);
      final updatedPages = List<QueryPage<T>>.from(state.pages)
        ..add(QueryPage(data: newPageData, pageParam: nextPageParam));

      await _cache.set(
        queryKey.toString(),
        updatedPages,
        ttl: config.cacheTime,
      );
      if (!_disposed) {
        _updateState(
          InfiniteQueryState.success(
            updatedPages,
            hasNextPage: _calculateHasNextPage(updatedPages),
          ).copyWith(isFetchingNextPage: false),
        );
      }
    } catch (error) {
      debugPrint('Error fetching next page for ${queryKey.toString()}: $error');
      if (!_disposed) {
        _updateState(
          state.copyWith(
            error: error,
            isFetchingNextPage: false,
            isStale: true, // Mark stale if pagination fails
          ),
        );
      }
    }
  }

  /// Fetches the previous page of data
  Future<void> fetchPreviousPage() async {
    if (_disposed || !config.enabled || state.pages.isEmpty) {
      return;
    }

    final firstPage = state.pages.first.data;
    final allPagesData = state.pages.map((p) => p.data).toList();
    final previousPageParam = getPreviousPageParam?.call(
      firstPage,
      allPagesData,
    );

    if (previousPageParam == null) {
      return;
    }

    try {
      final newPageData = await _fetchWithRetry(pageParam: previousPageParam);
      final updatedPages = <QueryPage<T>>[
        QueryPage(data: newPageData, pageParam: previousPageParam),
        ...state.pages,
      ];

      await _cache.set(
        queryKey.toString(),
        updatedPages,
        ttl: config.cacheTime,
      );
      if (!_disposed) {
        _updateState(
          InfiniteQueryState.success(
            updatedPages,
            hasNextPage: _calculateHasNextPage(updatedPages),
          ),
        );
      }
    } catch (error) {
      debugPrint(
        'Error fetching previous page for ${queryKey.toString()}: $error',
      );
      if (!_disposed) {
        _updateState(state.copyWith(error: error, isStale: true));
      }
    }
  }

  Future<void> refetch() => fetch(force: true);

  Future<T> _fetchWithRetry({PageParam? pageParam}) async {
    int attempts = 0;
    late Object lastError;

    while (attempts <= config.retryCount) {
      try {
        return await fetcher(pageParam: pageParam);
      } catch (error) {
        lastError = error;
        attempts++;
        debugPrint(
          'Fetch failed for ${queryKey.toString()}. Attempt ${attempts}/${config.retryCount + 1}. Error: $error',
        );
        if (attempts <= config.retryCount) {
          await Future.delayed(config.retryDelay * attempts);
        }
      }
    }
    throw lastError;
  }

  void _fetchInBackground() async {
    if (!config.enabled) return;
    debugPrint('Background refetching ${queryKey.toString()}...');
    try {
      // For infinite queries, background refetch usually means refetching the first page
      final firstPageData = await _fetchWithRetry(
        pageParam: null,
      ); // Assuming initial page param is null
      final newPages = [QueryPage(data: firstPageData, pageParam: null)];

      // If there are more pages, you might want to refetch them too,
      // or rely on the user scrolling to trigger fetchNextPage.
      // For simplicity, background refetch only refreshes the first page.

      await _cache.set(queryKey.toString(), newPages, ttl: config.cacheTime);
      if (!_disposed) {
        if (state.status != QueryStatus.loading) {
          _updateState(
            InfiniteQueryState.success(
              newPages,
              hasNextPage: _calculateHasNextPage(newPages),
            ),
          );
        } else {
          _updateState(
            state.copyWith(
              pages: newPages,
              isStale: false,
              hasNextPage: _calculateHasNextPage(newPages),
            ),
          );
        }
      }
    } catch (error) {
      debugPrint(
        'Background refetch failed for ${queryKey.toString()}: $error',
      );
      if (!_disposed) {
        _updateState(state.copyWith(isStale: true));
      }
    }
  }

  bool _isStale(List<QueryPage<T>> pages) {
    if (state.lastFetched == null) return true;
    return DateTime.now().difference(state.lastFetched!) > config.staleTime;
  }

  bool _calculateHasNextPage(List<QueryPage<T>> currentPages) {
    if (currentPages.isEmpty || getNextPageParam == null) return false;
    final lastPage = currentPages.last.data;
    final allPagesData = currentPages.map((p) => p.data).toList();
    return getNextPageParam!(lastPage, allPagesData) != null;
  }

  void invalidate({bool removeCache = true}) {
    if (removeCache) {
      _cache.remove(queryKey.toString());
    }
    _updateState(InfiniteQueryState.idle());
    if (config.enabled) {
      fetch();
    }
    debugPrint('InfiniteQuery ${queryKey.toString()} invalidated.');
  }

  void setData(List<QueryPage<T>> pages) {
    _updateState(
      InfiniteQueryState.success(
        pages,
        hasNextPage: _calculateHasNextPage(pages),
      ),
    );
    _cache.set(queryKey.toString(), pages, ttl: config.cacheTime);
    debugPrint('InfiniteQuery ${queryKey.toString()} data manually set.');
  }

  void dispose() {
    _disposed = true;
    _networkSubscription?.cancel();
    _stateController.close();
    debugPrint('InfiniteQuery ${queryKey.toString()} disposed.');
  }
}
