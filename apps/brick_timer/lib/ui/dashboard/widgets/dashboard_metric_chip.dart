import 'package:flutter/material.dart';

/// Compact pill showing a dashboard metric label and value.
class DashboardMetricChip extends StatelessWidget {
  /// Creates a new [DashboardMetricChip].
  const DashboardMetricChip({
    required this.label,
    required this.value,
    super.key,
  });

  /// Short metric label, such as Active or Completed.
  final String label;

  /// Metric value rendered with stronger emphasis.
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium,
          ),
        ],
      ),
    );
  }
}
