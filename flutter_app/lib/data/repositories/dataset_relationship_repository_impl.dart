//lib/data/repositories/dataset_relationship_repository_impl.dart

import 'package:drift/drift.dart';
import 'package:exlser/core/database/app_database.dart' as db;
import 'package:exlser/core/database/daos/dataset_relationships_dao.dart';
import 'package:exlser/domain/entities/dataset_relationship.dart';
import 'package:exlser/domain/repositories/dataset_relationship_repository.dart';
import 'package:exlser/domain/value_objects/join_cardinality.dart';

/// Drift-backed [DatasetRelationshipRepository].
///
/// The database import is prefixed `db` because Drift generates a row class also
/// named `DatasetRelationship`, which would clash with the domain entity.
class DatasetRelationshipRepositoryImpl
    implements DatasetRelationshipRepository {
  final DatasetRelationshipsDao dao;

  const DatasetRelationshipRepositoryImpl(this.dao);

  @override
  Future<DatasetRelationship> create(DatasetRelationship relationship) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final id = await dao.createRelationship(
      db.DatasetRelationshipsCompanion.insert(
        datasetId: relationship.datasetId,
        endpointATableId: relationship.endpointATableId,
        endpointAColumnDbName: relationship.endpointAColumnDbName,
        endpointBTableId: relationship.endpointBTableId,
        endpointBColumnDbName: relationship.endpointBColumnDbName,
        cardinality: Value(relationship.cardinality.name),
        relationshipConfidence: Value(relationship.relationshipConfidence),
        cardinalityConfidence: Value(relationship.cardinalityConfidence),
        sampleSize: Value(relationship.sampleSize),
        origin: Value(relationship.origin.name),
        confirmedAt: Value(relationship.confirmedAt?.millisecondsSinceEpoch),
        createdAt: nowMs,
        updatedAt: nowMs,
      ),
    );
    return relationship.copyWith(id: id);
  }

  @override
  Future<void> update(DatasetRelationship relationship) async {
    final id = relationship.id;
    if (id == null) {
      throw ArgumentError('Cannot update a relationship without an id');
    }
    await dao.updateRelationship(
      id,
      db.DatasetRelationshipsCompanion(
        cardinality: Value(relationship.cardinality.name),
        relationshipConfidence: Value(relationship.relationshipConfidence),
        cardinalityConfidence: Value(relationship.cardinalityConfidence),
        sampleSize: Value(relationship.sampleSize),
        origin: Value(relationship.origin.name),
        confirmedAt: Value(relationship.confirmedAt?.millisecondsSinceEpoch),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  @override
  Future<DatasetRelationship?> getById(int id) async {
    final row = await dao.getById(id);
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<List<DatasetRelationship>> listForDataset(int datasetId) async {
    final rows = await dao.getForDataset(datasetId);
    return rows.map(_toDomain).toList();
  }

  @override
  Future<void> deleteById(int id) => dao.deleteById(id);

  @override
  Future<void> deleteForDataset(int datasetId) =>
      dao.deleteForDataset(datasetId);

  DatasetRelationship _toDomain(db.DatasetRelationship row) {
    return DatasetRelationship(
      id: row.id,
      datasetId: row.datasetId,
      endpointATableId: row.endpointATableId,
      endpointAColumnDbName: row.endpointAColumnDbName,
      endpointBTableId: row.endpointBTableId,
      endpointBColumnDbName: row.endpointBColumnDbName,
      cardinality: JoinCardinality.fromName(row.cardinality),
      relationshipConfidence: row.relationshipConfidence,
      cardinalityConfidence: row.cardinalityConfidence,
      sampleSize: row.sampleSize,
      origin: RelationshipOrigin.fromName(row.origin),
      confirmedAt: row.confirmedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.confirmedAt!),
    );
  }
}
