library flutter_tanstack_query;

// Core exports
export 'src/core/query_config.dart';
export 'src/core/query_state.dart';
export 'src/core/query_options.dart';
export 'src/core/types.dart';
export 'src/core/app_lifecycle_manager.dart';

// Query management
export 'src/query_client.dart';
export 'src/query_cache.dart';
export 'src/network_policy.dart';
export 'src/query.dart';
export 'src/infinite_query.dart';
export 'src/mutation.dart';

// Widget providers and utilities
export 'src/widgets/query_client_provider.dart';
export 'src/widgets/query_listener.dart';

// Hook-style API
export 'src/hooks/use_query.dart';
export 'src/hooks/use_mutation.dart';
export 'src/hooks/use_infinite_query.dart';
