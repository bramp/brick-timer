// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ledger_repository.dart';

// ignore_for_file: type=lint
class $LegoSetsTable extends LegoSets with TableInfo<$LegoSetsTable, LegoSet> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LegoSetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _setNumberMeta = const VerificationMeta(
    'setNumber',
  );
  @override
  late final GeneratedColumn<String> setNumber = GeneratedColumn<String>(
    'set_number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalPiecesMeta = const VerificationMeta(
    'totalPieces',
  );
  @override
  late final GeneratedColumn<int> totalPieces = GeneratedColumn<int>(
    'total_pieces',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    setNumber,
    name,
    totalPieces,
    imageUrl,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lego_sets';
  @override
  VerificationContext validateIntegrity(
    Insertable<LegoSet> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('set_number')) {
      context.handle(
        _setNumberMeta,
        setNumber.isAcceptableOrUnknown(data['set_number']!, _setNumberMeta),
      );
    } else if (isInserting) {
      context.missing(_setNumberMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('total_pieces')) {
      context.handle(
        _totalPiecesMeta,
        totalPieces.isAcceptableOrUnknown(
          data['total_pieces']!,
          _totalPiecesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalPiecesMeta);
    }
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LegoSet map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LegoSet(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      setNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}set_number'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      totalPieces: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_pieces'],
      )!,
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      ),
    );
  }

  @override
  $LegoSetsTable createAlias(String alias) {
    return $LegoSetsTable(attachedDatabase, alias);
  }
}

