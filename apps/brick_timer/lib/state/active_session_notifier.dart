import 'dart:async';

import 'package:brick_timer/main.dart'; // for ledgerRepository
import 'package:brick_timer/repositories/ledger_repository.dart';
import 'package:brick_timer/services/spreadsheet_service.dart';
import 'package:brick_timer/services/sync_orchestrator.dart';
import 'package:clock/clock.dart';
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
    Clock? clock,
  }) : _clock = clock ?? const Clock();

  /// The active build session.
  final BuildSession? session;

  /// The bag number currently being worked on.
  final int? currentBag;

  /// The current status of the timer.
  final TimerStatus status;

  /// The aggregated duration of all completed intervals in this session.
  final Duration elapsed;

  /// The start time of the current running interval, if any.
  final DateTime? currentIntervalStart;

  final Clock _clock;

  /// Returns the total duration including the currently running interval.
  Duration get totalElapsed {
    if (status == TimerStatus.running && currentIntervalStart != null) {
      return elapsed + _clock.now().difference(currentIntervalStart!);
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
    Clock? clock,
  }) {
    return ActiveSessionState(
      session: session ?? this.session,
      currentBag: currentBag ?? this.currentBag,
      status: status ?? this.status,
      elapsed: elapsed ?? this.elapsed,
      currentIntervalStart: currentIntervalStart ?? this.currentIntervalStart,
      clock: clock ?? _clock,
    );
  }
}

/// Notifier that manages the state of the active LEGO build session.
class ActiveSessionNotifier extends Notifier<ActiveSessionState> {
  /// Creates an [ActiveSessionNotifier].
  ActiveSessionNotifier({
    LedgerRepository? repository,
    Clock? clock,
    Future<void> Function()? syncPendingBags,
  }) : _repository = repository ?? ledgerRepository,
       _clock = clock ?? const Clock(),
       _syncPendingBags = syncPendingBags ?? syncOrchestrator.syncPendingBags;

  Timer? _ticker;
  final LedgerRepository _repository;
  final Clock _clock;
  final Future<void> Function() _syncPendingBags;

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

