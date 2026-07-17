import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/dataset_relationships.dart';

part 'dataset_relationships_dao.g.dart';

/// Data Access Object for [DatasetRelationships]. Pure database access.
@DriftAccessor(tables: [DatasetRelationships])
class DatasetRelationshipsDao extends DatabaseAccessor<AppDatabase>
    with _$DatasetRelationshipsDaoMixin {
  DatasetRelationshipsDao(super.db);

  Future<int> createRelationship(DatasetRelationshipsCompanion entry) {
    return into(datasetRelationships).insert(entry);
  }

  /// Writes the mutable fields of a relationship. Uses `write` rather than
  /// `replace` so immutable columns (e.g. createdAt) need not be re-supplied.
  Future<int> updateRelationship(
    int id,
    DatasetRelationshipsCompanion entry,
  ) {
    return (update(datasetRelationships)..where((t) => t.id.equals(id)))
        .write(entry);
  }

  Future<DatasetRelationship?> getById(int id) {
    return (select(datasetRelationships)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<List<DatasetRelationship>> getForDataset(int datasetId) {
    return (select(datasetRelationships)
          ..where((t) => t.datasetId.equals(datasetId))
          ..orderBy([
            (t) => OrderingTerm(
                  expression: t.createdAt,
                  mode: OrderingMode.asc,
                ),
          ]))
        .get();
  }

  Future<int> deleteById(int id) {
    return (delete(datasetRelationships)..where((t) => t.id.equals(id))).go();
  }

  Future<int> deleteForDataset(int datasetId) {
    return (delete(datasetRelationships)
          ..where((t) => t.datasetId.equals(datasetId)))
        .go();
  }
}
