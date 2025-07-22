import 'package:flutter/material.dart'; // Often needed for MaterialApp context in tests
import 'package:flutter_tanstack_query/src/query_client.dart';
import 'package:flutter_tanstack_query/src/widgets/query_client_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart'; // Import mocktail

 // Import the actual QueryClient

// Mock the QueryClient using mocktail's Mock class
class MockQueryClient extends Mock implements QueryClient {}

void main() {
  group('QueryClientProvider (Mocktail)', () {
    late MockQueryClient mockQueryClient;

    setUpAll(() {
      // Register fallback values for any non-primitive types that your mocked
      // QueryClient might return from unstubbed methods.
      // For QueryClientProvider, we only pass the client, not call its methods,
      // so this might not be strictly necessary here, but it's good practice
      // for other tests where MockQueryClient's methods are called.
      // Example: registerFallbackValue(MockQuery<dynamic>());
      // registerFallbackValue(MockInfiniteQuery<dynamic, dynamic>());
      // registerFallbackValue(MockMutation<dynamic, dynamic>());
    });

    setUp(() {
      mockQueryClient = MockQueryClient();
    });

    testWidgets('provides QueryClient to descendants', (tester) async {
      await tester.pumpWidget(
        QueryClientProvider(
          client: mockQueryClient,
          child: Builder(
            builder: (context) {
              final client = QueryClientProvider.of(context);
              expect(client, mockQueryClient);
              return const Placeholder();
            },
          ),
        ),
      );
    });

    testWidgets('throws FlutterError if no QueryClientProvider is found', (
      tester,
    ) async {
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            try {
              QueryClientProvider.of(context);
              fail('Should throw FlutterError');
            } catch (e) {
              expect(e, isA<FlutterError>());
              expect(
                e.toString(),
                contains('No QueryClientProvider found in the widget tree.'),
              );
            }
            return const Placeholder();
          },
        ),
      );
    });

    testWidgets('updateShouldNotify returns true when client changes', (
      tester,
    ) async {
      final mockClient1 = MockQueryClient();
      final mockClient2 = MockQueryClient();

      await tester.pumpWidget(
        QueryClientProvider(
          key: const ValueKey('provider'),
          client: mockClient1,
          child: const Placeholder(),
        ),
      );

      final providerElement = tester.element(
        find.byKey(const ValueKey('provider')),
      );
      final providerWidget = providerElement.widget as QueryClientProvider;

      // Simulate update with different client
      final newProviderWidget = QueryClientProvider(
        key: const ValueKey('provider'),
        client: mockClient2,
        child: const Placeholder(),
      );

      expect(newProviderWidget.updateShouldNotify(providerWidget), isTrue);
    });

    testWidgets('updateShouldNotify returns false when client is the same', (
      tester,
    ) async {
      final mockClient = MockQueryClient();

      await tester.pumpWidget(
        QueryClientProvider(
          key: const ValueKey('provider'),
          client: mockClient,
          child: const Placeholder(),
        ),
      );

      final providerElement = tester.element(
        find.byKey(const ValueKey('provider')),
      );
      final providerWidget = providerElement.widget as QueryClientProvider;

      // Simulate update with the same client
      final newProviderWidget = QueryClientProvider(
        key: const ValueKey('provider'),
        client: mockClient,
        child: const Placeholder(),
      );

      expect(newProviderWidget.updateShouldNotify(providerWidget), isFalse);
    });
  });
}
