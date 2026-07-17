// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $DatasetsTable extends Datasets with TableInfo<$DatasetsTable, Dataset> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DatasetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sourceFileNameMeta =
      const VerificationMeta('sourceFileName');
  @override
  late final GeneratedColumn<String> sourceFileName = GeneratedColumn<String>(
      'source_file_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sourceFileHashMeta =
      const VerificationMeta('sourceFileHash');
  @override
  late final GeneratedColumn<String> sourceFileHash = GeneratedColumn<String>(
      'source_file_hash', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _lastOpenedAtMeta =
      const VerificationMeta('lastOpenedAt');
  @override
  late final GeneratedColumn<int> lastOpenedAt = GeneratedColumn<int>(
      'last_opened_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _uiStateJsonMeta =
      const VerificationMeta('uiStateJson');
  @override
  late final GeneratedColumn<String> uiStateJson = GeneratedColumn<String>(
      'ui_state_json', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        sourceFileName,
        sourceFileHash,
        createdAt,
        lastOpenedAt,
        uiStateJson
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'datasets';
  @override
  VerificationContext validateIntegrity(Insertable<Dataset> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('source_file_name')) {
      context.handle(
          _sourceFileNameMeta,
          sourceFileName.isAcceptableOrUnknown(
              data['source_file_name']!, _sourceFileNameMeta));
    } else if (isInserting) {
      context.missing(_sourceFileNameMeta);
    }
    if (data.containsKey('source_file_hash')) {
      context.handle(
          _sourceFileHashMeta,
          sourceFileHash.isAcceptableOrUnknown(
              data['source_file_hash']!, _sourceFileHashMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('last_opened_at')) {
      context.handle(
          _lastOpenedAtMeta,
          lastOpenedAt.isAcceptableOrUnknown(
              data['last_opened_at']!, _lastOpenedAtMeta));
    }
    if (data.containsKey('ui_state_json')) {
      context.handle(
          _uiStateJsonMeta,
          uiStateJson.isAcceptableOrUnknown(
              data['ui_state_json']!, _uiStateJsonMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Dataset map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Dataset(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      sourceFileName: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}source_file_name'])!,
      sourceFileHash: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}source_file_hash']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      lastOpenedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}last_opened_at']),
      uiStateJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}ui_state_json']),
    );
  }

  @override
  $DatasetsTable createAlias(String alias) {
    return $DatasetsTable(attachedDatabase, alias);
  }
}

class Dataset extends DataClass implements Insertable<Dataset> {
  /// Primary key (auto increment)
  final int id;

  /// Human readable name (e.g. "Import 2026-03-04 - Suppliers")
  final String name;

  /// Original file name imported by the user
  final String sourceFileName;

  /// Optional file hash (useful to detect re-import of same file)
  final String? sourceFileHash;

  /// Unix timestamp (milliseconds) when the dataset was created
  final int createdAt;

  /// Unix timestamp (milliseconds) when last opened
  final int? lastOpenedAt;

  /// Serialized UI state (filters, sorting, visible columns, etc.)
  final String? uiStateJson;
  const Dataset(
      {required this.id,
      required this.name,
      required this.sourceFileName,
      this.sourceFileHash,
      required this.createdAt,
      this.lastOpenedAt,
      this.uiStateJson});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['source_file_name'] = Variable<String>(sourceFileName);
    if (!nullToAbsent || sourceFileHash != null) {
      map['source_file_hash'] = Variable<String>(sourceFileHash);
    }
    map['created_at'] = Variable<int>(createdAt);
    if (!nullToAbsent || lastOpenedAt != null) {
      map['last_opened_at'] = Variable<int>(lastOpenedAt);
    }
    if (!nullToAbsent || uiStateJson != null) {
      map['ui_state_json'] = Variable<String>(uiStateJson);
    }
    return map;
  }

  DatasetsCompanion toCompanion(bool nullToAbsent) {
    return DatasetsCompanion(
      id: Value(id),
      name: Value(name),
      sourceFileName: Value(sourceFileName),
      sourceFileHash: sourceFileHash == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceFileHash),
      createdAt: Value(createdAt),
      lastOpenedAt: lastOpenedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastOpenedAt),
      uiStateJson: uiStateJson == null && nullToAbsent
          ? const Value.absent()
          : Value(uiStateJson),
    );
  }

  factory Dataset.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Dataset(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      sourceFileName: serializer.fromJson<String>(json['sourceFileName']),
      sourceFileHash: serializer.fromJson<String?>(json['sourceFileHash']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      lastOpenedAt: serializer.fromJson<int?>(json['lastOpenedAt']),
      uiStateJson: serializer.fromJson<String?>(json['uiStateJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'sourceFileName': serializer.toJson<String>(sourceFileName),
      'sourceFileHash': serializer.toJson<String?>(sourceFileHash),
      'createdAt': serializer.toJson<int>(createdAt),
      'lastOpenedAt': serializer.toJson<int?>(lastOpenedAt),
      'uiStateJson': serializer.toJson<String?>(uiStateJson),
    };
  }

  Dataset copyWith(
          {int? id,
          String? name,
          String? sourceFileName,
          Value<String?> sourceFileHash = const Value.absent(),
          int? createdAt,
          Value<int?> lastOpenedAt = const Value.absent(),
          Value<String?> uiStateJson = const Value.absent()}) =>
      Dataset(
        id: id ?? this.id,
        name: name ?? this.name,
        sourceFileName: sourceFileName ?? this.sourceFileName,
        sourceFileHash:
            sourceFileHash.present ? sourceFileHash.value : this.sourceFileHash,
        createdAt: createdAt ?? this.createdAt,
        lastOpenedAt:
            lastOpenedAt.present ? lastOpenedAt.value : this.lastOpenedAt,
        uiStateJson: uiStateJson.present ? uiStateJson.value : this.uiStateJson,
      );
  Dataset copyWithCompanion(DatasetsCompanion data) {
    return Dataset(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      sourceFileName: data.sourceFileName.present
          ? data.sourceFileName.value
          : this.sourceFileName,
      sourceFileHash: data.sourceFileHash.present
          ? data.sourceFileHash.value
          : this.sourceFileHash,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastOpenedAt: data.lastOpenedAt.present
          ? data.lastOpenedAt.value
          : this.lastOpenedAt,
      uiStateJson:
          data.uiStateJson.present ? data.uiStateJson.value : this.uiStateJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Dataset(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sourceFileName: $sourceFileName, ')
          ..write('sourceFileHash: $sourceFileHash, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastOpenedAt: $lastOpenedAt, ')
          ..write('uiStateJson: $uiStateJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, sourceFileName, sourceFileHash,
      createdAt, lastOpenedAt, uiStateJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Dataset &&
          other.id == this.id &&
          other.name == this.name &&
          other.sourceFileName == this.sourceFileName &&
          other.sourceFileHash == this.sourceFileHash &&
          other.createdAt == this.createdAt &&
          other.lastOpenedAt == this.lastOpenedAt &&
          other.uiStateJson == this.uiStateJson);
}

class DatasetsCompanion extends UpdateCompanion<Dataset> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> sourceFileName;
  final Value<String?> sourceFileHash;
  final Value<int> createdAt;
  final Value<int?> lastOpenedAt;
  final Value<String?> uiStateJson;
  const DatasetsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.sourceFileName = const Value.absent(),
    this.sourceFileHash = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastOpenedAt = const Value.absent(),
    this.uiStateJson = const Value.absent(),
  });
  DatasetsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String sourceFileName,
    this.sourceFileHash = const Value.absent(),
    required int createdAt,
    this.lastOpenedAt = const Value.absent(),
    this.uiStateJson = const Value.absent(),
  })  : name = Value(name),
        sourceFileName = Value(sourceFileName),
        createdAt = Value(createdAt);
  static Insertable<Dataset> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? sourceFileName,
    Expression<String>? sourceFileHash,
    Expression<int>? createdAt,
    Expression<int>? lastOpenedAt,
    Expression<String>? uiStateJson,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (sourceFileName != null) 'source_file_name': sourceFileName,
      if (sourceFileHash != null) 'source_file_hash': sourceFileHash,
      if (createdAt != null) 'created_at': createdAt,
      if (lastOpenedAt != null) 'last_opened_at': lastOpenedAt,
      if (uiStateJson != null) 'ui_state_json': uiStateJson,
    });
  }

  DatasetsCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<String>? sourceFileName,
      Value<String?>? sourceFileHash,
      Value<int>? createdAt,
      Value<int?>? lastOpenedAt,
      Value<String?>? uiStateJson}) {
    return DatasetsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      sourceFileName: sourceFileName ?? this.sourceFileName,
      sourceFileHash: sourceFileHash ?? this.sourceFileHash,
      createdAt: createdAt ?? this.createdAt,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
      uiStateJson: uiStateJson ?? this.uiStateJson,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (sourceFileName.present) {
      map['source_file_name'] = Variable<String>(sourceFileName.value);
    }
    if (sourceFileHash.present) {
      map['source_file_hash'] = Variable<String>(sourceFileHash.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (lastOpenedAt.present) {
      map['last_opened_at'] = Variable<int>(lastOpenedAt.value);
    }
    if (uiStateJson.present) {
      map['ui_state_json'] = Variable<String>(uiStateJson.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DatasetsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sourceFileName: $sourceFileName, ')
          ..write('sourceFileHash: $sourceFileHash, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastOpenedAt: $lastOpenedAt, ')
          ..write('uiStateJson: $uiStateJson')
          ..write(')'))
        .toString();
  }
}

class $DatasetTablesTable extends DatasetTables
    with TableInfo<$DatasetTablesTable, DatasetTable> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DatasetTablesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _datasetIdMeta =
      const VerificationMeta('datasetId');
  @override
  late final GeneratedColumn<int> datasetId = GeneratedColumn<int>(
      'dataset_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES datasets (id)'));
  static const VerificationMeta _sheetNameOriginalMeta =
      const VerificationMeta('sheetNameOriginal');
  @override
  late final GeneratedColumn<String> sheetNameOriginal =
      GeneratedColumn<String>('sheet_name_original', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sqlTableNameMeta =
      const VerificationMeta('sqlTableName');
  @override
  late final GeneratedColumn<String> sqlTableName = GeneratedColumn<String>(
      'sql_table_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _rowCountMeta =
      const VerificationMeta('rowCount');
  @override
  late final GeneratedColumn<int> rowCount = GeneratedColumn<int>(
      'row_count', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _colCountMeta =
      const VerificationMeta('colCount');
  @override
  late final GeneratedColumn<int> colCount = GeneratedColumn<int>(
      'col_count', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, datasetId, sheetNameOriginal, sqlTableName, rowCount, colCount];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dataset_tables';
  @override
  VerificationContext validateIntegrity(Insertable<DatasetTable> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('dataset_id')) {
      context.handle(_datasetIdMeta,
          datasetId.isAcceptableOrUnknown(data['dataset_id']!, _datasetIdMeta));
    } else if (isInserting) {
      context.missing(_datasetIdMeta);
    }
    if (data.containsKey('sheet_name_original')) {
      context.handle(
          _sheetNameOriginalMeta,
          sheetNameOriginal.isAcceptableOrUnknown(
              data['sheet_name_original']!, _sheetNameOriginalMeta));
    } else if (isInserting) {
      context.missing(_sheetNameOriginalMeta);
    }
    if (data.containsKey('sql_table_name')) {
      context.handle(
          _sqlTableNameMeta,
          sqlTableName.isAcceptableOrUnknown(
              data['sql_table_name']!, _sqlTableNameMeta));
    } else if (isInserting) {
      context.missing(_sqlTableNameMeta);
    }
    if (data.containsKey('row_count')) {
      context.handle(_rowCountMeta,
          rowCount.isAcceptableOrUnknown(data['row_count']!, _rowCountMeta));
    } else if (isInserting) {
      context.missing(_rowCountMeta);
    }
    if (data.containsKey('col_count')) {
      context.handle(_colCountMeta,
          colCount.isAcceptableOrUnknown(data['col_count']!, _colCountMeta));
    } else if (isInserting) {
      context.missing(_colCountMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DatasetTable map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DatasetTable(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      datasetId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}dataset_id'])!,
      sheetNameOriginal: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}sheet_name_original'])!,
      sqlTableName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sql_table_name'])!,
      rowCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}row_count'])!,
      colCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}col_count'])!,
    );
  }

  @override
  $DatasetTablesTable createAlias(String alias) {
    return $DatasetTablesTable(attachedDatabase, alias);
  }
}

class DatasetTable extends DataClass implements Insertable<DatasetTable> {
  final int id;

  /// Foreign key to Datasets.id
  final int datasetId;

  /// Original sheet name inside Excel file
  final String sheetNameOriginal;

  /// Actual SQL table name (e.g. ds_12_sheet_1)
  final String sqlTableName;

  /// Number of rows inserted into this table
  final int rowCount;

