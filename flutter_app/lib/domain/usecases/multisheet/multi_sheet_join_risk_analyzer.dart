//lib/domain/usecases/multisheet/multi_sheet_join_risk_analyzer.dart

import 'package:exlser/domain/usecases/multisheet/multi_sheet_graph_validator.dart';
import 'package:exlser/domain/usecases/multisheet/relationship_heuristics.dart';

/// A risk detected on a confirmed join, surfaced to the user before running.
class JoinRiskWarning {
  /// Neither joined column looks like a key, so rows may multiply (many-to-many).
  static const String manyToManyRiskCode = 'many_to_many_risk';

  final String code;
  final String leftSheetLabel;
  final String rightSheetLabel;

  const JoinRiskWarning({
    required this.code,
    required this.leftSheetLabel,
    required this.rightSheetLabel,
  });
}

/// Flags joins that can multiply rows, without touching the database.
///
/// Heuristic and intentionally cheap: if neither side of a join looks like an
/// identifier/business key, the join is likely many-to-many and the UI should
/// ask the user to confirm before running it.
class MultiSheetJoinRiskAnalyzer {
  const MultiSheetJoinRiskAnalyzer();

  List<JoinRiskWarning> analyze({
    required ResolvedJoinPlan plan,
    required Map<int, String> sheetLabelByTableId,
    required Map<int, Map<String, String>> originalColumnNamesByTableId,
  }) {
    final warnings = <JoinRiskWarning>[];

    for (final step in plan.steps) {
      final existingName = _originalName(
        originalColumnNamesByTableId,
        step.existingTableId,
        step.existingColumnDbName,
      );
      final newName = _originalName(
        originalColumnNamesByTableId,
        step.newTableId,
        step.newColumnDbName,
      );

      final existingIsKey =
          RelationshipHeuristics.isIdentifierName(existingName);
      final newIsKey = RelationshipHeuristics.isIdentifierName(newName);

      if (!existingIsKey && !newIsKey) {
        warnings.add(JoinRiskWarning(
          code: JoinRiskWarning.manyToManyRiskCode,
          leftSheetLabel: _label(sheetLabelByTableId, step.existingTableId),
          rightSheetLabel: _label(sheetLabelByTableId, step.newTableId),
        ));
      }
    }

    return warnings;
  }

  String _originalName(
    Map<int, Map<String, String>> originalColumnNamesByTableId,
    int tableId,
    String dbName,
  ) {
    return originalColumnNamesByTableId[tableId]?[dbName] ?? dbName;
  }

  String _label(Map<int, String> sheetLabelByTableId, int tableId) {
    return sheetLabelByTableId[tableId] ?? 'sheet$tableId';
  }
}
