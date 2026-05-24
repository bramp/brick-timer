import 'package:brick_timer/main.dart';
import 'package:brick_timer/repositories/ledger_repository.dart';
import 'package:brick_timer/ui/search/lego_set_thumbnail.dart';
import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Card rendering a completed build with summary and details action.
class RecentBuildCard extends StatelessWidget {
  /// Creates a new [RecentBuildCard].
  const RecentBuildCard({required this.sessionWithSet, super.key});

  /// Session and set data for the completed build.
  final BuildSessionWithSet sessionWithSet;

  Future<_SessionSummary> _loadSummary() async {
    final session = sessionWithSet.session;
    final intervals = await (ledgerRepository.select(
      ledgerRepository.bagIntervals,
    )..where((t) => t.buildSessionId.equals(session.id))).get();

    final bagCount = intervals
        .map((interval) => interval.bagNumber)
        .toSet()
        .length;

    var totalDuration = Duration.zero;
    for (final interval in intervals) {
      final endTime = interval.endTime;
      if (endTime == null) {
        continue;
      }
      totalDuration += endTime.difference(interval.startTime);
    }

    return _SessionSummary(
      bagCount: bagCount,
      totalDuration: totalDuration,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = sessionWithSet.session;
    final set = sessionWithSet.legoSet;
    final pieceCount = NumberFormat.decimalPattern().format(set.totalPieces);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE7F8FF), Color(0xFFD7F0FF)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 64,
                  height: 64,
                  color: theme.colorScheme.surface,
                  child: LegoSetThumbnail(
                    imageUrl: set.imageUrl,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      set.name,
                      style: theme.textTheme.titleMedium?.copyWith(
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
                    const SizedBox(height: 4),
                    Text(
                      'Started ${DateFormat.yMMMd().format(session.startDate)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    FutureBuilder<_SessionSummary>(
                      future: _loadSummary(),
                      builder: (context, snapshot) {
                        final summary = snapshot.data;
                        if (summary == null) {
                          return Text(
                            'Loading build summary...',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          );
                        }

                        final bagLabel = summary.bagCount == 1
                            ? '1 bag'
                            : '${summary.bagCount} bags';
                        final durationLabel = _formatFriendlyDuration(
                          summary.totalDuration,
                        );

                        return Text(
                          '$bagLabel · $durationLabel',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () async {
                  await showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => _RecentBuildDetailsSheet(
                      sessionWithSet: sessionWithSet,
                    ),
                  );
                },
                icon: const Icon(Icons.receipt_long_outlined),
                label: const Text('Details'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionSummary {
  const _SessionSummary({required this.bagCount, required this.totalDuration});

  final int bagCount;
  final Duration totalDuration;
}

class _BagSummary {
  const _BagSummary({
    required this.bagNumber,
    required this.startTime,
    required this.duration,
  });

  final int bagNumber;
  final DateTime startTime;
  final Duration duration;
}

class _RecentBuildDetailsSheet extends StatelessWidget {
  const _RecentBuildDetailsSheet({required this.sessionWithSet});

  final BuildSessionWithSet sessionWithSet;

  Future<List<_BagSummary>> _loadBagSummaries() async {
    final sessionId = sessionWithSet.session.id;
    final intervals =
        await (ledgerRepository.select(ledgerRepository.bagIntervals)
              ..where((t) => t.buildSessionId.equals(sessionId))
              ..orderBy([
                (t) => OrderingTerm(expression: t.bagNumber),
                (t) => OrderingTerm(expression: t.startTime),
              ]))
            .get();

    final byBag = <int, List<BagInterval>>{};
    for (final interval in intervals) {
      byBag
          .putIfAbsent(interval.bagNumber, () => <BagInterval>[])
          .add(interval);
    }

    final summaries = <_BagSummary>[];
    for (final entry in byBag.entries) {
      final items = entry.value;
      final firstStart = items
          .map((e) => e.startTime)
          .reduce((a, b) => a.isBefore(b) ? a : b);

      var duration = Duration.zero;
      for (final item in items) {
        final end = item.endTime;
        if (end == null) {
          continue;
        }
        duration += end.difference(item.startTime);
      }

      summaries.add(
        _BagSummary(
          bagNumber: entry.key,
          startTime: firstStart,
          duration: duration,
        ),
      );
    }

    summaries.sort((a, b) => a.bagNumber.compareTo(b.bagNumber));
    return summaries;
  }

  @override
  Widget build(BuildContext context) {
    final set = sessionWithSet.legoSet;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: FutureBuilder<List<_BagSummary>>(
          future: _loadBagSummaries(),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SizedBox(
                height: 240,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final bags = snapshot.data ?? const <_BagSummary>[];

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
                  'Bag details',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                if (bags.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text('No bag details recorded for this build.'),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: bags.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final bag = bags[index];
                        final startLabel = DateFormat.yMMMd().add_jm().format(
                          bag.startTime,
                        );

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text('Bag ${bag.bagNumber}'),
                          subtitle: Text('Started $startLabel'),
                          trailing: Text(
                            _formatFriendlyDuration(bag.duration),
                            style: Theme.of(context).textTheme.labelLarge,
                            textAlign: TextAlign.end,
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

String _formatFriendlyDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);

  final parts = <String>[];
  if (hours > 0) {
    parts.add('$hours ${hours == 1 ? 'hour' : 'hours'}');
  }
  if (minutes > 0) {
    parts.add('$minutes ${minutes == 1 ? 'minute' : 'minutes'}');
  }
  if (seconds > 0 || parts.isEmpty) {
    parts.add('$seconds ${seconds == 1 ? 'second' : 'seconds'}');
  }

  if (parts.length == 1) {
    return parts.first;
  }
  if (parts.length == 2) {
    return '${parts[0]} and ${parts[1]}';
  }

  return '${parts[0]}, ${parts[1]}, and ${parts[2]}';
}
