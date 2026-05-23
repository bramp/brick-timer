import 'package:drift/drift.dart';

/// Represents a physical LEGO set.
@DataClassName('LegoSet')
class LegoSets extends Table {
  /// Primary key for a stored set.
  IntColumn get id => integer().autoIncrement()();

  /// Set number (for example, 42115-1).
  TextColumn get setNumber => text().unique()();

  /// Human-readable set name.
  TextColumn get name => text()();

  /// Number of pieces in the set.
  IntColumn get totalPieces => integer()();

  /// Optional remote image URL for the set.
  TextColumn get imageUrl => text().nullable()();
}

/// Represents a single build session for a given LEGO set.
@DataClassName('BuildSession')
class BuildSessions extends Table {
  /// Primary key for the build session.
  IntColumn get id => integer().autoIncrement()();

  /// Foreign key to [LegoSets].
  IntColumn get legoSetId => integer().references(LegoSets, #id)();

  /// Timestamp when this build was started.
  DateTimeColumn get startDate => dateTime()();

  /// Whether this build session has been completed.
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
}

/// Represents a single time interval spent building a specific bag.
@DataClassName('BagInterval')
class BagIntervals extends Table {
  /// Primary key for the recorded bag interval.
  IntColumn get id => integer().autoIncrement()();

  /// Foreign key to [BuildSessions].
  IntColumn get buildSessionId => integer().references(BuildSessions, #id)();

  /// Bag number from the set instructions.
  IntColumn get bagNumber => integer()();

  /// Timestamp when the timer interval started.
  DateTimeColumn get startTime => dateTime()();

  /// Optional timestamp when the timer interval ended.
  DateTimeColumn get endTime => dateTime().nullable()();

  /// Whether this bag interval has been completed.
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();

  /// Whether this interval has been synced to remote storage.
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
}
