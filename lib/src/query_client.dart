import 'dart:async';
import 'package:flutter/foundation.dart';
import 'query_cache.dart';
import 'network_policy.dart';
import 'query.dart';
import 'infinite_query.dart';
import 'mutation.dart';
import 'core/query_config.dart';
import 'core/types.dart';

/// The central client for managing all queries and mutations.
///
/// This class acts as a registry for [Query] and [Mutation] instances,
/// and provides methods to interact with them (e.g., invalidate, refetch).
class QueryClient {
  final QueryCache cache;
  final NetworkPolicy networkPolicy;

  // Registry for active queries and mutations
  final Map<String, Query> _queries = {};
  final Map<String, InfiniteQuery> _infiniteQueries = {};
  final Map<String, Mutation> _mutations = {};

  /// Creates a [QueryClient] instance.
  ///
  /// Requires instances of [QueryCache] and [NetworkPolicy].
  QueryClient({required this.cache, required this.networkPolicy});

  /// Retrieves or creates a [Query] instance.
  ///
  /// [queryKey] is a unique identifier for the query.
  /// [fetcher] is the function to fetch data if the query is not in cache or is stale.
  /// [config] provides specific configuration for this query.
  Query<T> getQuery<T>(
    List<Object> queryKey,
    Future<T> Function() fetcher, {
    QueryConfig config = const QueryConfig(),
  }) {
    final keyString = queryKey.toString();
    if (_queries.containsKey(keyString)) {
      return _queries[keyString] as Query<T>;
    }
    final query = Query<T>(
      queryKey: queryKey,
      fetcher: fetcher,
      cache: cache,
      networkPolicy: networkPolicy,
      config: config,
    );
    _queries[keyString] = query;
    debugPrint('Created new Query: $keyString');
    return query;
  }

  /// Retrieves or creates an [InfiniteQuery] instance.
  InfiniteQuery<T, PageParam> getInfiniteQuery<T, PageParam>(
    List<Object> queryKey,
    InfiniteQueryFetcher<T, PageParam> fetcher, {
    GetNextPageParam<T, PageParam>? getNextPageParam,
    GetPreviousPageParam<T, PageParam>? getPreviousPageParam,
    QueryConfig config = const QueryConfig(),
  }) {
    final keyString = queryKey.toString();
    if (_infiniteQueries.containsKey(keyString)) {
      return _infiniteQueries[keyString] as InfiniteQuery<T, PageParam>;
    }
    final query = InfiniteQuery<T, PageParam>(
      queryKey: queryKey,
      fetcher: fetcher,
      cache: cache,
      networkPolicy: networkPolicy,
      getNextPageParam: getNextPageParam,
      getPreviousPageParam: getPreviousPageParam,
      config: config,
    );
    _infiniteQueries[keyString] = query;
    debugPrint('Created new InfiniteQuery: $keyString');
    return query;
  }

  /// Retrieves or creates a [Mutation] instance.
  ///
  /// [mutationFn] is the function to execute the mutation.
  /// [config] provides specific configuration for this mutation.
  Mutation<T, V> getMutation<T, V>(
    String mutationKey,
    MutationFetcher<T, V> mutationFn, {
    MutationConfig<T, V> config = const MutationConfig(),
  }) {
    if (_mutations.containsKey(mutationKey)) {
      return _mutations[mutationKey] as Mutation<T, V>;
    }
    final mutation = Mutation<T, V>(
      mutationFn: mutationFn,
      cache: cache,
      queryClient: this, // Pass itself for invalidation
      config: config,
    );
    _mutations[mutationKey] = mutation;
    debugPrint('Created new Mutation: $mutationKey');
    return mutation;
  }

  /// Invalidates one or more queries.
  ///
  /// This will mark the queries as stale and trigger a refetch on next access.
  /// If the query is currently being observed, it will refetch immediately.
  void invalidateQueries(List<Object> queryKey) {
    final keyString = queryKey.toString();
    if (_queries.containsKey(keyString)) {
      (_queries[keyString] as Query).invalidate();
    } else if (_infiniteQueries.containsKey(keyString)) {
      (_infiniteQueries[keyString] as InfiniteQuery).invalidate();
    }
    debugPrint('Invalidated query: $keyString');
  }

  /// Refetches one or more queries, bypassing cache.
  void refetchQueries(List<Object> queryKey) {
    final keyString = queryKey.toString();
    if (_queries.containsKey(keyString)) {
      (_queries[keyString] as Query).refetch();
    } else if (_infiniteQueries.containsKey(keyString)) {
      (_infiniteQueries[keyString] as InfiniteQuery).refetch();
    }
    debugPrint('Refetched query: $keyString');
  }

  /// Disposes all managed queries and mutations.
  ///
  /// This should be called when the [QueryClient] is no longer needed,
  /// typically on application shutdown.
  void dispose() {
    for (final query in _queries.values) {
      query.dispose();
    }
    _queries.clear();

    for (final infiniteQuery in _infiniteQueries.values) {
      infiniteQuery.dispose();
    }
    _infiniteQueries.clear();

    for (final mutation in _mutations.values) {
      mutation.dispose();
    }
    _mutations.clear();
    debugPrint('QueryClient disposed. All managed queries/mutations disposed.');
  }
}
