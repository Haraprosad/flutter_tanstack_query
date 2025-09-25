import 'package:flutter_tanstack_query/flutter_tanstack_query.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FlutterTanStackQuery', () {
    late QueryClient queryClient;
    late QueryCache cache;
    late NetworkPolicy networkPolicy;

    setUp(() async {
      cache = QueryCache.instance;
      networkPolicy = NetworkPolicy.instance;

      await cache.initialize();
      await networkPolicy.initialize();

      queryClient = QueryClient(cache: cache, networkPolicy: networkPolicy);
    });

    tearDown(() {
      queryClient.dispose();
    });

    group('Core Types', () {
      test('should create QueryError with context', () {
        final error = QueryError(
          'Test error',
          queryKey: 'test-query',
          originalError: Exception('Original'),
        );

        expect(error.message, equals('Test error'));
        expect(error.queryKey, equals('test-query'));
        expect(error.originalError, isA<Exception>());
        expect(error.toString(), contains('Test error'));
        expect(error.toString(), contains('test-query'));
      });

      test('should create MutationError with context', () {
        final error = MutationError(
          'Mutation failed',
          variables: {'key': 'value'},
          originalError: Exception('Original'),
        );

        expect(error.message, equals('Mutation failed'));
        expect(error.variables, equals({'key': 'value'}));
        expect(error.originalError, isA<Exception>());
        expect(error.toString(), contains('Mutation failed'));
      });

      test('should configure retry settings', () {
        const retryConfig = RetryConfig(
          attempts: 5,
          delay: Duration(seconds: 2),
          exponentialBackoff: true,
          maxDelay: Duration(minutes: 1),
        );

        expect(retryConfig.attempts, equals(5));
        expect(retryConfig.delay, equals(Duration(seconds: 2)));
        expect(retryConfig.exponentialBackoff, isTrue);
        expect(retryConfig.maxDelay, equals(Duration(minutes: 1)));

        // Test delay calculation
        expect(retryConfig.getDelay(1), equals(Duration(seconds: 2)));
        expect(retryConfig.getDelay(2), equals(Duration(seconds: 4)));
        expect(retryConfig.getDelay(3), equals(Duration(seconds: 8)));
      });
    });

    group('QueryClient', () {
      test('should create and manage queries', () {
        final query = queryClient.getQuery<String>([
          'test',
        ], () async => 'test data');

        expect(query, isNotNull);
        expect(query.queryKey, equals(['test']));
      });

      test('should reuse existing queries with same key', () {
        final query1 = queryClient.getQuery<String>([
          'test',
        ], () async => 'test data');

        final query2 = queryClient.getQuery<String>([
          'test',
        ], () async => 'test data');

        expect(identical(query1, query2), isTrue);
      });

      test('should create and manage mutations', () {
        final mutation = queryClient.getMutation<String, String>(
          'test-mutation',
          (variables) async => 'mutated: $variables',
        );

        expect(mutation, isNotNull);
      });
    });

    group('Query States', () {
      test('should have correct initial state', () {
        final state = QueryState<String>.idle();

        expect(state.status, equals(QueryStatus.idle));
        expect(state.data, isNull);
        expect(state.error, isNull);
        expect(state.isLoading, isFalse);
        expect(state.isSuccess, isFalse);
        expect(state.isError, isFalse);
        expect(state.hasData, isFalse);
      });

      test('should create loading state', () {
        final state = QueryState<String>.loading();

        expect(state.status, equals(QueryStatus.loading));
        expect(state.isLoading, isTrue);
        expect(state.isSuccess, isFalse);
        expect(state.isError, isFalse);
      });

      test('should create success state', () {
        final state = QueryState<String>.success('test data');

        expect(state.status, equals(QueryStatus.success));
        expect(state.data, equals('test data'));
        expect(state.isLoading, isFalse);
        expect(state.isSuccess, isTrue);
        expect(state.isError, isFalse);
        expect(state.hasData, isTrue);
      });

      test('should create error state', () {
        final error = Exception('Test error');
        final state = QueryState<String>.error(error);

        expect(state.status, equals(QueryStatus.error));
        expect(state.error, equals(error));
        expect(state.isLoading, isFalse);
        expect(state.isSuccess, isFalse);
        expect(state.isError, isTrue);
      });
    });

    group('Mutation States', () {
      test('should have correct initial state', () {
        final state = MutationState<String>.idle();

        expect(state.status, equals(MutationStatus.idle));
        expect(state.data, isNull);
        expect(state.error, isNull);
        expect(state.isLoading, isFalse);
        expect(state.isSuccess, isFalse);
        expect(state.isError, isFalse);
        expect(state.isIdle, isTrue);
      });

      test('should create loading state', () {
        final state = MutationState<String>.loading();

        expect(state.status, equals(MutationStatus.loading));
        expect(state.isLoading, isTrue);
        expect(state.isSuccess, isFalse);
        expect(state.isError, isFalse);
        expect(state.isIdle, isFalse);
      });

      test('should create success state', () {
        final state = MutationState<String>.success('test result');

        expect(state.status, equals(MutationStatus.success));
        expect(state.data, equals('test result'));
        expect(state.isLoading, isFalse);
        expect(state.isSuccess, isTrue);
        expect(state.isError, isFalse);
        expect(state.isIdle, isFalse);
      });

      test('should create error state', () {
        final error = Exception('Test error');
        final state = MutationState<String>.error(error);

        expect(state.status, equals(MutationStatus.error));
        expect(state.error, equals(error));
        expect(state.isLoading, isFalse);
        expect(state.isSuccess, isFalse);
        expect(state.isError, isTrue);
        expect(state.isIdle, isFalse);
      });
    });

    group('Query Configuration', () {
      test('should create default configuration', () {
        const config = QueryConfig();

        expect(config.staleTime, equals(Duration(minutes: 5)));
        expect(config.cacheTime, equals(Duration(minutes: 30)));
        expect(config.retryCount, equals(3));
        expect(config.retryDelay, equals(Duration(seconds: 1)));
        expect(config.refetchOnWindowFocus, isTrue);
        expect(config.refetchOnReconnect, isTrue);
        expect(config.enabled, isTrue);
      });

      test('should support copyWith', () {
        const config = QueryConfig();
        final updated = config.copyWith(
          staleTime: Duration(minutes: 10),
          enabled: false,
        );

        expect(updated.staleTime, equals(Duration(minutes: 10)));
        expect(updated.enabled, isFalse);
        expect(updated.cacheTime, equals(Duration(minutes: 30))); // unchanged
      });
    });

    group('Network Policy', () {
      test('should have network status', () {
        expect(networkPolicy.status, isA<NetworkStatus>());
        expect(networkPolicy.statusStream, isA<Stream<NetworkStatus>>());
      });
    });
  });
}
