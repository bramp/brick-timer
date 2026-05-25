import 'dart:async';

import 'package:brick_timer/state/active_session_notifier.dart';
import 'package:brick_timer/state/dashboard_providers.dart';
import 'package:brick_timer/state/dashboard_view_model_provider.dart';
import 'package:brick_timer/ui/dashboard/active_build_card.dart';
import 'package:brick_timer/ui/dashboard/widgets/dashboard_empty_build_card.dart';
import 'package:brick_timer/ui/dashboard/widgets/dashboard_error_view.dart';
import 'package:brick_timer/ui/dashboard/widgets/dashboard_loading_view.dart';
import 'package:brick_timer/ui/dashboard/widgets/dashboard_metric_chip.dart';
import 'package:brick_timer/ui/dashboard/widgets/dashboard_section_header.dart';
import 'package:brick_timer/ui/dashboard/widgets/dashboard_sync_status_action.dart';
import 'package:brick_timer/ui/dashboard/widgets/recent_build_card.dart';
import 'package:brick_timer/ui/dashboard/widgets/recent_build_empty_state.dart';
import 'package:brick_timer/ui/search/lego_catalog_search_screen.dart';
import 'package:brick_timer/ui/settings/legal_notices_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum _DashboardMenuAction { about }

/// The main dashboard screen displaying in-progress builds and recent sessions.
class DashboardScreen extends ConsumerWidget {
  /// Creates a new [DashboardScreen].
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModelAsync = ref.watch(dashboardViewModelProvider);
    final syncCountAsync = ref.watch(unsyncedBagsCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: viewModelAsync.maybeWhen(
          data: (viewModel) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _DashboardBranding(),
                const SizedBox(width: 12),
                DashboardMetricChip(
                  label: 'Active',
                  value: viewModel.activeCount.toString(),
                ),
                const SizedBox(width: 6),
                DashboardMetricChip(
                  label: 'Completed',
                  value: viewModel.completedCount.toString(),
                ),
                const SizedBox(width: 6),
                DashboardSyncStatusAction(
                  countAsync: syncCountAsync,
                  onRetry: () async {
                    await syncOrchestrator.syncPendingBags();
                  },
                ),
              ],
            );
          },
          orElse: () => const _DashboardBranding(),
        ),
        centerTitle: false,
        actions: [
          PopupMenuButton<_DashboardMenuAction>(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onSelected: (value) {
              switch (value) {
                case _DashboardMenuAction.about:
                  unawaited(
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => const LegalNoticesScreen(),
                      ),
                    ),
                  );
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem<_DashboardMenuAction>(
                value: _DashboardMenuAction.about,
                child: Text('About'),
              ),
            ],
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
              Theme.of(context).scaffoldBackgroundColor,
              Theme.of(context).colorScheme.surface,
              const Color(0xFFDFF4FB),
            ],
          ),
        ),
        child: viewModelAsync.when(
          loading: () => const DashboardLoadingView(),
          error: (error, _) => DashboardErrorView(
            error: error,
            onRetry: () {
              ref
                ..invalidate(buildSessionsProvider)
                ..invalidate(unsyncedBagsCountProvider)
                ..invalidate(activeSessionProvider);
            },
          ),
          data: (viewModel) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                const DashboardSectionHeader(
                  title: 'Active builds',
                ),
                const SizedBox(height: 12),
                if (viewModel.activeSessions.isEmpty)
                  const DashboardEmptyBuildCard(),
                if (viewModel.activeSessions.isNotEmpty)
                  ...viewModel.activeSessions.map(
                    (sessionWithSet) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ActiveBuildCard(
                        sessionWithSet: sessionWithSet,
                        timerState:
                            viewModel.activeSessionState.session?.id ==
                                sessionWithSet.session.id
                            ? viewModel.activeSessionState
                            : null,
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: () => _startBuild(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Start New Build'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                  ),
                ),
                const SizedBox(height: 20),
                const DashboardSectionHeader(
                  title: 'Finished builds',
                ),
                const SizedBox(height: 12),
                if (viewModel.completedSessions.isEmpty)
                  const RecentBuildEmptyState()
                else
                  ...viewModel.completedSessions
                      .take(3)
                      .map(
                        (sessionWithSet) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: RecentBuildCard(
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

class _DashboardBranding extends StatelessWidget {
  const _DashboardBranding();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          'assets/logo.svg',
          width: 28,
          height: 28,
        ),
        const SizedBox(width: 8),
        SvgPicture.asset(
          'assets/title.svg',
          height: 22,
          fit: BoxFit.fitHeight,
        ),
      ],
    );
  }
}
