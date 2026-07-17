import 'package:exlser/domain/repositories/dataset_file_repository.dart';
import 'package:exlser/domain/repositories/dataset_relationship_repository.dart';
import 'package:exlser/domain/repositories/datasets_repository.dart';
import 'package:exlser/domain/repositories/saved_multi_sheet_query_repository.dart';
import 'package:exlser/domain/repositories/schema_repository.dart';

/// Deletes a dataset and its associated metadata.
///
/// This operation removes:
/// - dataset metadata
/// - associated schema metadata
/// - dynamic SQL tables (if they exist)
/// - saved multi-sheet join configurations
/// - dataset relationships
///
/// Responsibilities:
/// - call repository delete method
/// - ensure cleanup of related schema and tables
///
/// Dependencies:
/// - DatasetsRepository
/// - SchemaRepository
///
/// Expected flow:
/// 1. Receive datasetId
/// 2. Remove owned rows (files, saved queries) and schema metadata
/// 3. Delete dataset via DatasetsRepository
class DeleteDatasetUseCase {
  final DatasetsRepository datasetsRepository;
  final SchemaRepository schemaRepository;
  final DatasetFileRepository datasetFileRepository;
  final SavedMultiSheetQueryRepository savedMultiSheetQueryRepository;
  final DatasetRelationshipRepository datasetRelationshipRepository;

  const DeleteDatasetUseCase({
    required this.datasetsRepository,
    required this.schemaRepository,
    required this.datasetFileRepository,
    required this.savedMultiSheetQueryRepository,
    required this.datasetRelationshipRepository,
  });

  Future<void> call(int datasetId) async {
    if (datasetId <= 0) {
      throw Exception('Dataset id must be greater than 0');
    }

    await datasetFileRepository.deleteByDatasetId(datasetId);
    await savedMultiSheetQueryRepository.deleteForDataset(datasetId);
    await datasetRelationshipRepository.deleteForDataset(datasetId);
    await schemaRepository.deleteSchemaForDataset(datasetId);
    await datasetsRepository.deleteDataset(datasetId);
  }
}
