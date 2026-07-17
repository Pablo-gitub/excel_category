//lib/domain/usecases/multisheet/manage_dataset_relationships_usecases.dart

import 'package:exlser/domain/entities/dataset_relationship.dart';
import 'package:exlser/domain/repositories/dataset_relationship_repository.dart';

/// Raised when a relationship duplicates an existing one (same endpoints, any order).
class DuplicateRelationshipException implements Exception {
  final int existingId;

  const DuplicateRelationshipException(this.existingId);

  @override
  String toString() => 'DuplicateRelationshipException($existingId)';
}

/// Creates a dataset relationship, rejecting a duplicate of an existing pair.
///
/// Equivalence is by unordered endpoint pair ([DatasetRelationship.endpointKey]),
/// so A↔B swapped counts as the same relationship. Enforced in the domain, never
/// via a SQLite constraint.
class CreateDatasetRelationshipUseCase {
  final DatasetRelationshipRepository repository;
  final DateTime Function() now;

  CreateDatasetRelationshipUseCase({
    required this.repository,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;

  Future<DatasetRelationship> call(DatasetRelationship relationship) async {
    if (relationship.endpointATableId == relationship.endpointBTableId) {
      throw ArgumentError('A relationship must connect two different sheets');
    }

    final existing = await repository.listForDataset(relationship.datasetId);
    final duplicate = existing
        .where((r) => r.endpointKey == relationship.endpointKey)
        .firstOrNull;
    if (duplicate != null) {
      throw DuplicateRelationshipException(duplicate.id ?? -1);
    }

    return repository.create(relationship);
  }
}

/// Lists a dataset's relationships (oldest first).
class ListDatasetRelationshipsUseCase {
  final DatasetRelationshipRepository repository;

  const ListDatasetRelationshipsUseCase({required this.repository});

  Future<List<DatasetRelationship>> call(int datasetId) =>
      repository.listForDataset(datasetId);
}

/// Loads a single relationship.
class LoadDatasetRelationshipUseCase {
  final DatasetRelationshipRepository repository;

  const LoadDatasetRelationshipUseCase({required this.repository});

  Future<DatasetRelationship?> call(int id) => repository.getById(id);
}

/// Updates a relationship's metadata (cardinality, confidences, confirmation).
///
/// Endpoints are identity: changing them would silently repoint saved queries,
/// so a different pair must be created as a new relationship, not edited here.
class UpdateDatasetRelationshipUseCase {
  final DatasetRelationshipRepository repository;
  final DateTime Function() now;

  UpdateDatasetRelationshipUseCase({
    required this.repository,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;

  Future<DatasetRelationship> call(DatasetRelationship relationship) async {
    final id = relationship.id;
    if (id == null) {
      throw ArgumentError('Cannot update a relationship without an id');
    }
    final existing = await repository.getById(id);
    if (existing == null) {
      throw StateError('Relationship $id no longer exists');
    }
    if (existing.endpointKey != relationship.endpointKey) {
      throw ArgumentError(
        'Endpoints are immutable; create a new relationship instead',
      );
    }
    await repository.update(relationship);
    return relationship;
  }
}
