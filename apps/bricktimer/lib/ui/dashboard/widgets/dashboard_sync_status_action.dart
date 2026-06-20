import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// App-bar action that displays sync state and allows retrying pending uploads.
class DashboardSyncStatusAction extends StatelessWidget {
  /// Creates a new [DashboardSyncStatusAction].
  const DashboardSyncStatusAction({
    required this.countAsync,
    required this.onRetry,
    super.key,
  });

  /// Async provider state for the number of unsynced bags.
  final AsyncValue<int> countAsync;

  /// Callback to trigger a manual sync retry.
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return countAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (_, _) => const IconButton(
        tooltip: 'Sync unavailable',
        onPressed: null,
        icon: Icon(Icons.cloud_off_outlined),
      ),
      data: (count) {
        final icon = count > 0 ? Icons.cloud_upload_outlined : Icons.cloud_done;
        final tooltip = count > 0
            ? '$count unsynced bag${count == 1 ? '' : 's'}'
            : 'All synced';

        final button = IconButton(
          tooltip: tooltip,
          onPressed: count > 0 ? onRetry : null,
          icon: Badge(
            isLabelVisible: count > 0,
            label: Text(count.toString()),
            child: Icon(icon),
          ),
        );

        return Tooltip(
          message: tooltip,
          child: button,
        );
      },
    );
  }
}
