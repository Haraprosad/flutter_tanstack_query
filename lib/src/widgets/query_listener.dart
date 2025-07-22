import 'dart:async';
import 'package:flutter/widgets.dart';

/// An internal widget used by `useQuery` and `useMutation` (or similar hooks)
/// to listen to streams and trigger widget rebuilds.
///
/// This widget serves as a robust listener that handles stream lifecycle:
/// - Displays initial data on first build.
/// - Rebuilds its child whenever the subscribed stream emits a new value.
/// - Unsubscribes from the old stream and subscribes to a new one
///   if the `stream` instance changes in `didUpdateWidget`.
/// - Cancels its subscription cleanly when the widget is disposed to prevent
///   memory leaks and unnecessary processing.
class QueryListener<T> extends StatefulWidget {
  /// The stream to listen to for data updates.
  final Stream<T> stream;

  /// The initial data to use before the first value from the [stream] is received.
  /// This value is displayed immediately upon widget creation.
  final T initialData;

  /// A builder function that receives the current data from the stream.
  /// This function is called every time the data updates, triggering a rebuild
  /// of the subtree defined by the builder.
  final Widget Function(BuildContext context, T data) builder;

  /// Creates a [QueryListener] widget.
  ///
  /// [key] is optional and can be used to control widget identity.
  /// [stream] is the required data stream to listen to.
  /// [initialData] is the required initial value to display.
  /// [builder] is the required function to build the widget's child.
  const QueryListener({
    super.key,
    required this.stream,
    required this.initialData,
    required this.builder,
  });

  @override
  State<QueryListener<T>> createState() => _QueryListenerState<T>();
}

class _QueryListenerState<T> extends State<QueryListener<T>> {
  /// The current data being displayed by the widget.
  /// It starts with [widget.initialData] and updates with stream emissions.
  late T _currentData;

  /// The subscription to the [widget.stream].
  /// This must be managed carefully to subscribe and unsubscribe correctly.
  StreamSubscription<T>? _subscription;

  @override
  void initState() {
    super.initState();
    _currentData = widget.initialData;
    _subscribe();
  }

  @override
  void didUpdateWidget(covariant QueryListener<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the stream instance itself has changed, we need to
    // unsubscribe from the old stream and subscribe to the new one.
    if (widget.stream != oldWidget.stream) {
      _unsubscribe(); // Cancel old subscription
      // When switching to a new stream, reset currentData to the new stream's
      // initialData to ensure the UI reflects the new stream's starting state.
      _currentData = widget.initialData;
      _subscribe(); // Subscribe to the new stream
    }
    // Note: If only initialData changes but the stream instance is the same,
    // _currentData is NOT reset here. It continues to hold the last value
    // emitted by the current stream, or its original initialData if no emission yet.
  }

  @override
  void dispose() {
    // Cancel the stream subscription to prevent memory leaks and
    // attempting to call setState on a disposed widget.
    _unsubscribe();
    super.dispose();
  }

  /// Subscribes to the current [widget.stream].
  ///
  /// The listener updates [_currentData] and triggers a [setState]
  /// whenever new data is emitted, causing the widget to rebuild.
  /// It checks if the widget is [mounted] before calling [setState].
  void _subscribe() {
    _subscription = widget.stream.listen(
      (data) {
        // Only update state if the widget is still active in the widget tree.
        if (mounted) {
          setState(() {
            _currentData = data;
          });
        }
      },
      onError: (error) {
        // Optionally, handle errors from the stream.
        // For a general listener, typically the consumer of the hook
        // would handle specific error states.
      },
      onDone: () {
        // Optionally, handle when the stream completes.
      },
    );
  }

  /// Cancels the active [StreamSubscription].
  ///
  /// Sets [_subscription] to `null` after cancellation.
  void _unsubscribe() {
    _subscription?.cancel();
    _subscription = null;
  }

  @override
  Widget build(BuildContext context) {
    // Builds the widget's child using the current data.
    return widget.builder(context, _currentData);
  }
}
