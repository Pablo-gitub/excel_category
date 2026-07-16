import 'dart:async';

import 'package:exlser/application/services/multi_sheet_analysis_service.dart';
import 'package:exlser/domain/entities/dataset_column.dart';
import 'package:exlser/domain/entities/dataset_table.dart';
import 'package:exlser/domain/entities/saved_multi_sheet_query.dart';
import 'package:exlser/domain/usecases/multisheet/execute_multi_sheet_preview_usecase.dart';
import 'package:exlser/domain/usecases/multisheet/multi_sheet_graph_validator.dart';
import 'package:exlser/domain/usecases/multisheet/multi_sheet_sql_builder.dart';
import 'package:exlser/domain/value_objects/column_type.dart';
import 'package:exlser/domain/value_objects/multi_sheet_query_spec.dart';
import 'package:exlser/domain/value_objects/sheet_join_relationship.dart';
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

  const relationship = SheetJoinRelationship(
    leftTableId: 1,
    leftColumnDbName: 'product_id',
    rightTableId: 2,
    rightColumnDbName: 'product',
  );

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

  setUpAll(() {
    registerFallbackValue(const MultiSheetQuerySpec());
  });

  setUp(() {
    service = MockService();
    when(() => service.loadSheets(any()))
        .thenAnswer((_) async => [sales, products]);
    when(() => service.listSavedQueries(any())).thenAnswer((_) async => []);
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

  test('deselecting a sheet drops relationships that referenced it', () async {
    await controller.load();
    controller.toggleSheet(1);
    controller.toggleSheet(2);
    controller.addRelationship(relationship);
    expect(controller.state.spec.relationships, hasLength(1));

    controller.toggleSheet(2);

    expect(controller.state.spec.relationships, isEmpty);
  });

  test('rejects a duplicate relationship with a validation error', () async {
    await controller.load();
    controller.toggleSheet(1);
    controller.toggleSheet(2);
    controller.addRelationship(relationship);
    controller.addRelationship(relationship.flipped());

    expect(controller.state.status, MultiSheetJoinStatus.validationError);
    expect(
      controller.state.errorCode,
      MultiSheetGraphValidator.duplicateRelationshipCode,
    );
    expect(controller.state.spec.relationships, hasLength(1));
  });

  test('surfaces a validation error code when the graph is invalid', () async {
    when(() => service.buildQuery(
          spec: any(named: 'spec'),
          sheets: any(named: 'sheets'),
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
          spec: any(named: 'spec'),
          sheets: any(named: 'sheets'),
        )).thenReturn(const GeneratedMultiSheetQuery(
      sql: 'SELECT 1',
      outputColumns: [],
      displayLabelsByAlias: {},
    ));
    when(() => service.runPreview(
          spec: any(named: 'spec'),
          sheets: any(named: 'sheets'),
        )).thenAnswer((_) async => preview);

    await controller.load();
    controller.toggleSheet(1);
    controller.toggleSheet(2);
    controller.addRelationship(relationship);
    await controller.runPreview();

    expect(controller.state.status, MultiSheetJoinStatus.success);
    expect(controller.state.preview, isNotNull);
  });

  test('ignores the result of a superseded run', () async {
    when(() => service.buildQuery(
          spec: any(named: 'spec'),
          sheets: any(named: 'sheets'),
        )).thenReturn(const GeneratedMultiSheetQuery(
      sql: 'SELECT 1',
      outputColumns: [],
      displayLabelsByAlias: {},
    ));

    final slow = Completer<MultiSheetPreviewResult>();
    var call = 0;
    when(() => service.runPreview(
          spec: any(named: 'spec'),
          sheets: any(named: 'sheets'),
        )).thenAnswer((_) {
      call++;
      return call == 1 ? slow.future : Future.value(preview);
    });

    await controller.load();
    controller.toggleSheet(1);
    controller.toggleSheet(2);
    controller.addRelationship(relationship);

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
      spec: const MultiSheetQuerySpec(
        baseTableId: 1,
        selectedTableIds: [1, 2],
        relationships: [relationship],
      ),
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    when(() => service.loadSavedQuery(7)).thenAnswer((_) async => saved);
    when(() => service.buildQuery(
          spec: any(named: 'spec'),
          sheets: any(named: 'sheets'),
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
}
