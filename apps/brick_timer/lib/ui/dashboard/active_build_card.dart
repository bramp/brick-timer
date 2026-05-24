import 'package:brick_timer/main.dart';
import 'package:brick_timer/repositories/ledger_repository.dart';
import 'package:brick_timer/state/active_session_notifier.dart';
import 'package:brick_timer/ui/search/lego_set_thumbnail.dart';
import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

enum _ActiveBuildUiState {
  starting,
  building,
  paused,
  bagFinished,
  finished,
}

/// Card used to show an in-progress build on the dashboard.
class ActiveBuildCard extends ConsumerWidget {
  /// Creates an [ActiveBuildCard].
  const ActiveBuildCard({
    required this.sessionWithSet,
    required this.timerState,
    this.totalBags,
    super.key,
  });

  /// Session and set details to render.
  final BuildSessionWithSet sessionWithSet;

  /// Optional timer state.
  ///
  /// Null means this card is not the currently tracked one.
  final ActiveSessionState? timerState;

  /// Optional total number of bags in the set.
  final int? totalBags;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final set = sessionWithSet.legoSet;
    final session = sessionWithSet.session;
    final pieceCount = NumberFormat.decimalPattern().format(set.totalPieces);
    final currentBag = timerState?.currentBag;
    final status = timerState?.status ?? TimerStatus.stopped;
    final canControl = !session.isCompleted;
    final canPauseResume =
        canControl &&
        currentBag != null &&
        (status == TimerStatus.running || status == TimerStatus.paused);
    final canFinishBag = canControl && currentBag != null;
    final canStartNextBag = canControl;
    final hasStartedBagFuture =
        (ledgerRepository.select(ledgerRepository.bagIntervals)
              ..where((t) => t.buildSessionId.equals(session.id))
              ..limit(1))
            .getSingleOrNull()
            .then((interval) => interval != null);
    final bagLabel = switch ((currentBag, totalBags)) {
      (null, _) => 'Not started',
      (final int bag, final int total) => 'Bag $bag of $total',
      (final int bag, null) => 'Bag $bag',
    };
    final timerLabel = _formatDuration(
      timerState?.totalElapsed ?? Duration.zero,
    );
    final uiState = switch ((session.isCompleted, status, currentBag)) {
      (true, _, _) => _ActiveBuildUiState.finished,
      (_, TimerStatus.running, _) => _ActiveBuildUiState.building,
      (_, TimerStatus.paused, _) => _ActiveBuildUiState.paused,
      (_, TimerStatus.stopped, null) => _ActiveBuildUiState.starting,
      (_, TimerStatus.stopped, _) => _ActiveBuildUiState.bagFinished,
    };
    final cardGradient = switch (uiState) {
      _ActiveBuildUiState.finished => const [
        Color(0xFFF3F5F7),
        Color(0xFFE9EEF2),
      ],
      _ActiveBuildUiState.paused => const [
        Color(0xFFFFF8EA),
        Color(0xFFFFEECC),
      ],
      _ActiveBuildUiState.building => const [
        Color(0xFFEFFFF6),
        Color(0xFFDDF8EA),
      ],
      _ActiveBuildUiState.bagFinished => const [
        Color(0xFFF0FAFF),
        Color(0xFFDFF3FF),
      ],
      _ActiveBuildUiState.starting => const [
        Color(0xFFF7FDFF),
        Color(0xFFEAF7FF),
      ],
    };
    final primaryStatusLabel = switch ((uiState, currentBag)) {
      (_ActiveBuildUiState.finished, _) => 'Finished',
      (_ActiveBuildUiState.building, final int bag) => 'Building Bag $bag',
      (_ActiveBuildUiState.paused, final int bag) => 'Building Bag $bag',
      (_ActiveBuildUiState.bagFinished, final int bag) => 'Bag $bag Finished',
      _ => 'Starting',
    };
    final secondaryStatusLabel = uiState == _ActiveBuildUiState.paused
        ? 'Paused'
        : null;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: cardGradient,
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
                      width: 116,
                      height: 116,
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                set.name,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Wrap(
                                alignment: WrapAlignment.end,
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  _StatusPill(label: primaryStatusLabel),
                                  if (secondaryStatusLabel != null)
                                    _StatusPill(label: secondaryStatusLabel),
                                ],
                              ),
                            ),
                          ],
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
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _MetricBlock(
                        title: 'Total duration',
                        value: timerLabel,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricBlock(
                        title: 'Current bag',
                        value: bagLabel,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: canStartNextBag
                        ? () async {
                            final notifier = ref.read(
                              activeSessionProvider.notifier,
                            );
                            await notifier.activateSession(session.id);
                            final active = ref.read(activeSessionProvider);
                            final activeCurrentBag = active.currentBag;
                            final activeStatus = active.status;
                            final nextBag = (activeCurrentBag ?? 0) + 1;
                            if (activeCurrentBag != null &&
                                activeStatus != TimerStatus.stopped) {
                              await notifier.completeBag();
                            }
                            await notifier.startOrResumeBag(nextBag);
                          }
                        : null,
                    icon: const Icon(Icons.skip_next),
                    label: Text('Start Bag ${(currentBag ?? 0) + 1}'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: canFinishBag
                        ? () async {
                            final notifier = ref.read(
                              activeSessionProvider.notifier,
                            );
                            await notifier.activateSession(session.id);
                            final active = ref.read(activeSessionProvider);
                            if (active.currentBag == null) {
                              return;
                            }
                            await notifier.completeBag();
                          }
                        : null,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Bag Finished'),
                  ),
                  OutlinedButton.icon(
                    onPressed: canPauseResume
                        ? () async {
                            final notifier = ref.read(
                              activeSessionProvider.notifier,
                            );
                            await notifier.activateSession(session.id);
                            final active = ref.read(activeSessionProvider);
                            if (active.status == TimerStatus.running) {
                              await notifier.pause();
                            } else if (active.status == TimerStatus.paused) {
                              final bagToResume = active.currentBag;
                              if (bagToResume == null) {
                                return;
                              }
                              await notifier.startOrResumeBag(bagToResume);
                            }
                          }
                        : null,
                    icon: Icon(
                      status == TimerStatus.running
                          ? Icons.pause_circle_outline
                          : Icons.play_circle_outline,
                    ),
                    label: Text(
                      status == TimerStatus.running ? 'Pause' : 'Resume',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () async {
                      await showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => _BagDetailsSheet(
                          sessionWithSet: sessionWithSet,
                        ),
                      );
                    },
                    icon: const Icon(Icons.receipt_long_outlined),
                    label: const Text('Details'),
                  ),
                  const Spacer(),
                  FutureBuilder<bool>(
                    future: hasStartedBagFuture,
                    builder: (context, snapshot) {
                      final canFinishSet =
                          canControl && (snapshot.data ?? false);

                      return FilledButton.icon(
                        onPressed: canFinishSet
                            ? () async {
                                final notifier = ref.read(
                                  activeSessionProvider.notifier,
                                );
                                await notifier.activateSession(session.id);
                                await notifier.finishSet();
                              }
                            : null,
                        icon: const Icon(Icons.done_all),
                        label: const Text('Finished Set!'),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricBlock extends StatelessWidget {
  const _MetricBlock({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _BagDetailsSheet extends StatelessWidget {
  const _BagDetailsSheet({required this.sessionWithSet});

  final BuildSessionWithSet sessionWithSet;

  @override
  Widget build(BuildContext context) {
    final session = sessionWithSet.session;
    final set = sessionWithSet.legoSet;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: FutureBuilder<List<BagInterval>>(
          future:
              (ledgerRepository.select(ledgerRepository.bagIntervals)
                    ..where((t) => t.buildSessionId.equals(session.id))
                    ..orderBy([
                      (t) => OrderingTerm(
                        expression: t.bagNumber,
                      ),
                      (t) => OrderingTerm(
                        expression: t.startTime,
                      ),
                    ]))
                  .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SizedBox(
                height: 220,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final rows = snapshot.data ?? const <BagInterval>[];

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  set.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Bag timeline',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                if (rows.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text('No bag intervals recorded yet.'),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: rows.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final interval = rows[index];
                        final end = interval.endTime;
                        final duration = end?.difference(interval.startTime);
                        final startText = DateFormat.yMd().add_jm().format(
                          interval.startTime,
                        );
                        final endText = end == null
                            ? 'In progress'
                            : DateFormat.yMd().add_jm().format(end);
                        final rangeText = '$startText to $endText';

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text('Bag ${interval.bagNumber}'),
                          subtitle: Text(rangeText),
                          trailing: Text(
                            duration == null
                                ? 'Running'
                                : _formatDuration(duration),
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
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
