import 'package:flutter_tanstack_query/flutter_tanstack_query.dart';
import 'package:flutter_test/flutter_test.dart';
// Adjust import path if necessary

void main() {
  group('QueryConfig', () {
    // Define expected default values for easier maintenance
    const Duration defaultStaleTime = Duration(minutes: 5);
    const Duration defaultCacheTime = Duration(minutes: 30);
    const int defaultRetryCount = 3;
    const Duration defaultRetryDelay = Duration(seconds: 1);
    const bool defaultRefetchOnReconnect = true;
    const bool defaultRefetchOnWindowFocus = true;
    const bool defaultEnabled = true;

    test(
      'default constructor creates instance with correct default values',
      () {
        const config = QueryConfig();

        expect(config.staleTime, defaultStaleTime);
        expect(config.cacheTime, defaultCacheTime);
        expect(config.retryCount, defaultRetryCount);
        expect(config.retryDelay, defaultRetryDelay);
        expect(config.refetchOnReconnect, defaultRefetchOnReconnect);
        expect(config.refetchOnWindowFocus, defaultRefetchOnWindowFocus);
        expect(config.enabled, defaultEnabled);
      },
    );

    test('constructor assigns provided values correctly', () {
      final config = QueryConfig(
        staleTime: const Duration(minutes: 1),
        cacheTime: const Duration(minutes: 10),
        retryCount: 5,
        retryDelay: const Duration(seconds: 2),
        refetchOnReconnect: false,
        refetchOnWindowFocus: false,
        enabled: false,
      );

      expect(config.staleTime, const Duration(minutes: 1));
      expect(config.cacheTime, const Duration(minutes: 10));
      expect(config.retryCount, 5);
      expect(config.retryDelay, const Duration(seconds: 2));
      expect(config.refetchOnReconnect, isFalse);
      expect(config.refetchOnWindowFocus, isFalse);
      expect(config.enabled, isFalse);
    });

    group('copyWith', () {
      const baseConfig = QueryConfig(
        staleTime: Duration(seconds: 10),
        cacheTime: Duration(minutes: 2),
        retryCount: 2,
        retryDelay: Duration(milliseconds: 500),
        refetchOnReconnect: false,
        refetchOnWindowFocus: false,
        enabled: true,
      );

      test('copyWith returns a new instance', () {
        final newConfig = baseConfig.copyWith();
        expect(newConfig, isNot(same(baseConfig)));
      });

      test('copyWith without arguments creates an identical copy', () {
        final newConfig = baseConfig.copyWith();
        expect(newConfig, baseConfig);
        expect(newConfig.hashCode, baseConfig.hashCode);
      });

      test('copyWith updates specified properties', () {
        final newConfig = baseConfig.copyWith(
          staleTime: const Duration(seconds: 30),
          enabled: false,
        );

        expect(newConfig.staleTime, const Duration(seconds: 30));
        expect(newConfig.enabled, isFalse);

        // Verify other properties remain unchanged
        expect(newConfig.cacheTime, baseConfig.cacheTime);
        expect(newConfig.retryCount, baseConfig.retryCount);
        expect(newConfig.retryDelay, baseConfig.retryDelay);
        expect(newConfig.refetchOnReconnect, baseConfig.refetchOnReconnect);
        expect(newConfig.refetchOnWindowFocus, baseConfig.refetchOnWindowFocus);
      });
    });

    group('Equality and HashCode', () {
      test('two identical configs are equal and have same hash code', () {
        const config1 = QueryConfig(
          staleTime: Duration(seconds: 10),
          retryCount: 3,
          enabled: true,
        );
        const config2 = QueryConfig(
          staleTime: Duration(seconds: 10),
          retryCount: 3,
          enabled: true,
        );

        expect(config1, config2);
        expect(config1.hashCode, config2.hashCode);
      });

      test('configs with different staleTime are not equal', () {
        const config1 = QueryConfig(staleTime: Duration(seconds: 10));
        const config2 = QueryConfig(staleTime: Duration(seconds: 20));
        expect(config1, isNot(config2));
        expect(config1.hashCode, isNot(config2.hashCode));
      });

      test('configs with different cacheTime are not equal', () {
        const config1 = QueryConfig(cacheTime: Duration(minutes: 5));
        const config2 = QueryConfig(cacheTime: Duration(minutes: 10));
        expect(config1, isNot(config2));
        expect(config1.hashCode, isNot(config2.hashCode));
      });

      test('configs with different retryCount are not equal', () {
        const config1 = QueryConfig(retryCount: 3);
        const config2 = QueryConfig(retryCount: 5);
        expect(config1, isNot(config2));
        expect(config1.hashCode, isNot(config2.hashCode));
      });

      test('configs with different retryDelay are not equal', () {
        const config1 = QueryConfig(retryDelay: Duration(seconds: 1));
        const config2 = QueryConfig(retryDelay: Duration(seconds: 2));
        expect(config1, isNot(config2));
        expect(config1.hashCode, isNot(config2.hashCode));
      });

      test('configs with different refetchOnReconnect are not equal', () {
        const config1 = QueryConfig(refetchOnReconnect: true);
        const config2 = QueryConfig(refetchOnReconnect: false);
        expect(config1, isNot(config2));
        expect(config1.hashCode, isNot(config2.hashCode));
      });

      test('configs with different refetchOnWindowFocus are not equal', () {
        const config1 = QueryConfig(refetchOnWindowFocus: true);
        const config2 = QueryConfig(refetchOnWindowFocus: false);
        expect(config1, isNot(config2));
        expect(config1.hashCode, isNot(config2.hashCode));
      });

      test('configs with different enabled status are not equal', () {
        const config1 = QueryConfig(enabled: true);
        const config2 = QueryConfig(enabled: false);
        expect(config1, isNot(config2));
        expect(config1.hashCode, isNot(config2.hashCode));
      });
    });
  });

  group('MutationConfig', () {
    const List<List<Object>> defaultInvalidateQueries = [];

    test(
      'default constructor creates instance with correct default values',
      () {
        const config = MutationConfig();

        expect(config.optimisticUpdate, isNull);
        expect(config.invalidateQueries, defaultInvalidateQueries);
        expect(config.onSuccess, isNull);
        expect(config.onError, isNull);
        expect(config.timeout, isNull);
      },
    );

    test('constructor assigns provided values correctly', () {
      final successCallback = (String data) => {};
      final errorCallback = (Object error) => {};
      final optimisticUpdateCallback =
          (String variables, String? previousData) => 'optimistic';
      final invalidateKeys = [
        ['user', 123],
      ];

      final config = MutationConfig<String, String>(
        optimisticUpdate: optimisticUpdateCallback,
        invalidateQueries: invalidateKeys,
        onSuccess: successCallback,
        onError: errorCallback,
        timeout: const Duration(seconds: 60),
      );

      expect(config.optimisticUpdate, optimisticUpdateCallback);
      expect(config.invalidateQueries, invalidateKeys);
      expect(config.onSuccess, successCallback);
      expect(config.onError, errorCallback);
      expect(config.timeout, const Duration(seconds: 60));
    });

    group('copyWith', () {
      final optimisticCallback = (String vars, String? prev) => 'optimistic';
      final successCallback = (String data) => {};
      final errorCallback = (Object err) => {};

      final baseConfig = MutationConfig<String, String>(
        optimisticUpdate: optimisticCallback,
        invalidateQueries: [
          ['user', 1],
        ],
        onSuccess: successCallback,
        onError: errorCallback,
        timeout: const Duration(seconds: 30),
      );

      test('copyWith returns a new instance', () {
        final newConfig = baseConfig.copyWith();
        expect(newConfig, isNot(same(baseConfig)));
      });

      test('copyWith without arguments creates an identical copy', () {
        final newConfig = baseConfig.copyWith();
        expect(newConfig, baseConfig);
        expect(newConfig.hashCode, baseConfig.hashCode);
      });

      test('copyWith updates specified properties', () {
        final newOnSuccess = (String data) => print('new success');
        final newConfig = baseConfig.copyWith(
          invalidateQueries: [
            ['products'],
          ],
          onSuccess: Value(newOnSuccess), // Now needs Value wrapper
          timeout: Value(const Duration(minutes: 1)), // Now needs Value wrapper
        );

        expect(newConfig.invalidateQueries, [
          ['products'],
        ]);
        expect(newConfig.onSuccess, newOnSuccess);
        expect(newConfig.timeout, const Duration(minutes: 1));

        // Verify other properties remain unchanged
        expect(newConfig.optimisticUpdate, baseConfig.optimisticUpdate);
        expect(newConfig.onError, baseConfig.onError);
      });

      test('copyWith can set nullable properties to null', () {
        final configWithAll = MutationConfig<String, String>(
          // This ensures a non-nullable String is returned, solving previous type error
          optimisticUpdate: (v, p) => p ?? 'default_optimistic_value',
          onSuccess: (d) => {},
          onError: (e) => {},
          timeout: const Duration(seconds: 10),
        );

        final newConfig = configWithAll.copyWith(
          optimisticUpdate: Value(
            null,
          ), // Explicitly setting to null using Value(null)
          onSuccess: Value(
            null,
          ), // Explicitly setting to null using Value(null)
          onError: Value(null), // Explicitly setting to null using Value(null)
          timeout: Value(null), // Explicitly setting to null using Value(null)
        );

        expect(newConfig.optimisticUpdate, isNull);
        expect(newConfig.onSuccess, isNull);
        expect(newConfig.onError, isNull);
        expect(newConfig.timeout, isNull);
      });
    });

    group('Equality and HashCode', () {
      test('two identical configs are equal and have same hash code', () {
        final optimisticCallback = (String vars, String? prev) => 'optimistic';
        final successCallback = (String data) => {};
        final invalidateKeys = [
          ['todos'],
          ['users'],
        ];

        final config1 = MutationConfig<String, String>(
          optimisticUpdate: optimisticCallback,
          invalidateQueries: invalidateKeys,
          onSuccess: successCallback,
          timeout: const Duration(seconds: 30),
        );
        final config2 = MutationConfig<String, String>(
          optimisticUpdate: optimisticCallback,
          invalidateQueries: invalidateKeys,
          onSuccess: successCallback,
          timeout: const Duration(seconds: 30),
        );

        expect(config1, config2);
        expect(config1.hashCode, config2.hashCode);
      });

      test('configs with different invalidateQueries are not equal', () {
        final config1 = MutationConfig(
          invalidateQueries: [
            ['a'],
          ],
        );
        final config2 = MutationConfig(
          invalidateQueries: [
            ['b'],
          ],
        );
        expect(config1, isNot(config2));
        expect(config1.hashCode, isNot(config2.hashCode));
      });

      test(
        'configs with different callback functions are not equal (by reference)',
        () {
          final onSuccess1 = (String data) => {};
          final onSuccess2 = (String data) => {}; // Different instance
          final config1 = MutationConfig<String, String>(onSuccess: onSuccess1);
          final config2 = MutationConfig<String, String>(onSuccess: onSuccess2);
          expect(config1, isNot(config2));
          expect(config1.hashCode, isNot(config2.hashCode));
        },
      );
    });
  });
}
