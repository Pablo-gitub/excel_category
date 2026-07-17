import 'package:drift/drift.dart';
import 'package:exlser/core/database/connection/connection.dart';
import 'package:exlser/core/database/daos/dataset_columns_dao.dart';
import 'package:exlser/core/database/daos/dataset_relationships_dao.dart';
import 'package:exlser/core/database/daos/dataset_tables_dao.dart';
import 'package:exlser/core/database/daos/datasets_dao.dart';
import 'package:exlser/core/database/daos/saved_multi_sheet_queries_dao.dart';
import 'package:exlser/core/database/tables/dataset_files.dart';
import 'package:exlser/core/database/tables/dataset_relationships.dart';
import 'package:exlser/core/database/tables/saved_multi_sheet_queries.dart';

import 'tables/datasets.dart';
import 'tables/dataset_tables.dart';
import 'tables/dataset_columns.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Datasets,
    DatasetTables,
    DatasetColumns,
    DatasetFiles,
    SavedMultiSheetQueries,
    DatasetRelationships,
  ],
  daos: [
    DatasetsDao,
    DatasetTablesDao,
    DatasetColumnsDao,
    SavedMultiSheetQueriesDao,
    DatasetRelationshipsDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);
  AppDatabase.defaults() : super(openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          // v2 introduced saved multi-sheet queries; v3 added relationships.
          // A v1 database upgrades straight to v3 in a single launch (both
          // blocks run); a database already at the branch's v2 gets only the
          // relationships table.
          if (from < 2) {
            await m.createTable(savedMultiSheetQueries);
          }
          if (from < 3) {
            await m.createTable(datasetRelationships);
          }
        },
      );
}
