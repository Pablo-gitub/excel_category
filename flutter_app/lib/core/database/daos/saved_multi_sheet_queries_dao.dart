import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/saved_multi_sheet_queries.dart';

part 'saved_multi_sheet_queries_dao.g.dart';

/// Data Access Object for [SavedMultiSheetQueries].
///
/// Pure database access (no business logic): insert, update, read, list, delete.
@DriftAccessor(tables: [SavedMultiSheetQueries])
class SavedMultiSheetQueriesDao extends DatabaseAccessor<AppDatabase>
    with _$SavedMultiSheetQueriesDaoMixin {
  SavedMultiSheetQueriesDao(super.db);

  Future<int> createQuery(SavedMultiSheetQueriesCompanion entry) {
    return into(savedMultiSheetQueries).insert(entry);
  }

  Future<bool> updateQuery(SavedMultiSheetQueriesCompanion entry) {
    return update(savedMultiSheetQueries).replace(entry);
  }

  Future<SavedMultiSheetQuery?> getById(int id) {
    return (select(savedMultiSheetQueries)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<List<SavedMultiSheetQuery>> getForDataset(int datasetId) {
    return (select(savedMultiSheetQueries)
          ..where((t) => t.datasetId.equals(datasetId))
          ..orderBy([
            (t) => OrderingTerm(
                  expression: t.updatedAt,
                  mode: OrderingMode.desc,
                ),
          ]))
        .get();
  }

  Future<int> deleteById(int id) {
    return (delete(savedMultiSheetQueries)..where((t) => t.id.equals(id))).go();
  }

  Future<int> deleteForDataset(int datasetId) {
    return (delete(savedMultiSheetQueries)
          ..where((t) => t.datasetId.equals(datasetId)))
        .go();
  }
}
