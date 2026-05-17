import 'dart:async';

import 'package:brick_time/main.dart'; // for ledgerRepository
import 'package:brick_time/repositories/ledger_repository.dart';
import 'package:brick_time/services/spreadsheet_service.dart';
import 'package:brick_time/services/sync_orchestrator.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A global instance or provider for the sync orchestrator.
/// In a full Riverpod app, this would be provided via ProviderScope.
final syncOrchestrator = SyncOrchestrator(
  ledger: ledgerRepository,
  // The webhook URL should be injected from config in production
  api: SpreadsheetService(webhookUrl: 'YOUR_WEBHOOK_URL'),
);

/// The status of the current timer.
enum TimerStatus {
  /// The timer is stopped.
  stopped,

  /// The timer is actively running.
  running,

  /// The timer is paused.
  paused,
}

/// The state of the active build session.
class ActiveSessionState {
  /// Creates a new [ActiveSessionState].
  ActiveSessionState({
    this.session,
    this.currentBag,
    this.status = TimerStatus.stopped,
    this.elapsed = Duration.zero,
    this.currentIntervalStart,
  });

  /// The active build session.
  final BuildSession? session;

  /// The bag number currently being worked on.
  final int? currentBag;

  /// The current status of the timer.
  final TimerStatus status;

  /// The aggregated duration of completed intervals for the current bag.
  final Duration elapsed;

  /// The start time of the current running interval, if any.
  final DateTime? currentIntervalStart;

  /// Returns the total duration including the currently running interval.
  Duration get totalElapsed {
    if (status == TimerStatus.running && currentIntervalStart != null) {
      return elapsed + DateTime.now().difference(currentIntervalStart!);
    }
    return elapsed;
  }

  /// Creates a copy of this state with the given fields replaced.
  ActiveSessionState copyWith({
    BuildSession? session,
    int? currentBag,
    TimerStatus? status,
    Duration? elapsed,
    DateTime? currentIntervalStart,
  }) {
    return ActiveSessionState(
      session: session ?? this.session,
      currentBag: currentBag ?? this.currentBag,
      status: status ?? this.status,
      elapsed: elapsed ?? this.elapsed,
      currentIntervalStart: currentIntervalStart ?? this.currentIntervalStart,
    );
  }
}

/// Notifier that manages the state of the active LEGO build session.
class ActiveSessionNotifier extends Notifier<ActiveSessionState> {
  Timer? _ticker;

