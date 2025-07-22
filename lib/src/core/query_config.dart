import 'package:flutter/foundation.dart'; // For listEquals in MutationConfig's operator==

/// Configuration options for a single query.
class QueryConfig {
  /// The duration after which cached data is considered stale.
  /// If data is stale, it will be refetched in the background on subsequent access.
  final Duration staleTime;

  /// The duration for which data remains in the cache after it's no longer actively observed.
  /// After this time, the data is garbage collected.
  final Duration cacheTime;

  /// The number of times to retry a failed fetch.
  final int retryCount;

  /// The base delay between retries. The actual delay will increase with each attempt.
  final Duration retryDelay;

  /// Whether to refetch the query when the application window regains focus.
  final bool refetchOnWindowFocus;

  /// Whether to refetch the query when the network connection is restored.
  final bool refetchOnReconnect;

  /// Whether the query is enabled. If false, the query will not fetch data.
  final bool enabled;

  /// Creates a new [QueryConfig] instance.
  const QueryConfig({
    this.staleTime = const Duration(minutes: 5),
    this.cacheTime = const Duration(minutes: 30),
    this.retryCount = 3,
    this.retryDelay = const Duration(seconds: 1),
    this.refetchOnWindowFocus = true,
    this.refetchOnReconnect = true,
    this.enabled = true,
  });

  /// Creates a copy of this [QueryConfig] with updated values.
  QueryConfig copyWith({
    Duration? staleTime,
    Duration? cacheTime,
    int? retryCount,
    Duration? retryDelay,
    bool? refetchOnWindowFocus,
    bool? refetchOnReconnect,
    bool? enabled,
  }) {
    return QueryConfig(
      staleTime: staleTime ?? this.staleTime,
      cacheTime: cacheTime ?? this.cacheTime,
      retryCount: retryCount ?? this.retryCount,
      retryDelay: retryDelay ?? this.retryDelay,
      refetchOnWindowFocus: refetchOnWindowFocus ?? this.refetchOnWindowFocus,
      refetchOnReconnect: refetchOnReconnect ?? this.refetchOnReconnect,
      enabled: enabled ?? this.enabled,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is QueryConfig &&
        other.runtimeType == runtimeType &&
        other.staleTime == staleTime &&
        other.cacheTime == cacheTime &&
        other.retryCount == retryCount &&
        other.retryDelay == retryDelay &&
        other.refetchOnWindowFocus == refetchOnWindowFocus &&
        other.refetchOnReconnect == refetchOnReconnect &&
        other.enabled == enabled;
  }

  @override
  int get hashCode {
    return Object.hash(
      staleTime,
      cacheTime,
      retryCount,
      retryDelay,
      refetchOnWindowFocus,
      refetchOnReconnect,
      enabled,
    );
  }
}

/// A wrapper class used in copyWith to distinguish between a null value
/// being explicitly provided and a parameter being omitted.
///
/// If a copyWith parameter is of type `Value<T>?`:
/// - `null` means the parameter was omitted (keep existing value).
/// - `Value(null)` means explicitly set the field to null.
/// - `Value(someValue)` means set the field to `someValue`.
class Value<T> {
  final T value;
  const Value(this.value);
}

/// Configuration options for a single mutation.
class MutationConfig<T, V> {
  /// An optional function to optimistically update cached data before the mutation completes.
  ///
  /// [variables] are the input to the mutation.
  /// [previousData] is the current data in the cache.
  /// Returns the new optimistic data.
  final T Function(V variables, T? previousData)? optimisticUpdate;

  /// A list of query keys to invalidate after the mutation successfully completes.
  /// Invalidation will trigger a refetch of the associated queries.
  final List<List<Object>> invalidateQueries;

  /// A callback function executed when the mutation successfully completes.
  final void Function(T data)? onSuccess;

  /// A callback function executed if the mutation encounters an error.
  final void Function(Object error)? onError;

  /// An optional timeout for the mutation's API call.
  final Duration? timeout;

  /// Creates a new [MutationConfig] instance.
  const MutationConfig({
    this.optimisticUpdate,
    this.invalidateQueries = const [],
    this.onSuccess,
    this.onError,
    this.timeout,
  });

  /// Creates a copy of this [MutationConfig] with updated values.
  ///
  /// For nullable properties like `optimisticUpdate`, `onSuccess`, `onError`, and `timeout`:
  /// - Omit the parameter to keep its current value.
  /// - Pass `Value(null)` to explicitly set the property to `null`.
  /// - Pass `Value(newValue)` to set the property to a new non-null value.
  ///
  /// For `invalidateQueries`, which is a non-nullable list:
  /// - Omit the parameter to keep its current value.
  /// - Pass `[]` or a new list to set its value.
  MutationConfig<T, V> copyWith({
    Value<T Function(V variables, T? previousData)?>? optimisticUpdate,
    List<List<Object>>? invalidateQueries,
    Value<void Function(T data)?>? onSuccess,
    Value<void Function(Object error)?>? onError,
    Value<Duration?>? timeout,
  }) {
    return MutationConfig<T, V>(
      optimisticUpdate: optimisticUpdate != null
          ? optimisticUpdate.value
          : this.optimisticUpdate,
      invalidateQueries: invalidateQueries ?? this.invalidateQueries,
      onSuccess: onSuccess != null ? onSuccess.value : this.onSuccess,
      onError: onError != null ? onError.value : this.onError,
      timeout: timeout != null ? timeout.value : this.timeout,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MutationConfig<T, V> &&
        other.runtimeType == runtimeType && // Ensure same generic types
        other.optimisticUpdate == optimisticUpdate &&
        listEquals(
          other.invalidateQueries,
          invalidateQueries,
        ) && // Deep comparison
        other.onSuccess == onSuccess &&
        other.onError == onError &&
        other.timeout == timeout;
  }

  @override
  int get hashCode {
    return Object.hash(
      optimisticUpdate,
      // Create a hash for the list of lists
      Object.hashAll(invalidateQueries.map((e) => Object.hashAll(e))),
      onSuccess,
      onError,
      timeout,
    );
  }
}
