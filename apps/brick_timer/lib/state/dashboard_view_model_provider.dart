import 'package:brick_timer/repositories/ledger_repository.dart';
import 'package:brick_timer/state/active_session_notifier.dart';
import 'package:brick_timer/state/dashboard_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// View-model containing dashboard session groupings and counts.
class DashboardViewModel {
  /// Creates a new [DashboardViewModel].
  const DashboardViewModel({
    required this.activeSessions,
    required this.completedSessions,
    required this.activeSessionState,
  });

  /// Build sessions that are still in progress.
  final List<BuildSessionWithSet> activeSessions;

  /// Build sessions marked as completed.
  final List<BuildSessionWithSet> completedSessions;

  /// Active timer state used to drive active build controls.
  final ActiveSessionState activeSessionState;

  /// Number of in-progress sessions.
  int get activeCount => activeSessions.length;

  /// Number of completed sessions.
  int get completedCount => completedSessions.length;
}

/// Combines dashboard data sources into a UI-focused async view-model.
final dashboardViewModelProvider = Provider<AsyncValue<DashboardViewModel>>((
  ref,
) {
  final sessionsAsync = ref.watch(buildSessionsProvider);
  final activeSessionState = ref.watch(activeSessionProvider);

  return sessionsAsync.whenData((sessions) {
    final activeSessions = sessions
        .where((sessionWithSet) => !sessionWithSet.session.isCompleted)
        .toList();
    final completedSessions = sessions
        .where((sessionWithSet) => sessionWithSet.session.isCompleted)
        .toList();

    return DashboardViewModel(
      activeSessions: activeSessions,
      completedSessions: completedSessions,
      activeSessionState: activeSessionState,
    );
  });
});
