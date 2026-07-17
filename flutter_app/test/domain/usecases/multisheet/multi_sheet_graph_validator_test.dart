import 'package:exlser/domain/entities/dataset_relationship.dart';
import 'package:exlser/domain/usecases/multisheet/multi_sheet_graph_validator.dart';
import 'package:exlser/domain/value_objects/multi_sheet_join.dart';
import 'package:exlser/domain/value_objects/multi_sheet_query_spec.dart';
import 'package:exlser/domain/value_objects/sheet_join_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const validator = MultiSheetGraphValidator();

  final available = {1, 2, 3};
  final columns = {
    1: {'id', 'name', 'product_id'},
    2: {'product', 'stock'},
    3: {'product', 'price'},
  };

  // Relationship registry keyed by id.
  DatasetRelationship rel(
    int id,
    int at,
    String ac,
    int bt,
    String bc,
  ) {
    return DatasetRelationship(
      id: id,
      datasetId: 1,
      endpointATableId: at,
      endpointAColumnDbName: ac,
      endpointBTableId: bt,
      endpointBColumnDbName: bc,
    );
  }

  final relationships = {
    10: rel(10, 1, 'product_id', 2, 'product'),
    20: rel(20, 2, 'product', 3, 'product'),
    30: rel(30, 3, 'product', 1, 'product_id'),
    // A stale relationship pointing at a missing column.
    40: rel(40, 1, 'gone', 2, 'product'),
  };

  MultiSheetJoin join(
    int relationshipId, {
    SheetJoinType type = SheetJoinType.inner,
  }) {
    return MultiSheetJoin(
      relationshipId: relationshipId,
      joinType: type,
    );
  }

  MultiSheetQuerySpec spec({
    int? base,
    required List<int> tables,
    required List<MultiSheetJoin> joins,
  }) {
    return MultiSheetQuerySpec(
      baseTableId: base,
      selectedTableIds: tables,
      joins: joins,
    );
  }

  ResolvedJoinPlan run(MultiSheetQuerySpec s) => validator.validate(
        datasetId: 1,
        spec: s,
        relationshipsById: relationships,
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
    final plan = run(spec(base: 1, tables: [1, 2], joins: [join(10)]));
    expect(plan.baseTableId, 1);
    expect(plan.orderedTableIds, [1, 2]);
    expect(plan.steps, hasLength(1));
    expect(plan.steps.first.existingTableId, 1);
    expect(plan.steps.first.newTableId, 2);
    expect(plan.steps.first.existingColumnDbName, 'product_id');
    expect(plan.steps.first.newColumnDbName, 'product');
  });

  test('valid three-table chain is ordered deterministically from base', () {
    final plan =
        run(spec(base: 1, tables: [1, 2, 3], joins: [join(10), join(20)]));
    expect(plan.orderedTableIds, [1, 2, 3]);
    expect(plan.steps.map((s) => s.newTableId), [2, 3]);
  });

  test('a LEFT join derives the preserved side from the rooted plan', () {
    final plan = run(spec(
      base: 1,
      tables: [1, 2],
      joins: [join(10, type: SheetJoinType.left)],
    ));
    expect(plan.steps.first.joinType, SheetJoinType.left);
    expect(plan.steps.first.existingTableId, 1);
  });

  test('LEFT preservation follows graph growth, not sheet selection order', () {
    final plan = run(spec(
      base: 1,
      tables: [1, 3, 2],
      joins: [
        join(10),
        join(20, type: SheetJoinType.left),
      ],
    ));

    final leftStep =
        plan.steps.singleWhere((step) => step.relationshipId == 20);
    expect(plan.orderedTableIds, [1, 2, 3]);
    expect(leftStep.existingTableId, 2);
    expect(leftStep.newTableId, 3);
  });

  test('changing the base recalculates the LEFT-preserved side', () {
    final plan = run(spec(
      base: 3,
      tables: [1, 3, 2],
      joins: [
        join(10),
        join(20, type: SheetJoinType.left),
      ],
    ));

    final leftStep =
        plan.steps.singleWhere((step) => step.relationshipId == 20);
    expect(plan.orderedTableIds, [3, 2, 1]);
    expect(leftStep.existingTableId, 3);
    expect(leftStep.newTableId, 2);
  });

  test('rejects fewer than two tables', () {
    expectCode(
      spec(tables: [1], joins: []),
      MultiSheetGraphValidator.notEnoughTablesCode,
    );
  });

  test('reports a missing relationship reference', () {
    expectCode(
      spec(base: 1, tables: [1, 2], joins: [join(999)]),
      MultiSheetGraphValidator.missingRelationshipCode,
    );
  });

  test('rejects a relationship owned by another dataset', () {
    final foreign = {
      10: const DatasetRelationship(
        id: 10,
        datasetId: 999, // not the opened dataset
        endpointATableId: 1,
        endpointAColumnDbName: 'product_id',
        endpointBTableId: 2,
        endpointBColumnDbName: 'product',
      ),
    };
    expect(
      () => validator.validate(
        datasetId: 1,
        spec: spec(base: 1, tables: [1, 2], joins: [join(10)]),
        relationshipsById: foreign,
        availableTableIds: available,
        availableColumnsByTableId: columns,
      ),
      throwsA(isA<MultiSheetGraphException>().having(
        (e) => e.code,
        'code',
        MultiSheetGraphValidator.foreignRelationshipCode,
      )),
    );
  });

  test('reports a stale relationship column', () {
    expectCode(
      spec(base: 1, tables: [1, 2], joins: [join(40)]),
      MultiSheetGraphValidator.unavailableTableOrColumnCode,
    );
  });

  test('rejects a disconnected graph', () {
    expectCode(
      spec(base: 1, tables: [1, 2], joins: []),
      MultiSheetGraphValidator.disconnectedGraphCode,
    );
  });

  test('rejects a cycle (three tables, three joins)', () {
    expectCode(
      spec(base: 1, tables: [1, 2, 3], joins: [join(10), join(20), join(30)]),
      MultiSheetGraphValidator.cycleDetectedCode,
    );
  });

  test('rejects a relationship whose endpoint is not selected', () {
    // join 20 connects tables 2 and 3, but 3 is not selected.
    expectCode(
      spec(base: 1, tables: [1, 2], joins: [join(10), join(20)]),
      MultiSheetGraphValidator.incompleteRelationshipCode,
    );
  });
}
