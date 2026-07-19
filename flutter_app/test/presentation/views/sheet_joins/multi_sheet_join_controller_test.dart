import 'dart:async';

import 'package:exlser/application/services/multi_sheet_analysis_service.dart';
import 'package:exlser/domain/entities/dataset_column.dart';
import 'package:exlser/domain/entities/dataset_relationship.dart';
import 'package:exlser/domain/entities/dataset_table.dart';
import 'package:exlser/domain/entities/saved_multi_sheet_query.dart';
import 'package:exlser/domain/usecases/multisheet/execute_multi_sheet_preview_usecase.dart';
import 'package:exlser/domain/usecases/multisheet/manage_dataset_relationships_usecases.dart';
import 'package:exlser/domain/usecases/multisheet/multi_sheet_graph_validator.dart';
import 'package:exlser/domain/usecases/multisheet/multi_sheet_sql_builder.dart';
import 'package:exlser/domain/value_objects/column_type.dart';
import 'package:exlser/domain/value_objects/multi_sheet_join.dart';
import 'package:exlser/domain/value_objects/multi_sheet_query_spec.dart';
import 'package:exlser/domain/value_objects/sheet_join_relationship.dart';
import 'package:exlser/domain/value_objects/sheet_relationship_suggestion.dart';
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

  Future<bool> prepareAndExecutePreview() {
    if (controller.prepare() == null) return Future.value(false);
    return controller.executePreparedPreview();
  }

  setUpAll(() {
    registerFallbackValue(const MultiSheetQuerySpec());
    registerFallbackValue(const GeneratedMultiSheetQuery(
      sql: 'SELECT 1',
      outputColumns: [],
      displayLabelsByAlias: {},
    ));
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
    await prepareAndExecutePreview();

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
    when(() => service.executePreparedPreview(
          generated: any(named: 'generated'),
          spec: any(named: 'spec'),
          sheets: any(named: 'sheets'),
        )).thenAnswer((_) async => preview);

    await controller.load();
    controller.toggleSheet(1);
    controller.toggleSheet(2);
    await addProductRelationship();
    await prepareAndExecutePreview();

    expect(controller.state.status, MultiSheetJoinStatus.success);
    expect(controller.state.preview, isNotNull);
  });

  test('executePreparedPreview refuses to run without a valid preparation',
      () async {
    await controller.load();

    expect(await controller.executePreparedPreview(), isFalse);
    verifyNever(() => service.executePreparedPreview(
          generated: any(named: 'generated'),
          spec: any(named: 'spec'),
          sheets: any(named: 'sheets'),
        ));
  });

  test('editing the spec invalidates a prepared preview', () async {
    when(() => service.buildQuery(
          datasetId: any(named: 'datasetId'),
          spec: any(named: 'spec'),
          sheets: any(named: 'sheets'),
          relationshipsById: any(named: 'relationshipsById'),
        )).thenReturn(const GeneratedMultiSheetQuery(
      sql: 'SELECT prepared',
      outputColumns: [],
      displayLabelsByAlias: {},
    ));

    await controller.load();
    controller.toggleSheet(1);
    controller.toggleSheet(2);
    expect(controller.prepare(), isNotNull);

    controller.setResultLimit(25);

    expect(controller.state.generated, isNull);
    expect(await controller.executePreparedPreview(), isFalse);
    verifyNever(() => service.executePreparedPreview(
          generated: any(named: 'generated'),
          spec: any(named: 'spec'),
          sheets: any(named: 'sheets'),
        ));
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
    when(() => service.executePreparedPreview(
          generated: any(named: 'generated'),
          spec: any(named: 'spec'),
          sheets: any(named: 'sheets'),
        )).thenAnswer((_) {
      call++;
      return call == 1 ? slow.future : Future.value(preview);
    });

    await controller.load();
    controller.toggleSheet(1);
    controller.toggleSheet(2);
    await addProductRelationship();

    final first = prepareAndExecutePreview(); // stays pending
    await prepareAndExecutePreview(); // supersedes it
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

  test('startNewConfiguration ignores a preview from the discarded spec',
      () async {
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
    final pendingPreview = Completer<MultiSheetPreviewResult>();
    when(() => service.executePreparedPreview(
          generated: any(named: 'generated'),
          spec: any(named: 'spec'),
          sheets: any(named: 'sheets'),
        )).thenAnswer((_) => pendingPreview.future);

    await controller.load();
    controller.toggleSheet(1);
    controller.toggleSheet(2);
    await addProductRelationship();

    final run = prepareAndExecutePreview();
    await Future<void>.delayed(Duration.zero);
    controller.startNewConfiguration();

    pendingPreview.complete(preview);
    await run;

    expect(controller.state.status, MultiSheetJoinStatus.editing);
    expect(controller.state.spec.isEmpty, isTrue);
    expect(controller.state.preview, isNull);
    expect(controller.state.generated, isNull);
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
    when(() => service.listSavedQueries(any()))
        .thenAnswer((_) async => [saved]);
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

  test('confirming a suggestion persists all cardinality evidence', () async {
    await controller.load();
    controller.toggleSheet(1);
    controller.toggleSheet(2);

    const suggestion = SheetRelationshipSuggestion(
      relationship: SheetJoinRelationship(
        leftTableId: 1,
        leftColumnDbName: 'product_id',
        rightTableId: 2,
        rightColumnDbName: 'product',
      ),
      score: 0.82,
      confidence: SuggestionConfidence.high,
      reasons: [RelationshipReason.valueOverlap],
      cardinality: JoinCardinality.manyToOne,
      cardinalityConfidence: 0.9,
      sampleSize: 42,
    );

    await controller.confirmSuggestion(suggestion);

    final captured = verify(() => service.createRelationship(captureAny()))
        .captured
        .single as DatasetRelationship;
    expect(captured.cardinality, JoinCardinality.manyToOne);
    expect(captured.relationshipConfidence, 0.82);
    expect(captured.cardinalityConfidence, 0.9);
    expect(captured.sampleSize, 42);
    expect(captured.origin, RelationshipOrigin.suggested);
    expect(captured.confirmedAt, isNotNull);
  });

  // R4.4 — addManualRelationship contract

  test(
      'addManualRelationship returns true and persists a userDefined relationship',
      () async {
    await controller.load();
    controller.toggleSheet(1);
    controller.toggleSheet(2);

    final result = await controller.addManualRelationship(
      leftTableId: 1,
      leftColumnDbName: 'product_id',
      rightTableId: 2,
      rightColumnDbName: 'product',
    );

    expect(result, isTrue);
    expect(controller.state.spec.joins, hasLength(1));

    final captured = verify(() => service.createRelationship(captureAny()))
        .captured
        .single as DatasetRelationship;
    expect(captured.endpointATableId, 1);
    expect(captured.endpointAColumnDbName, 'product_id');
    expect(captured.endpointBTableId, 2);
    expect(captured.endpointBColumnDbName, 'product');
    expect(captured.origin, RelationshipOrigin.userDefined);
    expect(captured.confirmedAt, isNotNull);
    expect(captured.cardinality, JoinCardinality.unknown);
    expect(captured.cardinalityConfidence, 0);
    expect(captured.sampleSize, 0);
  });

  test(
      'addManualRelationship returns false and sets incompleteRelationshipCode for same table',
      () async {
    await controller.load();
    controller.toggleSheet(1);
    controller.toggleSheet(2);

    final result = await controller.addManualRelationship(
      leftTableId: 1,
      leftColumnDbName: 'product_id',
      rightTableId: 1,
      rightColumnDbName: 'qty',
    );

    expect(result, isFalse);
    expect(controller.state.status, MultiSheetJoinStatus.validationError);
    expect(controller.state.errorCode,
        MultiSheetGraphValidator.incompleteRelationshipCode);
    verifyNever(() => service.createRelationship(any()));
  });

  test('addManualRelationship returns false for an unselected table', () async {
    await controller.load();
    controller.toggleSheet(1); // only sheet 1 selected

    final result = await controller.addManualRelationship(
      leftTableId: 1,
      leftColumnDbName: 'product_id',
      rightTableId: 2,
      rightColumnDbName: 'product',
    );

    expect(result, isFalse);
    expect(controller.state.status, MultiSheetJoinStatus.validationError);
    expect(controller.state.errorCode,
        MultiSheetGraphValidator.unavailableTableOrColumnCode);
    verifyNever(() => service.createRelationship(any()));
  });

  test('addManualRelationship returns false for a missing column', () async {
    await controller.load();
    controller.toggleSheet(1);
    controller.toggleSheet(2);

    final result = await controller.addManualRelationship(
      leftTableId: 1,
      leftColumnDbName: 'nonexistent',
      rightTableId: 2,
      rightColumnDbName: 'product',
    );

    expect(result, isFalse);
    expect(controller.state.status, MultiSheetJoinStatus.validationError);
    expect(controller.state.errorCode,
        MultiSheetGraphValidator.unavailableTableOrColumnCode);
    verifyNever(() => service.createRelationship(any()));
  });

  test('addManualRelationship returns false for a current-spec duplicate',
      () async {
    await controller.load();
    controller.toggleSheet(1);
    controller.toggleSheet(2);

    await controller.addManualRelationship(
      leftTableId: 1,
      leftColumnDbName: 'product_id',
      rightTableId: 2,
      rightColumnDbName: 'product',
    );
    expect(controller.state.spec.joins, hasLength(1));

    // Swapped endpoints are the same endpoint key.
    final result = await controller.addManualRelationship(
      leftTableId: 2,
      leftColumnDbName: 'product',
      rightTableId: 1,
      rightColumnDbName: 'product_id',
    );

    expect(result, isFalse);
    expect(controller.state.spec.joins, hasLength(1));
    expect(controller.state.errorCode,
        MultiSheetGraphValidator.duplicateRelationshipCode);
  });

  test(
      'addManualRelationship reuses a dataset-level duplicate and returns true',
      () async {
    // Simulate the repository already having an equivalent row; it throws
    // DuplicateRelationshipException with the existing id.
    const existingId = 42;
    when(() => service.createRelationship(any()))
        .thenThrow(const DuplicateRelationshipException(existingId));

    // The controller recovers by loading relationships and reusing the existing one.
    final existing = const DatasetRelationship(
      id: existingId,
      datasetId: 1,
      endpointATableId: 1,
      endpointAColumnDbName: 'product_id',
      endpointBTableId: 2,
      endpointBColumnDbName: 'product',
      origin: RelationshipOrigin.userDefined,
    );
    when(() => service.loadRelationships(any()))
        .thenAnswer((_) async => [existing]);

    await controller.load();
    controller.toggleSheet(1);
    controller.toggleSheet(2);

    final result = await controller.addManualRelationship(
      leftTableId: 1,
      leftColumnDbName: 'product_id',
      rightTableId: 2,
      rightColumnDbName: 'product',
    );

    expect(result, isTrue);
    expect(controller.state.spec.joins, hasLength(1));
    expect(controller.state.spec.joins.first.relationshipId, existingId);
    // Only one createRelationship call — no second metadata row.
    verify(() => service.createRelationship(any())).called(1);
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
    when(() => service.listSavedQueries(any()))
        .thenAnswer((_) async => [saved]);
    when(() => service.loadSavedQuery(3)).thenAnswer((_) async => saved);

    await controller.load();
    await controller.loadSaved(3);
    expect(controller.state.status, MultiSheetJoinStatus.staleSpec);

    final result = await controller.save('anything');

    expect(result, isFalse);
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
    when(() => service.listSavedQueries(any()))
        .thenAnswer((_) async => [saved]);
    when(() => service.loadSavedQuery(3)).thenAnswer((_) async => saved);

    await controller.load();
    await controller.loadSaved(3);

    controller.startNewConfiguration();

    expect(controller.state.spec.unsupportedVersion, isFalse);
    expect(controller.state.spec.isEmpty, isTrue);
    expect(controller.state.activeSavedQueryId, isNull);
    expect(controller.state.status, MultiSheetJoinStatus.editing);
  });

  // R5.7 — save / load / delete contract

  SavedMultiSheetQuery savedQuery({
    int id = 1,
    int datasetId = 1,
    String name = 'My Config',
    MultiSheetQuerySpec spec = const MultiSheetQuerySpec(),
  }) =>
      SavedMultiSheetQuery(
        id: id,
        datasetId: datasetId,
        name: name,
        spec: spec,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );

  test(
      'save: trims name, passes null id for create, refreshes list, sets active id',
      () async {
    final created = savedQuery(id: 10, name: 'My Config');
    int? capturedId = -1; // sentinel
    String? capturedName;
    when(() => service.saveQuery(
          id: any(named: 'id'),
          datasetId: any(named: 'datasetId'),
          name: any(named: 'name'),
          spec: any(named: 'spec'),
        )).thenAnswer((inv) async {
      capturedId = inv.namedArguments[const Symbol('id')] as int?;
      capturedName = inv.namedArguments[const Symbol('name')] as String;
      return created;
    });
    when(() => service.listSavedQueries(any()))
        .thenAnswer((_) async => [created]);

    await controller.load();
    final result = await controller.save('  My Config  ');

    expect(result, isTrue);
    expect(controller.state.activeSavedQueryId, 10);
    expect(controller.state.savedQueries, [created]);
    expect(controller.state.errorCode, isNull);
    expect(controller.state.status, MultiSheetJoinStatus.editing);
    expect(capturedId, isNull); // null → create
    expect(capturedName, 'My Config'); // trimmed
  });

  test('save: active id is passed as overwrite target', () async {
    final existing = savedQuery(id: 5, name: 'Old');
    final updated = savedQuery(id: 5, name: 'New');
    when(() => service.listSavedQueries(any()))
        .thenAnswer((_) async => [existing]);
    when(() => service.loadSavedQuery(5)).thenAnswer((_) async => existing);

    int? capturedId = -1; // sentinel
    String? capturedName;
    when(() => service.saveQuery(
          id: any(named: 'id'),
          datasetId: any(named: 'datasetId'),
          name: any(named: 'name'),
          spec: any(named: 'spec'),
        )).thenAnswer((inv) async {
      capturedId = inv.namedArguments[const Symbol('id')] as int?;
      capturedName = inv.namedArguments[const Symbol('name')] as String;
      return updated;
    });

    await controller.load();
    await controller.loadSaved(5);
    expect(controller.state.activeSavedQueryId, 5);

    when(() => service.listSavedQueries(any()))
        .thenAnswer((_) async => [updated]);
    final result = await controller.save('New');

    expect(result, isTrue);
    expect(controller.state.activeSavedQueryId, 5);
    expect(capturedId, 5); // non-null → overwrite
    expect(capturedName, 'New');
  });

  test(
      'save: empty name returns false and sets save_name_required, no service call',
      () async {
    await controller.load();
    final result = await controller.save('   ');

    expect(result, isFalse);
    expect(controller.state.errorCode, 'save_name_required');
    expect(controller.state.status, MultiSheetJoinStatus.validationError);
    verifyNever(() => service.saveQuery(
          id: any(named: 'id'),
          datasetId: any(named: 'datasetId'),
          name: any(named: 'name'),
          spec: any(named: 'spec'),
        ));
  });

  test('save: exception returns false and sets save_failed without throwing',
      () async {
    when(() => service.saveQuery(
          id: any(named: 'id'),
          datasetId: any(named: 'datasetId'),
          name: any(named: 'name'),
          spec: any(named: 'spec'),
        )).thenThrow(Exception('db error'));

    await controller.load();
    final result = await controller.save('Config');

    expect(result, isFalse);
    expect(controller.state.errorCode, 'save_failed');
    expect(controller.state.savedQueries, isEmpty); // list unchanged
  });

  test('loadSaved: valid config replaces spec, sets active id, returns true',
      () async {
    final saved = savedQuery(id: 2, name: 'Work Config');
    when(() => service.listSavedQueries(any()))
        .thenAnswer((_) async => [saved]);
    when(() => service.loadSavedQuery(2)).thenAnswer((_) async => saved);

    await controller.load();
    final result = await controller.loadSaved(2);

    expect(result, isTrue);
    expect(controller.state.activeSavedQueryId, 2);
    expect(controller.state.preview, isNull);
    expect(controller.state.generated, isNull);
    expect(controller.state.errorCode, isNull);
  });

  test(
      'loadSaved applies only the latest request when completions are reversed',
      () async {
    final first = savedQuery(
      id: 11,
      name: 'First',
      spec: const MultiSheetQuerySpec(selectedTableIds: [1]),
    );
    final second = savedQuery(
      id: 12,
      name: 'Second',
      spec: const MultiSheetQuerySpec(selectedTableIds: [2]),
    );
    final firstResult = Completer<SavedMultiSheetQuery?>();
    final secondResult = Completer<SavedMultiSheetQuery?>();
    when(() => service.listSavedQueries(any()))
        .thenAnswer((_) async => [first, second]);
    when(() => service.loadSavedQuery(11))
        .thenAnswer((_) => firstResult.future);
    when(() => service.loadSavedQuery(12))
        .thenAnswer((_) => secondResult.future);

    await controller.load();
    final firstLoad = controller.loadSaved(11);
    final secondLoad = controller.loadSaved(12);

    secondResult.complete(second);
    expect(await secondLoad, isTrue);
    firstResult.complete(first);
    expect(await firstLoad, isFalse);

    expect(controller.state.activeSavedQueryId, 12);
    expect(controller.state.spec.selectedTableIds, [2]);
  });

  test(
      'loadSaved: id absent from savedQueries returns false, leaves spec unchanged',
      () async {
    await controller.load(); // savedQueries = []
    controller.toggleSheet(1);
    final specBefore = controller.state.spec;

    final result = await controller.loadSaved(99);

    expect(result, isFalse);
    expect(controller.state.errorCode, 'load_saved_failed');
    expect(controller.state.spec, specBefore); // unchanged
    verifyNever(() => service.loadSavedQuery(any()));
  });

  test('loadSaved: foreign datasetId returns false, leaves spec unchanged',
      () async {
    final foreign = SavedMultiSheetQuery(
      id: 8,
      datasetId: 999, // wrong dataset
      name: 'Foreign',
      spec: const MultiSheetQuerySpec(),
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    when(() => service.listSavedQueries(any()))
        .thenAnswer((_) async => [foreign]);
    when(() => service.loadSavedQuery(8)).thenAnswer((_) async => foreign);

    await controller.load();
    controller.toggleSheet(1);
    final specBefore = controller.state.spec;

    final result = await controller.loadSaved(8);

    expect(result, isFalse);
    expect(controller.state.errorCode, 'load_saved_failed');
    expect(controller.state.spec, specBefore);
  });

  test(
      'deleteSaved: inactive item is removed, active id unchanged, returns true',
      () async {
    final q1 = savedQuery(id: 1, name: 'A');
    final q2 = savedQuery(id: 2, name: 'B');
    when(() => service.listSavedQueries(any()))
        .thenAnswer((_) async => [q1, q2]);
    when(() => service.loadSavedQuery(1)).thenAnswer((_) async => q1);
    when(() => service.deleteSavedQuery(any())).thenAnswer((_) async {});

    await controller.load();
    await controller.loadSaved(1); // active = 1

    when(() => service.listSavedQueries(any()))
        .thenAnswer((_) async => [q1]); // q2 removed
    final result = await controller.deleteSaved(2);

    expect(result, isTrue);
    expect(controller.state.activeSavedQueryId, 1); // unchanged
    expect(controller.state.savedQueries, [q1]);
    expect(controller.state.errorCode, isNull);
  });

  test('deleteSaved: active item clears activeSavedQueryId but preserves spec',
      () async {
    final q1 = savedQuery(id: 1, name: 'Active');
    when(() => service.listSavedQueries(any())).thenAnswer((_) async => [q1]);
    when(() => service.loadSavedQuery(1)).thenAnswer((_) async => q1);
    when(() => service.deleteSavedQuery(any())).thenAnswer((_) async {});

    await controller.load();
    await controller.loadSaved(1); // loads empty spec
    // Edit the spec after loading so we can verify it is preserved on delete.
    controller.toggleSheet(1);
    expect(controller.state.activeSavedQueryId, 1);
    expect(controller.state.spec.selectedTableIds, [1]);

    when(() => service.listSavedQueries(any())).thenAnswer((_) async => []);
    final result = await controller.deleteSaved(1);

    expect(result, isTrue);
    expect(controller.state.activeSavedQueryId, isNull); // detached
    expect(controller.state.spec.selectedTableIds, [1]); // preserved
  });

  test('deleteSaved: exception preserves list and active id, returns false',
      () async {
    final q1 = savedQuery(id: 1);
    when(() => service.listSavedQueries(any())).thenAnswer((_) async => [q1]);
    when(() => service.deleteSavedQuery(any()))
        .thenThrow(Exception('db error'));

    await controller.load();
    final result = await controller.deleteSaved(1);

    expect(result, isFalse);
    expect(controller.state.errorCode, 'delete_saved_failed');
    expect(controller.state.savedQueries, [q1]); // preserved
  });
}
