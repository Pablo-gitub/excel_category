import 'dart:async';

import 'package:exlser/application/services/multi_sheet_analysis_service.dart';
import 'package:exlser/domain/entities/dataset_column.dart';
import 'package:exlser/domain/entities/dataset_relationship.dart';
import 'package:exlser/domain/entities/dataset_table.dart';
import 'package:exlser/domain/entities/saved_multi_sheet_query.dart';
import 'package:exlser/domain/usecases/multisheet/execute_multi_sheet_preview_usecase.dart';
import 'package:exlser/domain/usecases/multisheet/multi_sheet_graph_validator.dart';
import 'package:exlser/domain/usecases/multisheet/multi_sheet_sql_builder.dart';
import 'package:exlser/domain/value_objects/column_type.dart';
import 'package:exlser/domain/value_objects/multi_sheet_join.dart';
import 'package:exlser/domain/value_objects/multi_sheet_query_spec.dart';
import 'package:exlser/presentation/views/sheet_joins/multi_sheet_join_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockService extends Mock implements MultiSheetAnalysisService {}

DatasetColumn col(String dbName, {int tableId = 1}) => DatasetColumn(
      id: dbName.hashCode,
      datasetTableId: tableId,
      originalName: dbName,
      dbName: dbName,
      declaredType: ColumnType.text,
      inferredType: ColumnType.text,
      nullable: true,
    );

MultiSheetSheetInfo sheet(int id, String name, List<String> columns) {
  return MultiSheetSheetInfo(
    table: DatasetTable(
      id: id,
      datasetId: 1,
      sheetNameOriginal: name,
      sqlTableName: 'tbl_$id',
      rowCount: 10,
      colCount: columns.length,
    ),
    columns: [for (final c in columns) col(c, tableId: id)],
  );
}

