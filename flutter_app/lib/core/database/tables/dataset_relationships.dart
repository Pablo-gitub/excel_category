import 'package:drift/drift.dart';
import 'datasets.dart';

/// Directional semantic relationships between columns of a dataset's sheets.
///
/// Dataset **metadata**, deliberately not a SQLite foreign key: imported sheets
/// may be dirty, so no physical constraint is imposed on the dynamic tables.
/// Endpoints are neutral A/B; [cardinality] is read A → B.
class DatasetRelationships extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Owning dataset. Rows are removed with the dataset at the application layer.
  IntColumn get datasetId => integer().references(Datasets, #id)();

  IntColumn get endpointATableId => integer()();
  TextColumn get endpointAColumnDbName => text()();
  IntColumn get endpointBTableId => integer()();
  TextColumn get endpointBColumnDbName => text()();

  /// `JoinCardinality` name (oneToOne / oneToMany / manyToOne / manyToMany / unknown).
  TextColumn get cardinality => text().withDefault(const Constant('unknown'))();

  /// 0..1 confidence that this is a real relationship.
  RealColumn get relationshipConfidence =>
      real().withDefault(const Constant(0))();

  /// 0..1 confidence in the estimated cardinality specifically.
  RealColumn get cardinalityConfidence =>
      real().withDefault(const Constant(0))();

  /// Rows sampled per side when estimating (0 when not estimated from data).
  IntColumn get sampleSize => integer().withDefault(const Constant(0))();

  /// `RelationshipOrigin` name (suggested / userDefined).
  TextColumn get origin => text().withDefault(const Constant('suggested'))();

  /// Unix ms when the user confirmed the relationship (null = unconfirmed).
  IntColumn get confirmedAt => integer().nullable()();

  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
}
