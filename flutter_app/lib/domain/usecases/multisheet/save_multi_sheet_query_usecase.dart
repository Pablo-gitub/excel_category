//lib/domain/usecases/multisheet/save_multi_sheet_query_usecase.dart

import 'package:exlser/domain/entities/saved_multi_sheet_query.dart';
import 'package:exlser/domain/repositories/saved_multi_sheet_query_repository.dart';
import 'package:exlser/domain/value_objects/multi_sheet_query_spec.dart';

/// Creates a new saved join configuration or updates an existing one.
///
/// Timestamps are managed here so callers never have to: `createdAt` is set on
/// the first save, `updatedAt` on every save. The clock is injectable for tests.
class SaveMultiSheetQueryUseCase {
  final SavedMultiSheetQueryRepository repository;
  final DateTime Function() now;

  SaveMultiSheetQueryUseCase({
    required this.repository,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;

  Future<SavedMultiSheetQuery> call({
    int? id,
    required int datasetId,
    required String name,
    required MultiSheetQuerySpec spec,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Saved query name cannot be empty');
    }
    if (datasetId <= 0) {
      throw ArgumentError('Dataset id must be greater than 0');
    }

    final timestamp = now();

    if (id == null) {
      return repository.create(
        SavedMultiSheetQuery(
          datasetId: datasetId,
          name: trimmedName,
          spec: spec,
          createdAt: timestamp,
          updatedAt: timestamp,
        ),
      );
    }

    final existing = await repository.getById(id);
    if (existing == null) {
      throw StateError('Saved query $id no longer exists');
    }

    final updated = existing.copyWith(
      name: trimmedName,
      spec: spec,
      updatedAt: timestamp,
    );
    await repository.update(updated);
    return updated;
  }
}
