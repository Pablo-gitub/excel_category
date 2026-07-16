//lib/domain/usecases/multisheet/manage_multi_sheet_queries_usecases.dart

import 'package:exlser/domain/entities/saved_multi_sheet_query.dart';
import 'package:exlser/domain/repositories/saved_multi_sheet_query_repository.dart';

/// Lists every saved join configuration of a dataset, most recent first.
class ListMultiSheetQueriesUseCase {
  final SavedMultiSheetQueryRepository repository;

  const ListMultiSheetQueriesUseCase({required this.repository});

  Future<List<SavedMultiSheetQuery>> call(int datasetId) {
    if (datasetId <= 0) {
      throw ArgumentError('Dataset id must be greater than 0');
    }
    return repository.listForDataset(datasetId);
  }
}

/// Loads a single saved join configuration.
///
/// The returned spec still has to be validated against the current schema by
/// `MultiSheetGraphValidator`, which reports stale table/column references.
class LoadMultiSheetQueryUseCase {
  final SavedMultiSheetQueryRepository repository;

  const LoadMultiSheetQueryUseCase({required this.repository});

  Future<SavedMultiSheetQuery?> call(int id) {
    if (id <= 0) {
      throw ArgumentError('Saved query id must be greater than 0');
    }
    return repository.getById(id);
  }
}

/// Deletes a saved join configuration.
class DeleteMultiSheetQueryUseCase {
  final SavedMultiSheetQueryRepository repository;

  const DeleteMultiSheetQueryUseCase({required this.repository});

  Future<void> call(int id) {
    if (id <= 0) {
      throw ArgumentError('Saved query id must be greater than 0');
    }
    return repository.deleteById(id);
  }
}
