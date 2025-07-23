import 'package:flutter/widgets.dart';
import '../core/query_state.dart';
import '../core/query_options.dart';
import '../core/query_config.dart';
import '../core/types.dart';
import '../widgets/query_client_provider.dart';
import '../widgets/query_listener.dart';

/// Result object for useMutation hook
class MutationResult<T, V> {
  /// Current mutation data
  final T? data;

  /// Current error if any
  final Object? error;

  /// Whether the mutation is currently loading
  final bool isLoading;

  /// Whether the mutation was successful
  final bool isSuccess;

  /// Whether the mutation has an error
  final bool isError;

  /// Whether the mutation is idle
  final bool isIdle;

  /// Function to execute the mutation
  final Future<T> Function(V variables) mutate;

  /// Function to execute the mutation asynchronously (fire and forget)
  final void Function(V variables) mutateAsync;

  /// Function to reset mutation state
  final void Function() reset;

  const MutationResult({
    this.data,
    this.error,
    required this.isLoading,
    required this.isSuccess,
    required this.isError,
    required this.isIdle,
    required this.mutate,
    required this.mutateAsync,
    required this.reset,
  });

  /// Create MutationResult from MutationState
  factory MutationResult.fromState(
    MutationState<T> state, {
    required Future<T> Function(V variables) mutate,
    required void Function(V variables) mutateAsync,
    required void Function() reset,
  }) {
    return MutationResult<T, V>(
      data: state.data,
      error: state.error,
      isLoading: state.isLoading,
      isSuccess: state.isSuccess,
      isError: state.isError,
      isIdle: state.isIdle,
      mutate: mutate,
      mutateAsync: mutateAsync,
      reset: reset,
    );
  }
}

/// Hook-style widget for using mutations
class UseMutation<T, V> extends StatefulWidget {
  /// Mutation options
  final MutationOptions<T, V> options;

  /// Builder function
  final Widget Function(BuildContext context, MutationResult<T, V> result)
  builder;

  const UseMutation({super.key, required this.options, required this.builder});

  @override
  State<UseMutation<T, V>> createState() => _UseMutationState<T, V>();
}

class _UseMutationState<T, V> extends State<UseMutation<T, V>> {
  late String _mutationKey;

  @override
  void initState() {
    super.initState();
    _mutationKey =
        'mutation_${widget.hashCode}_${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  Widget build(BuildContext context) {
    final queryClient = QueryClientProvider.of(context);

    // Get or create the mutation
    final mutation = queryClient.getMutation<T, V>(
      _mutationKey,
      widget.options.mutationFn ??
          (variables) => throw MutationError('Mutation function is required'),
      config: MutationConfig<T, V>(
        invalidateQueries: widget.options.invalidateQueries,
        onSuccess: widget.options.onSuccess != null
            ? (data) =>
                  {} // Handle in mutate function
            : null,
        onError: widget.options.onError != null
            ? (error) =>
                  {} // Handle in mutate function
            : null,
      ),
    );

    return QueryListener<MutationState<T>>(
      stream: mutation.stateStream,
      initialData: mutation.state,
      builder: (context, state) {
        final result = MutationResult<T, V>.fromState(
          state,
          mutate: (V variables) async {
            if (widget.options.onMutate != null) {
              widget.options.onMutate!(variables);
            }

            try {
              final data = await mutation.mutate(variables);

              if (widget.options.onSuccess != null) {
                widget.options.onSuccess!(data, variables);
              }

              if (widget.options.onSettled != null) {
                widget.options.onSettled!(data, null, variables);
              }

              return data;
            } catch (error) {
              if (widget.options.onError != null) {
                widget.options.onError!(error, variables);
              }

              if (widget.options.onSettled != null) {
                widget.options.onSettled!(null, error, variables);
              }

              rethrow;
            }
          },
          mutateAsync: (V variables) {
            // Fire and forget version
            mutation.mutate(variables).catchError((error) {
              // Silent fail for async version
              return error as T; // Return error as fallback
            });
          },
          reset: () => mutation.reset(),
        );

        return widget.builder(context, result);
      },
    );
  }
}

/// Convenience function to create UseMutation widget
UseMutation<T, V> useMutation<T, V>(
  MutationFetcher<T, V> mutationFn, {
  MutationOptions<T, V>? options,
  required Widget Function(BuildContext context, MutationResult<T, V> result)
  builder,
}) {
  final mutationOptions =
      options?.copyWith(mutationFn: mutationFn) ??
      MutationOptions<T, V>(mutationFn: mutationFn);

  return UseMutation<T, V>(options: mutationOptions, builder: builder);
}
