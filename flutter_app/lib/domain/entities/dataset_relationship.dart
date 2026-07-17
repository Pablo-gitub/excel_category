//lib/domain/entities/dataset_relationship.dart

import 'package:exlser/domain/value_objects/join_cardinality.dart';

/// Where a relationship came from.
enum RelationshipOrigin {
  suggested,
  userDefined;

  static RelationshipOrigin fromName(Object? value) {
    return value?.toString().trim() == 'userDefined'
        ? RelationshipOrigin.userDefined
        : RelationshipOrigin.suggested;
  }
}

/// A directional semantic relationship between two columns of a dataset's sheets.
///
/// This is dataset **metadata**, not a SQLite foreign key: imported sheets can be
/// dirty, duplicated or have missing references, so we never impose a physical
/// constraint that could block an import. Endpoints are neutral A/B and the
/// [cardinality] is read A → B (e.g. `manyToOne` = A is the many side).
///
/// Two relationships are equivalent when they connect the same unordered pair of
/// endpoints, regardless of A/B order (see [endpointKey]); the domain rejects
/// duplicates on that basis.
class DatasetRelationship {
  /// Null until persisted.
  final int? id;
  final int datasetId;

  final int endpointATableId;
  final String endpointAColumnDbName;
  final int endpointBTableId;
  final String endpointBColumnDbName;

  /// Estimated relation of rows, read A → B.
  final JoinCardinality cardinality;

  /// 0..1 — confidence that this is a real relationship (names, types, overlap).
  final double relationshipConfidence;

  /// 0..1 — confidence in the estimated [cardinality] specifically.
  final double cardinalityConfidence;

  /// Rows sampled per side when estimating; 0 when not estimated from data.
  final int sampleSize;

  final RelationshipOrigin origin;

  /// Set once the user has confirmed the relationship.
  final DateTime? confirmedAt;

  const DatasetRelationship({
    this.id,
    required this.datasetId,
    required this.endpointATableId,
    required this.endpointAColumnDbName,
    required this.endpointBTableId,
    required this.endpointBColumnDbName,
    this.cardinality = JoinCardinality.unknown,
    this.relationshipConfidence = 0,
    this.cardinalityConfidence = 0,
    this.sampleSize = 0,
    this.origin = RelationshipOrigin.suggested,
    this.confirmedAt,
  });

  /// True when neither side is unique — an associative link, risky to join.
  bool get isAssociative => cardinality.isAssociative;

  bool get isConfirmed => confirmedAt != null;

  Set<int> get tableIds => {endpointATableId, endpointBTableId};

  bool involvesTable(int tableId) =>
      endpointATableId == tableId || endpointBTableId == tableId;

  bool involvesColumn(int tableId, String dbName) =>
      (endpointATableId == tableId && endpointAColumnDbName == dbName) ||
      (endpointBTableId == tableId && endpointBColumnDbName == dbName);

  /// Order-independent identity of the endpoint pair, used to reject duplicates
  /// (A↔B swapped counts as the same relationship).
  String get endpointKey {
    final a = '$endpointATableId.${endpointAColumnDbName.trim()}';
    final b = '$endpointBTableId.${endpointBColumnDbName.trim()}';
    final ends = [a, b]..sort();
    return ends.join('=');
  }

  DatasetRelationship copyWith({
    int? id,
    int? datasetId,
    int? endpointATableId,
    String? endpointAColumnDbName,
    int? endpointBTableId,
    String? endpointBColumnDbName,
    JoinCardinality? cardinality,
    double? relationshipConfidence,
    double? cardinalityConfidence,
    int? sampleSize,
    RelationshipOrigin? origin,
    DateTime? confirmedAt,
  }) {
    return DatasetRelationship(
      id: id ?? this.id,
      datasetId: datasetId ?? this.datasetId,
      endpointATableId: endpointATableId ?? this.endpointATableId,
      endpointAColumnDbName:
          endpointAColumnDbName ?? this.endpointAColumnDbName,
      endpointBTableId: endpointBTableId ?? this.endpointBTableId,
      endpointBColumnDbName:
          endpointBColumnDbName ?? this.endpointBColumnDbName,
      cardinality: cardinality ?? this.cardinality,
      relationshipConfidence:
          relationshipConfidence ?? this.relationshipConfidence,
      cardinalityConfidence:
          cardinalityConfidence ?? this.cardinalityConfidence,
      sampleSize: sampleSize ?? this.sampleSize,
      origin: origin ?? this.origin,
      confirmedAt: confirmedAt ?? this.confirmedAt,
    );
  }
}
