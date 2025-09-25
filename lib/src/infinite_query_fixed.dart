import 'dart:async';
import 'package:flutter/foundation.dart';
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
    this.isStale = false,
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

  bool get isIdle => status == QueryStatus.idle;
  bool get isLoading => status == QueryStatus.loading;
  bool get isSuccess => status == QueryStatus.success;
  bool get isError => status == QueryStatus.error;
  bool get hasData => pages.isNotEmpty;

  /// Checks if the infinite query has no data loaded
  bool get hasNoData => pages.isEmpty;

  /// Gets the total number of items across all pages (assumes T is List<Item>)
  int get totalItemCount {
    int count = 0;
    for (final page in pages) {
      if (page.data is List) {
        count += (page.data as List).length;
      }
    }
    return count;
  }

  /// Gets all data flattened into a single list (assumes T is List<Item>)
  List<E> getAllItems<E>() {
    final List<E> allItems = [];
    for (final page in pages) {
      if (page.data is List<E>) {
        allItems.addAll(page.data as List<E>);
      }
    }
    return allItems;
  }

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
  final PageParam? initialPageParam;

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
    this.initialPageParam,
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
    _stateController.add(newState);
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

      _updateState(
        InfiniteQueryState.success(
          newPages,
          hasNextPage: _calculateHasNextPage(newPages),
        ),
      );
    } catch (error) {
      debugPrint(
        'Error fetching initial page for ${queryKey.toString()}: $error',
      );
      _updateState(InfiniteQueryState.error(error, state.pages));
    }
  }

  Future<void> fetchNextPage() async {
    if (_disposed ||
        !config.enabled ||
        state.isFetchingNextPage ||
        !state.hasNextPage) {
      return;
    }

    final nextPageParam = getNextPageParam?.call(
      state.pages.last.data,
      state.pages.map((page) => page.data).toList(),
    );

    if (nextPageParam == null) return;

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

      _updateState(
        InfiniteQueryState.success(
          updatedPages,
          hasNextPage: _calculateHasNextPage(updatedPages),
        ),
      );
    } catch (error) {
      debugPrint('Error fetching next page for ${queryKey.toString()}: $error');
      _updateState(state.copyWith(error: error, isFetchingNextPage: false));
    }
  }

  Future<void> fetchPreviousPage() async {
    if (_disposed || !config.enabled || state.pages.isEmpty) return;

    final getPrevious = getPreviousPageParam;
    if (getPrevious == null) return;

    final previousPageParam = getPrevious(
      state.pages.first.data,
      state.pages.map((page) => page.data).toList(),
    );

    if (previousPageParam == null) return;

    try {
      final newPageData = await _fetchWithRetry(pageParam: previousPageParam);
      final updatedPages = [
        QueryPage(data: newPageData, pageParam: previousPageParam),
        ...state.pages,
      ];

      await _cache.set(
        queryKey.toString(),
        updatedPages,
        ttl: config.cacheTime,
      );

      _updateState(
        InfiniteQueryState.success(
          updatedPages,
          hasNextPage: _calculateHasNextPage(updatedPages),
        ),
      );
    } catch (error) {
      debugPrint(
        'Error fetching previous page for ${queryKey.toString()}: $error',
      );
      _updateState(state.copyWith(error: error, isStale: true));
    }
  }

  Future<void> refetch() => fetch(force: true);

  /// Refreshes the query by clearing all cached data and refetching from the first page
  /// This is ideal for pull-to-refresh functionality
  Future<void> refresh() async {
    if (_disposed || !config.enabled) return;

    // Clear cached data for a fresh start
    await _cache.remove(queryKey.toString());

    // Reset to empty state while fetching
    _updateState(InfiniteQueryState.loading([]));

    // Fetch fresh data from the first page
    await fetch(force: true, initialPageParam: initialPageParam);
  }

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
          await Future.delayed(Duration(seconds: attempts * 2));
        }
      }
    }

    throw lastError;
  }

  void _fetchInBackground() async {
    try {
      final firstPageData = await _fetchWithRetry(pageParam: null);
      final newPages = [QueryPage(data: firstPageData, pageParam: null)];

      if (!_disposed) {
        await _cache.set(queryKey.toString(), newPages, ttl: config.cacheTime);

        if (state.hasData) {
          _updateState(
            InfiniteQueryState.success(
              newPages,
              hasNextPage: _calculateHasNextPage(newPages),
            ),
          );
        } else {
          _updateState(
            InfiniteQueryState.error(
              Exception('Background fetch failed'),
              newPages,
            ),
          );
        }
      }
    } catch (error) {
      debugPrint('Background fetch failed for ${queryKey.toString()}: $error');
    }
  }

  bool _isStale(List<QueryPage<T>> pages) {
    if (pages.isEmpty) return false;

    // Get the lastFetched from the current state, not from pages
    final lastFetched = state.lastFetched;
    if (lastFetched == null) return true;

    return DateTime.now().difference(lastFetched) > config.staleTime;
  }

  bool _calculateHasNextPage(List<QueryPage<T>> pages) {
    if (pages.isEmpty || getNextPageParam == null) return false;

    final nextPageParam = getNextPageParam!(
      pages.last.data,
      pages.map((page) => page.data).toList(),
    );

    return nextPageParam != null;
  }

  Future<void> invalidate({bool removeCache = false}) async {
    if (removeCache) {
      await _cache.remove(queryKey.toString());
    }
    _updateState(InfiniteQueryState.idle());
  }

  void dispose() {
    _disposed = true;
    _networkSubscription?.cancel();
    _stateController.close();
  }
}
