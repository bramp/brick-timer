import 'package:brick_timer/state/dashboard_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A widget that displays the current cloud sync status based on the count of
/// unsynced completed bags.
class SyncStatusWidget extends ConsumerWidget {
  /// Creates a new [SyncStatusWidget].
  const SyncStatusWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countAsync = ref.watch(unsyncedBagsCountProvider);

    return countAsync.when(
      data: (count) {
        if (count == 0) {
          return const Tooltip(
            message: 'All synced',
            child: Icon(Icons.cloud_done),
          );
        }
        return Tooltip(
          message: '$count unsynced bag(s)',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_upload, color: Colors.orange),
              const SizedBox(width: 4),
              Text(
                count.toString(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (error, stackTrace) => const Icon(Icons.error, color: Colors.red),
    );
  }
}