void main() {
  late MockService service;
  late MultiSheetJoinController controller;

  final sales = sheet(1, 'Vendite', ['product_id', 'qty']);
  final products = sheet(2, 'Prodotti', ['product', 'price']);

  final preview = MultiSheetPreviewResult(
    rows: const [
      {'t0__product_id': 'A1'}
    ],
    outputColumns: const [],
    displayLabelsByAlias: const {},
    warnings: const [],
    executedSql: 'SELECT 1',
    limit: 100,
  );

  // Adds the sales.product_id <-> products.product relationship as a user would.
  Future<void> addProductRelationship({bool flipped = false}) {
    return controller.addManualRelationship(
      leftTableId: flipped ? 2 : 1,
      leftColumnDbName: flipped ? 'product' : 'product_id',
      rightTableId: flipped ? 1 : 2,
      rightColumnDbName: flipped ? 'product_id' : 'product',
    );
  }

  setUpAll(() {
    registerFallbackValue(const MultiSheetQuerySpec());
    registerFallbackValue(const DatasetRelationship(
      datasetId: 0,
      endpointATableId: 0,
      endpointAColumnDbName: '',
      endpointBTableId: 0,
      endpointBColumnDbName: '',
    ));
  });

  setUp(() {
    service = MockService();
    when(() => service.loadSheets(any()))
        .thenAnswer((_) async => [sales, products]);
    when(() => service.listSavedQueries(any())).thenAnswer((_) async => []);
    when(() => service.loadRelationships(any())).thenAnswer((_) async => []);

    // Persisting assigns an incrementing id, as the real repository would.
    var nextId = 0;
    when(() => service.createRelationship(any())).thenAnswer((inv) async {
      final r = inv.positionalArguments.first as DatasetRelationship;
      return r.copyWith(id: ++nextId);
    });

    controller = MultiSheetJoinController(service: service, datasetId: 1);
  });

  tearDown(() => controller.dispose());

  test('load() moves to editing with sheets and saved queries', () async {
    await controller.load();

    expect(controller.state.status, MultiSheetJoinStatus.editing);
    expect(controller.state.sheets, hasLength(2));
    expect(controller.state.canConfigure, isTrue);
  });

  test('toggleSheet selects the sheet and auto-selects a capped column set',
      () async {
    await controller.load();
    controller.toggleSheet(1);

    expect(controller.state.spec.selectedTableIds, [1]);
    expect(controller.state.spec.columnsForTable(1), ['product_id', 'qty']);
    expect(controller.state.spec.baseTableId, 1);
    expect(
      controller.state.spec.columnsForTable(1).length,
      lessThanOrEqualTo(MultiSheetJoinController.maxAutoSelectedColumns),
    );
  });

  test('a confirmed manual relationship is persisted and referenced by id',
      () async {
    await controller.load();
    controller.toggleSheet(1);
    controller.toggleSheet(2);
    await addProductRelationship();

    expect(controller.state.spec.joins, hasLength(1));
    final relationshipId = controller.state.spec.joins.first.relationshipId;
    expect(relationshipId, greaterThan(0));
    // The persisted relationship is now resolvable from state.
    expect(controller.state.relationshipsById[relationshipId], isNotNull);
    verify(() => service.createRelationship(any())).called(1);
  });

  test('deselecting a sheet drops joins that referenced it', () async {
    await controller.load();
    controller.toggleSheet(1);
    controller.toggleSheet(2);
    await addProductRelationship();
    expect(controller.state.spec.joins, hasLength(1));

    controller.toggleSheet(2);

    expect(controller.state.spec.joins, isEmpty);
  });

  test('rejects a duplicate relationship with a validation error', () async {
    await controller.load();
    controller.toggleSheet(1);
    controller.toggleSheet(2);
    await addProductRelationship();
    await addProductRelationship(flipped: true); // same endpoints, swapped

    expect(controller.state.status, MultiSheetJoinStatus.validationError);
    expect(
      controller.state.errorCode,
      MultiSheetGraphValidator.duplicateRelationshipCode,
    );
    expect(controller.state.spec.joins, hasLength(1));
    verify(() => service.createRelationship(any())).called(1);
  });

  test('surfaces a validation error code when the graph is invalid', () async {
    when(() => service.buildQuery(
          datasetId: any(named: 'datasetId'),
          spec: any(named: 'spec'),
          sheets: any(named: 'sheets'),
          relationshipsById: any(named: 'relationshipsById'),
        )).thenThrow(
      const MultiSheetGraphException(
          MultiSheetGraphValidator.disconnectedGraphCode),
    );

    await controller.load();
    controller.toggleSheet(1);
    controller.toggleSheet(2);
    await controller.runPreview();

    expect(controller.state.status, MultiSheetJoinStatus.validationError);
    expect(
      controller.state.errorCode,
      MultiSheetGraphValidator.disconnectedGraphCode,
    );
  });

  test('runPreview succeeds and exposes the preview', () async {
    when(() => service.buildQuery(
          datasetId: any(named: 'datasetId'),
          spec: any(named: 'spec'),
          sheets: any(named: 'sheets'),
          relationshipsById: any(named: 'relationshipsById'),
        )).thenReturn(const GeneratedMultiSheetQuery(
      sql: 'SELECT 1',
      outputColumns: [],
      displayLabelsByAlias: {},
    ));
    when(() => service.runPreview(
          datasetId: any(named: 'datasetId'),
          spec: any(named: 'spec'),
          sheets: any(named: 'sheets'),
          relationshipsById: any(named: 'relationshipsById'),
        )).thenAnswer((_) async => preview);

    await controller.load();
    controller.toggleSheet(1);
    controller.toggleSheet(2);
    await addProductRelationship();
    await controller.runPreview();

    expect(controller.state.status, MultiSheetJoinStatus.success);
    expect(controller.state.preview, isNotNull);
  });

  test('ignores the result of a superseded run', () async {
    when(() => service.buildQuery(
          datasetId: any(named: 'datasetId'),
          spec: any(named: 'spec'),
          sheets: any(named: 'sheets'),
          relationshipsById: any(named: 'relationshipsById'),
        )).thenReturn(const GeneratedMultiSheetQuery(
      sql: 'SELECT 1',
      outputColumns: [],
      displayLabelsByAlias: {},
    ));

    final slow = Completer<MultiSheetPreviewResult>();
    var call = 0;
    when(() => service.runPreview(
          datasetId: any(named: 'datasetId'),
          spec: any(named: 'spec'),
          sheets: any(named: 'sheets'),
          relationshipsById: any(named: 'relationshipsById'),
        )).thenAnswer((_) {
      call++;
      return call == 1 ? slow.future : Future.value(preview);
    });

    await controller.load();
    controller.toggleSheet(1);
    controller.toggleSheet(2);
    await addProductRelationship();

    final first = controller.runPreview(); // stays pending
    await controller.runPreview(); // supersedes it
    expect(controller.state.status, MultiSheetJoinStatus.success);

    // The stale run finishing must not overwrite the newer state.
    slow.complete(MultiSheetPreviewResult(
      rows: const [],
      outputColumns: const [],
      displayLabelsByAlias: const {},
      warnings: const [],
      executedSql: 'STALE',
      limit: 100,
    ));
    await first;

    expect(
      controller.state.preview!.executedSql,
      preview.executedSql,
      reason: 'the stale run must not overwrite the newer preview',
    );
    expect(controller.state.status, MultiSheetJoinStatus.success);
  });

  test('flags a saved spec that references a missing column as stale',
      () async {
    final saved = SavedMultiSheetQuery(
      id: 7,
      datasetId: 1,
      name: 'old',
      spec: MultiSheetQuerySpec(
        baseTableId: 1,
        selectedTableIds: const [1, 2],
        joins: [MultiSheetJoin(relationshipId: 99)],
      ),
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    when(() => service.loadSavedQuery(7)).thenAnswer((_) async => saved);
    when(() => service.buildQuery(
          datasetId: any(named: 'datasetId'),
          spec: any(named: 'spec'),
          sheets: any(named: 'sheets'),
          relationshipsById: any(named: 'relationshipsById'),
        )).thenThrow(
      const MultiSheetGraphException(
          MultiSheetGraphValidator.unavailableTableOrColumnCode),
    );

    await controller.load();
    await controller.loadSaved(7);

    expect(controller.state.status, MultiSheetJoinStatus.staleSpec);
    expect(
      controller.state.errorCode,
      MultiSheetGraphValidator.unavailableTableOrColumnCode,
    );
    expect(controller.state.activeSavedQueryId, 7);
  });

  test('deselecting the last sheet clears the stale base table id', () async {
    await controller.load();
    controller.toggleSheet(1);
    expect(controller.state.spec.baseTableId, 1);

    controller.toggleSheet(1); // deselect the only sheet

    expect(controller.state.spec.selectedTableIds, isEmpty);
    expect(controller.state.spec.baseTableId, isNull);
  });

  test('refuses to save an unsupported spec and stays stale', () async {
    final saved = SavedMultiSheetQuery(
      id: 3,
      datasetId: 1,
      name: 'legacy',
      spec: const MultiSheetQuerySpec.unsupported(1),
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    when(() => service.loadSavedQuery(3)).thenAnswer((_) async => saved);

    await controller.load();
    await controller.loadSaved(3);
    expect(controller.state.status, MultiSheetJoinStatus.staleSpec);

    await controller.save('anything');

    expect(controller.state.status, MultiSheetJoinStatus.staleSpec);
    verifyNever(() => service.saveQuery(
          id: any(named: 'id'),
          datasetId: any(named: 'datasetId'),
          name: any(named: 'name'),
          spec: any(named: 'spec'),
        ));
  });

  test('startNewConfiguration resets to a clean editable v2 spec', () async {
    final saved = SavedMultiSheetQuery(
      id: 3,
      datasetId: 1,
      name: 'legacy',
      spec: const MultiSheetQuerySpec.unsupported(1),
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    when(() => service.loadSavedQuery(3)).thenAnswer((_) async => saved);

    await controller.load();
    await controller.loadSaved(3);

    controller.startNewConfiguration();

    expect(controller.state.spec.unsupportedVersion, isFalse);
    expect(controller.state.spec.isEmpty, isTrue);
    expect(controller.state.activeSavedQueryId, isNull);
    expect(controller.state.status, MultiSheetJoinStatus.editing);
  });
}