class LegoSet extends DataClass implements Insertable<LegoSet> {
  final int id;
  final String setNumber;
  final String name;
  final int totalPieces;
  final String? imageUrl;
  const LegoSet({
    required this.id,
    required this.setNumber,
    required this.name,
    required this.totalPieces,
    this.imageUrl,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['set_number'] = Variable<String>(setNumber);
    map['name'] = Variable<String>(name);
    map['total_pieces'] = Variable<int>(totalPieces);
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    return map;
  }

  LegoSetsCompanion toCompanion(bool nullToAbsent) {
    return LegoSetsCompanion(
      id: Value(id),
      setNumber: Value(setNumber),
      name: Value(name),
      totalPieces: Value(totalPieces),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
    );
  }

  factory LegoSet.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LegoSet(
      id: serializer.fromJson<int>(json['id']),
      setNumber: serializer.fromJson<String>(json['setNumber']),
      name: serializer.fromJson<String>(json['name']),
      totalPieces: serializer.fromJson<int>(json['totalPieces']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'setNumber': serializer.toJson<String>(setNumber),
      'name': serializer.toJson<String>(name),
      'totalPieces': serializer.toJson<int>(totalPieces),
      'imageUrl': serializer.toJson<String?>(imageUrl),
    };
  }

  LegoSet copyWith({
    int? id,
    String? setNumber,
    String? name,
    int? totalPieces,
    Value<String?> imageUrl = const Value.absent(),
  }) => LegoSet(
    id: id ?? this.id,
    setNumber: setNumber ?? this.setNumber,
    name: name ?? this.name,
    totalPieces: totalPieces ?? this.totalPieces,
    imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
  );
  LegoSet copyWithCompanion(LegoSetsCompanion data) {
    return LegoSet(
      id: data.id.present ? data.id.value : this.id,
      setNumber: data.setNumber.present ? data.setNumber.value : this.setNumber,
      name: data.name.present ? data.name.value : this.name,
      totalPieces: data.totalPieces.present
          ? data.totalPieces.value
          : this.totalPieces,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LegoSet(')
          ..write('id: $id, ')
          ..write('setNumber: $setNumber, ')
          ..write('name: $name, ')
          ..write('totalPieces: $totalPieces, ')
          ..write('imageUrl: $imageUrl')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, setNumber, name, totalPieces, imageUrl);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LegoSet &&
          other.id == this.id &&
          other.setNumber == this.setNumber &&
          other.name == this.name &&
          other.totalPieces == this.totalPieces &&
          other.imageUrl == this.imageUrl);
}

class LegoSetsCompanion extends UpdateCompanion<LegoSet> {
  final Value<int> id;
  final Value<String> setNumber;
  final Value<String> name;
  final Value<int> totalPieces;
  final Value<String?> imageUrl;
  const LegoSetsCompanion({
    this.id = const Value.absent(),
    this.setNumber = const Value.absent(),
    this.name = const Value.absent(),
    this.totalPieces = const Value.absent(),
    this.imageUrl = const Value.absent(),
  });
  LegoSetsCompanion.insert({
    this.id = const Value.absent(),
    required String setNumber,
    required String name,
    required int totalPieces,
    this.imageUrl = const Value.absent(),
  }) : setNumber = Value(setNumber),
       name = Value(name),
       totalPieces = Value(totalPieces);
  static Insertable<LegoSet> custom({
    Expression<int>? id,
    Expression<String>? setNumber,
    Expression<String>? name,
    Expression<int>? totalPieces,
    Expression<String>? imageUrl,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (setNumber != null) 'set_number': setNumber,
      if (name != null) 'name': name,
      if (totalPieces != null) 'total_pieces': totalPieces,
      if (imageUrl != null) 'image_url': imageUrl,
    });
  }

  LegoSetsCompanion copyWith({
    Value<int>? id,
    Value<String>? setNumber,
    Value<String>? name,
    Value<int>? totalPieces,
    Value<String?>? imageUrl,
  }) {
    return LegoSetsCompanion(
      id: id ?? this.id,
      setNumber: setNumber ?? this.setNumber,
      name: name ?? this.name,
      totalPieces: totalPieces ?? this.totalPieces,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (setNumber.present) {
      map['set_number'] = Variable<String>(setNumber.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (totalPieces.present) {
      map['total_pieces'] = Variable<int>(totalPieces.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LegoSetsCompanion(')
          ..write('id: $id, ')
          ..write('setNumber: $setNumber, ')
          ..write('name: $name, ')
          ..write('totalPieces: $totalPieces, ')
          ..write('imageUrl: $imageUrl')
          ..write(')'))
        .toString();
  }
}

class $BuildSessionsTable extends BuildSessions
    with TableInfo<$BuildSessionsTable, BuildSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BuildSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _legoSetIdMeta = const VerificationMeta(
    'legoSetId',
  );
  @override
  late final GeneratedColumn<int> legoSetId = GeneratedColumn<int>(
    'lego_set_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES lego_sets (id)',
    ),
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isCompletedMeta = const VerificationMeta(
    'isCompleted',
  );
  @override
  late final GeneratedColumn<bool> isCompleted = GeneratedColumn<bool>(
    'is_completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [id, legoSetId, startDate, isCompleted];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'build_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<BuildSession> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('lego_set_id')) {
      context.handle(
        _legoSetIdMeta,
        legoSetId.isAcceptableOrUnknown(data['lego_set_id']!, _legoSetIdMeta),
      );
    } else if (isInserting) {
      context.missing(_legoSetIdMeta);
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('is_completed')) {
      context.handle(
        _isCompletedMeta,
        isCompleted.isAcceptableOrUnknown(
          data['is_completed']!,
          _isCompletedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BuildSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BuildSession(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      legoSetId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lego_set_id'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_date'],
      )!,
      isCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_completed'],
      )!,
    );
  }

  @override
  $BuildSessionsTable createAlias(String alias) {
    return $BuildSessionsTable(attachedDatabase, alias);
  }
}

class BuildSession extends DataClass implements Insertable<BuildSession> {
  final int id;
  final int legoSetId;
  final DateTime startDate;
  final bool isCompleted;
  const BuildSession({
    required this.id,
    required this.legoSetId,
    required this.startDate,
    required this.isCompleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['lego_set_id'] = Variable<int>(legoSetId);
    map['start_date'] = Variable<DateTime>(startDate);
    map['is_completed'] = Variable<bool>(isCompleted);
    return map;
  }

  BuildSessionsCompanion toCompanion(bool nullToAbsent) {
    return BuildSessionsCompanion(
      id: Value(id),
      legoSetId: Value(legoSetId),
      startDate: Value(startDate),
      isCompleted: Value(isCompleted),
    );
  }

  factory BuildSession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BuildSession(
      id: serializer.fromJson<int>(json['id']),
      legoSetId: serializer.fromJson<int>(json['legoSetId']),
      startDate: serializer.fromJson<DateTime>(json['startDate']),
      isCompleted: serializer.fromJson<bool>(json['isCompleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'legoSetId': serializer.toJson<int>(legoSetId),
      'startDate': serializer.toJson<DateTime>(startDate),
      'isCompleted': serializer.toJson<bool>(isCompleted),
    };
  }

  BuildSession copyWith({
    int? id,
    int? legoSetId,
    DateTime? startDate,
    bool? isCompleted,
  }) => BuildSession(
    id: id ?? this.id,
    legoSetId: legoSetId ?? this.legoSetId,
    startDate: startDate ?? this.startDate,
    isCompleted: isCompleted ?? this.isCompleted,
  );
  BuildSession copyWithCompanion(BuildSessionsCompanion data) {
    return BuildSession(
      id: data.id.present ? data.id.value : this.id,
      legoSetId: data.legoSetId.present ? data.legoSetId.value : this.legoSetId,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      isCompleted: data.isCompleted.present
          ? data.isCompleted.value
          : this.isCompleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BuildSession(')
          ..write('id: $id, ')
          ..write('legoSetId: $legoSetId, ')
          ..write('startDate: $startDate, ')
          ..write('isCompleted: $isCompleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, legoSetId, startDate, isCompleted);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BuildSession &&
          other.id == this.id &&
          other.legoSetId == this.legoSetId &&
          other.startDate == this.startDate &&
          other.isCompleted == this.isCompleted);
}

class BuildSessionsCompanion extends UpdateCompanion<BuildSession> {
  final Value<int> id;
  final Value<int> legoSetId;
  final Value<DateTime> startDate;
  final Value<bool> isCompleted;
  const BuildSessionsCompanion({
    this.id = const Value.absent(),
    this.legoSetId = const Value.absent(),
    this.startDate = const Value.absent(),
    this.isCompleted = const Value.absent(),
  });
  BuildSessionsCompanion.insert({
    this.id = const Value.absent(),
    required int legoSetId,
    required DateTime startDate,
    this.isCompleted = const Value.absent(),
  }) : legoSetId = Value(legoSetId),
       startDate = Value(startDate);
  static Insertable<BuildSession> custom({
    Expression<int>? id,
    Expression<int>? legoSetId,
    Expression<DateTime>? startDate,
    Expression<bool>? isCompleted,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (legoSetId != null) 'lego_set_id': legoSetId,
      if (startDate != null) 'start_date': startDate,
      if (isCompleted != null) 'is_completed': isCompleted,
    });
  }

  BuildSessionsCompanion copyWith({
    Value<int>? id,
    Value<int>? legoSetId,
    Value<DateTime>? startDate,
    Value<bool>? isCompleted,
  }) {
    return BuildSessionsCompanion(
      id: id ?? this.id,
      legoSetId: legoSetId ?? this.legoSetId,
      startDate: startDate ?? this.startDate,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (legoSetId.present) {
      map['lego_set_id'] = Variable<int>(legoSetId.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (isCompleted.present) {
      map['is_completed'] = Variable<bool>(isCompleted.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BuildSessionsCompanion(')
          ..write('id: $id, ')
          ..write('legoSetId: $legoSetId, ')
          ..write('startDate: $startDate, ')
          ..write('isCompleted: $isCompleted')
          ..write(')'))
        .toString();
  }
}

class $BagIntervalsTable extends BagIntervals
    with TableInfo<$BagIntervalsTable, BagInterval> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BagIntervalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _buildSessionIdMeta = const VerificationMeta(
    'buildSessionId',
  );
  @override
  late final GeneratedColumn<int> buildSessionId = GeneratedColumn<int>(
    'build_session_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES build_sessions (id)',
    ),
  );
  static const VerificationMeta _bagNumberMeta = const VerificationMeta(
    'bagNumber',
  );
  @override
  late final GeneratedColumn<int> bagNumber = GeneratedColumn<int>(
    'bag_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startTimeMeta = const VerificationMeta(
    'startTime',
  );
  @override
  late final GeneratedColumn<DateTime> startTime = GeneratedColumn<DateTime>(
    'start_time',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endTimeMeta = const VerificationMeta(
    'endTime',
  );
  @override
  late final GeneratedColumn<DateTime> endTime = GeneratedColumn<DateTime>(
    'end_time',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isCompletedMeta = const VerificationMeta(
    'isCompleted',
  );
  @override
  late final GeneratedColumn<bool> isCompleted = GeneratedColumn<bool>(
    'is_completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    buildSessionId,
    bagNumber,
    startTime,
    endTime,
    isCompleted,
    isSynced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bag_intervals';
  @override
  VerificationContext validateIntegrity(
    Insertable<BagInterval> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('build_session_id')) {
      context.handle(
        _buildSessionIdMeta,
        buildSessionId.isAcceptableOrUnknown(
          data['build_session_id']!,
          _buildSessionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_buildSessionIdMeta);
    }
    if (data.containsKey('bag_number')) {
      context.handle(
        _bagNumberMeta,
        bagNumber.isAcceptableOrUnknown(data['bag_number']!, _bagNumberMeta),
      );
    } else if (isInserting) {
      context.missing(_bagNumberMeta);
    }
    if (data.containsKey('start_time')) {
      context.handle(
        _startTimeMeta,
        startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_startTimeMeta);
    }
    if (data.containsKey('end_time')) {
      context.handle(
        _endTimeMeta,
        endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta),
      );
    }
    if (data.containsKey('is_completed')) {
      context.handle(
        _isCompletedMeta,
        isCompleted.isAcceptableOrUnknown(
          data['is_completed']!,
          _isCompletedMeta,
        ),
      );
    }
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BagInterval map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BagInterval(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      buildSessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}build_session_id'],
      )!,
      bagNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bag_number'],
      )!,
      startTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_time'],
      )!,
      endTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}end_time'],
      ),
      isCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_completed'],
      )!,
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
    );
  }

  @override
  $BagIntervalsTable createAlias(String alias) {
    return $BagIntervalsTable(attachedDatabase, alias);
  }
}

class BagInterval extends DataClass implements Insertable<BagInterval> {
  final int id;
  final int buildSessionId;
  final int bagNumber;
  final DateTime startTime;
  final DateTime? endTime;
  final bool isCompleted;
  final bool isSynced;
  const BagInterval({
    required this.id,
    required this.buildSessionId,
    required this.bagNumber,
    required this.startTime,
    this.endTime,
    required this.isCompleted,
    required this.isSynced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['build_session_id'] = Variable<int>(buildSessionId);
    map['bag_number'] = Variable<int>(bagNumber);
    map['start_time'] = Variable<DateTime>(startTime);
    if (!nullToAbsent || endTime != null) {
      map['end_time'] = Variable<DateTime>(endTime);
    }
    map['is_completed'] = Variable<bool>(isCompleted);
    map['is_synced'] = Variable<bool>(isSynced);
    return map;
  }

  BagIntervalsCompanion toCompanion(bool nullToAbsent) {
    return BagIntervalsCompanion(
      id: Value(id),
      buildSessionId: Value(buildSessionId),
      bagNumber: Value(bagNumber),
      startTime: Value(startTime),
      endTime: endTime == null && nullToAbsent
          ? const Value.absent()
          : Value(endTime),
      isCompleted: Value(isCompleted),
      isSynced: Value(isSynced),
    );
  }

  factory BagInterval.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BagInterval(
      id: serializer.fromJson<int>(json['id']),
      buildSessionId: serializer.fromJson<int>(json['buildSessionId']),
      bagNumber: serializer.fromJson<int>(json['bagNumber']),
      startTime: serializer.fromJson<DateTime>(json['startTime']),
      endTime: serializer.fromJson<DateTime?>(json['endTime']),
      isCompleted: serializer.fromJson<bool>(json['isCompleted']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'buildSessionId': serializer.toJson<int>(buildSessionId),
      'bagNumber': serializer.toJson<int>(bagNumber),
      'startTime': serializer.toJson<DateTime>(startTime),
      'endTime': serializer.toJson<DateTime?>(endTime),
      'isCompleted': serializer.toJson<bool>(isCompleted),
      'isSynced': serializer.toJson<bool>(isSynced),
    };
  }

  BagInterval copyWith({
    int? id,
    int? buildSessionId,
    int? bagNumber,
    DateTime? startTime,
    Value<DateTime?> endTime = const Value.absent(),
    bool? isCompleted,
    bool? isSynced,
  }) => BagInterval(
    id: id ?? this.id,
    buildSessionId: buildSessionId ?? this.buildSessionId,
    bagNumber: bagNumber ?? this.bagNumber,
    startTime: startTime ?? this.startTime,
    endTime: endTime.present ? endTime.value : this.endTime,
    isCompleted: isCompleted ?? this.isCompleted,
    isSynced: isSynced ?? this.isSynced,
  );
  BagInterval copyWithCompanion(BagIntervalsCompanion data) {
    return BagInterval(
      id: data.id.present ? data.id.value : this.id,
      buildSessionId: data.buildSessionId.present
          ? data.buildSessionId.value
          : this.buildSessionId,
      bagNumber: data.bagNumber.present ? data.bagNumber.value : this.bagNumber,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      isCompleted: data.isCompleted.present
          ? data.isCompleted.value
          : this.isCompleted,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BagInterval(')
          ..write('id: $id, ')
          ..write('buildSessionId: $buildSessionId, ')
          ..write('bagNumber: $bagNumber, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('isSynced: $isSynced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    buildSessionId,
    bagNumber,
    startTime,
    endTime,
    isCompleted,
    isSynced,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BagInterval &&
          other.id == this.id &&
          other.buildSessionId == this.buildSessionId &&
          other.bagNumber == this.bagNumber &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.isCompleted == this.isCompleted &&
          other.isSynced == this.isSynced);
}

class BagIntervalsCompanion extends UpdateCompanion<BagInterval> {
  final Value<int> id;
  final Value<int> buildSessionId;
  final Value<int> bagNumber;
  final Value<DateTime> startTime;
  final Value<DateTime?> endTime;
  final Value<bool> isCompleted;
  final Value<bool> isSynced;
  const BagIntervalsCompanion({
    this.id = const Value.absent(),
    this.buildSessionId = const Value.absent(),
    this.bagNumber = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.isSynced = const Value.absent(),
  });
  BagIntervalsCompanion.insert({
    this.id = const Value.absent(),
    required int buildSessionId,
    required int bagNumber,
    required DateTime startTime,
    this.endTime = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.isSynced = const Value.absent(),
  }) : buildSessionId = Value(buildSessionId),
       bagNumber = Value(bagNumber),
       startTime = Value(startTime);
  static Insertable<BagInterval> custom({
    Expression<int>? id,
    Expression<int>? buildSessionId,
    Expression<int>? bagNumber,
    Expression<DateTime>? startTime,
    Expression<DateTime>? endTime,
    Expression<bool>? isCompleted,
    Expression<bool>? isSynced,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (buildSessionId != null) 'build_session_id': buildSessionId,
      if (bagNumber != null) 'bag_number': bagNumber,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (isCompleted != null) 'is_completed': isCompleted,
      if (isSynced != null) 'is_synced': isSynced,
    });
  }

  BagIntervalsCompanion copyWith({
    Value<int>? id,
    Value<int>? buildSessionId,
    Value<int>? bagNumber,
    Value<DateTime>? startTime,
    Value<DateTime?>? endTime,
    Value<bool>? isCompleted,
    Value<bool>? isSynced,
  }) {
    return BagIntervalsCompanion(
      id: id ?? this.id,
      buildSessionId: buildSessionId ?? this.buildSessionId,
      bagNumber: bagNumber ?? this.bagNumber,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isCompleted: isCompleted ?? this.isCompleted,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (buildSessionId.present) {
      map['build_session_id'] = Variable<int>(buildSessionId.value);
    }
    if (bagNumber.present) {
      map['bag_number'] = Variable<int>(bagNumber.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<DateTime>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<DateTime>(endTime.value);
    }
    if (isCompleted.present) {
      map['is_completed'] = Variable<bool>(isCompleted.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BagIntervalsCompanion(')
          ..write('id: $id, ')
          ..write('buildSessionId: $buildSessionId, ')
          ..write('bagNumber: $bagNumber, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('isSynced: $isSynced')
          ..write(')'))
        .toString();
  }
}

abstract class _$LedgerRepository extends GeneratedDatabase {
  _$LedgerRepository(QueryExecutor e) : super(e);
  $LedgerRepositoryManager get managers => $LedgerRepositoryManager(this);
  late final $LegoSetsTable legoSets = $LegoSetsTable(this);
  late final $BuildSessionsTable buildSessions = $BuildSessionsTable(this);
  late final $BagIntervalsTable bagIntervals = $BagIntervalsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    legoSets,
    buildSessions,
    bagIntervals,
  ];
}

typedef $$LegoSetsTableCreateCompanionBuilder =
    LegoSetsCompanion Function({
      Value<int> id,
      required String setNumber,
      required String name,
      required int totalPieces,
      Value<String?> imageUrl,
    });
typedef $$LegoSetsTableUpdateCompanionBuilder =
    LegoSetsCompanion Function({
      Value<int> id,
      Value<String> setNumber,
      Value<String> name,
      Value<int> totalPieces,
      Value<String?> imageUrl,
    });

final class $$LegoSetsTableReferences
    extends BaseReferences<_$LedgerRepository, $LegoSetsTable, LegoSet> {
  $$LegoSetsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$BuildSessionsTable, List<BuildSession>>
  _buildSessionsRefsTable(_$LedgerRepository db) =>
      MultiTypedResultKey.fromTable(
        db.buildSessions,
        aliasName: $_aliasNameGenerator(
          db.legoSets.id,
          db.buildSessions.legoSetId,
        ),
      );

  $$BuildSessionsTableProcessedTableManager get buildSessionsRefs {
    final manager = $$BuildSessionsTableTableManager(
      $_db,
      $_db.buildSessions,
    ).filter((f) => f.legoSetId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_buildSessionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$LegoSetsTableFilterComposer
    extends Composer<_$LedgerRepository, $LegoSetsTable> {
  $$LegoSetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get setNumber => $composableBuilder(
    column: $table.setNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalPieces => $composableBuilder(
    column: $table.totalPieces,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> buildSessionsRefs(
    Expression<bool> Function($$BuildSessionsTableFilterComposer f) f,
  ) {
    final $$BuildSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.buildSessions,
      getReferencedColumn: (t) => t.legoSetId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BuildSessionsTableFilterComposer(
            $db: $db,
            $table: $db.buildSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LegoSetsTableOrderingComposer
    extends Composer<_$LedgerRepository, $LegoSetsTable> {
  $$LegoSetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get setNumber => $composableBuilder(
    column: $table.setNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalPieces => $composableBuilder(
    column: $table.totalPieces,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LegoSetsTableAnnotationComposer
    extends Composer<_$LedgerRepository, $LegoSetsTable> {
  $$LegoSetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get setNumber =>
      $composableBuilder(column: $table.setNumber, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get totalPieces => $composableBuilder(
    column: $table.totalPieces,
    builder: (column) => column,
  );

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  Expression<T> buildSessionsRefs<T extends Object>(
    Expression<T> Function($$BuildSessionsTableAnnotationComposer a) f,
  ) {
    final $$BuildSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.buildSessions,
      getReferencedColumn: (t) => t.legoSetId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BuildSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.buildSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LegoSetsTableTableManager
    extends
        RootTableManager<
          _$LedgerRepository,
          $LegoSetsTable,
          LegoSet,
          $$LegoSetsTableFilterComposer,
          $$LegoSetsTableOrderingComposer,
          $$LegoSetsTableAnnotationComposer,
          $$LegoSetsTableCreateCompanionBuilder,
          $$LegoSetsTableUpdateCompanionBuilder,
          (LegoSet, $$LegoSetsTableReferences),
          LegoSet,
          PrefetchHooks Function({bool buildSessionsRefs})
        > {
  $$LegoSetsTableTableManager(_$LedgerRepository db, $LegoSetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LegoSetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LegoSetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LegoSetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> setNumber = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> totalPieces = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
              }) => LegoSetsCompanion(
                id: id,
                setNumber: setNumber,
                name: name,
                totalPieces: totalPieces,
                imageUrl: imageUrl,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String setNumber,
                required String name,
                required int totalPieces,
                Value<String?> imageUrl = const Value.absent(),
              }) => LegoSetsCompanion.insert(
                id: id,
                setNumber: setNumber,
                name: name,
                totalPieces: totalPieces,
                imageUrl: imageUrl,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LegoSetsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({buildSessionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (buildSessionsRefs) db.buildSessions,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (buildSessionsRefs)
                    await $_getPrefetchedData<
                      LegoSet,
                      $LegoSetsTable,
                      BuildSession
                    >(
                      currentTable: table,
                      referencedTable: $$LegoSetsTableReferences
                          ._buildSessionsRefsTable(db),
                      managerFromTypedResult: (p0) => $$LegoSetsTableReferences(
                        db,
                        table,
                        p0,
                      ).buildSessionsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.legoSetId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$LegoSetsTableProcessedTableManager =
    ProcessedTableManager<
      _$LedgerRepository,
      $LegoSetsTable,
      LegoSet,
      $$LegoSetsTableFilterComposer,
      $$LegoSetsTableOrderingComposer,
      $$LegoSetsTableAnnotationComposer,
      $$LegoSetsTableCreateCompanionBuilder,
      $$LegoSetsTableUpdateCompanionBuilder,
      (LegoSet, $$LegoSetsTableReferences),
      LegoSet,
      PrefetchHooks Function({bool buildSessionsRefs})
    >;
typedef $$BuildSessionsTableCreateCompanionBuilder =
    BuildSessionsCompanion Function({
      Value<int> id,
      required int legoSetId,
      required DateTime startDate,
      Value<bool> isCompleted,
    });
typedef $$BuildSessionsTableUpdateCompanionBuilder =
    BuildSessionsCompanion Function({
      Value<int> id,
      Value<int> legoSetId,
      Value<DateTime> startDate,
      Value<bool> isCompleted,
    });

final class $$BuildSessionsTableReferences
    extends
        BaseReferences<_$LedgerRepository, $BuildSessionsTable, BuildSession> {
  $$BuildSessionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $LegoSetsTable _legoSetIdTable(_$LedgerRepository db) =>
      db.legoSets.createAlias(
        $_aliasNameGenerator(db.buildSessions.legoSetId, db.legoSets.id),
      );

  $$LegoSetsTableProcessedTableManager get legoSetId {
    final $_column = $_itemColumn<int>('lego_set_id')!;

    final manager = $$LegoSetsTableTableManager(
      $_db,
      $_db.legoSets,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_legoSetIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$BagIntervalsTable, List<BagInterval>>
  _bagIntervalsRefsTable(_$LedgerRepository db) =>
      MultiTypedResultKey.fromTable(
        db.bagIntervals,
        aliasName: $_aliasNameGenerator(
          db.buildSessions.id,
          db.bagIntervals.buildSessionId,
        ),
      );

  $$BagIntervalsTableProcessedTableManager get bagIntervalsRefs {
    final manager = $$BagIntervalsTableTableManager(
      $_db,
      $_db.bagIntervals,
    ).filter((f) => f.buildSessionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_bagIntervalsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$BuildSessionsTableFilterComposer
    extends Composer<_$LedgerRepository, $BuildSessionsTable> {
  $$BuildSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnFilters(column),
  );

  $$LegoSetsTableFilterComposer get legoSetId {
    final $$LegoSetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.legoSetId,
      referencedTable: $db.legoSets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LegoSetsTableFilterComposer(
            $db: $db,
            $table: $db.legoSets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> bagIntervalsRefs(
    Expression<bool> Function($$BagIntervalsTableFilterComposer f) f,
  ) {
    final $$BagIntervalsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.bagIntervals,
      getReferencedColumn: (t) => t.buildSessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BagIntervalsTableFilterComposer(
            $db: $db,
            $table: $db.bagIntervals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BuildSessionsTableOrderingComposer
    extends Composer<_$LedgerRepository, $BuildSessionsTable> {
  $$BuildSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  $$LegoSetsTableOrderingComposer get legoSetId {
    final $$LegoSetsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.legoSetId,
      referencedTable: $db.legoSets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LegoSetsTableOrderingComposer(
            $db: $db,
            $table: $db.legoSets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BuildSessionsTableAnnotationComposer
    extends Composer<_$LedgerRepository, $BuildSessionsTable> {
  $$BuildSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => column,
  );

  $$LegoSetsTableAnnotationComposer get legoSetId {
    final $$LegoSetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.legoSetId,
      referencedTable: $db.legoSets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LegoSetsTableAnnotationComposer(
            $db: $db,
            $table: $db.legoSets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> bagIntervalsRefs<T extends Object>(
    Expression<T> Function($$BagIntervalsTableAnnotationComposer a) f,
  ) {
    final $$BagIntervalsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.bagIntervals,
      getReferencedColumn: (t) => t.buildSessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BagIntervalsTableAnnotationComposer(
            $db: $db,
            $table: $db.bagIntervals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BuildSessionsTableTableManager
    extends
        RootTableManager<
          _$LedgerRepository,
          $BuildSessionsTable,
          BuildSession,
          $$BuildSessionsTableFilterComposer,
          $$BuildSessionsTableOrderingComposer,
          $$BuildSessionsTableAnnotationComposer,
          $$BuildSessionsTableCreateCompanionBuilder,
          $$BuildSessionsTableUpdateCompanionBuilder,
          (BuildSession, $$BuildSessionsTableReferences),
          BuildSession,
          PrefetchHooks Function({bool legoSetId, bool bagIntervalsRefs})
        > {
  $$BuildSessionsTableTableManager(
    _$LedgerRepository db,
    $BuildSessionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BuildSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BuildSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BuildSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> legoSetId = const Value.absent(),
                Value<DateTime> startDate = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
              }) => BuildSessionsCompanion(
                id: id,
                legoSetId: legoSetId,
                startDate: startDate,
                isCompleted: isCompleted,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int legoSetId,
                required DateTime startDate,
                Value<bool> isCompleted = const Value.absent(),
              }) => BuildSessionsCompanion.insert(
                id: id,
                legoSetId: legoSetId,
                startDate: startDate,
                isCompleted: isCompleted,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$BuildSessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({legoSetId = false, bagIntervalsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (bagIntervalsRefs) db.bagIntervals,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (legoSetId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.legoSetId,
                                    referencedTable:
                                        $$BuildSessionsTableReferences
                                            ._legoSetIdTable(db),
                                    referencedColumn:
                                        $$BuildSessionsTableReferences
                                            ._legoSetIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (bagIntervalsRefs)
                        await $_getPrefetchedData<
                          BuildSession,
                          $BuildSessionsTable,
                          BagInterval
                        >(
                          currentTable: table,
                          referencedTable: $$BuildSessionsTableReferences
                              ._bagIntervalsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BuildSessionsTableReferences(
                                db,
                                table,
                                p0,
                              ).bagIntervalsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.buildSessionId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$BuildSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$LedgerRepository,
      $BuildSessionsTable,
      BuildSession,
      $$BuildSessionsTableFilterComposer,
      $$BuildSessionsTableOrderingComposer,
      $$BuildSessionsTableAnnotationComposer,
      $$BuildSessionsTableCreateCompanionBuilder,
      $$BuildSessionsTableUpdateCompanionBuilder,
      (BuildSession, $$BuildSessionsTableReferences),
      BuildSession,
      PrefetchHooks Function({bool legoSetId, bool bagIntervalsRefs})
    >;
typedef $$BagIntervalsTableCreateCompanionBuilder =
    BagIntervalsCompanion Function({
      Value<int> id,
      required int buildSessionId,
      required int bagNumber,
      required DateTime startTime,
      Value<DateTime?> endTime,
      Value<bool> isCompleted,
      Value<bool> isSynced,
    });
typedef $$BagIntervalsTableUpdateCompanionBuilder =
    BagIntervalsCompanion Function({
      Value<int> id,
      Value<int> buildSessionId,
      Value<int> bagNumber,
      Value<DateTime> startTime,
      Value<DateTime?> endTime,
      Value<bool> isCompleted,
      Value<bool> isSynced,
    });

final class $$BagIntervalsTableReferences
    extends
        BaseReferences<_$LedgerRepository, $BagIntervalsTable, BagInterval> {
  $$BagIntervalsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $BuildSessionsTable _buildSessionIdTable(_$LedgerRepository db) =>
      db.buildSessions.createAlias(
        $_aliasNameGenerator(
          db.bagIntervals.buildSessionId,
          db.buildSessions.id,
        ),
      );

  $$BuildSessionsTableProcessedTableManager get buildSessionId {
    final $_column = $_itemColumn<int>('build_session_id')!;

    final manager = $$BuildSessionsTableTableManager(
      $_db,
      $_db.buildSessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_buildSessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$BagIntervalsTableFilterComposer
    extends Composer<_$LedgerRepository, $BagIntervalsTable> {
  $$BagIntervalsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bagNumber => $composableBuilder(
    column: $table.bagNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );

  $$BuildSessionsTableFilterComposer get buildSessionId {
    final $$BuildSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.buildSessionId,
      referencedTable: $db.buildSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BuildSessionsTableFilterComposer(
            $db: $db,
            $table: $db.buildSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BagIntervalsTableOrderingComposer
    extends Composer<_$LedgerRepository, $BagIntervalsTable> {
  $$BagIntervalsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bagNumber => $composableBuilder(
    column: $table.bagNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );

  $$BuildSessionsTableOrderingComposer get buildSessionId {
    final $$BuildSessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.buildSessionId,
      referencedTable: $db.buildSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BuildSessionsTableOrderingComposer(
            $db: $db,
            $table: $db.buildSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BagIntervalsTableAnnotationComposer
    extends Composer<_$LedgerRepository, $BagIntervalsTable> {
  $$BagIntervalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get bagNumber =>
      $composableBuilder(column: $table.bagNumber, builder: (column) => column);

  GeneratedColumn<DateTime> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<DateTime> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);

  GeneratedColumn<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  $$BuildSessionsTableAnnotationComposer get buildSessionId {
    final $$BuildSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.buildSessionId,
      referencedTable: $db.buildSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BuildSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.buildSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BagIntervalsTableTableManager
    extends
        RootTableManager<
          _$LedgerRepository,
          $BagIntervalsTable,
          BagInterval,
          $$BagIntervalsTableFilterComposer,
          $$BagIntervalsTableOrderingComposer,
          $$BagIntervalsTableAnnotationComposer,
          $$BagIntervalsTableCreateCompanionBuilder,
          $$BagIntervalsTableUpdateCompanionBuilder,
          (BagInterval, $$BagIntervalsTableReferences),
          BagInterval,
          PrefetchHooks Function({bool buildSessionId})
        > {
  $$BagIntervalsTableTableManager(
    _$LedgerRepository db,
    $BagIntervalsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BagIntervalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BagIntervalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BagIntervalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> buildSessionId = const Value.absent(),
                Value<int> bagNumber = const Value.absent(),
                Value<DateTime> startTime = const Value.absent(),
                Value<DateTime?> endTime = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
              }) => BagIntervalsCompanion(
                id: id,
                buildSessionId: buildSessionId,
                bagNumber: bagNumber,
                startTime: startTime,
                endTime: endTime,
                isCompleted: isCompleted,
                isSynced: isSynced,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int buildSessionId,
                required int bagNumber,
                required DateTime startTime,
                Value<DateTime?> endTime = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
              }) => BagIntervalsCompanion.insert(
                id: id,
                buildSessionId: buildSessionId,
                bagNumber: bagNumber,
                startTime: startTime,
                endTime: endTime,
                isCompleted: isCompleted,
                isSynced: isSynced,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$BagIntervalsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({buildSessionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (buildSessionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.buildSessionId,
                                referencedTable: $$BagIntervalsTableReferences
                                    ._buildSessionIdTable(db),
                                referencedColumn: $$BagIntervalsTableReferences
                                    ._buildSessionIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$BagIntervalsTableProcessedTableManager =
    ProcessedTableManager<
      _$LedgerRepository,
      $BagIntervalsTable,
      BagInterval,
      $$BagIntervalsTableFilterComposer,
      $$BagIntervalsTableOrderingComposer,
      $$BagIntervalsTableAnnotationComposer,
      $$BagIntervalsTableCreateCompanionBuilder,
      $$BagIntervalsTableUpdateCompanionBuilder,
      (BagInterval, $$BagIntervalsTableReferences),
      BagInterval,
      PrefetchHooks Function({bool buildSessionId})
    >;

class $LedgerRepositoryManager {
  final _$LedgerRepository _db;
  $LedgerRepositoryManager(this._db);
  $$LegoSetsTableTableManager get legoSets =>
      $$LegoSetsTableTableManager(_db, _db.legoSets);
  $$BuildSessionsTableTableManager get buildSessions =>
      $$BuildSessionsTableTableManager(_db, _db.buildSessions);
  $$BagIntervalsTableTableManager get bagIntervals =>
      $$BagIntervalsTableTableManager(_db, _db.bagIntervals);
}
