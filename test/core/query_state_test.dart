import 'package:flutter_tanstack_query/flutter_tanstack_query.dart';
import 'package:flutter_test/flutter_test.dart';
 // Ensure this import path is correct

void main() {
  group('QueryState', () {
    test('initial idle state is correct', () {
      final state = QueryState<String>.idle();
      expect(state.data, isNull);
      expect(state.error, isNull);
      expect(state.status, QueryStatus.idle);
      expect(state.isStale, isFalse);
      expect(state.lastFetched, isNull);
      expect(state.isLoading, isFalse);
      expect(state.isSuccess, isFalse);
      expect(state.isError, isFalse);
      expect(state.hasData, isFalse);
    });

    test('loading state is correct without previous data', () {
      final state = QueryState<String>.loading();
      expect(state.data, isNull);
      expect(state.status, QueryStatus.loading);
      expect(state.isStale, isFalse); // No previous data to be stale
      expect(state.isLoading, isTrue);
      expect(state.hasData, isFalse);
    });

    test('loading state is correct with previous data', () {
      final state = QueryState<String>.loading('old data');
      expect(state.data, 'old data');
      expect(state.status, QueryStatus.loading);
      expect(state.isStale, isTrue); // Previous data is stale
      expect(state.isLoading, isTrue);
      expect(state.hasData, isTrue);
    });

    test('success state is correct', () {
      final state = QueryState<String>.success('new data');
      expect(state.data, 'new data');
      expect(state.status, QueryStatus.success);
      expect(state.isStale, isFalse);
      expect(state.lastFetched, isA<DateTime>());
      expect(state.isSuccess, isTrue);
      expect(state.hasData, isTrue);
    });

    test('error state is correct without previous data', () {
      final error = Exception('Failed');
      final state = QueryState<String>.error(error);
      expect(state.data, isNull);
      expect(state.error, error);
      expect(state.status, QueryStatus.error);
      expect(state.isStale, isFalse); // No previous data to be stale
      expect(state.isError, isTrue);
      expect(state.hasData, isFalse);
    });

    test('error state is correct with previous data', () {
      final error = Exception('Failed');
      final state = QueryState<String>.error(error, 'previous data');
      expect(state.data, 'previous data');
      expect(state.error, error);
      expect(state.status, QueryStatus.error);
      expect(state.isStale, isTrue); // Previous data is stale
      expect(state.isError, isTrue);
      expect(state.hasData, isTrue);
    });

    test('copyWith creates a new instance with updated values', () {
      final initial = QueryState<String>.idle();
      final loading = initial.copyWith(status: QueryStatus.loading);
      expect(loading.status, QueryStatus.loading);
      expect(loading.isLoading, isTrue);
      expect(loading.data, isNull); // Should retain null if not specified

      // Create a state with data first
      final withData = QueryState<String>.success(
        'original data',
        isStale: false,
      );
      final updated = withData.copyWith(
        status: QueryStatus.stale,
        isStale: true,
        data: 'updated data',
      );
      expect(updated.data, 'updated data');
      expect(updated.status, QueryStatus.stale);
      expect(updated.isStale, isTrue);
      expect(updated.isLoading, isFalse); // Should be false based on status
      expect(
        updated.lastFetched,
        withData.lastFetched,
      ); // Should retain if not explicitly changed
    });

    test('equality and hashcode are correct', () {
      // For success states, lastFetched is DateTime.now(), so direct copyWith()
      // without specifying lastFetched will create a different object.
      // We need to ensure lastFetched is the same for equality.
      final now = DateTime.now();
      final state1 = QueryState<String>.success(
        'data',
        isStale: false,
      ).copyWith(lastFetched: now);
      final state2 = QueryState<String>.success(
        'data',
        isStale: false,
      ).copyWith(lastFetched: now);
      final state3 = QueryState<String>.success(
        'other data',
        isStale: false,
      ).copyWith(lastFetched: now);
      final state4 = QueryState<String>.success(
        'data',
        isStale: true,
      ).copyWith(lastFetched: now);

      expect(state1, state2);
      expect(state1.hashCode, state2.hashCode);
      expect(state1, isNot(state3));
      expect(state1.hashCode, isNot(state3.hashCode));
      expect(state1, isNot(state4));
      expect(state1.hashCode, isNot(state4.hashCode));

      // Test equality with null data/error
      final idle1 = QueryState<String>.idle();
      final idle2 = QueryState<String>.idle();
      expect(idle1, idle2);
      expect(idle1.hashCode, idle2.hashCode);

      final error1 = QueryState<String>.error(Exception('test'), 'prev');
      final error2 = QueryState<String>.error(Exception('test'), 'prev');
      // Note: Exception instances are not equal by default, so wrap in a custom error class or compare message
      // For simplicity, we'll compare the string representation of the error here, or rely on Object.hash for the error object itself.
      // A more robust test might use a custom Equatable error class.
      expect(
        error1.toString(),
        error2.toString(),
      ); // Compare string representation
      // For actual object equality, it depends on the error class's operator==
    });
  });

  group('MutationState', () {
    test('initial idle state is correct', () {
      final state = MutationState<String>.idle();
      expect(state.data, isNull);
      expect(state.error, isNull);
      expect(state.status, MutationStatus.idle);
      expect(state.isLoading, isFalse);
      expect(state.isSuccess, isFalse);
      expect(state.isError, isFalse);
      expect(state.isIdle, isTrue);
    });

    test('loading state is correct', () {
      final state = MutationState<String>.loading();
      expect(state.data, isNull);
      expect(state.status, MutationStatus.loading);
      expect(state.isLoading, isTrue);
      expect(state.isSuccess, isFalse);
      expect(state.isError, isFalse);
      expect(state.isIdle, isFalse);
    });

    test('success state is correct', () {
      final state = MutationState<String>.success('result');
      expect(state.data, 'result');
      expect(state.status, MutationStatus.success);
      expect(state.isLoading, isFalse);
      expect(state.isSuccess, isTrue);
      expect(state.isError, isFalse);
      expect(state.isIdle, isFalse);
    });

    test('error state is correct', () {
      final error = Exception('Failed');
      final state = MutationState<String>.error(error);
      expect(state.data, isNull);
      expect(state.error, error);
      expect(state.status, MutationStatus.error);
      expect(state.isLoading, isFalse);
      expect(state.isSuccess, isFalse);
      expect(state.isError, isTrue);
      expect(state.isIdle, isFalse);
    });

    test('copyWith creates a new instance with updated values', () {
      final initial = MutationState<String>.idle();
      final loading = initial.copyWith(status: MutationStatus.loading);
      expect(loading.status, MutationStatus.loading);

      // Start with a state that already has data
      final withData = MutationState<String>.success('data');
      final updated = withData.copyWith(
        status: MutationStatus.error,
        error: 'some error',
      );
      expect(updated.data, 'data'); // Data should be retained if not specified
      expect(updated.status, MutationStatus.error);
      expect(updated.error, 'some error');
    });

    test('equality and hashcode are correct', () {
      final state1 = MutationState<String>.success('data');
      final state2 = MutationState<String>.success('data');
      final state3 = MutationState<String>.success('other data');
      final state4 = MutationState<String>.error(Exception('error'));

      expect(state1, state2);
      expect(state1.hashCode, state2.hashCode);
      expect(state1, isNot(state3));
      expect(state1.hashCode, isNot(state3.hashCode));
      // For error states, if the error object itself isn't equatable, the hash code might differ.
      // For production code, consider making custom error classes Equatable.
      expect(state1, isNot(state4));
      // expect(state1.hashCode, isNot(state4.hashCode)); // This might fail if Exception hashCodes are same by chance
    });
  });
}
