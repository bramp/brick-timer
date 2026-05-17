import 'dart:io';

import 'package:brick_time/models/ledger_models.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'ledger_repository.g.dart';

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

/// A wrapper class to hold a BuildSession and its associated LegoSet.
class BuildSessionWithSet {
  /// Creates a new [BuildSessionWithSet].
  BuildSessionWithSet({required this.session, required this.legoSet});

  /// The build session.
  final BuildSession session;

  /// The associated lego set.
  final LegoSet legoSet;
}

@DriftDatabase(tables: [LegoSets, BuildSessions, BagIntervals])
class LedgerRepository extends _$LedgerRepository {
  LedgerRepository() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  Future<void> init() async {
    // With drift, the connection is opened lazily.
    // We can just run a simple query to ensure it's initialized.
    await customSelect('SELECT 1').get();
  }

  /// Saves or updates a LegoSet.
  Future<int> saveLegoSet(LegoSetsCompanion set) async {
    return into(legoSets).insertOnConflictUpdate(set);
  }

  /// Fetches a session by ID.
  Future<BuildSession?> getSession(int id) async {
    return (select(
      buildSessions,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Fetches a LegoSet by ID.
  Future<LegoSet?> getLegoSet(int id) async {
    return (select(legoSets)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Finds an active (uncompleted) build session for a set, if any.
  Future<BuildSession?> getActiveSession(String setNumber) async {
    final set = await (select(
      legoSets,
    )..where((t) => t.setNumber.equals(setNumber))).getSingleOrNull();

    if (set == null) return null;

    return (select(buildSessions)
          ..where((t) => t.legoSetId.equals(set.id))
          ..where((t) => t.isCompleted.equals(false)))
        .getSingleOrNull();
  }

  /// Fetches un-synced completed bags.
  Future<List<BagInterval>> getUnsyncedBags() async {
    return (select(bagIntervals)
          ..where((t) => t.isCompleted.equals(true))
          ..where((t) => t.isSynced.equals(false)))
        .get();
  }

  /// Calculates total duration for a bag.
  Future<int> getTotalDurationMinutes(int sessionId, int bagNumber) async {
    final allIntervals =
        await (select(bagIntervals)
              ..where((t) => t.buildSessionId.equals(sessionId))
              ..where((t) => t.bagNumber.equals(bagNumber)))
            .get();

    var total = Duration.zero;
    for (final interval in allIntervals) {
      if (interval.endTime != null) {
        total += interval.endTime!.difference(interval.startTime);
      }
    }
    return total.inMinutes;
  }

  /// Updates a completed bag sync status.
  Future<void> updateBagSyncStatus(
    int intervalId, {
    required bool synced,
  }) async {
    await (update(bagIntervals)..where((t) => t.id.equals(intervalId))).write(
      BagIntervalsCompanion(
        isSynced: Value(synced),
      ),
    );
  }

  /// Watches all build sessions combined with their associated LegoSet.
  Stream<List<BuildSessionWithSet>> watchBuildSessions() {
    final query = select(buildSessions).join([
      innerJoin(legoSets, legoSets.id.equalsExp(buildSessions.legoSetId)),
    ]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return BuildSessionWithSet(
          session: row.readTable(buildSessions),
          legoSet: row.readTable(legoSets),
        );
      }).toList();
    });
  }

  /// Watches un-synced completed bags count for the sync status widget.
  Stream<int> watchUnsyncedBagsCount() {
    final countExp = bagIntervals.id.count();
    final query = selectOnly(bagIntervals)
      ..addColumns([countExp])
      ..where(
        bagIntervals.isCompleted.equals(true) &
            bagIntervals.isSynced.equals(false),
      );

    return query.watchSingle().map((row) => row.read(countExp) ?? 0);
  }
}
