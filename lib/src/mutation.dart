import 'dart:async';
import 'package:flutter/foundation.dart';
import 'core/query_state.dart';
import 'core/query_config.dart';
import 'core/types.dart';
import 'query_cache.dart';
import 'query_client.dart'; // To access QueryClient for invalidation

/// Manages the state and lifecycle of a data mutation (e.g., POST, PUT, DELETE).
///
/// This class handles optimistic updates, error handling, and query invalidation.
class Mutation<T, V> {
  /// The function responsible for executing the mutation.
  final MutationFetcher<T, V> mutationFn;

  /// Configuration options for this specific mutation.
  final MutationConfig<T, V> config;

  final QueryCache _cache;
  final QueryClient _queryClient; // To invalidate queries

  /// The stream controller for emitting [MutationState] changes.
  final StreamController<MutationState<T>> _stateController =
      StreamController<MutationState<T>>.broadcast();

  /// The current state of the mutation.
  MutationState<T> _state;

  bool _disposed = false;
  
  // Data for rollback in case of optimistic update failure
  Map<List<Object>, dynamic> _rollbackCacheData = {};
  
  /// Creates a [Mutation] instance.
  Mutation({
    required this.mutationFn,
    required QueryCache cache,
    required QueryClient queryClient,
    this.config = const MutationConfig(),
  })  : _cache = cache,
        _queryClient = queryClient,
        _state = MutationState.idle();

  /// Exposes the stream of mutation state changes.
  Stream<MutationState<T>> get stateStream => _stateController.stream;

  /// Gets the current state of the mutation.
  MutationState<T> get state => _state;

  /// Updates the internal state and emits it through the stream.
  void _updateState(MutationState<T> newState) {
    if (_disposed) return;
    _state = newState;
    if (!_stateController.isClosed) {
      _stateController.add(_state);
    }
  }

  /// Executes the mutation with the given [variables].
  ///
  /// Handles optimistic updates, retries, and query invalidation.
  Future<T> mutate(V variables) async {
    if (_disposed) throw StateError('Mutation has been disposed');

    try {
      _updateState(MutationState.loading());

      // Apply optimistic update if configured
      if (config.optimisticUpdate != null) {
        await _applyOptimisticUpdate(variables);
      }

      // Execute mutation with optional timeout
      final result = await (config.timeout != null
          ? mutationFn(variables).timeout(config.timeout!)
          : mutationFn(variables));

      // Update state with result
      if (!_disposed) {
        _updateState(MutationState.success(result));
        config.onSuccess?.call(result);
      }

      // Invalidate specified queries
      await _invalidateQueries();

      return result;
    } catch (error) {
      debugPrint('Mutation failed: $error');
      // Rollback optimistic updates if they were applied
      if (config.optimisticUpdate != null) {
        await _rollbackOptimisticUpdate();
      }

      if (!_disposed) {
        _updateState(MutationState.error(error));
        config.onError?.call(error);
      }
      rethrow; // Re-throw the error for the caller to handle
    } finally {
      _rollbackCacheData.clear(); // Clear rollback data after attempt
    }
  }

  /// Applies optimistic updates to relevant queries in the cache.
  Future<void> _applyOptimisticUpdate(V variables) async {
    _rollbackCacheData.clear();

    for (final queryKey in config.invalidateQueries) {
      final cachedData = await _cache.get(queryKey.toString());
      if (cachedData != null) {
        // Store original data for rollback
        _rollbackCacheData[queryKey] = cachedData;

        // Apply optimistic update
        final optimisticData = config.optimisticUpdate!(variables, cachedData as T);
        await _cache.set(queryKey.toString(), optimisticData);
        // Also update the in-memory state of the Query object if it exists
        _queryClient.getQuery(queryKey, () async => optimisticData).setData(optimisticData);
      }
    }
    debugPrint('Optimistic update applied for mutation.');
  }

  /// Rolls back optimistic updates in case of mutation failure.
  Future<void> _rollbackOptimisticUpdate() async {
    for (final entry in _rollbackCacheData.entries) {
      final queryKey = entry.key;
      final originalData = entry.value;
      await _cache.set(queryKey.toString(), originalData);
      // Also revert the in-memory state of the Query object
      _queryClient.getQuery(queryKey, () async => originalData).setData(originalData);
    }
    debugPrint('Optimistic update rolled back.');
  }

  /// Invalidates queries specified in the mutation config.
  Future<void> _invalidateQueries() async {
    for (final queryKey in config.invalidateQueries) {
      _queryClient.invalidateQueries(queryKey);
    }
    debugPrint('Queries invalidated after mutation success.');
  }

  /// Resets the mutation's state to idle.
  void reset() {
    if (!_disposed) {
      _updateState(MutationState.idle());
    }
    debugPrint('Mutation state reset.');
  }

  /// Disposes the mutation's resources.
  void dispose() {
    _disposed = true;
    _stateController.close();
    debugPrint('Mutation disposed.');
  }
}