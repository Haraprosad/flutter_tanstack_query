import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart'
    show protected; // Import for @protected annotation
import '../query_client.dart';

/// An [InheritedWidget] that provides a [QueryClient] to its descendants.
///
/// This is similar to React Context Provider and should be placed high
/// in your widget tree, usually above `MaterialApp` or `CupertinoApp`.
class QueryClientProvider extends InheritedWidget {
  /// The [QueryClient] instance provided to the widget tree.
  @protected // Suggests this is primarily for internal use via .of(context)
  final QueryClient client;

  /// Creates a [QueryClientProvider].
  const QueryClientProvider({
    super.key,
    required this.client,
    required super.child,
  });

  /// Retrieves the [QueryClient] from the nearest [QueryClientProvider] in the widget tree.
  ///
  /// Throws a [FlutterError] if no [QueryClientProvider] is found.
  static QueryClient of(BuildContext context) {
    final provider = context
        .dependOnInheritedWidgetOfExactType<QueryClientProvider>();
    if (provider == null) {
      throw FlutterError(
        'No QueryClientProvider found in the widget tree. Make sure you have wrapped your app with QueryClientProvider.',
      );
    }
    return provider.client;
  }

  @override
  bool updateShouldNotify(QueryClientProvider oldWidget) =>
      oldWidget.client != client;
}