  /// Number of columns created (denormalized for quick access)
  final int colCount;
  const DatasetTable(
      {required this.id,
      required this.datasetId,
      required this.sheetNameOriginal,
      required this.sqlTableName,
      required this.rowCount,
      required this.colCount});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['dataset_id'] = Variable<int>(datasetId);
    map['sheet_name_original'] = Variable<String>(sheetNameOriginal);
    map['sql_table_name'] = Variable<String>(sqlTableName);
    map['row_count'] = Variable<int>(rowCount);
    map['col_count'] = Variable<int>(colCount);
    return map;
  }

  DatasetTablesCompanion toCompanion(bool nullToAbsent) {
    return DatasetTablesCompanion(
      id: Value(id),
      datasetId: Value(datasetId),
      sheetNameOriginal: Value(sheetNameOriginal),
      sqlTableName: Value(sqlTableName),
      rowCount: Value(rowCount),
      colCount: Value(colCount),
    );
  }

  factory DatasetTable.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DatasetTable(
      id: serializer.fromJson<int>(json['id']),
      datasetId: serializer.fromJson<int>(json['datasetId']),
      sheetNameOriginal: serializer.fromJson<String>(json['sheetNameOriginal']),
      sqlTableName: serializer.fromJson<String>(json['sqlTableName']),
      rowCount: serializer.fromJson<int>(json['rowCount']),
      colCount: serializer.fromJson<int>(json['colCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'datasetId': serializer.toJson<int>(datasetId),
      'sheetNameOriginal': serializer.toJson<String>(sheetNameOriginal),
      'sqlTableName': serializer.toJson<String>(sqlTableName),
      'rowCount': serializer.toJson<int>(rowCount),
      'colCount': serializer.toJson<int>(colCount),
    };
  }

  DatasetTable copyWith(
          {int? id,
          int? datasetId,
          String? sheetNameOriginal,
          String? sqlTableName,
          int? rowCount,
          int? colCount}) =>
      DatasetTable(
        id: id ?? this.id,
        datasetId: datasetId ?? this.datasetId,
        sheetNameOriginal: sheetNameOriginal ?? this.sheetNameOriginal,
        sqlTableName: sqlTableName ?? this.sqlTableName,
        rowCount: rowCount ?? this.rowCount,
        colCount: colCount ?? this.colCount,
      );
  DatasetTable copyWithCompanion(DatasetTablesCompanion data) {
    return DatasetTable(
      id: data.id.present ? data.id.value : this.id,
      datasetId: data.datasetId.present ? data.datasetId.value : this.datasetId,
      sheetNameOriginal: data.sheetNameOriginal.present
          ? data.sheetNameOriginal.value
          : this.sheetNameOriginal,
      sqlTableName: data.sqlTableName.present
          ? data.sqlTableName.value
          : this.sqlTableName,
      rowCount: data.rowCount.present ? data.rowCount.value : this.rowCount,
      colCount: data.colCount.present ? data.colCount.value : this.colCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DatasetTable(')
          ..write('id: $id, ')
          ..write('datasetId: $datasetId, ')
          ..write('sheetNameOriginal: $sheetNameOriginal, ')
          ..write('sqlTableName: $sqlTableName, ')
          ..write('rowCount: $rowCount, ')
          ..write('colCount: $colCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, datasetId, sheetNameOriginal, sqlTableName, rowCount, colCount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DatasetTable &&
          other.id == this.id &&
          other.datasetId == this.datasetId &&
          other.sheetNameOriginal == this.sheetNameOriginal &&
          other.sqlTableName == this.sqlTableName &&
          other.rowCount == this.rowCount &&
          other.colCount == this.colCount);
}

class DatasetTablesCompanion extends UpdateCompanion<DatasetTable> {
  final Value<int> id;
  final Value<int> datasetId;
  final Value<String> sheetNameOriginal;
  final Value<String> sqlTableName;
  final Value<int> rowCount;
  final Value<int> colCount;
  const DatasetTablesCompanion({
    this.id = const Value.absent(),
    this.datasetId = const Value.absent(),
    this.sheetNameOriginal = const Value.absent(),
    this.sqlTableName = const Value.absent(),
    this.rowCount = const Value.absent(),
    this.colCount = const Value.absent(),
  });
  DatasetTablesCompanion.insert({
    this.id = const Value.absent(),
    required int datasetId,
    required String sheetNameOriginal,
    required String sqlTableName,
    required int rowCount,
    required int colCount,
  })  : datasetId = Value(datasetId),
        sheetNameOriginal = Value(sheetNameOriginal),
        sqlTableName = Value(sqlTableName),
        rowCount = Value(rowCount),
        colCount = Value(colCount);
  static Insertable<DatasetTable> custom({
    Expression<int>? id,
    Expression<int>? datasetId,
    Expression<String>? sheetNameOriginal,
    Expression<String>? sqlTableName,
    Expression<int>? rowCount,
    Expression<int>? colCount,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (datasetId != null) 'dataset_id': datasetId,
      if (sheetNameOriginal != null) 'sheet_name_original': sheetNameOriginal,
      if (sqlTableName != null) 'sql_table_name': sqlTableName,
      if (rowCount != null) 'row_count': rowCount,
      if (colCount != null) 'col_count': colCount,
    });
  }

  DatasetTablesCompanion copyWith(
      {Value<int>? id,
      Value<int>? datasetId,
      Value<String>? sheetNameOriginal,
      Value<String>? sqlTableName,
      Value<int>? rowCount,
      Value<int>? colCount}) {
    return DatasetTablesCompanion(
      id: id ?? this.id,
      datasetId: datasetId ?? this.datasetId,
      sheetNameOriginal: sheetNameOriginal ?? this.sheetNameOriginal,
      sqlTableName: sqlTableName ?? this.sqlTableName,
      rowCount: rowCount ?? this.rowCount,
      colCount: colCount ?? this.colCount,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (datasetId.present) {
      map['dataset_id'] = Variable<int>(datasetId.value);
    }
    if (sheetNameOriginal.present) {
      map['sheet_name_original'] = Variable<String>(sheetNameOriginal.value);
    }
    if (sqlTableName.present) {
      map['sql_table_name'] = Variable<String>(sqlTableName.value);
    }
    if (rowCount.present) {
      map['row_count'] = Variable<int>(rowCount.value);
    }
    if (colCount.present) {
      map['col_count'] = Variable<int>(colCount.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DatasetTablesCompanion(')
          ..write('id: $id, ')
          ..write('datasetId: $datasetId, ')
          ..write('sheetNameOriginal: $sheetNameOriginal, ')
          ..write('sqlTableName: $sqlTableName, ')
          ..write('rowCount: $rowCount, ')
          ..write('colCount: $colCount')
          ..write(')'))
        .toString();
  }
}

class $DatasetColumnsTable extends DatasetColumns
    with TableInfo<$DatasetColumnsTable, DatasetColumn> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DatasetColumnsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _datasetTableIdMeta =
      const VerificationMeta('datasetTableId');
  @override
  late final GeneratedColumn<int> datasetTableId = GeneratedColumn<int>(
      'dataset_table_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES dataset_tables (id)'));
  static const VerificationMeta _originalNameMeta =
      const VerificationMeta('originalName');
  @override
  late final GeneratedColumn<String> originalName = GeneratedColumn<String>(
      'original_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dbNameMeta = const VerificationMeta('dbName');
  @override
  late final GeneratedColumn<String> dbName = GeneratedColumn<String>(
      'db_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _declaredTypeMeta =
      const VerificationMeta('declaredType');
  @override
  late final GeneratedColumn<String> declaredType = GeneratedColumn<String>(
      'declared_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _inferredTypeMeta =
      const VerificationMeta('inferredType');
  @override
  late final GeneratedColumn<String> inferredType = GeneratedColumn<String>(
      'inferred_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nullableMeta =
      const VerificationMeta('nullable');
  @override
  late final GeneratedColumn<bool> nullable = GeneratedColumn<bool>(
      'nullable', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("nullable" IN (0, 1))'));
  static const VerificationMeta _statsJsonMeta =
      const VerificationMeta('statsJson');
  @override
  late final GeneratedColumn<String> statsJson = GeneratedColumn<String>(
      'stats_json', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        datasetTableId,
        originalName,
        dbName,
        declaredType,
        inferredType,
        nullable,
        statsJson
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dataset_columns';
  @override
  VerificationContext validateIntegrity(Insertable<DatasetColumn> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('dataset_table_id')) {
      context.handle(
          _datasetTableIdMeta,
          datasetTableId.isAcceptableOrUnknown(
              data['dataset_table_id']!, _datasetTableIdMeta));
    } else if (isInserting) {
      context.missing(_datasetTableIdMeta);
    }
    if (data.containsKey('original_name')) {
      context.handle(
          _originalNameMeta,
          originalName.isAcceptableOrUnknown(
              data['original_name']!, _originalNameMeta));
    } else if (isInserting) {
      context.missing(_originalNameMeta);
    }
    if (data.containsKey('db_name')) {
      context.handle(_dbNameMeta,
          dbName.isAcceptableOrUnknown(data['db_name']!, _dbNameMeta));
    } else if (isInserting) {
      context.missing(_dbNameMeta);
    }
    if (data.containsKey('declared_type')) {
      context.handle(
          _declaredTypeMeta,
          declaredType.isAcceptableOrUnknown(
              data['declared_type']!, _declaredTypeMeta));
    } else if (isInserting) {
      context.missing(_declaredTypeMeta);
    }
    if (data.containsKey('inferred_type')) {
      context.handle(
          _inferredTypeMeta,
          inferredType.isAcceptableOrUnknown(
              data['inferred_type']!, _inferredTypeMeta));
    } else if (isInserting) {
      context.missing(_inferredTypeMeta);
    }
    if (data.containsKey('nullable')) {
      context.handle(_nullableMeta,
          nullable.isAcceptableOrUnknown(data['nullable']!, _nullableMeta));
    } else if (isInserting) {
      context.missing(_nullableMeta);
    }
    if (data.containsKey('stats_json')) {
      context.handle(_statsJsonMeta,
          statsJson.isAcceptableOrUnknown(data['stats_json']!, _statsJsonMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DatasetColumn map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DatasetColumn(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      datasetTableId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}dataset_table_id'])!,
      originalName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}original_name'])!,
      dbName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}db_name'])!,
      declaredType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}declared_type'])!,
      inferredType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}inferred_type'])!,
      nullable: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}nullable'])!,
      statsJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}stats_json']),
    );
  }

  @override
  $DatasetColumnsTable createAlias(String alias) {
    return $DatasetColumnsTable(attachedDatabase, alias);
  }
}

class DatasetColumn extends DataClass implements Insertable<DatasetColumn> {
  final int id;

  /// Foreign key to DatasetTables.id
  final int datasetTableId;

  /// Column name as found in the Excel header
  final String originalName;

  /// Sanitized SQL-safe column name
  final String dbName;

  /// Type selected/confirmed by user (TEXT, INTEGER, REAL, DATE, etc.)
  final String declaredType;

  /// Type inferred automatically by the system
  final String inferredType;

  /// Whether column allows null values
  final bool nullable;

  /// JSON containing statistics (min, max, distinctCount, etc.)
  final String? statsJson;
  const DatasetColumn(
      {required this.id,
      required this.datasetTableId,
      required this.originalName,
      required this.dbName,
      required this.declaredType,
      required this.inferredType,
      required this.nullable,
      this.statsJson});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['dataset_table_id'] = Variable<int>(datasetTableId);
    map['original_name'] = Variable<String>(originalName);
    map['db_name'] = Variable<String>(dbName);
    map['declared_type'] = Variable<String>(declaredType);
    map['inferred_type'] = Variable<String>(inferredType);
    map['nullable'] = Variable<bool>(nullable);
    if (!nullToAbsent || statsJson != null) {
      map['stats_json'] = Variable<String>(statsJson);
    }
    return map;
  }

  DatasetColumnsCompanion toCompanion(bool nullToAbsent) {
    return DatasetColumnsCompanion(
      id: Value(id),
      datasetTableId: Value(datasetTableId),
      originalName: Value(originalName),
      dbName: Value(dbName),
      declaredType: Value(declaredType),
      inferredType: Value(inferredType),
      nullable: Value(nullable),
      statsJson: statsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(statsJson),
    );
  }

  factory DatasetColumn.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DatasetColumn(
      id: serializer.fromJson<int>(json['id']),
      datasetTableId: serializer.fromJson<int>(json['datasetTableId']),
      originalName: serializer.fromJson<String>(json['originalName']),
      dbName: serializer.fromJson<String>(json['dbName']),
      declaredType: serializer.fromJson<String>(json['declaredType']),
      inferredType: serializer.fromJson<String>(json['inferredType']),
      nullable: serializer.fromJson<bool>(json['nullable']),
      statsJson: serializer.fromJson<String?>(json['statsJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'datasetTableId': serializer.toJson<int>(datasetTableId),
      'originalName': serializer.toJson<String>(originalName),
      'dbName': serializer.toJson<String>(dbName),
      'declaredType': serializer.toJson<String>(declaredType),
      'inferredType': serializer.toJson<String>(inferredType),
      'nullable': serializer.toJson<bool>(nullable),
      'statsJson': serializer.toJson<String?>(statsJson),
    };
  }

  DatasetColumn copyWith(
          {int? id,
          int? datasetTableId,
          String? originalName,
          String? dbName,
          String? declaredType,
          String? inferredType,
          bool? nullable,
          Value<String?> statsJson = const Value.absent()}) =>
      DatasetColumn(
        id: id ?? this.id,
        datasetTableId: datasetTableId ?? this.datasetTableId,
        originalName: originalName ?? this.originalName,
        dbName: dbName ?? this.dbName,
        declaredType: declaredType ?? this.declaredType,
        inferredType: inferredType ?? this.inferredType,
        nullable: nullable ?? this.nullable,
        statsJson: statsJson.present ? statsJson.value : this.statsJson,
      );
  DatasetColumn copyWithCompanion(DatasetColumnsCompanion data) {
    return DatasetColumn(
      id: data.id.present ? data.id.value : this.id,
      datasetTableId: data.datasetTableId.present
          ? data.datasetTableId.value
          : this.datasetTableId,
      originalName: data.originalName.present
          ? data.originalName.value
          : this.originalName,
      dbName: data.dbName.present ? data.dbName.value : this.dbName,
      declaredType: data.declaredType.present
          ? data.declaredType.value
          : this.declaredType,
      inferredType: data.inferredType.present
          ? data.inferredType.value
          : this.inferredType,
      nullable: data.nullable.present ? data.nullable.value : this.nullable,
      statsJson: data.statsJson.present ? data.statsJson.value : this.statsJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DatasetColumn(')
          ..write('id: $id, ')
          ..write('datasetTableId: $datasetTableId, ')
          ..write('originalName: $originalName, ')
          ..write('dbName: $dbName, ')
          ..write('declaredType: $declaredType, ')
          ..write('inferredType: $inferredType, ')
          ..write('nullable: $nullable, ')
          ..write('statsJson: $statsJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, datasetTableId, originalName, dbName,
      declaredType, inferredType, nullable, statsJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DatasetColumn &&
          other.id == this.id &&
          other.datasetTableId == this.datasetTableId &&
          other.originalName == this.originalName &&
          other.dbName == this.dbName &&
          other.declaredType == this.declaredType &&
          other.inferredType == this.inferredType &&
          other.nullable == this.nullable &&
          other.statsJson == this.statsJson);
}

class DatasetColumnsCompanion extends UpdateCompanion<DatasetColumn> {
  final Value<int> id;
  final Value<int> datasetTableId;
  final Value<String> originalName;
  final Value<String> dbName;
  final Value<String> declaredType;
  final Value<String> inferredType;
  final Value<bool> nullable;
  final Value<String?> statsJson;
  const DatasetColumnsCompanion({
    this.id = const Value.absent(),
    this.datasetTableId = const Value.absent(),
    this.originalName = const Value.absent(),
    this.dbName = const Value.absent(),
    this.declaredType = const Value.absent(),
    this.inferredType = const Value.absent(),
    this.nullable = const Value.absent(),
    this.statsJson = const Value.absent(),
  });
  DatasetColumnsCompanion.insert({
    this.id = const Value.absent(),
    required int datasetTableId,
    required String originalName,
    required String dbName,
    required String declaredType,
    required String inferredType,
    required bool nullable,
    this.statsJson = const Value.absent(),
  })  : datasetTableId = Value(datasetTableId),
        originalName = Value(originalName),
        dbName = Value(dbName),
        declaredType = Value(declaredType),
        inferredType = Value(inferredType),
        nullable = Value(nullable);
  static Insertable<DatasetColumn> custom({
    Expression<int>? id,
    Expression<int>? datasetTableId,
    Expression<String>? originalName,
    Expression<String>? dbName,
    Expression<String>? declaredType,
    Expression<String>? inferredType,
    Expression<bool>? nullable,
    Expression<String>? statsJson,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (datasetTableId != null) 'dataset_table_id': datasetTableId,
      if (originalName != null) 'original_name': originalName,
      if (dbName != null) 'db_name': dbName,
      if (declaredType != null) 'declared_type': declaredType,
      if (inferredType != null) 'inferred_type': inferredType,
      if (nullable != null) 'nullable': nullable,
      if (statsJson != null) 'stats_json': statsJson,
    });
  }

  DatasetColumnsCompanion copyWith(
      {Value<int>? id,
      Value<int>? datasetTableId,
      Value<String>? originalName,
      Value<String>? dbName,
      Value<String>? declaredType,
      Value<String>? inferredType,
      Value<bool>? nullable,
      Value<String?>? statsJson}) {
    return DatasetColumnsCompanion(
      id: id ?? this.id,
      datasetTableId: datasetTableId ?? this.datasetTableId,
      originalName: originalName ?? this.originalName,
      dbName: dbName ?? this.dbName,
      declaredType: declaredType ?? this.declaredType,
      inferredType: inferredType ?? this.inferredType,
      nullable: nullable ?? this.nullable,
      statsJson: statsJson ?? this.statsJson,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (datasetTableId.present) {
      map['dataset_table_id'] = Variable<int>(datasetTableId.value);
    }
    if (originalName.present) {
      map['original_name'] = Variable<String>(originalName.value);
    }
    if (dbName.present) {
      map['db_name'] = Variable<String>(dbName.value);
    }
    if (declaredType.present) {
      map['declared_type'] = Variable<String>(declaredType.value);
    }
    if (inferredType.present) {
      map['inferred_type'] = Variable<String>(inferredType.value);
    }
    if (nullable.present) {
      map['nullable'] = Variable<bool>(nullable.value);
    }
    if (statsJson.present) {
      map['stats_json'] = Variable<String>(statsJson.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DatasetColumnsCompanion(')
          ..write('id: $id, ')
          ..write('datasetTableId: $datasetTableId, ')
          ..write('originalName: $originalName, ')
          ..write('dbName: $dbName, ')
          ..write('declaredType: $declaredType, ')
          ..write('inferredType: $inferredType, ')
          ..write('nullable: $nullable, ')
          ..write('statsJson: $statsJson')
          ..write(')'))
        .toString();
  }
}

class $DatasetFilesTable extends DatasetFiles
    with TableInfo<$DatasetFilesTable, DatasetFile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DatasetFilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _datasetIdMeta =
      const VerificationMeta('datasetId');
  @override
  late final GeneratedColumn<int> datasetId = GeneratedColumn<int>(
      'dataset_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'UNIQUE REFERENCES datasets (id)'));
  static const VerificationMeta _storageModeMeta =
      const VerificationMeta('storageMode');
  @override
  late final GeneratedColumn<String> storageMode = GeneratedColumn<String>(
      'storage_mode', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _originalPathMeta =
      const VerificationMeta('originalPath');
  @override
  late final GeneratedColumn<String> originalPath = GeneratedColumn<String>(
      'original_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _storedPathMeta =
      const VerificationMeta('storedPath');
  @override
  late final GeneratedColumn<String> storedPath = GeneratedColumn<String>(
      'stored_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _importedAtMeta =
      const VerificationMeta('importedAt');
  @override
  late final GeneratedColumn<DateTime> importedAt = GeneratedColumn<DateTime>(
      'imported_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _fileSizeMeta =
      const VerificationMeta('fileSize');
  @override
  late final GeneratedColumn<int> fileSize = GeneratedColumn<int>(
      'file_size', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        datasetId,
        storageMode,
        originalPath,
        storedPath,
        importedAt,
        fileSize
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dataset_files';
  @override
  VerificationContext validateIntegrity(Insertable<DatasetFile> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('dataset_id')) {
      context.handle(_datasetIdMeta,
          datasetId.isAcceptableOrUnknown(data['dataset_id']!, _datasetIdMeta));
    } else if (isInserting) {
      context.missing(_datasetIdMeta);
    }
    if (data.containsKey('storage_mode')) {
      context.handle(
          _storageModeMeta,
          storageMode.isAcceptableOrUnknown(
              data['storage_mode']!, _storageModeMeta));
    } else if (isInserting) {
      context.missing(_storageModeMeta);
    }
    if (data.containsKey('original_path')) {
      context.handle(
          _originalPathMeta,
          originalPath.isAcceptableOrUnknown(
              data['original_path']!, _originalPathMeta));
    }
    if (data.containsKey('stored_path')) {
      context.handle(
          _storedPathMeta,
          storedPath.isAcceptableOrUnknown(
              data['stored_path']!, _storedPathMeta));
    }
    if (data.containsKey('imported_at')) {
      context.handle(
          _importedAtMeta,
          importedAt.isAcceptableOrUnknown(
              data['imported_at']!, _importedAtMeta));
    } else if (isInserting) {
      context.missing(_importedAtMeta);
    }
    if (data.containsKey('file_size')) {
      context.handle(_fileSizeMeta,
          fileSize.isAcceptableOrUnknown(data['file_size']!, _fileSizeMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DatasetFile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DatasetFile(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      datasetId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}dataset_id'])!,
      storageMode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}storage_mode'])!,
      originalPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}original_path']),
      storedPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}stored_path']),
      importedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}imported_at'])!,
      fileSize: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}file_size']),
    );
  }

  @override
  $DatasetFilesTable createAlias(String alias) {
    return $DatasetFilesTable(attachedDatabase, alias);
  }
}

class DatasetFile extends DataClass implements Insertable<DatasetFile> {
  /// Primary key
  final int id;

  /// Foreign key to datasets
  final int datasetId;

  /// Storage mode:
  /// path, pathAndCopy, webTemporary, webPersisted
  final String storageMode;

  /// Original file path (nullable if not available, e.g. web)
  final String? originalPath;

  /// Stored file path inside app storage (nullable if not copied)
  final String? storedPath;

  /// Timestamp of last import
  final DateTime importedAt;

  /// File size in bytes (optional)
  final int? fileSize;
  const DatasetFile(
      {required this.id,
      required this.datasetId,
      required this.storageMode,
      this.originalPath,
      this.storedPath,
      required this.importedAt,
      this.fileSize});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['dataset_id'] = Variable<int>(datasetId);
    map['storage_mode'] = Variable<String>(storageMode);
    if (!nullToAbsent || originalPath != null) {
      map['original_path'] = Variable<String>(originalPath);
    }
    if (!nullToAbsent || storedPath != null) {
      map['stored_path'] = Variable<String>(storedPath);
    }
    map['imported_at'] = Variable<DateTime>(importedAt);
    if (!nullToAbsent || fileSize != null) {
      map['file_size'] = Variable<int>(fileSize);
    }
    return map;
  }

  DatasetFilesCompanion toCompanion(bool nullToAbsent) {
    return DatasetFilesCompanion(
      id: Value(id),
      datasetId: Value(datasetId),
      storageMode: Value(storageMode),
      originalPath: originalPath == null && nullToAbsent
          ? const Value.absent()
          : Value(originalPath),
      storedPath: storedPath == null && nullToAbsent
          ? const Value.absent()
          : Value(storedPath),
      importedAt: Value(importedAt),
      fileSize: fileSize == null && nullToAbsent
          ? const Value.absent()
          : Value(fileSize),
    );
  }

  factory DatasetFile.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DatasetFile(
      id: serializer.fromJson<int>(json['id']),
      datasetId: serializer.fromJson<int>(json['datasetId']),
      storageMode: serializer.fromJson<String>(json['storageMode']),
      originalPath: serializer.fromJson<String?>(json['originalPath']),
      storedPath: serializer.fromJson<String?>(json['storedPath']),
      importedAt: serializer.fromJson<DateTime>(json['importedAt']),
      fileSize: serializer.fromJson<int?>(json['fileSize']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'datasetId': serializer.toJson<int>(datasetId),
      'storageMode': serializer.toJson<String>(storageMode),
      'originalPath': serializer.toJson<String?>(originalPath),
      'storedPath': serializer.toJson<String?>(storedPath),
      'importedAt': serializer.toJson<DateTime>(importedAt),
      'fileSize': serializer.toJson<int?>(fileSize),
    };
  }

  DatasetFile copyWith(
          {int? id,
          int? datasetId,
          String? storageMode,
          Value<String?> originalPath = const Value.absent(),
          Value<String?> storedPath = const Value.absent(),
          DateTime? importedAt,
          Value<int?> fileSize = const Value.absent()}) =>
      DatasetFile(
        id: id ?? this.id,
        datasetId: datasetId ?? this.datasetId,
        storageMode: storageMode ?? this.storageMode,
        originalPath:
            originalPath.present ? originalPath.value : this.originalPath,
        storedPath: storedPath.present ? storedPath.value : this.storedPath,
        importedAt: importedAt ?? this.importedAt,
        fileSize: fileSize.present ? fileSize.value : this.fileSize,
      );
  DatasetFile copyWithCompanion(DatasetFilesCompanion data) {
    return DatasetFile(
      id: data.id.present ? data.id.value : this.id,
      datasetId: data.datasetId.present ? data.datasetId.value : this.datasetId,
      storageMode:
          data.storageMode.present ? data.storageMode.value : this.storageMode,
      originalPath: data.originalPath.present
          ? data.originalPath.value
          : this.originalPath,
      storedPath:
          data.storedPath.present ? data.storedPath.value : this.storedPath,
      importedAt:
          data.importedAt.present ? data.importedAt.value : this.importedAt,
      fileSize: data.fileSize.present ? data.fileSize.value : this.fileSize,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DatasetFile(')
          ..write('id: $id, ')
          ..write('datasetId: $datasetId, ')
          ..write('storageMode: $storageMode, ')
          ..write('originalPath: $originalPath, ')
          ..write('storedPath: $storedPath, ')
          ..write('importedAt: $importedAt, ')
          ..write('fileSize: $fileSize')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, datasetId, storageMode, originalPath,
      storedPath, importedAt, fileSize);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DatasetFile &&
          other.id == this.id &&
          other.datasetId == this.datasetId &&
          other.storageMode == this.storageMode &&
          other.originalPath == this.originalPath &&
          other.storedPath == this.storedPath &&
          other.importedAt == this.importedAt &&
          other.fileSize == this.fileSize);
}

class DatasetFilesCompanion extends UpdateCompanion<DatasetFile> {
  final Value<int> id;
  final Value<int> datasetId;
  final Value<String> storageMode;
  final Value<String?> originalPath;
  final Value<String?> storedPath;
  final Value<DateTime> importedAt;
  final Value<int?> fileSize;
  const DatasetFilesCompanion({
    this.id = const Value.absent(),
    this.datasetId = const Value.absent(),
    this.storageMode = const Value.absent(),
    this.originalPath = const Value.absent(),
    this.storedPath = const Value.absent(),
    this.importedAt = const Value.absent(),
    this.fileSize = const Value.absent(),
  });
  DatasetFilesCompanion.insert({
    this.id = const Value.absent(),
    required int datasetId,
    required String storageMode,
    this.originalPath = const Value.absent(),
    this.storedPath = const Value.absent(),
    required DateTime importedAt,
    this.fileSize = const Value.absent(),
  })  : datasetId = Value(datasetId),
        storageMode = Value(storageMode),
        importedAt = Value(importedAt);
  static Insertable<DatasetFile> custom({
    Expression<int>? id,
    Expression<int>? datasetId,
    Expression<String>? storageMode,
    Expression<String>? originalPath,
    Expression<String>? storedPath,
    Expression<DateTime>? importedAt,
    Expression<int>? fileSize,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (datasetId != null) 'dataset_id': datasetId,
      if (storageMode != null) 'storage_mode': storageMode,
      if (originalPath != null) 'original_path': originalPath,
      if (storedPath != null) 'stored_path': storedPath,
      if (importedAt != null) 'imported_at': importedAt,
      if (fileSize != null) 'file_size': fileSize,
    });
  }

  DatasetFilesCompanion copyWith(
      {Value<int>? id,
      Value<int>? datasetId,
      Value<String>? storageMode,
      Value<String?>? originalPath,
      Value<String?>? storedPath,
      Value<DateTime>? importedAt,
      Value<int?>? fileSize}) {
    return DatasetFilesCompanion(
      id: id ?? this.id,
      datasetId: datasetId ?? this.datasetId,
      storageMode: storageMode ?? this.storageMode,
      originalPath: originalPath ?? this.originalPath,
      storedPath: storedPath ?? this.storedPath,
      importedAt: importedAt ?? this.importedAt,
      fileSize: fileSize ?? this.fileSize,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (datasetId.present) {
      map['dataset_id'] = Variable<int>(datasetId.value);
    }
    if (storageMode.present) {
      map['storage_mode'] = Variable<String>(storageMode.value);
    }
    if (originalPath.present) {
      map['original_path'] = Variable<String>(originalPath.value);
    }
    if (storedPath.present) {
      map['stored_path'] = Variable<String>(storedPath.value);
    }
    if (importedAt.present) {
      map['imported_at'] = Variable<DateTime>(importedAt.value);
    }
    if (fileSize.present) {
      map['file_size'] = Variable<int>(fileSize.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DatasetFilesCompanion(')
          ..write('id: $id, ')
          ..write('datasetId: $datasetId, ')
          ..write('storageMode: $storageMode, ')
          ..write('originalPath: $originalPath, ')
          ..write('storedPath: $storedPath, ')
          ..write('importedAt: $importedAt, ')
          ..write('fileSize: $fileSize')
          ..write(')'))
        .toString();
  }
}

class $SavedMultiSheetQueriesTable extends SavedMultiSheetQueries
    with TableInfo<$SavedMultiSheetQueriesTable, SavedMultiSheetQuery> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SavedMultiSheetQueriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _datasetIdMeta =
      const VerificationMeta('datasetId');
  @override
  late final GeneratedColumn<int> datasetId = GeneratedColumn<int>(
      'dataset_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES datasets (id)'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _baseTableIdMeta =
      const VerificationMeta('baseTableId');
  @override
  late final GeneratedColumn<int> baseTableId = GeneratedColumn<int>(
      'base_table_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _specificationJsonMeta =
      const VerificationMeta('specificationJson');
  @override
  late final GeneratedColumn<String> specificationJson =
      GeneratedColumn<String>('specification_json', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _schemaVersionMeta =
      const VerificationMeta('schemaVersion');
  @override
  late final GeneratedColumn<int> schemaVersion = GeneratedColumn<int>(
      'schema_version', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        datasetId,
        name,
        baseTableId,
        specificationJson,
        schemaVersion,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'saved_multi_sheet_queries';
  @override
  VerificationContext validateIntegrity(
      Insertable<SavedMultiSheetQuery> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('dataset_id')) {
      context.handle(_datasetIdMeta,
          datasetId.isAcceptableOrUnknown(data['dataset_id']!, _datasetIdMeta));
    } else if (isInserting) {
      context.missing(_datasetIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('base_table_id')) {
      context.handle(
          _baseTableIdMeta,
          baseTableId.isAcceptableOrUnknown(
              data['base_table_id']!, _baseTableIdMeta));
    }
    if (data.containsKey('specification_json')) {
      context.handle(
          _specificationJsonMeta,
          specificationJson.isAcceptableOrUnknown(
              data['specification_json']!, _specificationJsonMeta));
    } else if (isInserting) {
      context.missing(_specificationJsonMeta);
    }
    if (data.containsKey('schema_version')) {
      context.handle(
          _schemaVersionMeta,
          schemaVersion.isAcceptableOrUnknown(
              data['schema_version']!, _schemaVersionMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SavedMultiSheetQuery map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SavedMultiSheetQuery(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      datasetId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}dataset_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      baseTableId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}base_table_id']),
      specificationJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}specification_json'])!,
      schemaVersion: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}schema_version'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $SavedMultiSheetQueriesTable createAlias(String alias) {
    return $SavedMultiSheetQueriesTable(attachedDatabase, alias);
  }
}

class SavedMultiSheetQuery extends DataClass
    implements Insertable<SavedMultiSheetQuery> {
  /// Primary key.
  final int id;

  /// Foreign key to the owning dataset. Rows are removed together with the
  /// dataset at the application layer (see DeleteDatasetUseCase).
  final int datasetId;

  /// User-facing name of the saved configuration.
  final String name;

  /// Base table (FROM root) of the join tree, when set.
  final int? baseTableId;

  /// Serialized `MultiSheetQuerySpec`.
  final String specificationJson;

  /// Version of the specification JSON shape.
  final int schemaVersion;

  /// Unix timestamp (milliseconds) when created.
  final int createdAt;

  /// Unix timestamp (milliseconds) when last updated.
  final int updatedAt;
  const SavedMultiSheetQuery(
      {required this.id,
      required this.datasetId,
      required this.name,
      this.baseTableId,
      required this.specificationJson,
      required this.schemaVersion,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['dataset_id'] = Variable<int>(datasetId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || baseTableId != null) {
      map['base_table_id'] = Variable<int>(baseTableId);
    }
    map['specification_json'] = Variable<String>(specificationJson);
    map['schema_version'] = Variable<int>(schemaVersion);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  SavedMultiSheetQueriesCompanion toCompanion(bool nullToAbsent) {
    return SavedMultiSheetQueriesCompanion(
      id: Value(id),
      datasetId: Value(datasetId),
      name: Value(name),
      baseTableId: baseTableId == null && nullToAbsent
          ? const Value.absent()
          : Value(baseTableId),
      specificationJson: Value(specificationJson),
      schemaVersion: Value(schemaVersion),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory SavedMultiSheetQuery.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SavedMultiSheetQuery(
      id: serializer.fromJson<int>(json['id']),
      datasetId: serializer.fromJson<int>(json['datasetId']),
      name: serializer.fromJson<String>(json['name']),
      baseTableId: serializer.fromJson<int?>(json['baseTableId']),
      specificationJson: serializer.fromJson<String>(json['specificationJson']),
      schemaVersion: serializer.fromJson<int>(json['schemaVersion']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'datasetId': serializer.toJson<int>(datasetId),
      'name': serializer.toJson<String>(name),
      'baseTableId': serializer.toJson<int?>(baseTableId),
      'specificationJson': serializer.toJson<String>(specificationJson),
      'schemaVersion': serializer.toJson<int>(schemaVersion),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  SavedMultiSheetQuery copyWith(
          {int? id,
          int? datasetId,
          String? name,
          Value<int?> baseTableId = const Value.absent(),
          String? specificationJson,
          int? schemaVersion,
          int? createdAt,
          int? updatedAt}) =>
      SavedMultiSheetQuery(
        id: id ?? this.id,
        datasetId: datasetId ?? this.datasetId,
        name: name ?? this.name,
        baseTableId: baseTableId.present ? baseTableId.value : this.baseTableId,
        specificationJson: specificationJson ?? this.specificationJson,
        schemaVersion: schemaVersion ?? this.schemaVersion,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  SavedMultiSheetQuery copyWithCompanion(SavedMultiSheetQueriesCompanion data) {
    return SavedMultiSheetQuery(
      id: data.id.present ? data.id.value : this.id,
      datasetId: data.datasetId.present ? data.datasetId.value : this.datasetId,
      name: data.name.present ? data.name.value : this.name,
      baseTableId:
          data.baseTableId.present ? data.baseTableId.value : this.baseTableId,
      specificationJson: data.specificationJson.present
          ? data.specificationJson.value
          : this.specificationJson,
      schemaVersion: data.schemaVersion.present
          ? data.schemaVersion.value
          : this.schemaVersion,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SavedMultiSheetQuery(')
          ..write('id: $id, ')
          ..write('datasetId: $datasetId, ')
          ..write('name: $name, ')
          ..write('baseTableId: $baseTableId, ')
          ..write('specificationJson: $specificationJson, ')
          ..write('schemaVersion: $schemaVersion, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, datasetId, name, baseTableId,
      specificationJson, schemaVersion, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SavedMultiSheetQuery &&
          other.id == this.id &&
          other.datasetId == this.datasetId &&
          other.name == this.name &&
          other.baseTableId == this.baseTableId &&
          other.specificationJson == this.specificationJson &&
          other.schemaVersion == this.schemaVersion &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SavedMultiSheetQueriesCompanion
    extends UpdateCompanion<SavedMultiSheetQuery> {
  final Value<int> id;
  final Value<int> datasetId;
  final Value<String> name;
  final Value<int?> baseTableId;
  final Value<String> specificationJson;
  final Value<int> schemaVersion;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  const SavedMultiSheetQueriesCompanion({
    this.id = const Value.absent(),
    this.datasetId = const Value.absent(),
    this.name = const Value.absent(),
    this.baseTableId = const Value.absent(),
    this.specificationJson = const Value.absent(),
    this.schemaVersion = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  SavedMultiSheetQueriesCompanion.insert({
    this.id = const Value.absent(),
    required int datasetId,
    required String name,
    this.baseTableId = const Value.absent(),
    required String specificationJson,
    this.schemaVersion = const Value.absent(),
    required int createdAt,
    required int updatedAt,
  })  : datasetId = Value(datasetId),
        name = Value(name),
        specificationJson = Value(specificationJson),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<SavedMultiSheetQuery> custom({
    Expression<int>? id,
    Expression<int>? datasetId,
    Expression<String>? name,
    Expression<int>? baseTableId,
    Expression<String>? specificationJson,
    Expression<int>? schemaVersion,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (datasetId != null) 'dataset_id': datasetId,
      if (name != null) 'name': name,
      if (baseTableId != null) 'base_table_id': baseTableId,
      if (specificationJson != null) 'specification_json': specificationJson,
      if (schemaVersion != null) 'schema_version': schemaVersion,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  SavedMultiSheetQueriesCompanion copyWith(
      {Value<int>? id,
      Value<int>? datasetId,
      Value<String>? name,
      Value<int?>? baseTableId,
      Value<String>? specificationJson,
      Value<int>? schemaVersion,
      Value<int>? createdAt,
      Value<int>? updatedAt}) {
    return SavedMultiSheetQueriesCompanion(
      id: id ?? this.id,
      datasetId: datasetId ?? this.datasetId,
      name: name ?? this.name,
      baseTableId: baseTableId ?? this.baseTableId,
      specificationJson: specificationJson ?? this.specificationJson,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (datasetId.present) {
      map['dataset_id'] = Variable<int>(datasetId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (baseTableId.present) {
      map['base_table_id'] = Variable<int>(baseTableId.value);
    }
    if (specificationJson.present) {
      map['specification_json'] = Variable<String>(specificationJson.value);
    }
    if (schemaVersion.present) {
      map['schema_version'] = Variable<int>(schemaVersion.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SavedMultiSheetQueriesCompanion(')
          ..write('id: $id, ')
          ..write('datasetId: $datasetId, ')
          ..write('name: $name, ')
          ..write('baseTableId: $baseTableId, ')
          ..write('specificationJson: $specificationJson, ')
          ..write('schemaVersion: $schemaVersion, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $DatasetRelationshipsTable extends DatasetRelationships
    with TableInfo<$DatasetRelationshipsTable, DatasetRelationship> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DatasetRelationshipsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _datasetIdMeta =
      const VerificationMeta('datasetId');
  @override
  late final GeneratedColumn<int> datasetId = GeneratedColumn<int>(
      'dataset_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES datasets (id)'));
  static const VerificationMeta _endpointATableIdMeta =
      const VerificationMeta('endpointATableId');
  @override
  late final GeneratedColumn<int> endpointATableId = GeneratedColumn<int>(
      'endpoint_a_table_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _endpointAColumnDbNameMeta =
      const VerificationMeta('endpointAColumnDbName');
  @override
  late final GeneratedColumn<String> endpointAColumnDbName =
      GeneratedColumn<String>('endpoint_a_column_db_name', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _endpointBTableIdMeta =
      const VerificationMeta('endpointBTableId');
  @override
  late final GeneratedColumn<int> endpointBTableId = GeneratedColumn<int>(
      'endpoint_b_table_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _endpointBColumnDbNameMeta =
      const VerificationMeta('endpointBColumnDbName');
  @override
  late final GeneratedColumn<String> endpointBColumnDbName =
      GeneratedColumn<String>('endpoint_b_column_db_name', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _cardinalityMeta =
      const VerificationMeta('cardinality');
  @override
  late final GeneratedColumn<String> cardinality = GeneratedColumn<String>(
      'cardinality', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('unknown'));
  static const VerificationMeta _relationshipConfidenceMeta =
      const VerificationMeta('relationshipConfidence');
  @override
  late final GeneratedColumn<double> relationshipConfidence =
      GeneratedColumn<double>('relationship_confidence', aliasedName, false,
          type: DriftSqlType.double,
          requiredDuringInsert: false,
          defaultValue: const Constant(0));
  static const VerificationMeta _cardinalityConfidenceMeta =
      const VerificationMeta('cardinalityConfidence');
  @override
  late final GeneratedColumn<double> cardinalityConfidence =
      GeneratedColumn<double>('cardinality_confidence', aliasedName, false,
          type: DriftSqlType.double,
          requiredDuringInsert: false,
          defaultValue: const Constant(0));
  static const VerificationMeta _sampleSizeMeta =
      const VerificationMeta('sampleSize');
  @override
  late final GeneratedColumn<int> sampleSize = GeneratedColumn<int>(
      'sample_size', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _originMeta = const VerificationMeta('origin');
  @override
  late final GeneratedColumn<String> origin = GeneratedColumn<String>(
      'origin', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('suggested'));
  static const VerificationMeta _confirmedAtMeta =
      const VerificationMeta('confirmedAt');
  @override
  late final GeneratedColumn<int> confirmedAt = GeneratedColumn<int>(
      'confirmed_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        datasetId,
        endpointATableId,
        endpointAColumnDbName,
        endpointBTableId,
        endpointBColumnDbName,
        cardinality,
        relationshipConfidence,
        cardinalityConfidence,
        sampleSize,
        origin,
        confirmedAt,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dataset_relationships';
  @override
  VerificationContext validateIntegrity(
      Insertable<DatasetRelationship> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('dataset_id')) {
      context.handle(_datasetIdMeta,
          datasetId.isAcceptableOrUnknown(data['dataset_id']!, _datasetIdMeta));
    } else if (isInserting) {
      context.missing(_datasetIdMeta);
    }
    if (data.containsKey('endpoint_a_table_id')) {
      context.handle(
          _endpointATableIdMeta,
          endpointATableId.isAcceptableOrUnknown(
              data['endpoint_a_table_id']!, _endpointATableIdMeta));
    } else if (isInserting) {
      context.missing(_endpointATableIdMeta);
    }
    if (data.containsKey('endpoint_a_column_db_name')) {
      context.handle(
          _endpointAColumnDbNameMeta,
          endpointAColumnDbName.isAcceptableOrUnknown(
              data['endpoint_a_column_db_name']!, _endpointAColumnDbNameMeta));
    } else if (isInserting) {
      context.missing(_endpointAColumnDbNameMeta);
    }
    if (data.containsKey('endpoint_b_table_id')) {
      context.handle(
          _endpointBTableIdMeta,
          endpointBTableId.isAcceptableOrUnknown(
              data['endpoint_b_table_id']!, _endpointBTableIdMeta));
    } else if (isInserting) {
      context.missing(_endpointBTableIdMeta);
    }
    if (data.containsKey('endpoint_b_column_db_name')) {
      context.handle(
          _endpointBColumnDbNameMeta,
          endpointBColumnDbName.isAcceptableOrUnknown(
              data['endpoint_b_column_db_name']!, _endpointBColumnDbNameMeta));
    } else if (isInserting) {
      context.missing(_endpointBColumnDbNameMeta);
    }
    if (data.containsKey('cardinality')) {
      context.handle(
          _cardinalityMeta,
          cardinality.isAcceptableOrUnknown(
              data['cardinality']!, _cardinalityMeta));
    }
    if (data.containsKey('relationship_confidence')) {
      context.handle(
          _relationshipConfidenceMeta,
          relationshipConfidence.isAcceptableOrUnknown(
              data['relationship_confidence']!, _relationshipConfidenceMeta));
    }
    if (data.containsKey('cardinality_confidence')) {
      context.handle(
          _cardinalityConfidenceMeta,
          cardinalityConfidence.isAcceptableOrUnknown(
              data['cardinality_confidence']!, _cardinalityConfidenceMeta));
    }
    if (data.containsKey('sample_size')) {
      context.handle(
          _sampleSizeMeta,
          sampleSize.isAcceptableOrUnknown(
              data['sample_size']!, _sampleSizeMeta));
    }
    if (data.containsKey('origin')) {
      context.handle(_originMeta,
          origin.isAcceptableOrUnknown(data['origin']!, _originMeta));
    }
    if (data.containsKey('confirmed_at')) {
      context.handle(
          _confirmedAtMeta,
          confirmedAt.isAcceptableOrUnknown(
              data['confirmed_at']!, _confirmedAtMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DatasetRelationship map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DatasetRelationship(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      datasetId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}dataset_id'])!,
      endpointATableId: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}endpoint_a_table_id'])!,
      endpointAColumnDbName: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}endpoint_a_column_db_name'])!,
      endpointBTableId: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}endpoint_b_table_id'])!,
      endpointBColumnDbName: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}endpoint_b_column_db_name'])!,
      cardinality: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cardinality'])!,
      relationshipConfidence: attachedDatabase.typeMapping.read(
          DriftSqlType.double,
          data['${effectivePrefix}relationship_confidence'])!,
      cardinalityConfidence: attachedDatabase.typeMapping.read(
          DriftSqlType.double,
          data['${effectivePrefix}cardinality_confidence'])!,
      sampleSize: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sample_size'])!,
      origin: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}origin'])!,
      confirmedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}confirmed_at']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $DatasetRelationshipsTable createAlias(String alias) {
    return $DatasetRelationshipsTable(attachedDatabase, alias);
  }
}

class DatasetRelationship extends DataClass
    implements Insertable<DatasetRelationship> {
  final int id;

  /// Owning dataset. Rows are removed with the dataset at the application layer.
  final int datasetId;
  final int endpointATableId;
  final String endpointAColumnDbName;
  final int endpointBTableId;
  final String endpointBColumnDbName;

  /// `JoinCardinality` name (oneToOne / oneToMany / manyToOne / manyToMany / unknown).
  final String cardinality;

  /// 0..1 confidence that this is a real relationship.
  final double relationshipConfidence;

  /// 0..1 confidence in the estimated cardinality specifically.
  final double cardinalityConfidence;

  /// Rows sampled per side when estimating (0 when not estimated from data).
  final int sampleSize;

  /// `RelationshipOrigin` name (suggested / userDefined).
  final String origin;

  /// Unix ms when the user confirmed the relationship (null = unconfirmed).
  final int? confirmedAt;
  final int createdAt;
  final int updatedAt;
  const DatasetRelationship(
      {required this.id,
      required this.datasetId,
      required this.endpointATableId,
      required this.endpointAColumnDbName,
      required this.endpointBTableId,
      required this.endpointBColumnDbName,
      required this.cardinality,
      required this.relationshipConfidence,
      required this.cardinalityConfidence,
      required this.sampleSize,
      required this.origin,
      this.confirmedAt,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['dataset_id'] = Variable<int>(datasetId);
    map['endpoint_a_table_id'] = Variable<int>(endpointATableId);
    map['endpoint_a_column_db_name'] = Variable<String>(endpointAColumnDbName);
    map['endpoint_b_table_id'] = Variable<int>(endpointBTableId);
    map['endpoint_b_column_db_name'] = Variable<String>(endpointBColumnDbName);
    map['cardinality'] = Variable<String>(cardinality);
    map['relationship_confidence'] = Variable<double>(relationshipConfidence);
    map['cardinality_confidence'] = Variable<double>(cardinalityConfidence);
    map['sample_size'] = Variable<int>(sampleSize);
    map['origin'] = Variable<String>(origin);
    if (!nullToAbsent || confirmedAt != null) {
      map['confirmed_at'] = Variable<int>(confirmedAt);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  DatasetRelationshipsCompanion toCompanion(bool nullToAbsent) {
    return DatasetRelationshipsCompanion(
      id: Value(id),
      datasetId: Value(datasetId),
      endpointATableId: Value(endpointATableId),
      endpointAColumnDbName: Value(endpointAColumnDbName),
      endpointBTableId: Value(endpointBTableId),
      endpointBColumnDbName: Value(endpointBColumnDbName),
      cardinality: Value(cardinality),
      relationshipConfidence: Value(relationshipConfidence),
      cardinalityConfidence: Value(cardinalityConfidence),
      sampleSize: Value(sampleSize),
      origin: Value(origin),
      confirmedAt: confirmedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(confirmedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory DatasetRelationship.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DatasetRelationship(
      id: serializer.fromJson<int>(json['id']),
      datasetId: serializer.fromJson<int>(json['datasetId']),
      endpointATableId: serializer.fromJson<int>(json['endpointATableId']),
      endpointAColumnDbName:
          serializer.fromJson<String>(json['endpointAColumnDbName']),
      endpointBTableId: serializer.fromJson<int>(json['endpointBTableId']),
      endpointBColumnDbName:
          serializer.fromJson<String>(json['endpointBColumnDbName']),
      cardinality: serializer.fromJson<String>(json['cardinality']),
      relationshipConfidence:
          serializer.fromJson<double>(json['relationshipConfidence']),
      cardinalityConfidence:
          serializer.fromJson<double>(json['cardinalityConfidence']),
      sampleSize: serializer.fromJson<int>(json['sampleSize']),
      origin: serializer.fromJson<String>(json['origin']),
      confirmedAt: serializer.fromJson<int?>(json['confirmedAt']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'datasetId': serializer.toJson<int>(datasetId),
      'endpointATableId': serializer.toJson<int>(endpointATableId),
      'endpointAColumnDbName': serializer.toJson<String>(endpointAColumnDbName),
      'endpointBTableId': serializer.toJson<int>(endpointBTableId),
      'endpointBColumnDbName': serializer.toJson<String>(endpointBColumnDbName),
      'cardinality': serializer.toJson<String>(cardinality),
      'relationshipConfidence':
          serializer.toJson<double>(relationshipConfidence),
      'cardinalityConfidence': serializer.toJson<double>(cardinalityConfidence),
      'sampleSize': serializer.toJson<int>(sampleSize),
      'origin': serializer.toJson<String>(origin),
      'confirmedAt': serializer.toJson<int?>(confirmedAt),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  DatasetRelationship copyWith(
          {int? id,
          int? datasetId,
          int? endpointATableId,
          String? endpointAColumnDbName,
          int? endpointBTableId,
          String? endpointBColumnDbName,
          String? cardinality,
          double? relationshipConfidence,
          double? cardinalityConfidence,
          int? sampleSize,
          String? origin,
          Value<int?> confirmedAt = const Value.absent(),
          int? createdAt,
          int? updatedAt}) =>
      DatasetRelationship(
        id: id ?? this.id,
        datasetId: datasetId ?? this.datasetId,
        endpointATableId: endpointATableId ?? this.endpointATableId,
        endpointAColumnDbName:
            endpointAColumnDbName ?? this.endpointAColumnDbName,
        endpointBTableId: endpointBTableId ?? this.endpointBTableId,
        endpointBColumnDbName:
            endpointBColumnDbName ?? this.endpointBColumnDbName,
        cardinality: cardinality ?? this.cardinality,
        relationshipConfidence:
            relationshipConfidence ?? this.relationshipConfidence,
        cardinalityConfidence:
            cardinalityConfidence ?? this.cardinalityConfidence,
        sampleSize: sampleSize ?? this.sampleSize,
        origin: origin ?? this.origin,
        confirmedAt: confirmedAt.present ? confirmedAt.value : this.confirmedAt,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  DatasetRelationship copyWithCompanion(DatasetRelationshipsCompanion data) {
    return DatasetRelationship(
      id: data.id.present ? data.id.value : this.id,
      datasetId: data.datasetId.present ? data.datasetId.value : this.datasetId,
      endpointATableId: data.endpointATableId.present
          ? data.endpointATableId.value
          : this.endpointATableId,
      endpointAColumnDbName: data.endpointAColumnDbName.present
          ? data.endpointAColumnDbName.value
          : this.endpointAColumnDbName,
      endpointBTableId: data.endpointBTableId.present
          ? data.endpointBTableId.value
          : this.endpointBTableId,
      endpointBColumnDbName: data.endpointBColumnDbName.present
          ? data.endpointBColumnDbName.value
          : this.endpointBColumnDbName,
      cardinality:
          data.cardinality.present ? data.cardinality.value : this.cardinality,
      relationshipConfidence: data.relationshipConfidence.present
          ? data.relationshipConfidence.value
          : this.relationshipConfidence,
      cardinalityConfidence: data.cardinalityConfidence.present
          ? data.cardinalityConfidence.value
          : this.cardinalityConfidence,
      sampleSize:
          data.sampleSize.present ? data.sampleSize.value : this.sampleSize,
      origin: data.origin.present ? data.origin.value : this.origin,
      confirmedAt:
          data.confirmedAt.present ? data.confirmedAt.value : this.confirmedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DatasetRelationship(')
          ..write('id: $id, ')
          ..write('datasetId: $datasetId, ')
          ..write('endpointATableId: $endpointATableId, ')
          ..write('endpointAColumnDbName: $endpointAColumnDbName, ')
          ..write('endpointBTableId: $endpointBTableId, ')
          ..write('endpointBColumnDbName: $endpointBColumnDbName, ')
          ..write('cardinality: $cardinality, ')
          ..write('relationshipConfidence: $relationshipConfidence, ')
          ..write('cardinalityConfidence: $cardinalityConfidence, ')
          ..write('sampleSize: $sampleSize, ')
          ..write('origin: $origin, ')
          ..write('confirmedAt: $confirmedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      datasetId,
      endpointATableId,
      endpointAColumnDbName,
      endpointBTableId,
      endpointBColumnDbName,
      cardinality,
      relationshipConfidence,
      cardinalityConfidence,
      sampleSize,
      origin,
      confirmedAt,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DatasetRelationship &&
          other.id == this.id &&
          other.datasetId == this.datasetId &&
          other.endpointATableId == this.endpointATableId &&
          other.endpointAColumnDbName == this.endpointAColumnDbName &&
          other.endpointBTableId == this.endpointBTableId &&
          other.endpointBColumnDbName == this.endpointBColumnDbName &&
          other.cardinality == this.cardinality &&
          other.relationshipConfidence == this.relationshipConfidence &&
          other.cardinalityConfidence == this.cardinalityConfidence &&
          other.sampleSize == this.sampleSize &&
          other.origin == this.origin &&
          other.confirmedAt == this.confirmedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class DatasetRelationshipsCompanion
    extends UpdateCompanion<DatasetRelationship> {
  final Value<int> id;
  final Value<int> datasetId;
  final Value<int> endpointATableId;
  final Value<String> endpointAColumnDbName;
  final Value<int> endpointBTableId;
  final Value<String> endpointBColumnDbName;
  final Value<String> cardinality;
  final Value<double> relationshipConfidence;
  final Value<double> cardinalityConfidence;
  final Value<int> sampleSize;
  final Value<String> origin;
  final Value<int?> confirmedAt;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  const DatasetRelationshipsCompanion({
    this.id = const Value.absent(),
    this.datasetId = const Value.absent(),
    this.endpointATableId = const Value.absent(),
    this.endpointAColumnDbName = const Value.absent(),
    this.endpointBTableId = const Value.absent(),
    this.endpointBColumnDbName = const Value.absent(),
    this.cardinality = const Value.absent(),
    this.relationshipConfidence = const Value.absent(),
    this.cardinalityConfidence = const Value.absent(),
    this.sampleSize = const Value.absent(),
    this.origin = const Value.absent(),
    this.confirmedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  DatasetRelationshipsCompanion.insert({
    this.id = const Value.absent(),
    required int datasetId,
    required int endpointATableId,
    required String endpointAColumnDbName,
    required int endpointBTableId,
    required String endpointBColumnDbName,
    this.cardinality = const Value.absent(),
    this.relationshipConfidence = const Value.absent(),
    this.cardinalityConfidence = const Value.absent(),
    this.sampleSize = const Value.absent(),
    this.origin = const Value.absent(),
    this.confirmedAt = const Value.absent(),
    required int createdAt,
    required int updatedAt,
  })  : datasetId = Value(datasetId),
        endpointATableId = Value(endpointATableId),
        endpointAColumnDbName = Value(endpointAColumnDbName),
        endpointBTableId = Value(endpointBTableId),
        endpointBColumnDbName = Value(endpointBColumnDbName),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<DatasetRelationship> custom({
    Expression<int>? id,
    Expression<int>? datasetId,
    Expression<int>? endpointATableId,
    Expression<String>? endpointAColumnDbName,
    Expression<int>? endpointBTableId,
    Expression<String>? endpointBColumnDbName,
    Expression<String>? cardinality,
    Expression<double>? relationshipConfidence,
    Expression<double>? cardinalityConfidence,
    Expression<int>? sampleSize,
    Expression<String>? origin,
    Expression<int>? confirmedAt,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (datasetId != null) 'dataset_id': datasetId,
      if (endpointATableId != null) 'endpoint_a_table_id': endpointATableId,
      if (endpointAColumnDbName != null)
        'endpoint_a_column_db_name': endpointAColumnDbName,
      if (endpointBTableId != null) 'endpoint_b_table_id': endpointBTableId,
      if (endpointBColumnDbName != null)
        'endpoint_b_column_db_name': endpointBColumnDbName,
      if (cardinality != null) 'cardinality': cardinality,
      if (relationshipConfidence != null)
        'relationship_confidence': relationshipConfidence,
      if (cardinalityConfidence != null)
        'cardinality_confidence': cardinalityConfidence,
      if (sampleSize != null) 'sample_size': sampleSize,
      if (origin != null) 'origin': origin,
      if (confirmedAt != null) 'confirmed_at': confirmedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  DatasetRelationshipsCompanion copyWith(
      {Value<int>? id,
      Value<int>? datasetId,
      Value<int>? endpointATableId,
      Value<String>? endpointAColumnDbName,
      Value<int>? endpointBTableId,
      Value<String>? endpointBColumnDbName,
      Value<String>? cardinality,
      Value<double>? relationshipConfidence,
      Value<double>? cardinalityConfidence,
      Value<int>? sampleSize,
      Value<String>? origin,
      Value<int?>? confirmedAt,
      Value<int>? createdAt,
      Value<int>? updatedAt}) {
    return DatasetRelationshipsCompanion(
      id: id ?? this.id,
      datasetId: datasetId ?? this.datasetId,
      endpointATableId: endpointATableId ?? this.endpointATableId,
      endpointAColumnDbName:
          endpointAColumnDbName ?? this.endpointAColumnDbName,
      endpointBTableId: endpointBTableId ?? this.endpointBTableId,
      endpointBColumnDbName:
          endpointBColumnDbName ?? this.endpointBColumnDbName,
      cardinality: cardinality ?? this.cardinality,
      relationshipConfidence:
          relationshipConfidence ?? this.relationshipConfidence,
      cardinalityConfidence:
          cardinalityConfidence ?? this.cardinalityConfidence,
      sampleSize: sampleSize ?? this.sampleSize,
      origin: origin ?? this.origin,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (datasetId.present) {
      map['dataset_id'] = Variable<int>(datasetId.value);
    }
    if (endpointATableId.present) {
      map['endpoint_a_table_id'] = Variable<int>(endpointATableId.value);
    }
    if (endpointAColumnDbName.present) {
      map['endpoint_a_column_db_name'] =
          Variable<String>(endpointAColumnDbName.value);
    }
    if (endpointBTableId.present) {
      map['endpoint_b_table_id'] = Variable<int>(endpointBTableId.value);
    }
    if (endpointBColumnDbName.present) {
      map['endpoint_b_column_db_name'] =
          Variable<String>(endpointBColumnDbName.value);
    }
    if (cardinality.present) {
      map['cardinality'] = Variable<String>(cardinality.value);
    }
    if (relationshipConfidence.present) {
      map['relationship_confidence'] =
          Variable<double>(relationshipConfidence.value);
    }
    if (cardinalityConfidence.present) {
      map['cardinality_confidence'] =
          Variable<double>(cardinalityConfidence.value);
    }
    if (sampleSize.present) {
      map['sample_size'] = Variable<int>(sampleSize.value);
    }
    if (origin.present) {
      map['origin'] = Variable<String>(origin.value);
    }
    if (confirmedAt.present) {
      map['confirmed_at'] = Variable<int>(confirmedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DatasetRelationshipsCompanion(')
          ..write('id: $id, ')
          ..write('datasetId: $datasetId, ')
          ..write('endpointATableId: $endpointATableId, ')
          ..write('endpointAColumnDbName: $endpointAColumnDbName, ')
          ..write('endpointBTableId: $endpointBTableId, ')
          ..write('endpointBColumnDbName: $endpointBColumnDbName, ')
          ..write('cardinality: $cardinality, ')
          ..write('relationshipConfidence: $relationshipConfidence, ')
          ..write('cardinalityConfidence: $cardinalityConfidence, ')
          ..write('sampleSize: $sampleSize, ')
          ..write('origin: $origin, ')
          ..write('confirmedAt: $confirmedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $DatasetsTable datasets = $DatasetsTable(this);
  late final $DatasetTablesTable datasetTables = $DatasetTablesTable(this);
  late final $DatasetColumnsTable datasetColumns = $DatasetColumnsTable(this);
  late final $DatasetFilesTable datasetFiles = $DatasetFilesTable(this);
  late final $SavedMultiSheetQueriesTable savedMultiSheetQueries =
      $SavedMultiSheetQueriesTable(this);
  late final $DatasetRelationshipsTable datasetRelationships =
      $DatasetRelationshipsTable(this);
  late final DatasetsDao datasetsDao = DatasetsDao(this as AppDatabase);
  late final DatasetTablesDao datasetTablesDao =
      DatasetTablesDao(this as AppDatabase);
  late final DatasetColumnsDao datasetColumnsDao =
      DatasetColumnsDao(this as AppDatabase);
  late final SavedMultiSheetQueriesDao savedMultiSheetQueriesDao =
      SavedMultiSheetQueriesDao(this as AppDatabase);
  late final DatasetRelationshipsDao datasetRelationshipsDao =
      DatasetRelationshipsDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        datasets,
        datasetTables,
        datasetColumns,
        datasetFiles,
        savedMultiSheetQueries,
        datasetRelationships
      ];
}

typedef $$DatasetsTableCreateCompanionBuilder = DatasetsCompanion Function({
  Value<int> id,
  required String name,
  required String sourceFileName,
  Value<String?> sourceFileHash,
  required int createdAt,
  Value<int?> lastOpenedAt,
  Value<String?> uiStateJson,
});
typedef $$DatasetsTableUpdateCompanionBuilder = DatasetsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String> sourceFileName,
  Value<String?> sourceFileHash,
  Value<int> createdAt,
  Value<int?> lastOpenedAt,
  Value<String?> uiStateJson,
});

final class $$DatasetsTableReferences
    extends BaseReferences<_$AppDatabase, $DatasetsTable, Dataset> {
  $$DatasetsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$DatasetTablesTable, List<DatasetTable>>
      _datasetTablesRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.datasetTables,
              aliasName: $_aliasNameGenerator(
                  db.datasets.id, db.datasetTables.datasetId));

  $$DatasetTablesTableProcessedTableManager get datasetTablesRefs {
    final manager = $$DatasetTablesTableTableManager($_db, $_db.datasetTables)
        .filter((f) => f.datasetId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_datasetTablesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$DatasetFilesTable, List<DatasetFile>>
      _datasetFilesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.datasetFiles,
          aliasName:
              $_aliasNameGenerator(db.datasets.id, db.datasetFiles.datasetId));

  $$DatasetFilesTableProcessedTableManager get datasetFilesRefs {
    final manager = $$DatasetFilesTableTableManager($_db, $_db.datasetFiles)
        .filter((f) => f.datasetId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_datasetFilesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$SavedMultiSheetQueriesTable,
      List<SavedMultiSheetQuery>> _savedMultiSheetQueriesRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.savedMultiSheetQueries,
          aliasName: $_aliasNameGenerator(
              db.datasets.id, db.savedMultiSheetQueries.datasetId));

  $$SavedMultiSheetQueriesTableProcessedTableManager
      get savedMultiSheetQueriesRefs {
    final manager = $$SavedMultiSheetQueriesTableTableManager(
            $_db, $_db.savedMultiSheetQueries)
        .filter((f) => f.datasetId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_savedMultiSheetQueriesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$DatasetRelationshipsTable,
      List<DatasetRelationship>> _datasetRelationshipsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.datasetRelationships,
          aliasName: $_aliasNameGenerator(
              db.datasets.id, db.datasetRelationships.datasetId));

  $$DatasetRelationshipsTableProcessedTableManager
      get datasetRelationshipsRefs {
    final manager =
        $$DatasetRelationshipsTableTableManager($_db, $_db.datasetRelationships)
            .filter((f) => f.datasetId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_datasetRelationshipsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$DatasetsTableFilterComposer
    extends Composer<_$AppDatabase, $DatasetsTable> {
  $$DatasetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sourceFileName => $composableBuilder(
      column: $table.sourceFileName,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sourceFileHash => $composableBuilder(
      column: $table.sourceFileHash,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lastOpenedAt => $composableBuilder(
      column: $table.lastOpenedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get uiStateJson => $composableBuilder(
      column: $table.uiStateJson, builder: (column) => ColumnFilters(column));

  Expression<bool> datasetTablesRefs(
      Expression<bool> Function($$DatasetTablesTableFilterComposer f) f) {
    final $$DatasetTablesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.datasetTables,
        getReferencedColumn: (t) => t.datasetId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DatasetTablesTableFilterComposer(
              $db: $db,
              $table: $db.datasetTables,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> datasetFilesRefs(
      Expression<bool> Function($$DatasetFilesTableFilterComposer f) f) {
    final $$DatasetFilesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.datasetFiles,
        getReferencedColumn: (t) => t.datasetId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DatasetFilesTableFilterComposer(
              $db: $db,
              $table: $db.datasetFiles,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> savedMultiSheetQueriesRefs(
      Expression<bool> Function($$SavedMultiSheetQueriesTableFilterComposer f)
          f) {
    final $$SavedMultiSheetQueriesTableFilterComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.savedMultiSheetQueries,
            getReferencedColumn: (t) => t.datasetId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$SavedMultiSheetQueriesTableFilterComposer(
                  $db: $db,
                  $table: $db.savedMultiSheetQueries,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<bool> datasetRelationshipsRefs(
      Expression<bool> Function($$DatasetRelationshipsTableFilterComposer f)
          f) {
    final $$DatasetRelationshipsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.datasetRelationships,
        getReferencedColumn: (t) => t.datasetId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DatasetRelationshipsTableFilterComposer(
              $db: $db,
              $table: $db.datasetRelationships,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$DatasetsTableOrderingComposer
    extends Composer<_$AppDatabase, $DatasetsTable> {
  $$DatasetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sourceFileName => $composableBuilder(
      column: $table.sourceFileName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sourceFileHash => $composableBuilder(
      column: $table.sourceFileHash,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lastOpenedAt => $composableBuilder(
      column: $table.lastOpenedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get uiStateJson => $composableBuilder(
      column: $table.uiStateJson, builder: (column) => ColumnOrderings(column));
}

class $$DatasetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DatasetsTable> {
  $$DatasetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get sourceFileName => $composableBuilder(
      column: $table.sourceFileName, builder: (column) => column);

  GeneratedColumn<String> get sourceFileHash => $composableBuilder(
      column: $table.sourceFileHash, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get lastOpenedAt => $composableBuilder(
      column: $table.lastOpenedAt, builder: (column) => column);

  GeneratedColumn<String> get uiStateJson => $composableBuilder(
      column: $table.uiStateJson, builder: (column) => column);

  Expression<T> datasetTablesRefs<T extends Object>(
      Expression<T> Function($$DatasetTablesTableAnnotationComposer a) f) {
    final $$DatasetTablesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.datasetTables,
        getReferencedColumn: (t) => t.datasetId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DatasetTablesTableAnnotationComposer(
              $db: $db,
              $table: $db.datasetTables,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> datasetFilesRefs<T extends Object>(
      Expression<T> Function($$DatasetFilesTableAnnotationComposer a) f) {
    final $$DatasetFilesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.datasetFiles,
        getReferencedColumn: (t) => t.datasetId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DatasetFilesTableAnnotationComposer(
              $db: $db,
              $table: $db.datasetFiles,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> savedMultiSheetQueriesRefs<T extends Object>(
      Expression<T> Function($$SavedMultiSheetQueriesTableAnnotationComposer a)
          f) {
    final $$SavedMultiSheetQueriesTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.savedMultiSheetQueries,
            getReferencedColumn: (t) => t.datasetId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$SavedMultiSheetQueriesTableAnnotationComposer(
                  $db: $db,
                  $table: $db.savedMultiSheetQueries,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<T> datasetRelationshipsRefs<T extends Object>(
      Expression<T> Function($$DatasetRelationshipsTableAnnotationComposer a)
          f) {
    final $$DatasetRelationshipsTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.datasetRelationships,
            getReferencedColumn: (t) => t.datasetId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$DatasetRelationshipsTableAnnotationComposer(
                  $db: $db,
                  $table: $db.datasetRelationships,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$DatasetsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DatasetsTable,
    Dataset,
    $$DatasetsTableFilterComposer,
    $$DatasetsTableOrderingComposer,
    $$DatasetsTableAnnotationComposer,
    $$DatasetsTableCreateCompanionBuilder,
    $$DatasetsTableUpdateCompanionBuilder,
    (Dataset, $$DatasetsTableReferences),
    Dataset,
    PrefetchHooks Function(
        {bool datasetTablesRefs,
        bool datasetFilesRefs,
        bool savedMultiSheetQueriesRefs,
        bool datasetRelationshipsRefs})> {
  $$DatasetsTableTableManager(_$AppDatabase db, $DatasetsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DatasetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DatasetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DatasetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> sourceFileName = const Value.absent(),
            Value<String?> sourceFileHash = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int?> lastOpenedAt = const Value.absent(),
            Value<String?> uiStateJson = const Value.absent(),
          }) =>
              DatasetsCompanion(
            id: id,
            name: name,
            sourceFileName: sourceFileName,
            sourceFileHash: sourceFileHash,
            createdAt: createdAt,
            lastOpenedAt: lastOpenedAt,
            uiStateJson: uiStateJson,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            required String sourceFileName,
            Value<String?> sourceFileHash = const Value.absent(),
            required int createdAt,
            Value<int?> lastOpenedAt = const Value.absent(),
            Value<String?> uiStateJson = const Value.absent(),
          }) =>
              DatasetsCompanion.insert(
            id: id,
            name: name,
            sourceFileName: sourceFileName,
            sourceFileHash: sourceFileHash,
            createdAt: createdAt,
            lastOpenedAt: lastOpenedAt,
            uiStateJson: uiStateJson,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$DatasetsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {datasetTablesRefs = false,
              datasetFilesRefs = false,
              savedMultiSheetQueriesRefs = false,
              datasetRelationshipsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (datasetTablesRefs) db.datasetTables,
                if (datasetFilesRefs) db.datasetFiles,
                if (savedMultiSheetQueriesRefs) db.savedMultiSheetQueries,
                if (datasetRelationshipsRefs) db.datasetRelationships
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (datasetTablesRefs)
                    await $_getPrefetchedData<Dataset, $DatasetsTable,
                            DatasetTable>(
                        currentTable: table,
                        referencedTable: $$DatasetsTableReferences
                            ._datasetTablesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$DatasetsTableReferences(db, table, p0)
                                .datasetTablesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.datasetId == item.id),
                        typedResults: items),
                  if (datasetFilesRefs)
                    await $_getPrefetchedData<Dataset, $DatasetsTable,
                            DatasetFile>(
                        currentTable: table,
                        referencedTable: $$DatasetsTableReferences
                            ._datasetFilesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$DatasetsTableReferences(db, table, p0)
                                .datasetFilesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.datasetId == item.id),
                        typedResults: items),
                  if (savedMultiSheetQueriesRefs)
                    await $_getPrefetchedData<Dataset, $DatasetsTable,
                            SavedMultiSheetQuery>(
                        currentTable: table,
                        referencedTable: $$DatasetsTableReferences
                            ._savedMultiSheetQueriesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$DatasetsTableReferences(db, table, p0)
                                .savedMultiSheetQueriesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.datasetId == item.id),
                        typedResults: items),
                  if (datasetRelationshipsRefs)
                    await $_getPrefetchedData<Dataset, $DatasetsTable,
                            DatasetRelationship>(
                        currentTable: table,
                        referencedTable: $$DatasetsTableReferences
                            ._datasetRelationshipsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$DatasetsTableReferences(db, table, p0)
                                .datasetRelationshipsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.datasetId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$DatasetsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DatasetsTable,
    Dataset,
    $$DatasetsTableFilterComposer,
    $$DatasetsTableOrderingComposer,
    $$DatasetsTableAnnotationComposer,
    $$DatasetsTableCreateCompanionBuilder,
    $$DatasetsTableUpdateCompanionBuilder,
    (Dataset, $$DatasetsTableReferences),
    Dataset,
    PrefetchHooks Function(
        {bool datasetTablesRefs,
        bool datasetFilesRefs,
        bool savedMultiSheetQueriesRefs,
        bool datasetRelationshipsRefs})>;
typedef $$DatasetTablesTableCreateCompanionBuilder = DatasetTablesCompanion
    Function({
  Value<int> id,
  required int datasetId,
  required String sheetNameOriginal,
  required String sqlTableName,
  required int rowCount,
  required int colCount,
});
typedef $$DatasetTablesTableUpdateCompanionBuilder = DatasetTablesCompanion
    Function({
  Value<int> id,
  Value<int> datasetId,
  Value<String> sheetNameOriginal,
  Value<String> sqlTableName,
  Value<int> rowCount,
  Value<int> colCount,
});

final class $$DatasetTablesTableReferences
    extends BaseReferences<_$AppDatabase, $DatasetTablesTable, DatasetTable> {
  $$DatasetTablesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $DatasetsTable _datasetIdTable(_$AppDatabase db) =>
      db.datasets.createAlias(
          $_aliasNameGenerator(db.datasetTables.datasetId, db.datasets.id));

  $$DatasetsTableProcessedTableManager get datasetId {
    final $_column = $_itemColumn<int>('dataset_id')!;

    final manager = $$DatasetsTableTableManager($_db, $_db.datasets)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_datasetIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$DatasetColumnsTable, List<DatasetColumn>>
      _datasetColumnsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.datasetColumns,
              aliasName: $_aliasNameGenerator(
                  db.datasetTables.id, db.datasetColumns.datasetTableId));

  $$DatasetColumnsTableProcessedTableManager get datasetColumnsRefs {
    final manager = $$DatasetColumnsTableTableManager($_db, $_db.datasetColumns)
        .filter((f) => f.datasetTableId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_datasetColumnsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$DatasetTablesTableFilterComposer
    extends Composer<_$AppDatabase, $DatasetTablesTable> {
  $$DatasetTablesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sheetNameOriginal => $composableBuilder(
      column: $table.sheetNameOriginal,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sqlTableName => $composableBuilder(
      column: $table.sqlTableName, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get rowCount => $composableBuilder(
      column: $table.rowCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get colCount => $composableBuilder(
      column: $table.colCount, builder: (column) => ColumnFilters(column));

  $$DatasetsTableFilterComposer get datasetId {
    final $$DatasetsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.datasetId,
        referencedTable: $db.datasets,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DatasetsTableFilterComposer(
              $db: $db,
              $table: $db.datasets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> datasetColumnsRefs(
      Expression<bool> Function($$DatasetColumnsTableFilterComposer f) f) {
    final $$DatasetColumnsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.datasetColumns,
        getReferencedColumn: (t) => t.datasetTableId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DatasetColumnsTableFilterComposer(
              $db: $db,
              $table: $db.datasetColumns,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$DatasetTablesTableOrderingComposer
    extends Composer<_$AppDatabase, $DatasetTablesTable> {
  $$DatasetTablesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sheetNameOriginal => $composableBuilder(
      column: $table.sheetNameOriginal,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sqlTableName => $composableBuilder(
      column: $table.sqlTableName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get rowCount => $composableBuilder(
      column: $table.rowCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get colCount => $composableBuilder(
      column: $table.colCount, builder: (column) => ColumnOrderings(column));

  $$DatasetsTableOrderingComposer get datasetId {
    final $$DatasetsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.datasetId,
        referencedTable: $db.datasets,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DatasetsTableOrderingComposer(
              $db: $db,
              $table: $db.datasets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$DatasetTablesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DatasetTablesTable> {
  $$DatasetTablesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sheetNameOriginal => $composableBuilder(
      column: $table.sheetNameOriginal, builder: (column) => column);

  GeneratedColumn<String> get sqlTableName => $composableBuilder(
      column: $table.sqlTableName, builder: (column) => column);

  GeneratedColumn<int> get rowCount =>
      $composableBuilder(column: $table.rowCount, builder: (column) => column);

  GeneratedColumn<int> get colCount =>
      $composableBuilder(column: $table.colCount, builder: (column) => column);

  $$DatasetsTableAnnotationComposer get datasetId {
    final $$DatasetsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.datasetId,
        referencedTable: $db.datasets,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DatasetsTableAnnotationComposer(
              $db: $db,
              $table: $db.datasets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> datasetColumnsRefs<T extends Object>(
      Expression<T> Function($$DatasetColumnsTableAnnotationComposer a) f) {
    final $$DatasetColumnsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.datasetColumns,
        getReferencedColumn: (t) => t.datasetTableId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DatasetColumnsTableAnnotationComposer(
              $db: $db,
              $table: $db.datasetColumns,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$DatasetTablesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DatasetTablesTable,
    DatasetTable,
    $$DatasetTablesTableFilterComposer,
    $$DatasetTablesTableOrderingComposer,
    $$DatasetTablesTableAnnotationComposer,
    $$DatasetTablesTableCreateCompanionBuilder,
    $$DatasetTablesTableUpdateCompanionBuilder,
    (DatasetTable, $$DatasetTablesTableReferences),
    DatasetTable,
    PrefetchHooks Function({bool datasetId, bool datasetColumnsRefs})> {
  $$DatasetTablesTableTableManager(_$AppDatabase db, $DatasetTablesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DatasetTablesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DatasetTablesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DatasetTablesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> datasetId = const Value.absent(),
            Value<String> sheetNameOriginal = const Value.absent(),
            Value<String> sqlTableName = const Value.absent(),
            Value<int> rowCount = const Value.absent(),
            Value<int> colCount = const Value.absent(),
          }) =>
              DatasetTablesCompanion(
            id: id,
            datasetId: datasetId,
            sheetNameOriginal: sheetNameOriginal,
            sqlTableName: sqlTableName,
            rowCount: rowCount,
            colCount: colCount,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int datasetId,
            required String sheetNameOriginal,
            required String sqlTableName,
            required int rowCount,
            required int colCount,
          }) =>
              DatasetTablesCompanion.insert(
            id: id,
            datasetId: datasetId,
            sheetNameOriginal: sheetNameOriginal,
            sqlTableName: sqlTableName,
            rowCount: rowCount,
            colCount: colCount,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$DatasetTablesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {datasetId = false, datasetColumnsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (datasetColumnsRefs) db.datasetColumns
              ],
              addJoins: <
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
                      dynamic>>(state) {
                if (datasetId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.datasetId,
                    referencedTable:
                        $$DatasetTablesTableReferences._datasetIdTable(db),
                    referencedColumn:
                        $$DatasetTablesTableReferences._datasetIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (datasetColumnsRefs)
                    await $_getPrefetchedData<DatasetTable, $DatasetTablesTable,
                            DatasetColumn>(
                        currentTable: table,
                        referencedTable: $$DatasetTablesTableReferences
                            ._datasetColumnsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$DatasetTablesTableReferences(db, table, p0)
                                .datasetColumnsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.datasetTableId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$DatasetTablesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DatasetTablesTable,
    DatasetTable,
    $$DatasetTablesTableFilterComposer,
    $$DatasetTablesTableOrderingComposer,
    $$DatasetTablesTableAnnotationComposer,
    $$DatasetTablesTableCreateCompanionBuilder,
    $$DatasetTablesTableUpdateCompanionBuilder,
    (DatasetTable, $$DatasetTablesTableReferences),
    DatasetTable,
    PrefetchHooks Function({bool datasetId, bool datasetColumnsRefs})>;
typedef $$DatasetColumnsTableCreateCompanionBuilder = DatasetColumnsCompanion
    Function({
  Value<int> id,
  required int datasetTableId,
  required String originalName,
  required String dbName,
  required String declaredType,
  required String inferredType,
  required bool nullable,
  Value<String?> statsJson,
});
typedef $$DatasetColumnsTableUpdateCompanionBuilder = DatasetColumnsCompanion
    Function({
  Value<int> id,
  Value<int> datasetTableId,
  Value<String> originalName,
  Value<String> dbName,
  Value<String> declaredType,
  Value<String> inferredType,
  Value<bool> nullable,
  Value<String?> statsJson,
});

final class $$DatasetColumnsTableReferences
    extends BaseReferences<_$AppDatabase, $DatasetColumnsTable, DatasetColumn> {
  $$DatasetColumnsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $DatasetTablesTable _datasetTableIdTable(_$AppDatabase db) =>
      db.datasetTables.createAlias($_aliasNameGenerator(
          db.datasetColumns.datasetTableId, db.datasetTables.id));

  $$DatasetTablesTableProcessedTableManager get datasetTableId {
    final $_column = $_itemColumn<int>('dataset_table_id')!;

    final manager = $$DatasetTablesTableTableManager($_db, $_db.datasetTables)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_datasetTableIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$DatasetColumnsTableFilterComposer
    extends Composer<_$AppDatabase, $DatasetColumnsTable> {
  $$DatasetColumnsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get originalName => $composableBuilder(
      column: $table.originalName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dbName => $composableBuilder(
      column: $table.dbName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get declaredType => $composableBuilder(
      column: $table.declaredType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get inferredType => $composableBuilder(
      column: $table.inferredType, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get nullable => $composableBuilder(
      column: $table.nullable, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get statsJson => $composableBuilder(
      column: $table.statsJson, builder: (column) => ColumnFilters(column));

  $$DatasetTablesTableFilterComposer get datasetTableId {
    final $$DatasetTablesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.datasetTableId,
        referencedTable: $db.datasetTables,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DatasetTablesTableFilterComposer(
              $db: $db,
              $table: $db.datasetTables,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$DatasetColumnsTableOrderingComposer
    extends Composer<_$AppDatabase, $DatasetColumnsTable> {
  $$DatasetColumnsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get originalName => $composableBuilder(
      column: $table.originalName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dbName => $composableBuilder(
      column: $table.dbName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get declaredType => $composableBuilder(
      column: $table.declaredType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get inferredType => $composableBuilder(
      column: $table.inferredType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get nullable => $composableBuilder(
      column: $table.nullable, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get statsJson => $composableBuilder(
      column: $table.statsJson, builder: (column) => ColumnOrderings(column));

  $$DatasetTablesTableOrderingComposer get datasetTableId {
    final $$DatasetTablesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.datasetTableId,
        referencedTable: $db.datasetTables,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DatasetTablesTableOrderingComposer(
              $db: $db,
              $table: $db.datasetTables,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$DatasetColumnsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DatasetColumnsTable> {
  $$DatasetColumnsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get originalName => $composableBuilder(
      column: $table.originalName, builder: (column) => column);

  GeneratedColumn<String> get dbName =>
      $composableBuilder(column: $table.dbName, builder: (column) => column);

  GeneratedColumn<String> get declaredType => $composableBuilder(
      column: $table.declaredType, builder: (column) => column);

  GeneratedColumn<String> get inferredType => $composableBuilder(
      column: $table.inferredType, builder: (column) => column);

  GeneratedColumn<bool> get nullable =>
      $composableBuilder(column: $table.nullable, builder: (column) => column);

  GeneratedColumn<String> get statsJson =>
      $composableBuilder(column: $table.statsJson, builder: (column) => column);

  $$DatasetTablesTableAnnotationComposer get datasetTableId {
    final $$DatasetTablesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.datasetTableId,
        referencedTable: $db.datasetTables,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DatasetTablesTableAnnotationComposer(
              $db: $db,
              $table: $db.datasetTables,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$DatasetColumnsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DatasetColumnsTable,
    DatasetColumn,
    $$DatasetColumnsTableFilterComposer,
    $$DatasetColumnsTableOrderingComposer,
    $$DatasetColumnsTableAnnotationComposer,
    $$DatasetColumnsTableCreateCompanionBuilder,
    $$DatasetColumnsTableUpdateCompanionBuilder,
    (DatasetColumn, $$DatasetColumnsTableReferences),
    DatasetColumn,
    PrefetchHooks Function({bool datasetTableId})> {
  $$DatasetColumnsTableTableManager(
      _$AppDatabase db, $DatasetColumnsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DatasetColumnsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DatasetColumnsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DatasetColumnsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> datasetTableId = const Value.absent(),
            Value<String> originalName = const Value.absent(),
            Value<String> dbName = const Value.absent(),
            Value<String> declaredType = const Value.absent(),
            Value<String> inferredType = const Value.absent(),
            Value<bool> nullable = const Value.absent(),
            Value<String?> statsJson = const Value.absent(),
          }) =>
              DatasetColumnsCompanion(
            id: id,
            datasetTableId: datasetTableId,
            originalName: originalName,
            dbName: dbName,
            declaredType: declaredType,
            inferredType: inferredType,
            nullable: nullable,
            statsJson: statsJson,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int datasetTableId,
            required String originalName,
            required String dbName,
            required String declaredType,
            required String inferredType,
            required bool nullable,
            Value<String?> statsJson = const Value.absent(),
          }) =>
              DatasetColumnsCompanion.insert(
            id: id,
            datasetTableId: datasetTableId,
            originalName: originalName,
            dbName: dbName,
            declaredType: declaredType,
            inferredType: inferredType,
            nullable: nullable,
            statsJson: statsJson,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$DatasetColumnsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({datasetTableId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (datasetTableId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.datasetTableId,
                    referencedTable: $$DatasetColumnsTableReferences
                        ._datasetTableIdTable(db),
                    referencedColumn: $$DatasetColumnsTableReferences
                        ._datasetTableIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$DatasetColumnsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DatasetColumnsTable,
    DatasetColumn,
    $$DatasetColumnsTableFilterComposer,
    $$DatasetColumnsTableOrderingComposer,
    $$DatasetColumnsTableAnnotationComposer,
    $$DatasetColumnsTableCreateCompanionBuilder,
    $$DatasetColumnsTableUpdateCompanionBuilder,
    (DatasetColumn, $$DatasetColumnsTableReferences),
    DatasetColumn,
    PrefetchHooks Function({bool datasetTableId})>;
typedef $$DatasetFilesTableCreateCompanionBuilder = DatasetFilesCompanion
    Function({
  Value<int> id,
  required int datasetId,
  required String storageMode,
  Value<String?> originalPath,
  Value<String?> storedPath,
  required DateTime importedAt,
  Value<int?> fileSize,
});
typedef $$DatasetFilesTableUpdateCompanionBuilder = DatasetFilesCompanion
    Function({
  Value<int> id,
  Value<int> datasetId,
  Value<String> storageMode,
  Value<String?> originalPath,
  Value<String?> storedPath,
  Value<DateTime> importedAt,
  Value<int?> fileSize,
});

final class $$DatasetFilesTableReferences
    extends BaseReferences<_$AppDatabase, $DatasetFilesTable, DatasetFile> {
  $$DatasetFilesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $DatasetsTable _datasetIdTable(_$AppDatabase db) =>
      db.datasets.createAlias(
          $_aliasNameGenerator(db.datasetFiles.datasetId, db.datasets.id));

  $$DatasetsTableProcessedTableManager get datasetId {
    final $_column = $_itemColumn<int>('dataset_id')!;

    final manager = $$DatasetsTableTableManager($_db, $_db.datasets)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_datasetIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$DatasetFilesTableFilterComposer
    extends Composer<_$AppDatabase, $DatasetFilesTable> {
  $$DatasetFilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get storageMode => $composableBuilder(
      column: $table.storageMode, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get originalPath => $composableBuilder(
      column: $table.originalPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get storedPath => $composableBuilder(
      column: $table.storedPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get importedAt => $composableBuilder(
      column: $table.importedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get fileSize => $composableBuilder(
      column: $table.fileSize, builder: (column) => ColumnFilters(column));

  $$DatasetsTableFilterComposer get datasetId {
    final $$DatasetsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.datasetId,
        referencedTable: $db.datasets,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DatasetsTableFilterComposer(
              $db: $db,
              $table: $db.datasets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$DatasetFilesTableOrderingComposer
    extends Composer<_$AppDatabase, $DatasetFilesTable> {
  $$DatasetFilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get storageMode => $composableBuilder(
      column: $table.storageMode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get originalPath => $composableBuilder(
      column: $table.originalPath,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get storedPath => $composableBuilder(
      column: $table.storedPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get importedAt => $composableBuilder(
      column: $table.importedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get fileSize => $composableBuilder(
      column: $table.fileSize, builder: (column) => ColumnOrderings(column));

  $$DatasetsTableOrderingComposer get datasetId {
    final $$DatasetsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.datasetId,
        referencedTable: $db.datasets,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DatasetsTableOrderingComposer(
              $db: $db,
              $table: $db.datasets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$DatasetFilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DatasetFilesTable> {
  $$DatasetFilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get storageMode => $composableBuilder(
      column: $table.storageMode, builder: (column) => column);

  GeneratedColumn<String> get originalPath => $composableBuilder(
      column: $table.originalPath, builder: (column) => column);

  GeneratedColumn<String> get storedPath => $composableBuilder(
      column: $table.storedPath, builder: (column) => column);

  GeneratedColumn<DateTime> get importedAt => $composableBuilder(
      column: $table.importedAt, builder: (column) => column);

  GeneratedColumn<int> get fileSize =>
      $composableBuilder(column: $table.fileSize, builder: (column) => column);

  $$DatasetsTableAnnotationComposer get datasetId {
    final $$DatasetsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.datasetId,
        referencedTable: $db.datasets,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DatasetsTableAnnotationComposer(
              $db: $db,
              $table: $db.datasets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$DatasetFilesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DatasetFilesTable,
    DatasetFile,
    $$DatasetFilesTableFilterComposer,
    $$DatasetFilesTableOrderingComposer,
    $$DatasetFilesTableAnnotationComposer,
    $$DatasetFilesTableCreateCompanionBuilder,
    $$DatasetFilesTableUpdateCompanionBuilder,
    (DatasetFile, $$DatasetFilesTableReferences),
    DatasetFile,
    PrefetchHooks Function({bool datasetId})> {
  $$DatasetFilesTableTableManager(_$AppDatabase db, $DatasetFilesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DatasetFilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DatasetFilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DatasetFilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> datasetId = const Value.absent(),
            Value<String> storageMode = const Value.absent(),
            Value<String?> originalPath = const Value.absent(),
            Value<String?> storedPath = const Value.absent(),
            Value<DateTime> importedAt = const Value.absent(),
            Value<int?> fileSize = const Value.absent(),
          }) =>
              DatasetFilesCompanion(
            id: id,
            datasetId: datasetId,
            storageMode: storageMode,
            originalPath: originalPath,
            storedPath: storedPath,
            importedAt: importedAt,
            fileSize: fileSize,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int datasetId,
            required String storageMode,
            Value<String?> originalPath = const Value.absent(),
            Value<String?> storedPath = const Value.absent(),
            required DateTime importedAt,
            Value<int?> fileSize = const Value.absent(),
          }) =>
              DatasetFilesCompanion.insert(
            id: id,
            datasetId: datasetId,
            storageMode: storageMode,
            originalPath: originalPath,
            storedPath: storedPath,
            importedAt: importedAt,
            fileSize: fileSize,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$DatasetFilesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({datasetId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (datasetId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.datasetId,
                    referencedTable:
                        $$DatasetFilesTableReferences._datasetIdTable(db),
                    referencedColumn:
                        $$DatasetFilesTableReferences._datasetIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$DatasetFilesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DatasetFilesTable,
    DatasetFile,
    $$DatasetFilesTableFilterComposer,
    $$DatasetFilesTableOrderingComposer,
    $$DatasetFilesTableAnnotationComposer,
    $$DatasetFilesTableCreateCompanionBuilder,
    $$DatasetFilesTableUpdateCompanionBuilder,
    (DatasetFile, $$DatasetFilesTableReferences),
    DatasetFile,
    PrefetchHooks Function({bool datasetId})>;
typedef $$SavedMultiSheetQueriesTableCreateCompanionBuilder
    = SavedMultiSheetQueriesCompanion Function({
  Value<int> id,
  required int datasetId,
  required String name,
  Value<int?> baseTableId,
  required String specificationJson,
  Value<int> schemaVersion,
  required int createdAt,
  required int updatedAt,
});
typedef $$SavedMultiSheetQueriesTableUpdateCompanionBuilder
    = SavedMultiSheetQueriesCompanion Function({
  Value<int> id,
  Value<int> datasetId,
  Value<String> name,
  Value<int?> baseTableId,
  Value<String> specificationJson,
  Value<int> schemaVersion,
  Value<int> createdAt,
  Value<int> updatedAt,
});

final class $$SavedMultiSheetQueriesTableReferences extends BaseReferences<
    _$AppDatabase, $SavedMultiSheetQueriesTable, SavedMultiSheetQuery> {
  $$SavedMultiSheetQueriesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $DatasetsTable _datasetIdTable(_$AppDatabase db) =>
      db.datasets.createAlias($_aliasNameGenerator(
          db.savedMultiSheetQueries.datasetId, db.datasets.id));

  $$DatasetsTableProcessedTableManager get datasetId {
    final $_column = $_itemColumn<int>('dataset_id')!;

    final manager = $$DatasetsTableTableManager($_db, $_db.datasets)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_datasetIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$SavedMultiSheetQueriesTableFilterComposer
    extends Composer<_$AppDatabase, $SavedMultiSheetQueriesTable> {
  $$SavedMultiSheetQueriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get baseTableId => $composableBuilder(
      column: $table.baseTableId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get specificationJson => $composableBuilder(
      column: $table.specificationJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get schemaVersion => $composableBuilder(
      column: $table.schemaVersion, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  $$DatasetsTableFilterComposer get datasetId {
    final $$DatasetsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.datasetId,
        referencedTable: $db.datasets,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DatasetsTableFilterComposer(
              $db: $db,
              $table: $db.datasets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SavedMultiSheetQueriesTableOrderingComposer
    extends Composer<_$AppDatabase, $SavedMultiSheetQueriesTable> {
  $$SavedMultiSheetQueriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get baseTableId => $composableBuilder(
      column: $table.baseTableId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get specificationJson => $composableBuilder(
      column: $table.specificationJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get schemaVersion => $composableBuilder(
      column: $table.schemaVersion,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  $$DatasetsTableOrderingComposer get datasetId {
    final $$DatasetsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.datasetId,
        referencedTable: $db.datasets,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DatasetsTableOrderingComposer(
              $db: $db,
              $table: $db.datasets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SavedMultiSheetQueriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SavedMultiSheetQueriesTable> {
  $$SavedMultiSheetQueriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get baseTableId => $composableBuilder(
      column: $table.baseTableId, builder: (column) => column);

  GeneratedColumn<String> get specificationJson => $composableBuilder(
      column: $table.specificationJson, builder: (column) => column);

  GeneratedColumn<int> get schemaVersion => $composableBuilder(
      column: $table.schemaVersion, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$DatasetsTableAnnotationComposer get datasetId {
    final $$DatasetsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.datasetId,
        referencedTable: $db.datasets,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DatasetsTableAnnotationComposer(
              $db: $db,
              $table: $db.datasets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$SavedMultiSheetQueriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SavedMultiSheetQueriesTable,
    SavedMultiSheetQuery,
    $$SavedMultiSheetQueriesTableFilterComposer,
    $$SavedMultiSheetQueriesTableOrderingComposer,
    $$SavedMultiSheetQueriesTableAnnotationComposer,
    $$SavedMultiSheetQueriesTableCreateCompanionBuilder,
    $$SavedMultiSheetQueriesTableUpdateCompanionBuilder,
    (SavedMultiSheetQuery, $$SavedMultiSheetQueriesTableReferences),
    SavedMultiSheetQuery,
    PrefetchHooks Function({bool datasetId})> {
  $$SavedMultiSheetQueriesTableTableManager(
      _$AppDatabase db, $SavedMultiSheetQueriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SavedMultiSheetQueriesTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$SavedMultiSheetQueriesTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SavedMultiSheetQueriesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> datasetId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int?> baseTableId = const Value.absent(),
            Value<String> specificationJson = const Value.absent(),
            Value<int> schemaVersion = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
          }) =>
              SavedMultiSheetQueriesCompanion(
            id: id,
            datasetId: datasetId,
            name: name,
            baseTableId: baseTableId,
            specificationJson: specificationJson,
            schemaVersion: schemaVersion,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int datasetId,
            required String name,
            Value<int?> baseTableId = const Value.absent(),
            required String specificationJson,
            Value<int> schemaVersion = const Value.absent(),
            required int createdAt,
            required int updatedAt,
          }) =>
              SavedMultiSheetQueriesCompanion.insert(
            id: id,
            datasetId: datasetId,
            name: name,
            baseTableId: baseTableId,
            specificationJson: specificationJson,
            schemaVersion: schemaVersion,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$SavedMultiSheetQueriesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({datasetId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (datasetId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.datasetId,
                    referencedTable: $$SavedMultiSheetQueriesTableReferences
                        ._datasetIdTable(db),
                    referencedColumn: $$SavedMultiSheetQueriesTableReferences
                        ._datasetIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$SavedMultiSheetQueriesTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $SavedMultiSheetQueriesTable,
        SavedMultiSheetQuery,
        $$SavedMultiSheetQueriesTableFilterComposer,
        $$SavedMultiSheetQueriesTableOrderingComposer,
        $$SavedMultiSheetQueriesTableAnnotationComposer,
        $$SavedMultiSheetQueriesTableCreateCompanionBuilder,
        $$SavedMultiSheetQueriesTableUpdateCompanionBuilder,
        (SavedMultiSheetQuery, $$SavedMultiSheetQueriesTableReferences),
        SavedMultiSheetQuery,
        PrefetchHooks Function({bool datasetId})>;
typedef $$DatasetRelationshipsTableCreateCompanionBuilder
    = DatasetRelationshipsCompanion Function({
  Value<int> id,
  required int datasetId,
  required int endpointATableId,
  required String endpointAColumnDbName,
  required int endpointBTableId,
  required String endpointBColumnDbName,
  Value<String> cardinality,
  Value<double> relationshipConfidence,
  Value<double> cardinalityConfidence,
  Value<int> sampleSize,
  Value<String> origin,
  Value<int?> confirmedAt,
  required int createdAt,
  required int updatedAt,
});
typedef $$DatasetRelationshipsTableUpdateCompanionBuilder
    = DatasetRelationshipsCompanion Function({
  Value<int> id,
  Value<int> datasetId,
  Value<int> endpointATableId,
  Value<String> endpointAColumnDbName,
  Value<int> endpointBTableId,
  Value<String> endpointBColumnDbName,
  Value<String> cardinality,
  Value<double> relationshipConfidence,
  Value<double> cardinalityConfidence,
  Value<int> sampleSize,
  Value<String> origin,
  Value<int?> confirmedAt,
  Value<int> createdAt,
  Value<int> updatedAt,
});

final class $$DatasetRelationshipsTableReferences extends BaseReferences<
    _$AppDatabase, $DatasetRelationshipsTable, DatasetRelationship> {
  $$DatasetRelationshipsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $DatasetsTable _datasetIdTable(_$AppDatabase db) =>
      db.datasets.createAlias($_aliasNameGenerator(
          db.datasetRelationships.datasetId, db.datasets.id));

  $$DatasetsTableProcessedTableManager get datasetId {
    final $_column = $_itemColumn<int>('dataset_id')!;

    final manager = $$DatasetsTableTableManager($_db, $_db.datasets)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_datasetIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$DatasetRelationshipsTableFilterComposer
    extends Composer<_$AppDatabase, $DatasetRelationshipsTable> {
  $$DatasetRelationshipsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get endpointATableId => $composableBuilder(
      column: $table.endpointATableId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get endpointAColumnDbName => $composableBuilder(
      column: $table.endpointAColumnDbName,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get endpointBTableId => $composableBuilder(
      column: $table.endpointBTableId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get endpointBColumnDbName => $composableBuilder(
      column: $table.endpointBColumnDbName,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cardinality => $composableBuilder(
      column: $table.cardinality, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get relationshipConfidence => $composableBuilder(
      column: $table.relationshipConfidence,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get cardinalityConfidence => $composableBuilder(
      column: $table.cardinalityConfidence,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sampleSize => $composableBuilder(
      column: $table.sampleSize, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get origin => $composableBuilder(
      column: $table.origin, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get confirmedAt => $composableBuilder(
      column: $table.confirmedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  $$DatasetsTableFilterComposer get datasetId {
    final $$DatasetsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.datasetId,
        referencedTable: $db.datasets,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DatasetsTableFilterComposer(
              $db: $db,
              $table: $db.datasets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$DatasetRelationshipsTableOrderingComposer
    extends Composer<_$AppDatabase, $DatasetRelationshipsTable> {
  $$DatasetRelationshipsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get endpointATableId => $composableBuilder(
      column: $table.endpointATableId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get endpointAColumnDbName => $composableBuilder(
      column: $table.endpointAColumnDbName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get endpointBTableId => $composableBuilder(
      column: $table.endpointBTableId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get endpointBColumnDbName => $composableBuilder(
      column: $table.endpointBColumnDbName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cardinality => $composableBuilder(
      column: $table.cardinality, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get relationshipConfidence => $composableBuilder(
      column: $table.relationshipConfidence,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get cardinalityConfidence => $composableBuilder(
      column: $table.cardinalityConfidence,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sampleSize => $composableBuilder(
      column: $table.sampleSize, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get origin => $composableBuilder(
      column: $table.origin, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get confirmedAt => $composableBuilder(
      column: $table.confirmedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  $$DatasetsTableOrderingComposer get datasetId {
    final $$DatasetsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.datasetId,
        referencedTable: $db.datasets,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DatasetsTableOrderingComposer(
              $db: $db,
              $table: $db.datasets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$DatasetRelationshipsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DatasetRelationshipsTable> {
  $$DatasetRelationshipsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get endpointATableId => $composableBuilder(
      column: $table.endpointATableId, builder: (column) => column);

  GeneratedColumn<String> get endpointAColumnDbName => $composableBuilder(
      column: $table.endpointAColumnDbName, builder: (column) => column);

  GeneratedColumn<int> get endpointBTableId => $composableBuilder(
      column: $table.endpointBTableId, builder: (column) => column);

  GeneratedColumn<String> get endpointBColumnDbName => $composableBuilder(
      column: $table.endpointBColumnDbName, builder: (column) => column);

  GeneratedColumn<String> get cardinality => $composableBuilder(
      column: $table.cardinality, builder: (column) => column);

  GeneratedColumn<double> get relationshipConfidence => $composableBuilder(
      column: $table.relationshipConfidence, builder: (column) => column);

  GeneratedColumn<double> get cardinalityConfidence => $composableBuilder(
      column: $table.cardinalityConfidence, builder: (column) => column);

  GeneratedColumn<int> get sampleSize => $composableBuilder(
      column: $table.sampleSize, builder: (column) => column);

  GeneratedColumn<String> get origin =>
      $composableBuilder(column: $table.origin, builder: (column) => column);

  GeneratedColumn<int> get confirmedAt => $composableBuilder(
      column: $table.confirmedAt, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$DatasetsTableAnnotationComposer get datasetId {
    final $$DatasetsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.datasetId,
        referencedTable: $db.datasets,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DatasetsTableAnnotationComposer(
              $db: $db,
              $table: $db.datasets,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$DatasetRelationshipsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DatasetRelationshipsTable,
    DatasetRelationship,
    $$DatasetRelationshipsTableFilterComposer,
    $$DatasetRelationshipsTableOrderingComposer,
    $$DatasetRelationshipsTableAnnotationComposer,
    $$DatasetRelationshipsTableCreateCompanionBuilder,
    $$DatasetRelationshipsTableUpdateCompanionBuilder,
    (DatasetRelationship, $$DatasetRelationshipsTableReferences),
    DatasetRelationship,
    PrefetchHooks Function({bool datasetId})> {
  $$DatasetRelationshipsTableTableManager(
      _$AppDatabase db, $DatasetRelationshipsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DatasetRelationshipsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DatasetRelationshipsTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DatasetRelationshipsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> datasetId = const Value.absent(),
            Value<int> endpointATableId = const Value.absent(),
            Value<String> endpointAColumnDbName = const Value.absent(),
            Value<int> endpointBTableId = const Value.absent(),
            Value<String> endpointBColumnDbName = const Value.absent(),
            Value<String> cardinality = const Value.absent(),
            Value<double> relationshipConfidence = const Value.absent(),
            Value<double> cardinalityConfidence = const Value.absent(),
            Value<int> sampleSize = const Value.absent(),
            Value<String> origin = const Value.absent(),
            Value<int?> confirmedAt = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
          }) =>
              DatasetRelationshipsCompanion(
            id: id,
            datasetId: datasetId,
            endpointATableId: endpointATableId,
            endpointAColumnDbName: endpointAColumnDbName,
            endpointBTableId: endpointBTableId,
            endpointBColumnDbName: endpointBColumnDbName,
            cardinality: cardinality,
            relationshipConfidence: relationshipConfidence,
            cardinalityConfidence: cardinalityConfidence,
            sampleSize: sampleSize,
            origin: origin,
            confirmedAt: confirmedAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int datasetId,
            required int endpointATableId,
            required String endpointAColumnDbName,
            required int endpointBTableId,
            required String endpointBColumnDbName,
            Value<String> cardinality = const Value.absent(),
            Value<double> relationshipConfidence = const Value.absent(),
            Value<double> cardinalityConfidence = const Value.absent(),
            Value<int> sampleSize = const Value.absent(),
            Value<String> origin = const Value.absent(),
            Value<int?> confirmedAt = const Value.absent(),
            required int createdAt,
            required int updatedAt,
          }) =>
              DatasetRelationshipsCompanion.insert(
            id: id,
            datasetId: datasetId,
            endpointATableId: endpointATableId,
            endpointAColumnDbName: endpointAColumnDbName,
            endpointBTableId: endpointBTableId,
            endpointBColumnDbName: endpointBColumnDbName,
            cardinality: cardinality,
            relationshipConfidence: relationshipConfidence,
            cardinalityConfidence: cardinalityConfidence,
            sampleSize: sampleSize,
            origin: origin,
            confirmedAt: confirmedAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$DatasetRelationshipsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({datasetId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (datasetId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.datasetId,
                    referencedTable: $$DatasetRelationshipsTableReferences
                        ._datasetIdTable(db),
                    referencedColumn: $$DatasetRelationshipsTableReferences
                        ._datasetIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$DatasetRelationshipsTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $DatasetRelationshipsTable,
        DatasetRelationship,
        $$DatasetRelationshipsTableFilterComposer,
        $$DatasetRelationshipsTableOrderingComposer,
        $$DatasetRelationshipsTableAnnotationComposer,
        $$DatasetRelationshipsTableCreateCompanionBuilder,
        $$DatasetRelationshipsTableUpdateCompanionBuilder,
        (DatasetRelationship, $$DatasetRelationshipsTableReferences),
        DatasetRelationship,
        PrefetchHooks Function({bool datasetId})>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$DatasetsTableTableManager get datasets =>
      $$DatasetsTableTableManager(_db, _db.datasets);
  $$DatasetTablesTableTableManager get datasetTables =>
      $$DatasetTablesTableTableManager(_db, _db.datasetTables);
  $$DatasetColumnsTableTableManager get datasetColumns =>
      $$DatasetColumnsTableTableManager(_db, _db.datasetColumns);
  $$DatasetFilesTableTableManager get datasetFiles =>
      $$DatasetFilesTableTableManager(_db, _db.datasetFiles);
  $$SavedMultiSheetQueriesTableTableManager get savedMultiSheetQueries =>
      $$SavedMultiSheetQueriesTableTableManager(
          _db, _db.savedMultiSheetQueries);
  $$DatasetRelationshipsTableTableManager get datasetRelationships =>
      $$DatasetRelationshipsTableTableManager(_db, _db.datasetRelationships);
}