    return ActiveSessionState(clock: _clock);
  }

  Future<void> _loadInitialState() async {
    final activeSession =
        await (_repository.select(_repository.buildSessions)
              ..where((t) => t.isCompleted.equals(false))
              ..orderBy([
                (t) => OrderingTerm(
                  expression: t.startDate,
                  mode: OrderingMode.desc,
                ),
              ])
              ..limit(1))
            .getSingleOrNull();

    if (activeSession == null) {
      return;
    }

    await _hydrateSession(activeSession);
  }

  Future<void> _hydrateSession(BuildSession session) async {
    final latestInterval =
        await (_repository.select(_repository.bagIntervals)
              ..where((t) => t.buildSessionId.equals(session.id))
              ..orderBy([
                (t) => OrderingTerm(
                  expression: t.startTime,
                ),
              ])
              ..limit(1))
            .getSingleOrNull();

    if (latestInterval == null) {
      state = ActiveSessionState(
        session: session,
        clock: _clock,
      );
      return;
    }

    final endedIntervals =
        await (_repository.select(_repository.bagIntervals)
              ..where((t) => t.buildSessionId.equals(session.id))
              ..where((t) => t.endTime.isNotNull()))
            .get();

    var totalElapsed = Duration.zero;
    for (final interval in endedIntervals) {
      totalElapsed += interval.endTime!.difference(interval.startTime);
    }

    final isRunning = latestInterval.endTime == null;
    final status = isRunning
        ? TimerStatus.running
        : latestInterval.isCompleted
        ? TimerStatus.stopped
        : TimerStatus.paused;

    state = ActiveSessionState(
      session: session,
      currentBag: latestInterval.bagNumber,
      status: status,
      elapsed: totalElapsed,
      currentIntervalStart: isRunning ? latestInterval.startTime : null,
      clock: _clock,
    );
  }

  /// Activates the given session for timer controls.
  Future<void> activateSession(int sessionId) async {
    if (state.session?.id == sessionId) {
      return;
    }

    final session = await _repository.getSession(sessionId);
    if (session == null || session.isCompleted) {
      return;
    }

    await _hydrateSession(session);
  }

  /// Starts or resumes tracking for a bag.
  Future<void> startOrResumeBag(int bagNumber) async {
    final session = state.session;
    if (session == null) {
      return;
    }

    final now = _clock.now();

    final runningInterval =
        await (_repository.select(_repository.bagIntervals)
              ..where((t) => t.buildSessionId.equals(session.id))
              ..where((t) => t.endTime.isNull())
              ..orderBy([
                (t) => OrderingTerm(
                  expression: t.startTime,
                  mode: OrderingMode.desc,
                ),
              ])
              ..limit(1))
            .getSingleOrNull();

    if (runningInterval != null) {
      if (runningInterval.bagNumber == bagNumber) {
        return;
      }

      await (_repository.update(_repository.bagIntervals)
            ..where((t) => t.id.equals(runningInterval.id)))
          .write(BagIntervalsCompanion(endTime: Value(now)));

      final intervalDuration = now.difference(runningInterval.startTime);
      state = state.copyWith(elapsed: state.elapsed + intervalDuration);
    }

    await _repository
        .into(_repository.bagIntervals)
        .insert(
          BagIntervalsCompanion.insert(
            buildSessionId: session.id,
            bagNumber: bagNumber,
            startTime: now,
          ),
        );

    state = state.copyWith(
      currentBag: bagNumber,
      status: TimerStatus.running,
      currentIntervalStart: now,
    );
  }

  /// Pauses the current tracking.
  Future<void> pause() async {
    if (state.status != TimerStatus.running || state.currentBag == null) {
      return;
    }

    final now = _clock.now();

    final runningInterval =
        await (_repository.select(_repository.bagIntervals)
              ..where((t) => t.buildSessionId.equals(state.session!.id))
              ..where((t) => t.bagNumber.equals(state.currentBag!))
              ..where((t) => t.endTime.isNull())
              ..limit(1))
            .getSingleOrNull();

    if (runningInterval != null) {
      await (_repository.update(_repository.bagIntervals)
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
    if (state.currentBag == null || state.session == null) {
      return;
    }

    final now = _clock.now();

    await _repository.transaction(() async {
      final runningInterval =
          await (_repository.select(_repository.bagIntervals)
                ..where((t) => t.buildSessionId.equals(state.session!.id))
                ..where((t) => t.bagNumber.equals(state.currentBag!))
                ..where((t) => t.endTime.isNull())
                ..limit(1))
              .getSingleOrNull();

      if (runningInterval != null) {
        await (_repository.update(
          _repository.bagIntervals,
        )..where((t) => t.id.equals(runningInterval.id))).write(
          BagIntervalsCompanion(
            endTime: Value(now),
            isCompleted: const Value(true),
          ),
        );
      } else {
        final lastInterval =
            await (_repository.select(_repository.bagIntervals)
                  ..where((t) => t.buildSessionId.equals(state.session!.id))
                  ..where((t) => t.bagNumber.equals(state.currentBag!))
                  ..orderBy([
                    (t) => OrderingTerm(
                      expression: t.endTime,
                    ),
                  ])
                  ..limit(1))
                .getSingleOrNull();

        if (lastInterval != null) {
          await (_repository.update(_repository.bagIntervals)
                ..where((t) => t.id.equals(lastInterval.id)))
              .write(const BagIntervalsCompanion(isCompleted: Value(true)));
        }
      }
    });

    state = state.copyWith(
      status: TimerStatus.stopped,
    );

    _syncPendingBags().ignore();
  }

  /// Marks the active build session complete.
  Future<void> finishSet() async {
    final session = state.session;
    if (session == null) {
      return;
    }

    final now = _clock.now();

    await _repository.transaction(() async {
      final runningInterval =
          await (_repository.select(_repository.bagIntervals)
                ..where((t) => t.buildSessionId.equals(session.id))
                ..where((t) => t.endTime.isNull())
                ..orderBy([
                  (t) => OrderingTerm(
                    expression: t.startTime,
                  ),
                ])
                ..limit(1))
              .getSingleOrNull();

      if (runningInterval != null) {
        await (_repository.update(
          _repository.bagIntervals,
        )..where((t) => t.id.equals(runningInterval.id))).write(
          BagIntervalsCompanion(
            endTime: Value(now),
            isCompleted: const Value(true),
          ),
        );

        final intervalDuration = now.difference(runningInterval.startTime);
        state = state.copyWith(elapsed: state.elapsed + intervalDuration);
      }

      await (_repository.update(
        _repository.buildSessions,
      )..where((t) => t.id.equals(session.id))).write(
        const BuildSessionsCompanion(isCompleted: Value(true)),
      );
    });

    state = ActiveSessionState(clock: _clock);
    _syncPendingBags().ignore();
  }

  /// Starts a completely new build session for a set.
  Future<void> startNewSession(LegoSet legoSet) async {
    final now = _clock.now();

    final sessionId = await _repository
        .into(_repository.buildSessions)
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

    state = ActiveSessionState(session: session, clock: _clock);
  }
}

/// A Riverpod provider for the active session state.
final activeSessionProvider =
    NotifierProvider<ActiveSessionNotifier, ActiveSessionState>(() {
      return ActiveSessionNotifier();
    });
