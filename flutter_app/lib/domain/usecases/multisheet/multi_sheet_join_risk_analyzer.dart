//lib/domain/usecases/multisheet/multi_sheet_join_risk_analyzer.dart

import 'package:exlser/domain/usecases/multisheet/multi_sheet_graph_validator.dart';
import 'package:exlser/domain/value_objects/column_relationship_sample.dart';
import 'package:exlser/domain/value_objects/join_cardinality.dart';

/// A risk detected on a confirmed join, surfaced to the user before running.
class JoinRiskWarning {
  /// Both sides have duplicates, so the join multiplies rows (many-to-many).
  static const String manyToManyRiskCode = 'many_to_many_risk';

  /// Cardinality could not be estimated from data, so multiplication is unknown.
  static const String unknownCardinalityRiskCode = 'unknown_cardinality_risk';

  /// Cardinality was estimated from too little / truncated data to trust.
  static const String lowCardinalityConfidenceRiskCode =
      'low_cardinality_confidence_risk';

  final String code;
  final int relationshipId;
  final String leftSheetLabel;
  final String rightSheetLabel;

  const JoinRiskWarning({
    required this.code,
    required this.relationshipId,
    required this.leftSheetLabel,
    required this.rightSheetLabel,
  });
}

/// Flags joins that can multiply rows or whose cardinality is not trustworthy,
/// **from persisted cardinality evidence** — never from column names.
///
/// Reads [ResolvedJoinStep.cardinality] / `cardinalityConfidence` / `sampleSize`
/// (already oriented existing → new by the validator) and emits at most one
/// primary cardinality warning per join, by deterministic precedence.
class MultiSheetJoinRiskAnalyzer {
  /// Below this the sampled cardinality estimate is treated as untrustworthy.
  static const double minCardinalityConfidence = 0.6;

  const MultiSheetJoinRiskAnalyzer();

  List<JoinRiskWarning> analyze({
    required ResolvedJoinPlan plan,
    required Map<int, String> sheetLabelByTableId,
  }) {
    final warnings = <JoinRiskWarning>[];

    for (final step in plan.steps) {
      final code = _codeFor(step);
      if (code == null) continue;
      warnings.add(JoinRiskWarning(
        code: code,
        relationshipId: step.relationshipId,
        leftSheetLabel: _label(sheetLabelByTableId, step.existingTableId),
        rightSheetLabel: _label(sheetLabelByTableId, step.newTableId),
      ));
    }

    return warnings;
  }

  /// Deterministic precedence: many-to-many, then unknown, then low confidence.
  String? _codeFor(ResolvedJoinStep step) {
    if (step.cardinality == JoinCardinality.manyToMany) {
      return JoinRiskWarning.manyToManyRiskCode;
    }
    if (step.cardinality == JoinCardinality.unknown) {
      return JoinRiskWarning.unknownCardinalityRiskCode;
    }
    if (step.cardinalityConfidence < minCardinalityConfidence ||
        step.sampleSize < ColumnRelationshipSample.minEvidence) {
      return JoinRiskWarning.lowCardinalityConfidenceRiskCode;
    }
    return null;
  }

  String _label(Map<int, String> sheetLabelByTableId, int tableId) {
    return sheetLabelByTableId[tableId] ?? 'sheet$tableId';
  }
}
