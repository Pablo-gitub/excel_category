import 'package:exlser/data/repositories/dataset_file_repository_impl.dart';
import 'package:exlser/data/repositories/dataset_repository_impl.dart';
import 'package:exlser/data/repositories/dataset_relationship_repository_impl.dart';
import 'package:exlser/data/repositories/query_repository_impl.dart';
import 'package:exlser/data/repositories/saved_multi_sheet_query_repository_impl.dart';
import 'package:exlser/data/repositories/schema_repository_impl.dart';
import 'package:exlser/data/schema/dynamic_table_builder.dart';
import 'package:exlser/domain/repositories/dataset_file_repository.dart';
import 'package:exlser/domain/repositories/datasets_repository.dart';
import 'package:exlser/domain/repositories/dataset_relationship_repository.dart';
import 'package:exlser/domain/repositories/query_repository.dart';
import 'package:exlser/domain/repositories/saved_multi_sheet_query_repository.dart';
import 'package:exlser/domain/repositories/schema_repository.dart';
import 'package:exlser/presentation/providers/database_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dynamicTableBuilderProvider = Provider<DynamicTableBuilder>((ref) {
  return DynamicTableBuilder();
});

final datasetsRepositoryProvider = Provider<DatasetsRepository>((ref) {
  return DatasetsRepositoryImpl(
    dao: ref.watch(datasetsDaoProvider),
  );
});

final datasetFileRepositoryProvider = Provider<DatasetFileRepository>((ref) {
  return DatasetFileRepositoryImpl(
    dao: ref.watch(datasetFilesDaoProvider),
  );
});

final schemaRepositoryProvider = Provider<SchemaRepository>((ref) {
  return SchemaRepositoryImpl(
    ref.watch(driftDatasourceProvider),
    ref.watch(dynamicTableBuilderProvider),
  );
});

final queryRepositoryProvider = Provider<QueryRepository>((ref) {
  return QueryRepositoryImpl(
    ref.watch(driftDatasourceProvider),
  );
});

final datasetRelationshipRepositoryProvider =
    Provider<DatasetRelationshipRepository>((ref) {
  return DatasetRelationshipRepositoryImpl(
    ref.watch(datasetRelationshipsDaoProvider),
  );
});

final savedMultiSheetQueryRepositoryProvider =
    Provider<SavedMultiSheetQueryRepository>((ref) {
  return SavedMultiSheetQueryRepositoryImpl(
    ref.watch(savedMultiSheetQueriesDaoProvider),
  );
});
