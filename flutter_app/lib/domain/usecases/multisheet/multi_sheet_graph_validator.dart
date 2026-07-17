//lib/domain/usecases/multisheet/multi_sheet_graph_validator.dart

import 'package:exlser/domain/entities/dataset_relationship.dart';
import 'package:exlser/domain/value_objects/join_cardinality.dart';
import 'package:exlser/domain/value_objects/multi_sheet_query_spec.dart';
import 'package:exlser/domain/value_objects/sheet_join_type.dart';

/// Raised when a [MultiSheetQuerySpec] does not describe a valid join tree.
class MultiSheetGraphException implements Exception {
  final String code;

  const MultiSheetGraphException(this.code);

  @override
  String toString() => 'MultiSheetGraphException($code)';
}

/// One resolved join, already oriented so that [existingTableId] is the table
/// already accumulated in the FROM chain and [newTableId] is the one this step
/// adds on the right. For a [SheetJoinType.left] the preserved side is always
/// the accumulated (existing) side.
class ResolvedJoinStep {
  final int existingTableId;
  final String existingColumnDbName;
  final int newTableId;
  final String newColumnDbName;
  final SheetJoinType joinType;

  /// Id of the persisted relationship this step came from.
  final int relationshipId;

  /// Cardinality re-oriented to read existing → new, so a `oneToMany` here means
  /// the newly added side multiplies the accumulated rows. Derived from the
  /// relationship's persisted A → B cardinality; the risk analyzer must rely on
  /// this rather than re-inferring meaning from column names.
  final JoinCardinality cardinality;
  final double cardinalityConfidence;
  final int sampleSize;

  const ResolvedJoinStep({
    required this.existingTableId,
    required this.existingColumnDbName,
    required this.newTableId,
    required this.newColumnDbName,
    required this.joinType,
    required this.relationshipId,
    this.cardinality = JoinCardinality.unknown,
    this.cardinalityConfidence = 0,
    this.sampleSize = 0,
  });
}

/// A fully validated, deterministically ordered join plan ready for SQL generation.
class ResolvedJoinPlan {
  final int baseTableId;
  final List<int> orderedTableIds;
  final List<ResolvedJoinStep> steps;

  const ResolvedJoinPlan({
    required this.baseTableId,
    required this.orderedTableIds,
    required this.steps,
  });
}

/// Validates that a [MultiSheetQuerySpec] resolves against the dataset's
/// relationships into a connected, acyclic join tree over tables/columns that
/// still exist, and produces an ordered plan.
///
/// Pure domain logic, independent of the UI and of any database.
class MultiSheetGraphValidator {
  static const String notEnoughTablesCode = 'not_enough_tables';
  static const String unavailableTableOrColumnCode =
      'unavailable_table_or_column';
  static const String missingRelationshipCode = 'missing_relationship';
  static const String foreignRelationshipCode = 'foreign_relationship';
  static const String incompleteRelationshipCode = 'incomplete_relationship';
  static const String duplicateRelationshipCode = 'duplicate_relationship';
  static const String disconnectedGraphCode = 'disconnected_graph';
  static const String cycleDetectedCode = 'cycle_detected';
  static const String invalidLeftJoinDirectionCode =
      'invalid_left_join_direction';

  const MultiSheetGraphValidator();

  ResolvedJoinPlan validate({
    required int datasetId,
    required MultiSheetQuerySpec spec,
    required Map<int, DatasetRelationship> relationshipsById,
    required Set<int> availableTableIds,
    required Map<int, Set<String>> availableColumnsByTableId,
  }) {
    final selectedIds = spec.selectedTableIds;
    final selectedSet = selectedIds.toSet();

    if (selectedSet.length < 2) {
      throw const MultiSheetGraphException(notEnoughTablesCode);
    }

    // Stale check: every selected table and output column must still exist.
    for (final tableId in selectedSet) {
      if (!availableTableIds.contains(tableId)) {
        throw const MultiSheetGraphException(unavailableTableOrColumnCode);
      }
      final available = availableColumnsByTableId[tableId] ?? const {};
      for (final dbName in spec.columnsForTable(tableId)) {
        if (!available.contains(dbName)) {
          throw const MultiSheetGraphException(unavailableTableOrColumnCode);
        }
      }
    }

    final edges = _resolveEdges(
      datasetId: datasetId,
      spec: spec,
      relationshipsById: relationshipsById,
      selectedSet: selectedSet,
      availableColumnsByTableId: availableColumnsByTableId,
    );

    final baseTableId = selectedSet.contains(spec.baseTableId)
        ? spec.baseTableId!
        : selectedIds.first;

    final plan = _buildOrderedPlan(
      baseTableId: baseTableId,
      selectedIds: selectedIds,
      edges: edges,
    );

    // A connected tree over N nodes has exactly N-1 edges; any extra is a cycle.
    if (plan.orderedTableIds.length < selectedSet.length) {
      throw const MultiSheetGraphException(disconnectedGraphCode);
    }
    if (edges.length != selectedSet.length - 1) {
      throw const MultiSheetGraphException(cycleDetectedCode);
    }

    return plan;
  }

