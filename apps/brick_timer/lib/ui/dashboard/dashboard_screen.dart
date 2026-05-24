import 'package:brick_timer/repositories/ledger_repository.dart';
import 'package:brick_timer/state/active_session_notifier.dart';
import 'package:brick_timer/state/dashboard_providers.dart';
import 'package:brick_timer/ui/dashboard/active_build_card.dart';
import 'package:brick_timer/ui/search/lego_catalog_search_screen.dart';
import 'package:brick_timer/ui/search/lego_set_thumbnail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// The main dashboard screen displaying in-progress builds and recent sessions.
class DashboardScreen extends ConsumerWidget {
  /// Creates a new [DashboardScreen].
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(buildSessionsProvider);
    final syncCountAsync = ref.watch(unsyncedBagsCountProvider);
    final activeSessionState = ref.watch(activeSessionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Brick Timer'),
        centerTitle: false,
        actions: [
          _SyncStatusAction(
            countAsync: syncCountAsync,
            onRetry: () async {
              await syncOrchestrator.syncPendingBags();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.surface,
              const Color(0xFFF5FCFF),
              const Color(0xFFEAF8FF),
            ],
          ),
        ),
        child: sessionsAsync.when(
          loading: () => const _DashboardLoadingView(),
          error: (error, _) => _DashboardErrorView(
            error: error,
            onRetry: () {
              ref
                ..invalidate(buildSessionsProvider)
                ..invalidate(unsyncedBagsCountProvider)
                ..invalidate(activeSessionProvider);
            },
          ),
          data: (sessions) {
            final activeSessions = sessions
                .where((sessionWithSet) => !sessionWithSet.session.isCompleted)
                .toList();
            final completedSessions = sessions
                .where((sessionWithSet) => sessionWithSet.session.isCompleted)
                .toList();

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                _DashboardHeader(
                  activeSessionCount: activeSessions.length,
                  completedSessionCount: completedSessions.length,
                ),
                const SizedBox(height: 16),
                _SectionHeader(
                  title: 'Active builds',
                  subtitle: activeSessions.isEmpty
                      ? 'No active sessions yet.'
                      : 'In-progress sessions.',
                ),
                const SizedBox(height: 12),
                if (activeSessions.isEmpty) const _EmptyBuildCard(),
                if (activeSessions.isNotEmpty)
                  ...activeSessions.map(
                    (sessionWithSet) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ActiveBuildCard(
                        sessionWithSet: sessionWithSet,
                        timerState:
                            activeSessionState.session?.id ==
                                sessionWithSet.session.id
                            ? activeSessionState
                            : null,
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: () => _startBuild(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Start build'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                  ),
                ),
                const SizedBox(height: 20),
                _SectionHeader(
                  title: 'Recent builds',
                  subtitle: completedSessions.isEmpty
                      ? 'Finished sessions will appear here.'
                      : 'Most recent completed sessions.',
                ),
                const SizedBox(height: 12),
                if (completedSessions.isEmpty)
                  const _RecentBuildEmptyState()
                else
                  ...completedSessions
                      .take(3)
                      .map(
                        (sessionWithSet) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _RecentBuildCard(
                            sessionWithSet: sessionWithSet,
                          ),
                        ),
                      ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _startBuild(BuildContext context) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const LegoCatalogSearchScreen(),
      ),
    );
  }
}

class _SyncStatusAction extends StatelessWidget {
  const _SyncStatusAction({required this.countAsync, required this.onRetry});

  final AsyncValue<int> countAsync;
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

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.activeSessionCount,
    required this.completedSessionCount,
  });

  final int activeSessionCount;
  final int completedSessionCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dashboard',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Current build, sync, and recent sessions at a glance.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetricChip(
                label: 'Active',
                value: activeSessionCount.toString(),
              ),
              _MetricChip(
                label: 'Completed',
                value: completedSessionCount.toString(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyBuildCard extends StatelessWidget {
  const _EmptyBuildCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF6FCFF), Color(0xFFE8F5FF)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'No active build',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Start a new set to bring the active timer here.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentBuildCard extends StatelessWidget {
  const _RecentBuildCard({required this.sessionWithSet});

  final BuildSessionWithSet sessionWithSet;

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
            colors: [Color(0xFFF7FDFF), Color(0xFFEDF8FF)],
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
                      'Recent build',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
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
                      'Started '
                      '${DateFormat.yMMMd().format(session.startDate)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

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
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});

  final String label;
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
          Text(label),
        ],
      ),
    );
  }
}

class _StatusCardSkeleton extends StatelessWidget {
  const _StatusCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: SizedBox(
          height: 76,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Color(0x22222222),
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
          ),
        ),
      ),
    );
  }
}

class _RecentBuildEmptyState extends StatelessWidget {
  const _RecentBuildEmptyState();

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

class _DashboardLoadingView extends StatelessWidget {
  const _DashboardLoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: const [
        _LoadingHeader(),
        SizedBox(height: 16),
        _StatusCardSkeleton(),
        SizedBox(height: 16),
        _LoadingHeroCard(),
        SizedBox(height: 20),
        _LoadingSectionHeader(),
        SizedBox(height: 12),
        _LoadingRecentRow(),
        SizedBox(height: 10),
        _LoadingRecentRow(),
        SizedBox(height: 10),
        _LoadingRecentRow(),
      ],
    );
  }
}

class _LoadingHeader extends StatelessWidget {
  const _LoadingHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LoadingBar(width: 180, height: 34),
        SizedBox(height: 10),
        _LoadingBar(width: 260, height: 18),
        SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _LoadingPill(width: 84),
            _LoadingPill(width: 96),
          ],
        ),
      ],
    );
  }
}

class _LoadingHeroCard extends StatelessWidget {
  const _LoadingHeroCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _LoadingBar(width: 120, height: 16),
            SizedBox(height: 12),
            _LoadingBar(width: double.infinity, height: 26),
            SizedBox(height: 8),
            _LoadingBar(width: 180, height: 18),
            SizedBox(height: 18),
            Center(child: _LoadingBar(width: 220, height: 54)),
            SizedBox(height: 16),
            _LoadingBar(width: double.infinity, height: 52),
          ],
        ),
      ),
    );
  }
}

class _LoadingSectionHeader extends StatelessWidget {
  const _LoadingSectionHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LoadingBar(width: 140, height: 22),
        SizedBox(height: 6),
        _LoadingBar(width: 240, height: 16),
      ],
    );
  }
}

class _LoadingRecentRow extends StatelessWidget {
  const _LoadingRecentRow();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(14),
        child: Row(
          children: [
            _LoadingAvatar(),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _LoadingBar(width: 160, height: 18),
                  SizedBox(height: 8),
                  _LoadingBar(width: 220, height: 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingAvatar extends StatelessWidget {
  const _LoadingAvatar();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 56,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Color(0x22222222),
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
    );
  }
}

class _LoadingPill extends StatelessWidget {
  const _LoadingPill({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return _LoadingBar(width: width, height: 30, radius: 999);
  }
}

class _LoadingBar extends StatelessWidget {
  const _LoadingBar({
    required this.width,
    required this.height,
    this.radius = 12,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width == double.infinity ? null : width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

class _DashboardErrorView extends StatelessWidget {
  const _DashboardErrorView({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: theme.colorScheme.error,
                  size: 40,
                ),
                const SizedBox(height: 12),
                Text(
                  'Could not load the dashboard',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
