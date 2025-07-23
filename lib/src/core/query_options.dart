import 'types.dart';

/// Comprehensive query options that extend QueryConfig
class QueryOptions<T> {
  /// Query key
  final List<Object> queryKey;

  /// Query fetcher function
  final QueryFetcher<T>? queryFn;

  /// The duration after which cached data is considered stale
  final Duration staleTime;

  /// The duration for which data remains in cache
  final Duration cacheTime;

  /// Retry configuration
  final RetryConfig retryConfig;

  /// Whether to refetch when window regains focus
  final bool refetchOnWindowFocus;

  /// Whether to refetch when network reconnects
  final bool refetchOnReconnect;

  /// Whether to refetch when component mounts
  final bool refetchOnMount;

  /// Whether the query is enabled
  final bool enabled;

  /// Initial data to use while loading
  final T? initialData;

  /// Placeholder data to show while loading
  final T? placeholderData;

  /// Whether to keep previous data while fetching new data
  final bool keepPreviousData;

  /// Whether to structure error as QueryError
  final bool structuralSharing;

  /// Callback for successful query
  final void Function(T data)? onSuccess;

  /// Callback for query error
  final void Function(Object error)? onError;

  /// Callback for settled query (success or error)
  final void Function(T? data, Object? error)? onSettled;

  /// Data selector to transform the data
  final R Function<R>(T data)? select;

  /// Network mode for the query
  final NetworkMode networkMode;

  /// Query metadata
  final Map<String, dynamic>? meta;

  const QueryOptions({
    required this.queryKey,
    this.queryFn,
    this.staleTime = const Duration(minutes: 5),
    this.cacheTime = const Duration(minutes: 30),
    this.retryConfig = const RetryConfig(),
    this.refetchOnWindowFocus = true,
    this.refetchOnReconnect = true,
    this.refetchOnMount = true,
    this.enabled = true,
    this.initialData,
    this.placeholderData,
    this.keepPreviousData = false,
    this.structuralSharing = true,
    this.onSuccess,
    this.onError,
    this.onSettled,
    this.select,
    this.networkMode = NetworkMode.online,
    this.meta,
  });

  QueryOptions<T> copyWith({
    List<Object>? queryKey,
    QueryFetcher<T>? queryFn,
    Duration? staleTime,
    Duration? cacheTime,
    RetryConfig? retryConfig,
    bool? refetchOnWindowFocus,
    bool? refetchOnReconnect,
    bool? refetchOnMount,
    bool? enabled,
    T? initialData,
    T? placeholderData,
    bool? keepPreviousData,
    bool? structuralSharing,
    void Function(T data)? onSuccess,
    void Function(Object error)? onError,
    void Function(T? data, Object? error)? onSettled,
    R Function<R>(T data)? select,
    NetworkMode? networkMode,
    Map<String, dynamic>? meta,
  }) {
    return QueryOptions<T>(
      queryKey: queryKey ?? this.queryKey,
      queryFn: queryFn ?? this.queryFn,
      staleTime: staleTime ?? this.staleTime,
      cacheTime: cacheTime ?? this.cacheTime,
      retryConfig: retryConfig ?? this.retryConfig,
      refetchOnWindowFocus: refetchOnWindowFocus ?? this.refetchOnWindowFocus,
      refetchOnReconnect: refetchOnReconnect ?? this.refetchOnReconnect,
      refetchOnMount: refetchOnMount ?? this.refetchOnMount,
      enabled: enabled ?? this.enabled,
      initialData: initialData ?? this.initialData,
      placeholderData: placeholderData ?? this.placeholderData,
      keepPreviousData: keepPreviousData ?? this.keepPreviousData,
      structuralSharing: structuralSharing ?? this.structuralSharing,
      onSuccess: onSuccess ?? this.onSuccess,
      onError: onError ?? this.onError,
      onSettled: onSettled ?? this.onSettled,
      select: select ?? this.select,
      networkMode: networkMode ?? this.networkMode,
      meta: meta ?? this.meta,
    );
  }
}

/// Mutation options
class MutationOptions<T, V> {
  /// Mutation function
  final MutationFetcher<T, V>? mutationFn;

  /// Retry configuration for mutations
  final RetryConfig retryConfig;

  /// Network mode for the mutation
  final NetworkMode networkMode;

  /// Callback for successful mutation
  final void Function(T data, V variables)? onSuccess;

  /// Callback for mutation error
  final void Function(Object error, V variables)? onError;

  /// Callback for settled mutation
  final void Function(T? data, Object? error, V variables)? onSettled;

  /// Callback before mutation starts
  final void Function(V variables)? onMutate;

  /// Query keys to invalidate on success
  final List<List<Object>> invalidateQueries;

  /// Query keys to refetch on success
  final List<List<Object>> refetchQueries;

  /// Mutation metadata
  final Map<String, dynamic>? meta;

