import 'package:exlser/domain/usecases/multisheet/multi_sheet_graph_validator.dart';
import 'package:exlser/domain/value_objects/multi_sheet_query_spec.dart';
import 'package:exlser/domain/value_objects/sheet_join_relationship.dart';
import 'package:exlser/domain/value_objects/sheet_join_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const validator = MultiSheetGraphValidator();

  final available = {1, 2, 3};
  final columns = {
    1: {'id', 'name', 'product_id'},
    2: {'product', 'price'},
    3: {'product', 'stock'},
  };

  SheetJoinRelationship edge(
    int lt,
    String lc,
    int rt,
    String rc, [
    SheetJoinType type = SheetJoinType.inner,
  ]) {
    return SheetJoinRelationship(
      leftTableId: lt,
      leftColumnDbName: lc,
      rightTableId: rt,
      rightColumnDbName: rc,
      joinType: type,
    );
  }

  MultiSheetQuerySpec spec({
    int? base,
    required List<int> tables,
    required List<SheetJoinRelationship> relationships,
  }) {
    return MultiSheetQuerySpec(
      baseTableId: base,
      selectedTableIds: tables,
      relationships: relationships,
    );
  }

  ResolvedJoinPlan run(MultiSheetQuerySpec s) => validator.validate(
        spec: s,
        availableTableIds: available,
        availableColumnsByTableId: columns,
      );

  void expectCode(MultiSheetQuerySpec s, String code) {
    expect(
      () => run(s),
      throwsA(
          isA<MultiSheetGraphException>().having((e) => e.code, 'code', code)),
    );
  }

  test('valid two-table tree resolves to one oriented step', () {
    final plan = run(spec(
      base: 1,
      tables: [1, 2],
      relationships: [edge(1, 'product_id', 2, 'product')],
    ));
    expect(plan.baseTableId, 1);
    expect(plan.orderedTableIds, [1, 2]);
    expect(plan.steps, hasLength(1));
    expect(plan.steps.first.existingTableId, 1);
    expect(plan.steps.first.newTableId, 2);
  });

  test('valid three-table chain is ordered deterministically from base', () {
    final plan = run(spec(
      base: 1,
      tables: [1, 2, 3],
      relationships: [
        edge(1, 'product_id', 2, 'product'),
        edge(2, 'product', 3, 'product'),
      ],
    ));
    expect(plan.orderedTableIds, [1, 2, 3]);
    expect(plan.steps.map((s) => s.newTableId), [2, 3]);
  });

  test('orients LEFT join so the accumulated side is preserved', () {
    final plan = run(spec(
      base: 1,
      tables: [1, 2],
      relationships: [edge(1, 'product_id', 2, 'product', SheetJoinType.left)],
    ));
    expect(plan.steps.first.existingTableId, 1);
    expect(plan.steps.first.joinType, SheetJoinType.left);
  });

  test('rejects fewer than two tables', () {
    expectCode(
      spec(tables: [1], relationships: []),
      MultiSheetGraphValidator.notEnoughTablesCode,
    );
  });

  test('rejects a stale column that no longer exists', () {
    expectCode(
      spec(
        base: 1,
        tables: [1, 2],
        relationships: [edge(1, 'gone', 2, 'product')],
      ),
      MultiSheetGraphValidator.unavailableTableOrColumnCode,
    );
  });

  test('rejects a duplicate relationship (same pair, any direction)', () {
    expectCode(
      spec(
        base: 1,
        tables: [1, 2],
        relationships: [
          edge(1, 'product_id', 2, 'product'),
          edge(2, 'product', 1, 'product_id'),
        ],
      ),
      MultiSheetGraphValidator.duplicateRelationshipCode,
    );
  });

  test('rejects a disconnected graph', () {
    expectCode(
      spec(base: 1, tables: [1, 2], relationships: []),
      MultiSheetGraphValidator.disconnectedGraphCode,
    );
  });

  test('rejects a cycle', () {
    expectCode(
      spec(
        base: 1,
        tables: [1, 2, 3],
        relationships: [
          edge(1, 'product_id', 2, 'product'),
          edge(2, 'product', 3, 'product'),
          edge(3, 'product', 1, 'product_id'),
        ],
      ),
      MultiSheetGraphValidator.cycleDetectedCode,
    );
  });

  test('rejects a LEFT join whose preserved side is the newly added table', () {
    // base is 1; edge preserves table 2 (the new table) -> invalid direction.
    expectCode(
      spec(
        base: 1,
        tables: [1, 2],
        relationships: [
          edge(2, 'product', 1, 'product_id', SheetJoinType.left)
        ],
      ),
      MultiSheetGraphValidator.invalidLeftJoinDirectionCode,
    );
  });

  test('rejects a relationship referencing an unselected table', () {
    expectCode(
      spec(
        base: 1,
        tables: [1, 2],
        relationships: [edge(1, 'product_id', 3, 'product')],
      ),
      MultiSheetGraphValidator.incompleteRelationshipCode,
    );
  });
}
