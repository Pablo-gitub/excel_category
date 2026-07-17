// Real migration tests: build an old on-disk schema, reopen it as AppDatabase so
// the declared onUpgrade actually runs, and check the new tables appear, existing
// data survives, and CRUD works afterwards.
import 'dart:io';

import 'package:drift/native.dart';
import 'package:exlser/core/database/app_database.dart'
    hide DatasetColumn, DatasetTable, DatasetRelationship, SavedMultiSheetQuery;
import 'package:exlser/core/database/daos/dataset_relationships_dao.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

const _datasetsDdl = '''
CREATE TABLE datasets (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  source_file_name TEXT NOT NULL,
  source_file_hash TEXT,
  created_at INTEGER NOT NULL,
  last_opened_at INTEGER,
  ui_state_json TEXT
);
''';

const _savedQueriesDdl = '''
CREATE TABLE saved_multi_sheet_queries (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  dataset_id INTEGER NOT NULL,
  name TEXT NOT NULL,
  base_table_id INTEGER,
  specification_json TEXT NOT NULL,
  schema_version INTEGER NOT NULL DEFAULT 1,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);
''';

void main() {
  late File file;

  setUp(() {
    file = File(
      '${Directory.systemTemp.path}/exlser_mig_${DateTime.now().microsecondsSinceEpoch}.db',
    );
    if (file.existsSync()) file.deleteSync();
  });

  tearDown(() {
    if (file.existsSync()) file.deleteSync();
  });

  /// Creates a v1 database (original tables only) with one dataset row.
  void seedV1() {
    final raw = sqlite.sqlite3.open(file.path);
    raw.execute(_datasetsDdl);
    raw.execute(
      "INSERT INTO datasets (name, source_file_name, created_at) "
      "VALUES ('keep-me', 'f.xlsx', 111);",
    );
    raw.execute('PRAGMA user_version = 1;');
    raw.close();
  }

  /// Creates a v2 database (adds saved queries) with a dataset and a saved query.
  void seedV2() {
    final raw = sqlite.sqlite3.open(file.path);
    raw.execute(_datasetsDdl);
    raw.execute(_savedQueriesDdl);
    raw.execute(
      "INSERT INTO datasets (id, name, source_file_name, created_at) "
      "VALUES (7, 'keep-me', 'f.xlsx', 111);",
    );
    raw.execute(
      "INSERT INTO saved_multi_sheet_queries "
      "(dataset_id, name, specification_json, created_at, updated_at) "
      "VALUES (7, 'my join', '{}', 1, 1);",
    );
    raw.execute('PRAGMA user_version = 2;');
    raw.close();
  }

  Future<int> tableCount(AppDatabase db, String table) async {
    final row =
        await db.customSelect('SELECT COUNT(*) AS c FROM $table').getSingle();
    return row.read<int>('c');
  }

  Future<void> assertUpgradedAndUsable(AppDatabase db) async {
    // Existing dataset preserved.
    final datasets = await db.customSelect('SELECT name FROM datasets').get();
    expect(datasets.map((r) => r.read<String>('name')), contains('keep-me'));

    // Both new tables exist and are empty/usable.
    expect(await tableCount(db, 'dataset_relationships'), 0);
    expect(await tableCount(db, 'saved_multi_sheet_queries'), isNonNegative);

    // CRUD works on the freshly migrated relationships table.
    final dao = DatasetRelationshipsDao(db);
    final datasetId =
        (await db.customSelect('SELECT id FROM datasets LIMIT 1').getSingle())
            .read<int>('id');
    await dao.createRelationship(
      DatasetRelationshipsCompanion.insert(
        datasetId: datasetId,
        endpointATableId: 1,
        endpointAColumnDbName: 'a',
        endpointBTableId: 2,
        endpointBColumnDbName: 'b',
        createdAt: 1,
        updatedAt: 1,
      ),
    );
    expect(await tableCount(db, 'dataset_relationships'), 1);
  }

  test('v1 -> v3 creates both new tables in a single upgrade', () async {
    seedV1();

    final db = AppDatabase(NativeDatabase(file));
    addTearDown(db.close);

    await assertUpgradedAndUsable(db);
    // v2 table also created on the way from v1.
    expect(await tableCount(db, 'saved_multi_sheet_queries'), 0);
  });

  test('v2 -> v3 adds relationships and keeps saved queries', () async {
    seedV2();

    final db = AppDatabase(NativeDatabase(file));
    addTearDown(db.close);

    await assertUpgradedAndUsable(db);
    // The pre-existing saved query survived the v2 -> v3 step.
    final saved = await db
        .customSelect('SELECT name FROM saved_multi_sheet_queries')
        .get();
    expect(saved.map((r) => r.read<String>('name')), contains('my join'));
  });
}
