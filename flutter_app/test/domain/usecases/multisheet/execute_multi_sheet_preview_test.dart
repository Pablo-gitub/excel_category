import 'package:exlser/domain/repositories/query_repository.dart';
import 'package:exlser/domain/usecases/multisheet/execute_multi_sheet_preview_usecase.dart';
import 'package:exlser/domain/usecases/multisheet/multi_sheet_graph_validator.dart';
import 'package:exlser/domain/usecases/multisheet/multi_sheet_join_risk_analyzer.dart';
import 'package:exlser/domain/usecases/multisheet/multi_sheet_sql_builder.dart';
import 'package:exlser/domain/usecases/query/read_only_sql_validator.dart';
import 'package:exlser/domain/value_objects/multi_sheet_query_spec.dart';
import 'package:exlser/domain/value_objects/sheet_join_relationship.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockQueryRepository extends Mock implements QueryRepository {}

void main() {
  const graphValidator = MultiSheetGraphValidator();
  const builder = MultiSheetSqlBuilder();

  final availableTables = {1, 2};
  final availableColumns = {
    1: {'product_id', 'qty'},
    2: {'product', 'price'},
  };
  final sqlTableNames = {1: 'sales_table', 2: 'products_table'};
  final sheetLabels = {1: 'Vendite', 2: 'Prodotti'};

  // product_id / product read as identifiers -> no many-to-many warning.
  final keyNames = {
    1: {'product_id': 'Product ID', 'qty': 'Qty'},
    2: {'product': 'Product', 'price': 'Price'},
  };
  // qty / price are plain measures -> many-to-many risk.
  final measureNames = {
    1: {'qty': 'Qty', 'product_id': 'Product ID'},
    2: {'price': 'Price', 'product': 'Product'},
  };

  MultiSheetQuerySpec specJoining(String leftCol, String rightCol) {
    return MultiSheetQuerySpec(
      baseTableId: 1,
      selectedTableIds: const [1, 2],
      selectedColumnsByTableId: const {
        1: ['product_id'],
        2: ['product'],
      },
      relationships: [
        SheetJoinRelationship(
          leftTableId: 1,
          leftColumnDbName: leftCol,
          rightTableId: 2,
          rightColumnDbName: rightCol,
        ),
      ],
      resultLimit: 2,
    );
  }

  ResolvedJoinPlan planFor(MultiSheetQuerySpec spec) => graphValidator.validate(
        spec: spec,
        availableTableIds: availableTables,
        availableColumnsByTableId: availableColumns,
      );

  GeneratedMultiSheetQuery generate(
    MultiSheetQuerySpec spec,
    Map<int, Map<String, String>> names,
  ) {
    return builder.build(
      plan: planFor(spec),
      spec: spec,
      sqlTableNameByTableId: sqlTableNames,
      sheetLabelByTableId: sheetLabels,
      originalColumnNamesByTableId: names,
    );
  }

  group('MultiSheetJoinRiskAnalyzer', () {
    const analyzer = MultiSheetJoinRiskAnalyzer();

    test('flags a join where neither side looks like a key', () {
      final warnings = analyzer.analyze(
        plan: planFor(specJoining('qty', 'price')),
        sheetLabelByTableId: sheetLabels,
        originalColumnNamesByTableId: measureNames,
      );
      expect(warnings, hasLength(1));
      expect(warnings.first.code, JoinRiskWarning.manyToManyRiskCode);
      expect(warnings.first.leftSheetLabel, 'Vendite');
      expect(warnings.first.rightSheetLabel, 'Prodotti');
    });

    test('does not flag a join on an identifier column', () {
      final warnings = analyzer.analyze(
        plan: planFor(specJoining('product_id', 'product')),
        sheetLabelByTableId: sheetLabels,
        originalColumnNamesByTableId: keyNames,
      );
      expect(warnings, isEmpty);
    });
  });

  group('ExecuteMultiSheetPreviewUseCase', () {
    late MockQueryRepository repository;
    late ExecuteMultiSheetPreviewUseCase useCase;

    setUp(() {
      repository = MockQueryRepository();
      useCase = ExecuteMultiSheetPreviewUseCase(repository: repository);
    });

    test('runs exactly one query — never a full COUNT', () async {
      when(() => repository.executeRawQuery(any(), any()))
          .thenAnswer((_) async => [
                {'t0__product_id': 'A1', 't1__product': 'A1'},
              ]);

      await useCase(
        generated: generate(specJoining('product_id', 'product'), keyNames),
        baseSqlTableName: 'sales_table',
        allowedTableNames: {'sales_table', 'products_table'},
        limit: 2,
      );

      verify(() => repository.executeRawQuery(any(), any())).called(1);
    });

    test('keeps headers when the join returns no rows', () async {
      when(() => repository.executeRawQuery(any(), any()))
          .thenAnswer((_) async => []);

      final result = await useCase(
        generated: generate(specJoining('product_id', 'product'), keyNames),
        baseSqlTableName: 'sales_table',
        allowedTableNames: {'sales_table', 'products_table'},
        limit: 2,
      );

      expect(result.isEmpty, isTrue);
      expect(result.outputColumns.map((c) => c.alias),
          ['t0__product_id', 't1__product']);
      expect(result.displayLabelsByAlias['t1__product'], 'Prodotti.Product');
      expect(result.isTruncated, isFalse);
    });

    test('marks the result as truncated when it hits the limit', () async {
      when(() => repository.executeRawQuery(any(), any()))
          .thenAnswer((_) async => [
                {'t0__product_id': 'A1'},
                {'t0__product_id': 'A2'},
              ]);

      final result = await useCase(
        generated: generate(specJoining('product_id', 'product'), keyNames),
        baseSqlTableName: 'sales_table',
        allowedTableNames: {'sales_table', 'products_table'},
        limit: 2,
      );

      expect(result.isTruncated, isTrue);
    });

    test('propagates join risk warnings to the preview result', () async {
      when(() => repository.executeRawQuery(any(), any()))
          .thenAnswer((_) async => []);

      final result = await useCase(
        generated: generate(specJoining('qty', 'price'), measureNames),
        baseSqlTableName: 'sales_table',
        allowedTableNames: {'sales_table', 'products_table'},
        limit: 2,
      );

      expect(result.warnings, hasLength(1));
      expect(result.warnings.first.code, JoinRiskWarning.manyToManyRiskCode);
    });

    test('rejects a query referencing a table outside the dataset', () async {
      final generated =
          generate(specJoining('product_id', 'product'), keyNames);
      expect(
        () => useCase(
          generated: generated,
          baseSqlTableName: 'sales_table',
          allowedTableNames: {'sales_table'}, // products_table missing
          limit: 2,
        ),
        throwsA(isA<ReadOnlyQueryException>()),
      );
    });
  });
}
