//lib/domain/repositories/dataset_relationship_repository.dart

import 'package:exlser/domain/entities/dataset_relationship.dart';

/// Persistence contract for dataset relationships (semantic metadata).
abstract class DatasetRelationshipRepository {
  Future<DatasetRelationship> create(DatasetRelationship relationship);

  Future<void> update(DatasetRelationship relationship);

  Future<DatasetRelationship?> getById(int id);

  /// All relationships of a dataset, oldest first.
  Future<List<DatasetRelationship>> listForDataset(int datasetId);

  Future<void> deleteById(int id);

  /// Removes every relationship owned by a dataset (used when the dataset is deleted).
  Future<void> deleteForDataset(int datasetId);
}
