/// Defines the various statues a query can be in
enum QueryStatus{
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
enum MutationStatus{
  /// The mutation has not started or has been reset
  idle,

  /// The mutation is currently executing
  loading,

  /// The mutation completed successfully
  success,

  /// The mutation encountered an error
  error,
}