  /// Resolves every join into an endpoint edge, validating references, endpoints
  /// and duplicates (equivalent by unordered endpoint pair).
  List<_JoinEdge> _resolveEdges({
    required int datasetId,
    required MultiSheetQuerySpec spec,
    required Map<int, DatasetRelationship> relationshipsById,
    required Set<int> selectedSet,
    required Map<int, Set<String>> availableColumnsByTableId,
  }) {
    final edges = <_JoinEdge>[];
    final seenRelationshipIds = <int>{};
    final seenEndpointKeys = <String>{};

    for (final join in spec.joins) {
      final relationship = relationshipsById[join.relationshipId];
      if (relationship == null) {
        throw const MultiSheetGraphException(missingRelationshipCode);
      }
      // A saved query must never resolve a relationship owned by another dataset.
      if (relationship.datasetId != datasetId) {
        throw const MultiSheetGraphException(foreignRelationshipCode);
      }

      final a = relationship.endpointATableId;
      final b = relationship.endpointBTableId;
      if (a == b) {
        throw const MultiSheetGraphException(incompleteRelationshipCode);
      }
      if (!selectedSet.contains(a) || !selectedSet.contains(b)) {
        throw const MultiSheetGraphException(incompleteRelationshipCode);
      }
      if (!_columnExists(availableColumnsByTableId, a,
              relationship.endpointAColumnDbName) ||
          !_columnExists(availableColumnsByTableId, b,
              relationship.endpointBColumnDbName)) {
        throw const MultiSheetGraphException(unavailableTableOrColumnCode);
      }
      if (!seenRelationshipIds.add(join.relationshipId) ||
          !seenEndpointKeys.add(relationship.endpointKey)) {
        throw const MultiSheetGraphException(duplicateRelationshipCode);
      }

      edges.add(_JoinEdge(
        relationshipId: join.relationshipId,
        aTableId: a,
        aColumnDbName: relationship.endpointAColumnDbName,
        bTableId: b,
        bColumnDbName: relationship.endpointBColumnDbName,
        joinType: join.joinType,
        preservedTableId: join.preservedTableId,
        cardinality: relationship.cardinality,
        cardinalityConfidence: relationship.cardinalityConfidence,
        sampleSize: relationship.sampleSize,
      ));
    }

    return edges;
  }

  /// Greedily grows the tree from [baseTableId], adding the next selected table
  /// (in selection order) that connects to an already-included one, so the join
  /// order is deterministic.
  ResolvedJoinPlan _buildOrderedPlan({
    required int baseTableId,
    required List<int> selectedIds,
    required List<_JoinEdge> edges,
  }) {
    final included = <int>{baseTableId};
    final ordered = <int>[baseTableId];
    final steps = <ResolvedJoinStep>[];

    var progressed = true;
    while (progressed && included.length < selectedIds.length) {
      progressed = false;

      for (final candidate in selectedIds) {
        if (included.contains(candidate)) continue;

        final edge = _firstEdgeConnecting(edges, candidate, included);
        if (edge == null) continue;

        final existingIsEndpointA = included.contains(edge.aTableId);
        final existingTableId =
            existingIsEndpointA ? edge.aTableId : edge.bTableId;
        final existingColumn =
            existingIsEndpointA ? edge.aColumnDbName : edge.bColumnDbName;
        final newColumn =
            existingIsEndpointA ? edge.bColumnDbName : edge.aColumnDbName;
        // Relationship cardinality is stored A → B; re-orient it to existing → new.
        final orientedCardinality =
            existingIsEndpointA ? edge.cardinality : edge.cardinality.inverted;

        // A LEFT join must explicitly preserve the already-accumulated side.
        if (edge.joinType == SheetJoinType.left) {
          final preserved = edge.preservedTableId;
          if (preserved == null ||
              (preserved != edge.aTableId && preserved != edge.bTableId) ||
              preserved != existingTableId) {
            throw const MultiSheetGraphException(invalidLeftJoinDirectionCode);
          }
        }

        steps.add(ResolvedJoinStep(
          existingTableId: existingTableId,
          existingColumnDbName: existingColumn,
          newTableId: candidate,
          newColumnDbName: newColumn,
          joinType: edge.joinType,
          relationshipId: edge.relationshipId,
          cardinality: orientedCardinality,
          cardinalityConfidence: edge.cardinalityConfidence,
          sampleSize: edge.sampleSize,
        ));
        included.add(candidate);
        ordered.add(candidate);
        progressed = true;
        break;
      }
    }

    return ResolvedJoinPlan(
      baseTableId: baseTableId,
      orderedTableIds: ordered,
      steps: steps,
    );
  }

  _JoinEdge? _firstEdgeConnecting(
    List<_JoinEdge> edges,
    int candidate,
    Set<int> included,
  ) {
    for (final edge in edges) {
      if (!edge.connects(candidate)) continue;
      final other = edge.aTableId == candidate ? edge.bTableId : edge.aTableId;
      if (included.contains(other)) {
        return edge;
      }
    }
    return null;
  }

  bool _columnExists(
    Map<int, Set<String>> availableColumnsByTableId,
    int tableId,
    String dbName,
  ) {
    return (availableColumnsByTableId[tableId] ?? const {}).contains(dbName);
  }
}

/// A join resolved to concrete endpoints, internal to the validator.
class _JoinEdge {
  final int relationshipId;
  final int aTableId;
  final String aColumnDbName;
  final int bTableId;
  final String bColumnDbName;
  final SheetJoinType joinType;
  final int? preservedTableId;
  final JoinCardinality cardinality;
  final double cardinalityConfidence;
  final int sampleSize;

  const _JoinEdge({
    required this.relationshipId,
    required this.aTableId,
    required this.aColumnDbName,
    required this.bTableId,
    required this.bColumnDbName,
    required this.joinType,
    required this.preservedTableId,
    required this.cardinality,
    required this.cardinalityConfidence,
    required this.sampleSize,
  });

  bool connects(int tableId) => aTableId == tableId || bTableId == tableId;
}