  const MutationOptions({
    this.mutationFn,
    this.retryConfig = const RetryConfig(
      attempts: 0,
    ), // No retry by default for mutations
    this.networkMode = NetworkMode.online,
    this.onSuccess,
    this.onError,
    this.onSettled,
    this.onMutate,
    this.invalidateQueries = const [],
    this.refetchQueries = const [],
    this.meta,
  });

  MutationOptions<T, V> copyWith({
    MutationFetcher<T, V>? mutationFn,
    RetryConfig? retryConfig,
    NetworkMode? networkMode,
    void Function(T data, V variables)? onSuccess,
    void Function(Object error, V variables)? onError,
    void Function(T? data, Object? error, V variables)? onSettled,
    void Function(V variables)? onMutate,
    List<List<Object>>? invalidateQueries,
    List<List<Object>>? refetchQueries,
    Map<String, dynamic>? meta,
  }) {
    return MutationOptions<T, V>(
      mutationFn: mutationFn ?? this.mutationFn,
      retryConfig: retryConfig ?? this.retryConfig,
      networkMode: networkMode ?? this.networkMode,
      onSuccess: onSuccess ?? this.onSuccess,
      onError: onError ?? this.onError,
      onSettled: onSettled ?? this.onSettled,
      onMutate: onMutate ?? this.onMutate,
      invalidateQueries: invalidateQueries ?? this.invalidateQueries,
      refetchQueries: refetchQueries ?? this.refetchQueries,
      meta: meta ?? this.meta,
    );
  }
}

/// Network mode options
enum NetworkMode {
  /// Only run when online
  online,

  /// Always run regardless of network status
  always,

  /// Run offline first, then online
  offlineFirst,
}

/// Infinite query options
class InfiniteQueryOptions<T, PageParam> {
  /// Query key
  final List<Object> queryKey;

  /// Query fetcher function
  final InfiniteQueryFetcher<T, PageParam>? queryFn;

  /// Function to get next page param
  final GetNextPageParam<T, PageParam>? getNextPageParam;

  /// Function to get previous page param
  final GetPreviousPageParam<T, PageParam>? getPreviousPageParam;

  /// Initial page param
  final PageParam? initialPageParam;

  /// The duration after which cached data is considered stale
  final Duration staleTime;

  /// The duration for which data remains in cache
  final Duration cacheTime;

  /// Retry configuration
  final RetryConfig retryConfig;

  /// Whether to refetch when window regains focus
  final bool refetchOnWindowFocus;

  /// Whether to refetch when network reconnects
  final bool refetchOnReconnect;

  /// Whether the query is enabled
  final bool enabled;

  /// Maximum number of pages to keep in memory
  final int? maxPages;

  /// Network mode for the query
  final NetworkMode networkMode;

  const InfiniteQueryOptions({
    required this.queryKey,
    this.queryFn,
    this.getNextPageParam,
    this.getPreviousPageParam,
    this.initialPageParam,
    this.staleTime = const Duration(minutes: 5),
    this.cacheTime = const Duration(minutes: 30),
    this.retryConfig = const RetryConfig(),
    this.refetchOnWindowFocus = true,
    this.refetchOnReconnect = true,
    this.enabled = true,
    this.maxPages,
    this.networkMode = NetworkMode.online,
  });

  InfiniteQueryOptions<T, PageParam> copyWith({
    List<Object>? queryKey,
    InfiniteQueryFetcher<T, PageParam>? queryFn,
    GetNextPageParam<T, PageParam>? getNextPageParam,
    GetPreviousPageParam<T, PageParam>? getPreviousPageParam,
    PageParam? initialPageParam,
    Duration? staleTime,
    Duration? cacheTime,
    RetryConfig? retryConfig,
    bool? refetchOnWindowFocus,
    bool? refetchOnReconnect,
    bool? enabled,
    int? maxPages,
    NetworkMode? networkMode,
  }) {
    return InfiniteQueryOptions<T, PageParam>(
      queryKey: queryKey ?? this.queryKey,
      queryFn: queryFn ?? this.queryFn,
      getNextPageParam: getNextPageParam ?? this.getNextPageParam,
      getPreviousPageParam: getPreviousPageParam ?? this.getPreviousPageParam,
      initialPageParam: initialPageParam ?? this.initialPageParam,
      staleTime: staleTime ?? this.staleTime,
      cacheTime: cacheTime ?? this.cacheTime,
      retryConfig: retryConfig ?? this.retryConfig,
      refetchOnWindowFocus: refetchOnWindowFocus ?? this.refetchOnWindowFocus,
      refetchOnReconnect: refetchOnReconnect ?? this.refetchOnReconnect,
      enabled: enabled ?? this.enabled,
      maxPages: maxPages ?? this.maxPages,
      networkMode: networkMode ?? this.networkMode,
    );
  }
}
