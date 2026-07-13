import 'package:flutter/material.dart';

/// Reusable stream-driven view: shows a spinner while waiting for the
/// first event, a friendly message on error, and [builder] once data
/// arrives. Every list/detail screen backed by a Firestore stream uses
/// this instead of hand-rolling its own StreamBuilder loading/error UI.
class AsyncValueView<T> extends StatelessWidget {
  const AsyncValueView({
    super.key,
    required this.stream,
    required this.builder,
    this.errorMessage = 'Something went wrong loading this data.',
  });

  final Stream<T> stream;
  final Widget Function(BuildContext context, T data) builder;
  final String errorMessage;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<T>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                errorMessage,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return builder(context, snapshot.data as T);
      },
    );
  }
}
