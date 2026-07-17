import 'package:exlser/domain/entities/dataset_relationship.dart';
import 'package:exlser/domain/usecases/multisheet/multi_sheet_graph_validator.dart';
import 'package:exlser/domain/usecases/multisheet/multi_sheet_sql_builder.dart';
import 'package:exlser/domain/usecases/query/read_only_sql_validator.dart';
import 'package:exlser/domain/value_objects/multi_sheet_join.dart';
import 'package:exlser/domain/value_objects/multi_sheet_query_spec.dart';
import 'package:exlser/domain/value_objects/sheet_join_type.dart';
import 'package:flutter_test/flutter_test.dart';

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
  final originalNames = {
    1: {'product_id': 'Product ID', 'qty': 'Qty'},
    2: {'product': 'Product', 'price': 'Price'},
  };

  final relationships = {
    10: const DatasetRelationship(
      id: 10,
      datasetId: 1,
      endpointATableId: 1,
      endpointAColumnDbName: 'product_id',
      endpointBTableId: 2,
      endpointBColumnDbName: 'product',
    ),
  };

  GeneratedMultiSheetQuery buildFor(MultiSheetQuerySpec spec) {
    final plan = graphValidator.validate(
      spec: spec,
      relationshipsById: relationships,
      availableTableIds: availableTables,
      availableColumnsByTableId: availableColumns,
    );
    return builder.build(
      plan: plan,
      spec: spec,
      sqlTableNameByTableId: sqlTableNames,
      sheetLabelByTableId: sheetLabels,
      originalColumnNamesByTableId: originalNames,
    );
  }

  MultiSheetQuerySpec baseSpec({
    SheetJoinType type = SheetJoinType.inner,
    int? preserved,
    Map<int, List<String>>? columns,
  }) {
    return MultiSheetQuerySpec(
      baseTableId: 1,
      selectedTableIds: const [1, 2],
      selectedColumnsByTableId: columns ??
          const {
            1: ['product_id', 'qty'],
            2: ['product', 'price'],
          },
      joins: [
        MultiSheetJoin(
          relationshipId: 10,
          joinType: type,
          preservedTableId: preserved,
        ),
      ],
      resultLimit: 100,
    );
  }

  test('generates a deterministic inner join with quoted aliased columns', () {
    final generated = buildFor(baseSpec());
    expect(
      generated.sql,
      'SELECT t0."product_id" AS "t0__product_id", '
      't0."qty" AS "t0__qty", '
      't1."product" AS "t1__product", '
      't1."price" AS "t1__price"'
      ' FROM "sales_table" t0'
      ' INNER JOIN "products_table" t1 '
      'ON t0."product_id" = t1."product"'
      ' LIMIT 100',
    );
  });

  test('uses the LEFT JOIN keyword for left joins', () {
    final generated =
        buildFor(baseSpec(type: SheetJoinType.left, preserved: 1));
    expect(generated.sql, contains(' LEFT JOIN "products_table" t1 '));
  });

  test('exposes output columns and display labels even before running', () {
    final generated = buildFor(baseSpec());
    expect(generated.outputColumns.map((c) => c.alias), [
      't0__product_id',
      't0__qty',
      't1__product',
      't1__price',
    ]);
    expect(
      generated.displayLabelsByAlias['t0__product_id'],
      'Vendite.Product ID',
    );
    expect(generated.displayLabelsByAlias['t1__price'], 'Prodotti.Price');
  });

  test('generated SQL is accepted by ReadOnlySqlValidator', () {
    final generated = buildFor(baseSpec());
    const validator = ReadOnlySqlValidator();
    final validation = validator.validate(
      sql: generated.sql,
      activeTableName: 'sales_table',
      allowedTableNames: {'sales_table', 'products_table'},
      limit: 100,
    );
    expect(validation.executableSql, contains('sales_table'));
    expect(validation.executableSql, contains('products_table'));
  });

  test('throws when no output columns are selected', () {
    expect(
      () => buildFor(baseSpec(columns: const {1: [], 2: []})),
      throwsA(isA<MultiSheetSqlBuilderException>().having(
        (e) => e.code,
        'code',
        MultiSheetSqlBuilder.noOutputColumnsCode,
      )),
    );
  });
}