  @override
  ActiveSessionState build() {
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.status == TimerStatus.running) {
        state = state.copyWith();
      }
    });

    ref.onDispose(() {
      _ticker?.cancel();
    });

    unawaited(_loadInitialState());

    return ActiveSessionState();
  }

  Future<void> _loadInitialState() async {
    final activeSession =
        await (ledgerRepository.select(ledgerRepository.buildSessions)
              ..where((t) => t.isCompleted.equals(false))
              ..orderBy([
                (t) => OrderingTerm(
                  expression: t.startDate,
                  mode: OrderingMode.desc,
                ),
              ])
              ..limit(1))
            .getSingleOrNull();

    if (activeSession == null) return;

    final latestInterval =
        await (ledgerRepository.select(ledgerRepository.bagIntervals)
              ..where((t) => t.buildSessionId.equals(activeSession.id))
              ..orderBy([
                (t) => OrderingTerm(
                  expression: t.startTime,
                  mode: OrderingMode.desc,
                ),
              ])
              ..limit(1))
            .getSingleOrNull();

    if (latestInterval != null) {
      final isRunning = latestInterval.endTime == null;

      final previousIntervals =
          await (ledgerRepository.select(ledgerRepository.bagIntervals)
                ..where((t) => t.buildSessionId.equals(activeSession.id))
                ..where((t) => t.bagNumber.equals(latestInterval.bagNumber))
                ..where((t) => t.endTime.isNotNull()))
              .get();

      var totalElapsed = Duration.zero;
      for (final interval in previousIntervals) {
        totalElapsed += interval.endTime!.difference(interval.startTime);
      }

      state = state.copyWith(
        session: activeSession,
        currentBag: latestInterval.bagNumber,
        status: isRunning ? TimerStatus.running : TimerStatus.paused,
        elapsed: totalElapsed,
        currentIntervalStart: isRunning ? latestInterval.startTime : null,
      );
    } else {
      state = state.copyWith(
        session: activeSession,
        status: TimerStatus.stopped,
      );
    }
  }

  /// Starts or resumes tracking for a bag.
  Future<void> startOrResumeBag(int bagNumber) async {
    final session = state.session;
    if (session == null) return;

    final now = DateTime.now();
    await ledgerRepository
        .into(ledgerRepository.bagIntervals)
        .insert(
          BagIntervalsCompanion.insert(
            buildSessionId: session.id,
            bagNumber: bagNumber,
            startTime: now,
          ),
        );

    final isNewBag = state.currentBag != bagNumber;

    state = state.copyWith(
      currentBag: bagNumber,
      status: TimerStatus.running,
      currentIntervalStart: now,
      elapsed: isNewBag ? Duration.zero : state.elapsed,
    );
  }

  /// Pauses the current tracking.
  Future<void> pause() async {
    if (state.status != TimerStatus.running || state.currentBag == null) return;

    final now = DateTime.now();

    final runningInterval =
        await (ledgerRepository.select(ledgerRepository.bagIntervals)
              ..where((t) => t.buildSessionId.equals(state.session!.id))
              ..where((t) => t.bagNumber.equals(state.currentBag!))
              ..where((t) => t.endTime.isNull())
              ..limit(1))
            .getSingleOrNull();

    if (runningInterval != null) {
      await (ledgerRepository.update(ledgerRepository.bagIntervals)
            ..where((t) => t.id.equals(runningInterval.id)))
          .write(BagIntervalsCompanion(endTime: Value(now)));

      final intervalDuration = now.difference(runningInterval.startTime);

      state = state.copyWith(
        status: TimerStatus.paused,
        elapsed: state.elapsed + intervalDuration,
      );
    }
  }

  /// Completes the current bag.
  Future<void> completeBag() async {
    if (state.currentBag == null || state.session == null) return;

    final now = DateTime.now();

    await ledgerRepository.transaction(() async {
      final runningInterval =
          await (ledgerRepository.select(ledgerRepository.bagIntervals)
                ..where((t) => t.buildSessionId.equals(state.session!.id))
                ..where((t) => t.bagNumber.equals(state.currentBag!))
                ..where((t) => t.endTime.isNull())
                ..limit(1))
              .getSingleOrNull();

      if (runningInterval != null) {
        await (ledgerRepository.update(
          ledgerRepository.bagIntervals,
        )..where((t) => t.id.equals(runningInterval.id))).write(
          BagIntervalsCompanion(
            endTime: Value(now),
            isCompleted: const Value(true),
          ),
        );
      } else {
        final lastInterval =
            await (ledgerRepository.select(ledgerRepository.bagIntervals)
                  ..where((t) => t.buildSessionId.equals(state.session!.id))
                  ..where((t) => t.bagNumber.equals(state.currentBag!))
                  ..orderBy([
                    (t) => OrderingTerm(
                      expression: t.endTime,
                      mode: OrderingMode.desc,
                    ),
                  ])
                  ..limit(1))
                .getSingleOrNull();

        if (lastInterval != null) {
          await (ledgerRepository.update(ledgerRepository.bagIntervals)
                ..where((t) => t.id.equals(lastInterval.id)))
              .write(const BagIntervalsCompanion(isCompleted: Value(true)));
        }
      }
    });

    state = state.copyWith(
      status: TimerStatus.stopped,
      elapsed: Duration.zero,
    );

    syncOrchestrator.syncPendingBags().ignore();
  }

  /// Starts a completely new build session for a set.
  Future<void> startNewSession(LegoSet legoSet) async {
    final now = DateTime.now();

    final sessionId = await ledgerRepository
        .into(ledgerRepository.buildSessions)
        .insert(
          BuildSessionsCompanion.insert(
            legoSetId: legoSet.id,
            startDate: now,
            isCompleted: const Value(false),
          ),
        );

    final session = BuildSession(
      id: sessionId,
      legoSetId: legoSet.id,
      startDate: now,
      isCompleted: false,
    );

    state = ActiveSessionState(session: session);
  }
}

/// A Riverpod provider for the active session state.
final activeSessionProvider =
    NotifierProvider<ActiveSessionNotifier, ActiveSessionState>(() {
      return ActiveSessionNotifier();
    });
