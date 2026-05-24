import 'package:brick_timer/repositories/ledger_repository.dart';
import 'package:brick_timer/state/active_session_notifier.dart';
import 'package:brick_timer/ui/search/lego_catalog_search_screen.dart';
import 'package:brick_timer/ui/search/lego_set_thumbnail.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Card used to show an in-progress build on the dashboard.
class ActiveBuildCard extends StatelessWidget {
  /// Creates an [ActiveBuildCard].
  const ActiveBuildCard({
    required this.sessionWithSet,
    required this.timerState,
    super.key,
  });

  /// Session and set details to render.
  final BuildSessionWithSet sessionWithSet;

  /// Optional timer state.
  ///
  /// Null means this card is not the currently tracked one.
  final ActiveSessionState? timerState;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final set = sessionWithSet.legoSet;
    final session = sessionWithSet.session;
    final pieceCount = NumberFormat.decimalPattern().format(set.totalPieces);
    final currentBag = timerState?.currentBag;
    final status = timerState?.status ?? TimerStatus.stopped;
    final bagLabel = currentBag == null ? 'Ready to start' : 'Bag $currentBag';
    final timerLabel = _formatDuration(
      timerState?.totalElapsed ?? Duration.zero,
    );
    final stateLabel = switch (status) {
      TimerStatus.running => 'Running',
      TimerStatus.paused => 'Paused',
      TimerStatus.stopped => currentBag == null ? 'Ready' : 'Stopped',
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF7FDFF), Color(0xFFEAF7FF)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      width: 88,
                      height: 88,
                      color: theme.colorScheme.surface.withValues(alpha: 0.6),
                      child: LegoSetThumbnail(
                        imageUrl: set.imageUrl,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                'Current build',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: theme.colorScheme.secondary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _StatusPill(label: stateLabel),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          set.name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Set ${set.setNumber} · '
                          '$pieceCount '
                          'pieces',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Started '
                          '${DateFormat.yMMMd().format(session.startDate)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Center(
                child: Column(
                  children: [
                    Text(
                      timerLabel,
                      style: theme.textTheme.displayMedium?.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      bagLabel,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                onPressed: () async {
                  await Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => const LegoCatalogSearchScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open build search'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

String _formatDuration(Duration duration) {
  String twoDigits(int value) => value.toString().padLeft(2, '0');

  final hours = twoDigits(duration.inHours);
  final minutes = twoDigits(duration.inMinutes.remainder(60));
  final seconds = twoDigits(duration.inSeconds.remainder(60));

  return '$hours:$minutes:$seconds';
}
