import 'package:flutter/widgets.dart';
import '../core/query_state.dart';
import '../core/query_options.dart';
import '../core/query_config.dart';
import '../core/types.dart';
import '../widgets/query_client_provider.dart';
import '../widgets/query_listener.dart';

/// Result object for useQuery hook
class QueryResult<T> {
  /// Current query data
  final T? data;

  /// Current error if any
  final Object? error;

  /// Whether the query is currently loading
  final bool isLoading;

  /// Whether the query is currently fetching (including background refetch)
  final bool isFetching;

  /// Whether the query was successful
  final bool isSuccess;

  /// Whether the query has an error
  final bool isError;

  /// Whether the data is stale
  final bool isStale;

  /// Whether there is data
  final bool hasData;

  /// Function to manually refetch
  final Future<void> Function() refetch;

  /// Function to remove from cache
  final void Function() remove;

  const QueryResult({
    this.data,
    this.error,
    required this.isLoading,
    required this.isFetching,
    required this.isSuccess,
    required this.isError,
    required this.isStale,
    required this.hasData,
    required this.refetch,
    required this.remove,
  });

  /// Create QueryResult from QueryState
  factory QueryResult.fromState(
    QueryState<T> state, {
    required Future<void> Function() refetch,
    required void Function() remove,
  }) {
    return QueryResult<T>(
      data: state.data,
      error: state.error,
      isLoading: state.isLoading,
      isFetching:
          state.isLoading, // TODO: Distinguish between loading and fetching
      isSuccess: state.isSuccess,
      isError: state.isError,
      isStale: state.isStale,
      hasData: state.hasData,
      refetch: refetch,
      remove: remove,
    );
  }
}

/// Hook-style widget for using queries
class UseQuery<T> extends StatelessWidget {
  /// Query options
  final QueryOptions<T> options;

  /// Builder function
  final Widget Function(BuildContext context, QueryResult<T> result) builder;

  const UseQuery({super.key, required this.options, required this.builder});

  @override
  Widget build(BuildContext context) {
    final queryClient = QueryClientProvider.of(context);

    // Get or create the query
    final query = queryClient.getQuery<T>(
      options.queryKey,
      options.queryFn ?? () => throw QueryError('Query function is required'),
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

    return QueryListener<QueryState<T>>(
      stream: query.stateStream,
      initialData: query.state,
      builder: (context, state) {
        final result = QueryResult.fromState(
          state,
          refetch: () => query.refetch(),
          remove: () => query.invalidate(removeCache: true),
        );

        // Call lifecycle callbacks
        if (state.isSuccess && options.onSuccess != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (state.data != null) {
              options.onSuccess!(state.data as T);
            }
          });
        }

        if (state.isError && options.onError != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            options.onError!(state.error!);
          });
        }

        if ((state.isSuccess || state.isError) && options.onSettled != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            options.onSettled!(state.data, state.error);
          });
        }

        return builder(context, result);
      },
    );
  }
}

/// Convenience function to create UseQuery widget
UseQuery<T> useQuery<T>(
  List<Object> queryKey,
  QueryFetcher<T> fetcher, {
  QueryOptions<T>? options,
  required Widget Function(BuildContext context, QueryResult<T> result) builder,
}) {
  final queryOptions =
      options?.copyWith(queryKey: queryKey, queryFn: fetcher) ??
      QueryOptions<T>(queryKey: queryKey, queryFn: fetcher);

  return UseQuery<T>(options: queryOptions, builder: builder);
}
