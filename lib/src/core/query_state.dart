import 'package:meta/meta.dart';

import 'types.dart';

///Represents the state of a single query.
///
/// This class is immutable and provides convenient getters for common states.

@immutable
class QueryState<T> {
  /// The data returned by the query. Null if no data has been fetched or on error.
  final T? data;

  /// The error encountered during the query, if any
  final Object? error;

  ///The current status of the query (e.g., loading, success, error)
  final QueryStatus status;

  /// True if the data is considered stale and might be refetched in the background
  final bool isStale;

  /// The timestamp when the data was last successfully fetched
  final DateTime? lastFetched;

  /// Creates a new [QueryState] instance.
  const QueryState._({
    this.data,
    this.error,
    required this.status,
    required this.isStale,
    this.lastFetched,
  });

  /// Factory constructor for an initial idle state.
  factory QueryState.idle() =>
      const QueryState._(status: QueryStatus.idle, isStale: false);

  /// Factory constructor for a loading state.
  /// [previousData] can be provided to show existing data while loading.
  factory QueryState.loading([T? previousData]) => QueryState._(
    data: previousData,
    status: QueryStatus.loading,
    isStale:
        previousData !=
        null, // If there's previous data, it's stale while loading
  );

  /// Factory constructor for a success state.
  factory QueryState.success(T data, {bool isStale = false}) => QueryState._(
    data: data,
    status: QueryStatus.success,
    isStale: isStale,
    lastFetched: DateTime.now(),
  );

  /// Factory constructor for an error state.
  /// [previousData] can be provided to show existing data even on error.
  factory QueryState.error(Object error, [T? previousData]) => QueryState._(
    data: previousData,
    error: error,
    status: QueryStatus.error,
    isStale: previousData != null, // Data is stale on error
  );

  /// True if the query is currently fetching data.
  bool get isLoading => status == QueryStatus.loading;

  /// True if the query has successfully fetched data.
  bool get isSuccess => status == QueryStatus.success;

  /// True if the query encountered an error.
  bool get isError => status == QueryStatus.error;

  /// True if the query has data (even if it's stale or there's an error).
  bool get hasData => data != null;

  /// Creates a copy of this [QueryState] with updated values.
  QueryState<T> copyWith({
    T? data,
    Object? error,
    QueryStatus? status,
    bool? isStale,
    DateTime? lastFetched,
  }) {
    return QueryState._(
      data: data ?? this.data,
      error: error ?? this.error,
      status: status ?? this.status,
      isStale: isStale ?? this.isStale,
      lastFetched: lastFetched ?? this.lastFetched,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is QueryState<T> &&
        other.data == data &&
        other.error == error &&
        other.status == status &&
        other.isStale == isStale &&
        other.lastFetched == lastFetched;
  }

  @override
  int get hashCode {
    return Object.hash(data, error, status, isStale, lastFetched);
  }

  @override
  String toString() {
    return 'QueryState(data: $data, error: $error, status: $status, isStale: $isStale, lastFetched: $lastFetched)';
  }
}

/// Represents the state of a mutation
///
/// This class is immutable and provides convenient getters for common states.
@immutable
class MutationState<T> {
  /// The data returned by the mutation. Null if no data has been returned.
  final T? data;

  /// The error encountered during the mutation, if any
  final Object? error;

  /// The current status of the mutation (e.g., loading, success, error)
  final MutationStatus status;

  /// Creates a new [MutationState] instance.
  const MutationState._({this.data, this.error, required this.status});

  /// Factory constructor for an initial idle state.
  factory MutationState.idle() =>
      const MutationState._(status: MutationStatus.idle);

  /// Factory constructor for a loading state.
  factory MutationState.loading() =>
      const MutationState._(status: MutationStatus.loading);

  /// Factory constructor for a success state.
  factory MutationState.success(T data) =>
      MutationState._(data: data, status: MutationStatus.success);

  /// Factory constructor for an error state.
  factory MutationState.error(Object error) =>
      MutationState._(error: error, status: MutationStatus.error);

  /// True if the mutation is currently executing.
  bool get isLoading => status == MutationStatus.loading;

  /// True if the mutation completed successfully.
  bool get isSuccess => status == MutationStatus.success;

  /// True if the mutation encountered an error.
  bool get isError => status == MutationStatus.error;

  /// True if the mutation is in its initial state.
  bool get isIdle => status == MutationStatus.idle;

  /// Creates a copy of this [MutationState] with updated values.
  MutationState<T> copyWith({T? data, Object? error, MutationStatus? status}) {
    return MutationState._(
      data: data ?? this.data,
      error: error ?? this.error,
      status: status ?? this.status,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MutationState<T> &&
        other.data == data &&
        other.error == error &&
        other.status == status;
  }

  @override
  int get hashCode {
    return Object.hash(data, error, status);
  }

  @override
  String toString() {
    return 'MutationState(data: $data, error: $error, status: $status)';
  }
}
