import 'package:exlser/core/database/app_database.dart';
import 'package:exlser/core/database/daos/dataset_files_dao.dart';
import 'package:exlser/core/database/daos/datasets_dao.dart';
import 'package:exlser/core/database/daos/saved_multi_sheet_queries_dao.dart';
import 'package:exlser/data/datasources/drift_datasource.dart';
import 'package:exlser/data/datasources/file_datasource.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase.defaults();

  ref.onDispose(database.close);

  return database;
});

final driftDatasourceProvider = Provider<DriftDatasource>((ref) {
  return DriftDatasource(
    ref.watch(appDatabaseProvider),
  );
});

final fileDatasourceProvider = Provider<FileDatasource>((ref) {
  return const FileDatasource();
});

final datasetsDaoProvider = Provider<DatasetsDao>((ref) {
  return DatasetsDao(
    ref.watch(appDatabaseProvider),
  );
});

final datasetFilesDaoProvider = Provider<DatasetFilesDao>((ref) {
  return DatasetFilesDao(
    ref.watch(appDatabaseProvider),
  );
});

final savedMultiSheetQueriesDaoProvider =
    Provider<SavedMultiSheetQueriesDao>((ref) {
  return SavedMultiSheetQueriesDao(
    ref.watch(appDatabaseProvider),
  );
});
