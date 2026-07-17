// Integration tests for guided multi-sheet joins against a real in-memory Drift
// database: the SQL the builder generates must actually run and return the rows
// SQLite really produces for INNER / LEFT / 1-N / M-N joins.
import 'package:drift/native.dart';
import 'package:exlser/application/services/multi_sheet_analysis_service.dart';
import 'package:exlser/core/database/app_database.dart'
    hide DatasetColumn, DatasetTable, DatasetRelationship, SavedMultiSheetQuery;
import 'package:exlser/core/database/daos/dataset_relationships_dao.dart';
import 'package:exlser/core/database/daos/datasets_dao.dart';
import 'package:exlser/core/database/daos/saved_multi_sheet_queries_dao.dart';
import 'package:exlser/data/datasources/drift_datasource.dart';
import 'package:exlser/data/repositories/dataset_relationship_repository_impl.dart';
import 'package:exlser/data/repositories/query_repository_impl.dart';
import 'package:exlser/data/repositories/saved_multi_sheet_query_repository_impl.dart';
import 'package:exlser/data/repositories/schema_repository_impl.dart';
import 'package:exlser/data/schema/dynamic_table_builder.dart';
import 'package:exlser/domain/entities/dataset_column.dart';
import 'package:exlser/domain/entities/dataset_relationship.dart';
import 'package:exlser/domain/entities/dataset_table.dart';
import 'package:exlser/domain/usecases/multisheet/execute_multi_sheet_preview_usecase.dart';
import 'package:exlser/domain/usecases/multisheet/manage_dataset_relationships_usecases.dart';
import 'package:exlser/domain/usecases/multisheet/multi_sheet_graph_validator.dart';
import 'package:exlser/domain/value_objects/join_cardinality.dart';
import 'package:exlser/domain/usecases/multisheet/manage_multi_sheet_queries_usecases.dart';
import 'package:exlser/domain/usecases/multisheet/save_multi_sheet_query_usecase.dart';
import 'package:exlser/domain/value_objects/column_type.dart';
import 'package:exlser/domain/value_objects/multi_sheet_join.dart';
import 'package:exlser/domain/value_objects/multi_sheet_query_spec.dart';
import 'package:exlser/domain/value_objects/sheet_join_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late MultiSheetAnalysisService service;
  late SchemaRepositoryImpl schemaRepository;
  late QueryRepositoryImpl queryRepository;
  late DatasetRelationshipRepositoryImpl relationshipRepository;
  late int datasetId;
  late int salesTableId;
  late int productsTableId;
  late int defaultRelationshipId;

  DatasetColumn column(String name, ColumnType type, {int tableId = 0}) {
    return DatasetColumn(
      id: 0,
      datasetTableId: tableId,
      originalName: name,
      dbName: name,
      declaredType: type,
      inferredType: type,
      nullable: true,
    );
  }

  Future<int> createSheet({
    required String sheetName,
    required String sqlTableName,
    required List<DatasetColumn> columns,
    required List<Map<String, dynamic>> rows,
  }) async {
    final table = await schemaRepository.createDatasetTable(
      DatasetTable(
        id: 0,
        datasetId: datasetId,
        sheetNameOriginal: sheetName,
        sqlTableName: sqlTableName,
        rowCount: rows.length,
        colCount: columns.length,
      ),
    );
    final owned = [
      for (final c in columns) c.copyWith(datasetTableId: table.id),
    ];
    await schemaRepository.createColumns(owned);
    await schemaRepository.createDynamicTable(sqlTableName, owned);
    if (rows.isNotEmpty) {
      await queryRepository.insertBatch(tableName: sqlTableName, rows: rows);
    }
    return table.id;
  }

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    final datasource = DriftDatasource(database);
    schemaRepository = SchemaRepositoryImpl(datasource, DynamicTableBuilder());
    queryRepository = QueryRepositoryImpl(datasource);
    final savedRepository = SavedMultiSheetQueryRepositoryImpl(
      SavedMultiSheetQueriesDao(database),
    );
    relationshipRepository = DatasetRelationshipRepositoryImpl(
      DatasetRelationshipsDao(database),
    );

    service = MultiSheetAnalysisService(
      schemaRepository: schemaRepository,
      queryRepository: queryRepository,
      executePreview:
          ExecuteMultiSheetPreviewUseCase(repository: queryRepository),
      saveQueryUseCase: SaveMultiSheetQueryUseCase(repository: savedRepository),
      listQueriesUseCase:
          ListMultiSheetQueriesUseCase(repository: savedRepository),
      loadQueryUseCase: LoadMultiSheetQueryUseCase(repository: savedRepository),
      deleteQueryUseCase:
          DeleteMultiSheetQueryUseCase(repository: savedRepository),
      createRelationshipUseCase: CreateDatasetRelationshipUseCase(
        repository: relationshipRepository,
      ),
      listRelationshipsUseCase: ListDatasetRelationshipsUseCase(
        repository: relationshipRepository,
      ),
      updateRelationshipUseCase: UpdateDatasetRelationshipUseCase(
        repository: relationshipRepository,
      ),
    );

    datasetId = await DatasetsDao(database).createDataset(
      name: 'ds',
      sourceFileName: 'file.xlsx',
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    // Sales has an unmatched product (A9) and a null key, Products has an
    // orphan (A3). A1 appears twice in Sales -> one-to-many.
    salesTableId = await createSheet(
      sheetName: 'Sales',
      sqlTableName: 'sales_t',
      columns: [
        column('product_id', ColumnType.text),
        column('qty', ColumnType.integer),
      ],
      rows: const [
        {'product_id': 'A1', 'qty': 1},
        {'product_id': 'A1', 'qty': 2},
        {'product_id': 'A2', 'qty': 3},
        {'product_id': 'A9', 'qty': 4},
        {'product_id': null, 'qty': 5},
      ],
    );

    productsTableId = await createSheet(
      sheetName: 'Products',
      sqlTableName: 'products_t',
      columns: [
        column('product', ColumnType.text),
        column('price', ColumnType.integer),
      ],
      rows: const [
        {'product': 'A1', 'price': 10},
        {'product': 'A2', 'price': 20},
        {'product': 'A3', 'price': 30},
      ],
    );

    // The default join (sales.product_id -> products.product) is a persisted
    // relationship; the saved query references it by id.
    defaultRelationshipId = (await service.createRelationship(
      DatasetRelationship(
        datasetId: datasetId,
        endpointATableId: salesTableId,
        endpointAColumnDbName: 'product_id',
        endpointBTableId: productsTableId,
        endpointBColumnDbName: 'product',
      ),
    ))
        .id!;
  });

  tearDown(() async => database.close());

  Future<int> makeRelationship({
    required int leftTableId,
    required String leftColumn,
    required int rightTableId,
    required String rightColumn,
  }) async {
    final created = await service.createRelationship(
      DatasetRelationship(
        datasetId: datasetId,
        endpointATableId: leftTableId,
        endpointAColumnDbName: leftColumn,
        endpointBTableId: rightTableId,
        endpointBColumnDbName: rightColumn,
      ),
    );
    return created.id!;
  }

  Future<Map<int, DatasetRelationship>> relMap() async {
    final rels = await service.loadRelationships(datasetId);
    return {for (final r in rels) r.id!: r};
  }

  MultiSheetQuerySpec spec({
    SheetJoinType joinType = SheetJoinType.inner,
    int limit = 100,
    int? relationshipId,
  }) {
    return MultiSheetQuerySpec(
      baseTableId: salesTableId,
      selectedTableIds: [salesTableId, productsTableId],
      selectedColumnsByTableId: {
        salesTableId: const ['product_id', 'qty'],
        productsTableId: const ['product', 'price'],
      },
      joins: [
        MultiSheetJoin(
          relationshipId: relationshipId ?? defaultRelationshipId,
          joinType: joinType,
          // A LEFT join preserves the accumulated base side (sales).
          preservedTableId:
              joinType == SheetJoinType.left ? salesTableId : null,
        ),
      ],
      resultLimit: limit,
    );
  }

  Future<MultiSheetPreviewResult> run(MultiSheetQuerySpec s) async {
    final sheets = await service.loadSheets(datasetId);
    return service.runPreview(
      datasetId: datasetId,
      spec: s,
      sheets: sheets,
      relationshipsById: await relMap(),
    );
  }

  test('INNER JOIN returns only matching rows, dropping unmatched and nulls',
      () async {
    final result = await run(spec());

    // A1 twice + A2 once. A9 and the null key are excluded; A3 has no sale.
    expect(result.rows, hasLength(3));
    final ids = result.rows.map((r) => r['t0__product_id']).toList();
    expect(ids, ['A1', 'A1', 'A2']);
    expect(result.rows.first['t1__price'], 10);
  });

  test('LEFT JOIN keeps every base row and nulls the unmatched side', () async {
    final result = await run(spec(joinType: SheetJoinType.left));

    // All 5 sales rows survive, including A9 and the null key.
    expect(result.rows, hasLength(5));
    final unmatched =
        result.rows.where((r) => r['t0__product_id'] == 'A9').single;
    expect(unmatched['t1__product'], isNull,
        reason: 'unmatched right side must be null, not dropped');
    final nullKey =
        result.rows.where((r) => r['t0__product_id'] == null).single;
    expect(nullKey['t1__price'], isNull);
  });

  test('one-to-many multiplies the base row once per match', () async {
    final result = await run(spec());
    final a1 = result.rows.where((r) => r['t0__product_id'] == 'A1');
    expect(a1, hasLength(2), reason: 'A1 has two sales rows');
    expect(a1.map((r) => r['t0__qty']).toSet(), {1, 2});
  });

  test('a join with no matches returns zero rows but keeps its headers',
      () async {
    // Join on unrelated columns: qty never equals price here.
    final rid = await makeRelationship(
      leftTableId: salesTableId,
      leftColumn: 'qty',
      rightTableId: productsTableId,
      rightColumn: 'price',
    );
    final result = await run(spec(relationshipId: rid));

    expect(result.rows, isEmpty);
    expect(result.isEmpty, isTrue);
    expect(
      result.outputColumns.map((c) => c.alias),
      ['t0__product_id', 't0__qty', 't1__product', 't1__price'],
      reason: 'headers come from the query, not from the rows',
    );
  });

  test('many-to-many multiplies rows and is flagged as risky', () async {
    // Give both sheets a repeated, non-key column to join on.
    final tagsTableId = await createSheet(
      sheetName: 'Tags',
      sqlTableName: 'tags_t',
      columns: [column('qty', ColumnType.integer)],
      rows: const [
        {'qty': 1},
        {'qty': 1},
      ],
    );

    final rid = await makeRelationship(
      leftTableId: salesTableId,
      leftColumn: 'qty',
      rightTableId: tagsTableId,
      rightColumn: 'qty',
    );
    final sheets = await service.loadSheets(datasetId);
    final manyToMany = MultiSheetQuerySpec(
      baseTableId: salesTableId,
      selectedTableIds: [salesTableId, tagsTableId],
      selectedColumnsByTableId: {
        salesTableId: const ['qty'],
        tagsTableId: const ['qty'],
      },
      joins: [MultiSheetJoin(relationshipId: rid)],
    );

    final result = await service.runPreview(
      datasetId: datasetId,
      spec: manyToMany,
      sheets: sheets,
      relationshipsById: await relMap(),
    );

    // qty=1 appears once in Sales and twice in Tags -> 2 rows.
    expect(result.rows, hasLength(2));
    expect(result.warnings, isNotEmpty,
        reason: 'neither side is a key, so the join must be flagged');
  });

  test('the result limit is really applied by SQLite', () async {
    final result = await run(spec(joinType: SheetJoinType.left, limit: 2));

    expect(result.rows, hasLength(2));
    expect(result.isTruncated, isTrue);
  });

  test('the preview reports no total count (no full COUNT(*))', () async {
    final result = await run(spec());

    // The contract is an isTruncated flag instead of an expensive total.
    expect(result.executedSql, isNot(contains('COUNT')));
    expect(result.isTruncated, isFalse);
  });

  test('a saved spec round-trips and still runs after reloading', () async {
    final saved = await service.saveQuery(
      datasetId: datasetId,
      name: 'sales x products',
      spec: spec(joinType: SheetJoinType.left),
    );

    final reloaded = await service.loadSavedQuery(saved.id!);
    expect(reloaded, isNotNull);

    final sheets = await service.loadSheets(datasetId);
    final result = await service.runPreview(
      datasetId: datasetId,
      spec: reloaded!.spec,
      sheets: sheets,
      relationshipsById: await relMap(),
    );

    expect(result.rows, hasLength(5));
  });

  test('estimates cardinality from real sampled data, duplicates retained',
      () async {
    final sheets = await service.loadSheets(datasetId);
    final suggestions = await service.suggestRelationships(
      sheets: sheets,
      selectedTableIds: [salesTableId, productsTableId],
    );

    final s = suggestions.firstWhere(
      (s) =>
          s.relationship.leftColumnDbName == 'product_id' &&
          s.relationship.rightColumnDbName == 'product',
    );

    // Sales.product_id repeats A1 and has a NULL; Products.product is unique.
    // A DISTINCT sample would make product_id look unique (one-to-one); getting
    // many-to-one proves duplicates were retained and the NULL was excluded.
    expect(s.cardinality, JoinCardinality.manyToOne);
    expect(s.sampleSize, greaterThan(0));
    expect(s.cardinalityConfidence, greaterThan(0));
  });

  test('a relationship owned by another dataset is rejected', () async {
    final otherDatasetId = await DatasetsDao(database).createDataset(
      name: 'other',
      sourceFileName: 'other.xlsx',
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    // Same endpoints, but the relationship belongs to a different dataset.
    final foreign = await service.createRelationship(
      DatasetRelationship(
        datasetId: otherDatasetId,
        endpointATableId: salesTableId,
        endpointAColumnDbName: 'product_id',
        endpointBTableId: productsTableId,
        endpointBColumnDbName: 'product',
      ),
    );
    final sheets = await service.loadSheets(datasetId);

    expect(
      () => service.runPreview(
        datasetId: datasetId,
        spec: spec(relationshipId: foreign.id!),
        sheets: sheets,
        relationshipsById: {foreign.id!: foreign},
      ),
      throwsA(isA<MultiSheetGraphException>().having(
        (e) => e.code,
        'code',
        MultiSheetGraphValidator.foreignRelationshipCode,
      )),
    );
  });
}
