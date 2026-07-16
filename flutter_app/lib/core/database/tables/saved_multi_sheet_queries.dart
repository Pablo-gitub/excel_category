import 'package:drift/drift.dart';
import 'datasets.dart';

/// A saved guided multi-sheet join configuration.
///
/// This is a reusable application entity (not UI state): several configurations
/// can belong to the same dataset. [specificationJson] holds a serialized
/// `MultiSheetQuerySpec` — only stable table ids and column `dbName`s, join
/// relationships, join types and output columns — so it survives restarts and
/// can be re-validated against the current schema when loaded.
class SavedMultiSheetQueries extends Table {
  /// Primary key.
  IntColumn get id => integer().autoIncrement()();

  /// Foreign key to the owning dataset. Rows are removed together with the
  /// dataset at the application layer (see DeleteDatasetUseCase).
  IntColumn get datasetId => integer().references(Datasets, #id)();

  /// User-facing name of the saved configuration.
  TextColumn get name => text()();

  /// Base table (FROM root) of the join tree, when set.
  IntColumn get baseTableId => integer().nullable()();

  /// Serialized `MultiSheetQuerySpec`.
  TextColumn get specificationJson => text()();

  /// Version of the specification JSON shape.
  IntColumn get schemaVersion => integer().withDefault(const Constant(1))();

  /// Unix timestamp (milliseconds) when created.
  IntColumn get createdAt => integer()();

  /// Unix timestamp (milliseconds) when last updated.
  IntColumn get updatedAt => integer()();
}
