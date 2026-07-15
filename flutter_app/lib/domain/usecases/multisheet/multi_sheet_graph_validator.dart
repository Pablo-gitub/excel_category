//lib/domain/usecases/multisheet/multi_sheet_graph_validator.dart

import 'package:exlser/domain/value_objects/multi_sheet_query_spec.dart';
import 'package:exlser/domain/value_objects/sheet_join_relationship.dart';
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

  const ResolvedJoinStep({
    required this.existingTableId,
    required this.existingColumnDbName,
    required this.newTableId,
    required this.newColumnDbName,
    required this.joinType,
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

/// Validates that a [MultiSheetQuerySpec] is a connected, acyclic join tree over
/// tables/columns that still exist, and resolves it into an ordered plan.
///
/// Pure domain logic, independent of the UI and of any database.
class MultiSheetGraphValidator {
  static const String notEnoughTablesCode = 'not_enough_tables';
  static const String unavailableTableOrColumnCode =
      'unavailable_table_or_column';
  static const String incompleteRelationshipCode = 'incomplete_relationship';
  static const String duplicateRelationshipCode = 'duplicate_relationship';
  static const String disconnectedGraphCode = 'disconnected_graph';
  static const String cycleDetectedCode = 'cycle_detected';
  static const String invalidLeftJoinDirectionCode =
      'invalid_left_join_direction';

  const MultiSheetGraphValidator();

  ResolvedJoinPlan validate({
    required MultiSheetQuerySpec spec,
    required Set<int> availableTableIds,
    required Map<int, Set<String>> availableColumnsByTableId,
  }) {
    final selectedIds = spec.selectedTableIds;
    final selectedSet = selectedIds.toSet();

    if (selectedSet.length < 2) {
      throw const MultiSheetGraphException(notEnoughTablesCode);
    }

    // Stale check: every selected table and column must still exist.
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

    // Relationship validity + duplicate detection.
    final seenIds = <String>{};
    for (final relationship in spec.relationships) {
      if (relationship.leftTableId == relationship.rightTableId) {
        throw const MultiSheetGraphException(incompleteRelationshipCode);
      }
      if (!selectedSet.contains(relationship.leftTableId) ||
          !selectedSet.contains(relationship.rightTableId)) {
        throw const MultiSheetGraphException(incompleteRelationshipCode);
      }
      if (!_columnExists(availableColumnsByTableId, relationship.leftTableId,
              relationship.leftColumnDbName) ||
          !_columnExists(availableColumnsByTableId, relationship.rightTableId,
              relationship.rightColumnDbName)) {
        throw const MultiSheetGraphException(unavailableTableOrColumnCode);
      }
      if (!seenIds.add(relationship.effectiveId)) {
        throw const MultiSheetGraphException(duplicateRelationshipCode);
      }
    }

    final baseTableId = selectedSet.contains(spec.baseTableId)
        ? spec.baseTableId!
        : selectedIds.first;

    final plan = _buildOrderedPlan(
      baseTableId: baseTableId,
      selectedIds: selectedIds,
      relationships: spec.relationships,
    );

    // Connected tree over N nodes has exactly N-1 edges; any extra edge is a cycle.
    if (plan.orderedTableIds.length < selectedSet.length) {
      throw const MultiSheetGraphException(disconnectedGraphCode);
    }
    if (spec.relationships.length != selectedSet.length - 1) {
      throw const MultiSheetGraphException(cycleDetectedCode);
    }

    return plan;
  }

  /// Greedily grows the tree from [baseTableId], adding the next selected table
  /// (in selection order) that connects to an already-included table. This makes
  /// the join order deterministic for a given spec.
  ResolvedJoinPlan _buildOrderedPlan({
    required int baseTableId,
    required List<int> selectedIds,
    required List<SheetJoinRelationship> relationships,
  }) {
    final included = <int>{baseTableId};
    final ordered = <int>[baseTableId];
    final steps = <ResolvedJoinStep>[];

    var progressed = true;
    while (progressed && included.length < selectedIds.length) {
      progressed = false;

      for (final candidate in selectedIds) {
        if (included.contains(candidate)) continue;

        final edge = _firstEdgeConnecting(relationships, candidate, included);
        if (edge == null) continue;

        final existingTableId =
            included.contains(edge.leftTableId) ? edge.leftTableId : edge.rightTableId;
        final existingColumn = existingTableId == edge.leftTableId
            ? edge.leftColumnDbName
            : edge.rightColumnDbName;
        final newColumn = existingTableId == edge.leftTableId
            ? edge.rightColumnDbName
            : edge.leftColumnDbName;

        // A LEFT join must preserve the already-accumulated side.
        if (edge.joinType == SheetJoinType.left &&
            edge.leftTableId != existingTableId) {
          throw const MultiSheetGraphException(invalidLeftJoinDirectionCode);
        }

        steps.add(ResolvedJoinStep(
          existingTableId: existingTableId,
          existingColumnDbName: existingColumn,
          newTableId: candidate,
          newColumnDbName: newColumn,
          joinType: edge.joinType,
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

  SheetJoinRelationship? _firstEdgeConnecting(
    List<SheetJoinRelationship> relationships,
    int candidate,
    Set<int> included,
  ) {
    for (final relationship in relationships) {
      if (!relationship.connects(candidate)) continue;
      final other = relationship.leftTableId == candidate
          ? relationship.rightTableId
          : relationship.leftTableId;
      if (included.contains(other)) {
        return relationship;
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
