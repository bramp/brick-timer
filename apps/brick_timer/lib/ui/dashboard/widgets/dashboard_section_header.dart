import 'package:flutter/material.dart';

/// Section heading used across dashboard content groups.
class DashboardSectionHeader extends StatelessWidget {
  /// Creates a new [DashboardSectionHeader].
  const DashboardSectionHeader({required this.title, super.key});

  /// Header text shown for the section.
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
