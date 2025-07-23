/// Defines the various statues a query can be in
enum QueryStatus {
  /// The query has not started or has been reset
  idle,

  /// The query is currently fetching data
  loading,

  /// The query has successfully fetched data
  success,

  /// The query encountered an error during data fetching
  error,

  /// The query has data, but it is considered stale and might be refetched in the background.
  stale,
}

/// Defines the various statuses a mutation can be in
enum MutationStatus {
  /// The mutation has not started or has been reset
  idle,

  /// The mutation is currently executing
  loading,

  /// The mutation completed successfully
  success,

  /// The mutation encountered an error
  error,
}

/// Function signature for query fetchers
typedef QueryFetcher<T> = Future<T> Function();

/// Function signature for mutation fetchers
/// [T] is the return type of the mutation
/// [V] is the type of variables passed to the mutation
typedef MutationFetcher<T, V> = Future<T> Function(V variables);

/// Function signature for infinite query fetchers
typedef InfiniteQueryFetcher<T, PageParam> =
    Future<T> Function({PageParam? pageParam});

/// Function signature for determining the next page parameter
typedef GetNextPageParam<T, PageParam> =
    PageParam? Function(T lastPage, List<T> allPages);

/// Function signature for determining the previous page parameter
typedef GetPreviousPageParam<T, PageParam> =
    PageParam? Function(T firstPage, List<T> allPages);

/// Custom error class for query-related errors
class QueryError extends Error {
  final String message;
  final Object? originalError;
  final StackTrace? originalStackTrace;
  final String? queryKey;

  QueryError(
    this.message, {
    this.originalError,
    this.originalStackTrace,
    this.queryKey,
  });

  @override
  String toString() {
    final buffer = StringBuffer('QueryError: $message');
    if (queryKey != null) {
      buffer.write(' (Query: $queryKey)');
    }
    if (originalError != null) {
      buffer.write('\nOriginal error: $originalError');
    }
    return buffer.toString();
  }
}

/// Custom error class for mutation-related errors
class MutationError extends Error {
  final String message;
  final Object? originalError;
  final StackTrace? originalStackTrace;
  final dynamic variables;

  MutationError(
    this.message, {
    this.originalError,
    this.originalStackTrace,
    this.variables,
  });

  @override
  String toString() {
    final buffer = StringBuffer('MutationError: $message');
    if (variables != null) {
      buffer.write('\nVariables: $variables');
    }
    if (originalError != null) {
      buffer.write('\nOriginal error: $originalError');
    }
    return buffer.toString();
  }
}

/// Retry configuration for failed requests
class RetryConfig {
  /// Number of retry attempts
  final int attempts;

  /// Base delay between retries
  final Duration delay;

  /// Whether delay should increase exponentially
  final bool exponentialBackoff;

  /// Maximum delay between retries
  final Duration maxDelay;

  /// Function to determine if error should be retried
  final bool Function(Object error)? shouldRetry;

  const RetryConfig({
    this.attempts = 3,
    this.delay = const Duration(seconds: 1),
    this.exponentialBackoff = true,
    this.maxDelay = const Duration(seconds: 30),
    this.shouldRetry,
  });

  /// Get delay for specific attempt
  Duration getDelay(int attempt) {
    if (!exponentialBackoff) return delay;

    final exponentialDelay = delay * (1 << (attempt - 1));
    return exponentialDelay > maxDelay ? maxDelay : exponentialDelay;
  }
}
