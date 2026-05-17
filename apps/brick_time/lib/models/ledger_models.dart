import 'package:drift/drift.dart';

/// Represents a physical LEGO set.
@DataClassName('LegoSet')
class LegoSets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get setNumber => text().unique()();
  TextColumn get name => text()();
  IntColumn get totalPieces => integer()();
  TextColumn get imageUrl => text().nullable()();
}

/// Represents a single build session for a given [LegoSet].
@DataClassName('BuildSession')
class BuildSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get legoSetId => integer().references(LegoSets, #id)();
  DateTimeColumn get startDate => dateTime()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
}

/// Represents a single time interval spent building a specific bag.
@DataClassName('BagInterval')
class BagIntervals extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get buildSessionId => integer().references(BuildSessions, #id)();
  IntColumn get bagNumber => integer()();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime().nullable()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
}
