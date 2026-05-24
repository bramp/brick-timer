import 'package:brick_timer/repositories/ledger_repository.dart';
import 'package:brick_timer/state/active_session_notifier.dart';
import 'package:clock/clock.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _MutableClock {
  _MutableClock(this._current);

  DateTime _current;

  Clock get clock => Clock(() => _current);

  void advance(Duration duration) {
    _current = _current.add(duration);
  }
}

Future<LegoSet> _insertLegoSet(
  LedgerRepository repository, {
  required String setNumber,
}) async {
  final setId = await repository
      .into(repository.legoSets)
      .insert(
        LegoSetsCompanion.insert(
          setNumber: setNumber,
          name: 'Test Set $setNumber',
          totalPieces: 1000,
        ),
      );

  final set = await repository.getLegoSet(setId);
  return set!;
}

void main() {
  late LedgerRepository repository;
  late ProviderContainer container;
  late ActiveSessionNotifier notifier;
  late _MutableClock clock;
  var syncCalls = 0;

  setUp(() {
    repository = LedgerRepository.forExecutor(NativeDatabase.memory());
    clock = _MutableClock(DateTime(2026, 1, 1, 10));
    syncCalls = 0;

    container = ProviderContainer(
      overrides: [
        activeSessionProvider.overrideWith(
          () => ActiveSessionNotifier(
            repository: repository,
            clock: clock.clock,
            syncPendingBags: () async {
              syncCalls++;
            },
          ),
        ),
      ],
    );

    notifier = container.read(activeSessionProvider.notifier);
  });

  tearDown(() async {
    container.dispose();
    await repository.close();
  });

  test('running totalElapsed uses injected clock', () async {
    final set = await _insertLegoSet(repository, setNumber: '1000-1');

    await notifier.startNewSession(set);
    await notifier.startOrResumeBag(1);

    expect(container.read(activeSessionProvider).totalElapsed, Duration.zero);

    clock.advance(const Duration(minutes: 1, seconds: 30));

    expect(
      container.read(activeSessionProvider).totalElapsed,
      const Duration(minutes: 1, seconds: 30),
    );
  });

  test('start/pause/resume/complete bag transitions are consistent', () async {
    final set = await _insertLegoSet(repository, setNumber: '1001-1');

    await notifier.startNewSession(set);
    expect(container.read(activeSessionProvider).status, TimerStatus.stopped);

    await notifier.startOrResumeBag(1);
    expect(container.read(activeSessionProvider).status, TimerStatus.running);

    clock.advance(const Duration(minutes: 5, seconds: 10));
    await notifier.pause();

    var state = container.read(activeSessionProvider);
    expect(state.status, TimerStatus.paused);
    expect(state.elapsed, const Duration(minutes: 5, seconds: 10));

    clock.advance(const Duration(seconds: 30));
    await notifier.startOrResumeBag(1);
    clock.advance(const Duration(minutes: 2));
    await notifier.pause();

    state = container.read(activeSessionProvider);
    expect(state.status, TimerStatus.paused);
    expect(state.elapsed, const Duration(minutes: 7, seconds: 10));

    await notifier.completeBag();
    state = container.read(activeSessionProvider);
    expect(state.status, TimerStatus.stopped);
    expect(state.currentBag, 1);
    expect(syncCalls, 1);

    final intervals =
        await (repository.select(repository.bagIntervals)
              ..where((t) => t.buildSessionId.equals(state.session!.id))
              ..where((t) => t.bagNumber.equals(1)))
            .get();

    expect(intervals, hasLength(2));
    expect(intervals.every((i) => i.endTime != null), isTrue);
  });

  test('starting another bag closes prior running interval', () async {
    final set = await _insertLegoSet(repository, setNumber: '1002-1');

    await notifier.startNewSession(set);
    await notifier.startOrResumeBag(1);

    clock.advance(const Duration(seconds: 20));
    await notifier.startOrResumeBag(2);

    final state = container.read(activeSessionProvider);
    expect(state.currentBag, 2);
    expect(state.status, TimerStatus.running);
    expect(state.elapsed, const Duration(seconds: 20));

    final openIntervals =
        await (repository.select(repository.bagIntervals)
              ..where((t) => t.buildSessionId.equals(state.session!.id))
              ..where((t) => t.endTime.isNull()))
            .get();

    expect(openIntervals, hasLength(1));
    expect(openIntervals.single.bagNumber, 2);
  });

  test('starting same bag does not create duplicate interval', () async {
    final set = await _insertLegoSet(repository, setNumber: '1003-1');

    await notifier.startNewSession(set);
    await notifier.startOrResumeBag(1);
    await notifier.startOrResumeBag(1);

    final state = container.read(activeSessionProvider);
    final intervals = await (repository.select(
      repository.bagIntervals,
    )..where((t) => t.buildSessionId.equals(state.session!.id))).get();
    final openIntervals = intervals.where((i) => i.endTime == null).toList();

    expect(intervals, hasLength(1));
    expect(openIntervals, hasLength(1));
  });

  test('finishSet marks session completed and clears active state', () async {
    final set = await _insertLegoSet(repository, setNumber: '1004-1');

    await notifier.startNewSession(set);
    await notifier.startOrResumeBag(1);
    clock.advance(const Duration(minutes: 2));

    final activeBefore = container.read(activeSessionProvider);
    final sessionId = activeBefore.session!.id;

    await notifier.finishSet();

    final state = container.read(activeSessionProvider);
    expect(state.session, isNull);
    expect(syncCalls, 1);

    final session = await repository.getSession(sessionId);
    expect(session, isNotNull);
    expect(session!.isCompleted, isTrue);

    final openIntervals =
        await (repository.select(repository.bagIntervals)
              ..where((t) => t.buildSessionId.equals(sessionId))
              ..where((t) => t.endTime.isNull()))
            .get();
    expect(openIntervals, isEmpty);
  });
}
