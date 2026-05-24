import 'package:flutter/material.dart';

/// Empty-state message shown when there are no completed builds.
class RecentBuildEmptyState extends StatelessWidget {
  /// Creates a new [RecentBuildEmptyState].
  const RecentBuildEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Completed builds will show up here after you finish a session.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
