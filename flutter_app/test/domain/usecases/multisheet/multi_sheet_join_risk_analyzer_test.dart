import 'package:exlser/domain/usecases/multisheet/multi_sheet_graph_validator.dart';
import 'package:exlser/domain/usecases/multisheet/multi_sheet_join_risk_analyzer.dart';
import 'package:exlser/domain/value_objects/join_cardinality.dart';
import 'package:exlser/domain/value_objects/sheet_join_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const analyzer = MultiSheetJoinRiskAnalyzer();
  final labels = {1: 'Sales', 2: 'Products'};

  ResolvedJoinPlan planWith({
    required JoinCardinality cardinality,
    double cardinalityConfidence = 1.0,
    int sampleSize = 100,
    String existingColumn = 'id',
    String newColumn = 'id',
  }) {
    return ResolvedJoinPlan(
      baseTableId: 1,
      orderedTableIds: const [1, 2],
      steps: [
        ResolvedJoinStep(
          existingTableId: 1,
          existingColumnDbName: existingColumn,
          newTableId: 2,
          newColumnDbName: newColumn,
          joinType: SheetJoinType.inner,
          relationshipId: 7,
          cardinality: cardinality,
          cardinalityConfidence: cardinalityConfidence,
          sampleSize: sampleSize,
        ),
      ],
    );
  }

  List<JoinRiskWarning> analyze(ResolvedJoinPlan plan) =>
      analyzer.analyze(plan: plan, sheetLabelByTableId: labels);

  test('many-to-many warns even when both columns are named id', () {
    final warnings = analyze(planWith(cardinality: JoinCardinality.manyToMany));
    expect(warnings, hasLength(1));
    expect(warnings.first.code, JoinRiskWarning.manyToManyRiskCode);
  });

  test('one-to-many with adequate confidence does not warn', () {
    final warnings = analyze(planWith(cardinality: JoinCardinality.oneToMany));
    expect(warnings, isEmpty);
  });

  test('one-to-one with adequate confidence does not warn', () {
    final warnings = analyze(planWith(cardinality: JoinCardinality.oneToOne));
    expect(warnings, isEmpty);
  });

  test('unknown cardinality warns', () {
    final warnings = analyze(planWith(
      cardinality: JoinCardinality.unknown,
      cardinalityConfidence: 0,
      sampleSize: 0,
    ));
    expect(warnings, hasLength(1));
    expect(warnings.first.code, JoinRiskWarning.unknownCardinalityRiskCode);
  });

  test('a low-confidence sampled estimate warns', () {
    final warnings = analyze(planWith(
      cardinality: JoinCardinality.manyToOne,
      cardinalityConfidence: 0.5, // below the 0.6 threshold
    ));
    expect(warnings, hasLength(1));
    expect(
        warnings.first.code, JoinRiskWarning.lowCardinalityConfidenceRiskCode);
  });

  test('too small a sample warns even at high nominal confidence', () {
    final warnings = analyze(planWith(
      cardinality: JoinCardinality.manyToOne,
      cardinalityConfidence: 1.0,
      sampleSize: 1, // below minEvidence
    ));
    expect(warnings, hasLength(1));
    expect(
        warnings.first.code, JoinRiskWarning.lowCardinalityConfidenceRiskCode);
  });

  test('orientation inversion keeps many-to-many risky', () {
    final direct = analyze(planWith(cardinality: JoinCardinality.manyToMany));
    // manyToMany.inverted == manyToMany, so risk is orientation-independent.
    final inverted =
        analyze(planWith(cardinality: JoinCardinality.manyToMany.inverted));
    expect(direct.first.code, JoinRiskWarning.manyToManyRiskCode);
    expect(inverted.first.code, JoinRiskWarning.manyToManyRiskCode);
  });

  test('the warning carries the relationship id and sheet labels', () {
    final warnings = analyze(planWith(cardinality: JoinCardinality.manyToMany));
    expect(warnings.first.relationshipId, 7);
    expect(warnings.first.leftSheetLabel, 'Sales');
    expect(warnings.first.rightSheetLabel, 'Products');
  });
}
