//lib/domain/repositories/saved_multi_sheet_query_repository.dart

import 'package:exlser/domain/entities/saved_multi_sheet_query.dart';

/// Persistence contract for saved multi-sheet join configurations.
abstract class SavedMultiSheetQueryRepository {
  /// Persists a new configuration and returns it with its generated id.
  Future<SavedMultiSheetQuery> create(SavedMultiSheetQuery query);

  /// Updates an existing configuration (must have a non-null id).
  Future<void> update(SavedMultiSheetQuery query);

  Future<SavedMultiSheetQuery?> getById(int id);

  /// All configurations of a dataset, most recently updated first.
  Future<List<SavedMultiSheetQuery>> listForDataset(int datasetId);

  Future<void> deleteById(int id);

  /// Removes every configuration owned by a dataset (used when the dataset is deleted).
  Future<void> deleteForDataset(int datasetId);
}
