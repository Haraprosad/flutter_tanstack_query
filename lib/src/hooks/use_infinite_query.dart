import 'package:flutter/widgets.dart';
import '../core/query_options.dart';
import '../core/query_config.dart';
import '../core/types.dart';
import '../infinite_query.dart';
import '../widgets/query_client_provider.dart';
import '../widgets/query_listener.dart';

/// Result object for useInfiniteQuery hook
class InfiniteQueryResult<T, PageParam> {
  /// All pages of data
  final List<T> data;

  /// Current error if any
  final Object? error;

  /// Whether the query is currently loading
  final bool isLoading;

  /// Whether the query is currently fetching (including background refetch)
  final bool isFetching;

  /// Whether currently fetching next page
  final bool isFetchingNextPage;

  /// Whether currently fetching previous page
  final bool isFetchingPreviousPage;

  /// Whether the query was successful
  final bool isSuccess;

  /// Whether the query has an error
  final bool isError;

  /// Whether the data is stale
  final bool isStale;

  /// Whether there is a next page
  final bool hasNextPage;

  /// Whether there is a previous page
  final bool hasPreviousPage;

  /// Function to fetch next page
  final Future<void> Function() fetchNextPage;

  /// Function to fetch previous page
  final Future<void> Function() fetchPreviousPage;

  /// Function to manually refetch all pages
  final Future<void> Function() refetch;

  /// Function to remove from cache
  final void Function() remove;

  const InfiniteQueryResult({
    required this.data,
    this.error,
    required this.isLoading,
    required this.isFetching,
    required this.isFetchingNextPage,
    required this.isFetchingPreviousPage,
    required this.isSuccess,
    required this.isError,
    required this.isStale,
    required this.hasNextPage,
    required this.hasPreviousPage,
    required this.fetchNextPage,
    required this.fetchPreviousPage,
    required this.refetch,
    required this.remove,
  });

  /// Create InfiniteQueryResult from InfiniteQueryState
  factory InfiniteQueryResult.fromState(
    InfiniteQueryState<T> state, {
    required Future<void> Function() fetchNextPage,
    required Future<void> Function() fetchPreviousPage,
    required Future<void> Function() refetch,
    required void Function() remove,
  }) {
    return InfiniteQueryResult<T, PageParam>(
      data: state.pages.map((page) => page.data).toList(),
      error: state.error,
      isLoading: state.isLoading,
      isFetching:
          state.isLoading, // TODO: Distinguish between loading and fetching
      isFetchingNextPage: state.isFetchingNextPage,
      isFetchingPreviousPage: false, // TODO: Add to InfiniteQueryState
      isSuccess: state.isSuccess,
      isError: state.isError,
      isStale: state.isStale,
      hasNextPage: state.hasNextPage,
      hasPreviousPage: false, // TODO: Add to InfiniteQueryState
      fetchNextPage: fetchNextPage,
      fetchPreviousPage: fetchPreviousPage,
      refetch: refetch,
      remove: remove,
    );
  }
}

/// Hook-style widget for using infinite queries
class UseInfiniteQuery<T, PageParam> extends StatelessWidget {
  /// Infinite query options
  final InfiniteQueryOptions<T, PageParam> options;

  /// Builder function
  final Widget Function(
    BuildContext context,
    InfiniteQueryResult<T, PageParam> result,
  )
  builder;

  const UseInfiniteQuery({
    super.key,
    required this.options,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final queryClient = QueryClientProvider.of(context);

    // Get or create the infinite query
    final infiniteQuery = queryClient.getInfiniteQuery<T, PageParam>(
      options.queryKey,
      options.queryFn ??
          ({pageParam}) => throw QueryError('Query function is required'),
      getNextPageParam: options.getNextPageParam,
      getPreviousPageParam: options.getPreviousPageParam,
      config: QueryConfig(
        staleTime: options.staleTime,
        cacheTime: options.cacheTime,
        retryCount: options.retryConfig.attempts,
        retryDelay: options.retryConfig.delay,
        refetchOnWindowFocus: options.refetchOnWindowFocus,
        refetchOnReconnect: options.refetchOnReconnect,
        enabled: options.enabled,
      ),
    );

    return QueryListener<InfiniteQueryState<T>>(
      stream: infiniteQuery.stateStream,
      initialData: infiniteQuery.state,
      builder: (context, state) {
        final result = InfiniteQueryResult<T, PageParam>.fromState(
          state,
          fetchNextPage: () => infiniteQuery.fetchNextPage(),
          fetchPreviousPage: () => infiniteQuery.fetchPreviousPage(),
          refetch: () => infiniteQuery.refetch(),
          remove: () => infiniteQuery.invalidate(removeCache: true),
        );

        return builder(context, result);
      },
    );
  }
}

/// Convenience function to create UseInfiniteQuery widget
UseInfiniteQuery<T, PageParam> useInfiniteQuery<T, PageParam>(
  List<Object> queryKey,
  Future<T> Function({PageParam? pageParam}) fetcher, {
  PageParam? Function(T lastPage, List<T> allPages)? getNextPageParam,
  PageParam? Function(T firstPage, List<T> allPages)? getPreviousPageParam,
  InfiniteQueryOptions<T, PageParam>? options,
  required Widget Function(
    BuildContext context,
    InfiniteQueryResult<T, PageParam> result,
  )
  builder,
}) {
  final queryOptions =
      options?.copyWith(
        queryKey: queryKey,
        queryFn: fetcher,
        getNextPageParam: getNextPageParam,
        getPreviousPageParam: getPreviousPageParam,
      ) ??
      InfiniteQueryOptions<T, PageParam>(
        queryKey: queryKey,
        queryFn: fetcher,
        getNextPageParam: getNextPageParam,
        getPreviousPageParam: getPreviousPageParam,
      );

  return UseInfiniteQuery<T, PageParam>(
    options: queryOptions,
    builder: builder,
  );
}
