import 'package:easy_localization/easy_localization.dart';
import 'package:exlser/application/services/multi_sheet_analysis_service.dart';
import 'package:exlser/domain/entities/dataset_column.dart';
import 'package:exlser/domain/entities/dataset_relationship.dart';
import 'package:exlser/domain/entities/dataset_table.dart';
import 'package:exlser/domain/entities/saved_multi_sheet_query.dart';
import 'package:exlser/domain/usecases/multisheet/execute_multi_sheet_preview_usecase.dart';
import 'package:exlser/domain/usecases/multisheet/multi_sheet_graph_validator.dart';
import 'package:exlser/domain/usecases/multisheet/multi_sheet_join_risk_analyzer.dart';
import 'package:exlser/domain/usecases/multisheet/multi_sheet_sql_builder.dart';
import 'package:exlser/domain/value_objects/column_type.dart';
import 'package:exlser/domain/value_objects/multi_sheet_query_spec.dart';
import 'package:exlser/domain/value_objects/sheet_join_relationship.dart';
import 'package:exlser/domain/value_objects/sheet_relationship_suggestion.dart';
import 'package:exlser/presentation/providers/service_providers.dart';
import 'package:exlser/presentation/views/sheet_joins/sheet_joins_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockService extends Mock implements MultiSheetAnalysisService {}

DatasetColumn col(String name, int tableId) => DatasetColumn(
      id: '$tableId$name'.hashCode,
      datasetTableId: tableId,
      originalName: name,
      dbName: name.toLowerCase(),
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
      rowCount: 5,
      colCount: columns.length,
    ),
    columns: [for (final c in columns) col(c, id)],
  );
}

Future<void> pumpView(
  WidgetTester tester,
  ProviderContainer container,
) async {
  // The view is a lazy ListView: give the test a tall surface so every
  // section is actually built and findable.
  tester.view.physicalSize = const Size(1400, 3200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();

  await tester.runAsync(() async {
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en')],
        path: 'assets/i18n',
        fallbackLocale: const Locale('en'),
        startLocale: const Locale('en'),
        child: UncontrolledProviderScope(
          container: container,
          child: Builder(
            builder: (context) => MaterialApp(
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              home: const Scaffold(body: SheetJoinsView(datasetId: 1)),
            ),
          ),
        ),
      ),
    );
    await Future.delayed(const Duration(milliseconds: 200));
  });
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
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

  late MockService service;

  ProviderContainer containerWith(MockService service) {
    return ProviderContainer(
      overrides: [
        multiSheetAnalysisServiceProvider.overrideWithValue(service),
      ],
    );
  }

  SavedMultiSheetQuery savedQ({int id = 1, String name = 'Test Config'}) =>
      SavedMultiSheetQuery(
        id: id,
        datasetId: 1,
        name: name,
        spec: const MultiSheetQuerySpec(),
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026, 7, 19),
      );

  setUp(() {
    service = MockService();
    when(() => service.listSavedQueries(any())).thenAnswer((_) async => []);
    when(() => service.loadRelationships(any())).thenAnswer((_) async => []);
    // Persisting a confirmed/manual relationship assigns it an id.
    var nextId = 0;
    when(() => service.createRelationship(any())).thenAnswer((inv) async {
      final r = inv.positionalArguments.first as DatasetRelationship;
      return r.copyWith(id: ++nextId);
    });
    // saveQuery / loadSavedQuery / deleteSavedQuery default stubs.
    when(() => service.saveQuery(
          id: any(named: 'id'),
          datasetId: any(named: 'datasetId'),
          name: any(named: 'name'),
          spec: any(named: 'spec'),
        )).thenAnswer((_) async => savedQ());
    when(() => service.loadSavedQuery(any())).thenAnswer((_) async => null);
    when(() => service.deleteSavedQuery(any())).thenAnswer((_) async {});
  });

  testWidgets('asks for more sheets when the dataset has only one',
      (tester) async {
    when(() => service.loadSheets(any())).thenAnswer((_) async => [
          sheet(1, 'Only', ['a'])
        ]);

    final container = containerWith(service);
    addTearDown(container.dispose);
    await pumpView(tester, container);

    expect(find.text('Select at least two sheets.'), findsOneWidget);
    expect(find.byKey(const ValueKey('join_run_button')), findsNothing);
  });

  testWidgets('shows the sheet picker and run bar with two sheets',
      (tester) async {
    when(() => service.loadSheets(any())).thenAnswer((_) async => [
          sheet(1, 'Sales', ['Product ID', 'Qty']),
          sheet(2, 'Products', ['Product', 'Price']),
        ]);

    final container = containerWith(service);
    addTearDown(container.dispose);
    await pumpView(tester, container);

    expect(find.byKey(const ValueKey('join_sheet_1')), findsOneWidget);
    expect(find.byKey(const ValueKey('join_sheet_2')), findsOneWidget);
    expect(find.byKey(const ValueKey('join_run_button')), findsOneWidget);
    // Run is disabled until at least two sheets are selected.
    final button = tester.widget<FilledButton>(
      find.byKey(const ValueKey('join_run_button')),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('selecting two sheets reveals base picker and enables run',
      (tester) async {
    when(() => service.loadSheets(any())).thenAnswer((_) async => [
          sheet(1, 'Sales', ['Product ID']),
          sheet(2, 'Products', ['Product']),
        ]);

    final container = containerWith(service);
    addTearDown(container.dispose);
    await pumpView(tester, container);

    await tester.tap(find.byKey(const ValueKey('join_sheet_1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('join_sheet_2')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('join_base_sheet')), findsOneWidget);
    expect(find.byKey(const ValueKey('join_suggest_button')), findsOneWidget);
  });

  testWidgets(
      'renders headers and an empty message when the join returns no rows',
      (tester) async {
    final sheets = [
      sheet(1, 'Sales', ['Product ID']),
      sheet(2, 'Products', ['Product']),
    ];
    when(() => service.loadSheets(any())).thenAnswer((_) async => sheets);
    when(() => service.buildQuery(
          datasetId: any(named: 'datasetId'),
          spec: any(named: 'spec'),
          sheets: any(named: 'sheets'),
          relationshipsById: any(named: 'relationshipsById'),
        )).thenReturn(const GeneratedMultiSheetQuery(
      sql: 'SELECT 1',
      outputColumns: [
        MultiSheetOutputColumn(
          alias: 't0__product_id',
          tableId: 1,
          dbName: 'product id',
          label: 'Sales.Product ID',
        ),
      ],
      displayLabelsByAlias: {'t0__product_id': 'Sales.Product ID'},
    ));
    when(() => service.executePreparedPreview(
          generated: any(named: 'generated'),
          spec: any(named: 'spec'),
          sheets: any(named: 'sheets'),
        )).thenAnswer((_) async => const MultiSheetPreviewResult(
          rows: [],
          outputColumns: [
            MultiSheetOutputColumn(
              alias: 't0__product_id',
              tableId: 1,
              dbName: 'product id',
              label: 'Sales.Product ID',
            ),
          ],
          displayLabelsByAlias: {'t0__product_id': 'Sales.Product ID'},
          warnings: [],
          executedSql: 'SELECT 1',
          limit: 100,
        ));

    final container = containerWith(service);
    addTearDown(container.dispose);
    await pumpView(tester, container);

    await tester.tap(find.byKey(const ValueKey('join_sheet_1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('join_sheet_2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('join_run_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('join_preview_table')), findsOneWidget);
    expect(find.text('Sales.Product ID'), findsOneWidget,
        reason: 'headers must survive a zero-row result');
    expect(
        find.text('No row matches the chosen relationships.'), findsOneWidget);
    expect(find.byKey(const ValueKey('join_generated_sql')), findsOneWidget);
  });

  testWidgets('confirms a suggested relationship and then removes it',
      (tester) async {
    when(() => service.loadSheets(any())).thenAnswer((_) async => [
          sheet(1, 'Sales', ['Product ID']),
          sheet(2, 'Products', ['Product']),
        ]);
    when(() => service.suggestRelationships(
          sheets: any(named: 'sheets'),
          selectedTableIds: any(named: 'selectedTableIds'),
        )).thenAnswer((_) async => const [
          SheetRelationshipSuggestion(
            relationship: SheetJoinRelationship(
              leftTableId: 1,
              leftColumnDbName: 'product id',
              rightTableId: 2,
              rightColumnDbName: 'product',
            ),
            score: 0.9,
            confidence: SuggestionConfidence.high,
            reasons: [RelationshipReason.nameMatch],
          ),
        ]);

    final container = containerWith(service);
    addTearDown(container.dispose);
    await pumpView(tester, container);

    await tester.tap(find.byKey(const ValueKey('join_sheet_1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('join_sheet_2')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('join_suggest_button')));
    await tester.pumpAndSettle();
    expect(find.text('Confirm'), findsOneWidget);

    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(find.text('No relationship yet. Add one to combine the sheets.'),
        findsNothing);

    await tester.tap(find.byIcon(Icons.delete_outline).first);
    await tester.pumpAndSettle();
    expect(find.text('No relationship yet. Add one to combine the sheets.'),
        findsOneWidget);
  });

  testWidgets('risky preview requires confirmation and cancel does not execute',
      (tester) async {
    when(() => service.loadSheets(any())).thenAnswer((_) async => [
          sheet(1, 'Sales', ['Qty']),
          sheet(2, 'Products', ['Price']),
        ]);
    when(() => service.buildQuery(
          datasetId: any(named: 'datasetId'),
          spec: any(named: 'spec'),
          sheets: any(named: 'sheets'),
          relationshipsById: any(named: 'relationshipsById'),
        )).thenReturn(const GeneratedMultiSheetQuery(
      sql: 'SELECT 1',
      outputColumns: [],
      displayLabelsByAlias: {},
      warnings: [
        JoinRiskWarning(
          code: JoinRiskWarning.manyToManyRiskCode,
          relationshipId: 1,
          leftSheetLabel: 'Sales',
          rightSheetLabel: 'Products',
        ),
      ],
    ));
    when(() => service.executePreparedPreview(
          generated: any(named: 'generated'),
          spec: any(named: 'spec'),
          sheets: any(named: 'sheets'),
        )).thenAnswer((_) async => const MultiSheetPreviewResult(
          rows: [],
          outputColumns: [],
          displayLabelsByAlias: {},
          warnings: [],
          executedSql: 'SELECT 1',
          limit: 100,
        ));

    final container = containerWith(service);
    addTearDown(container.dispose);
    await pumpView(tester, container);

    await tester.tap(find.byKey(const ValueKey('join_sheet_1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('join_sheet_2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('join_run_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('join_risk_confirmation_dialog')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('join_warning_banner')), findsOneWidget);
    expect(
      find.text('Sales and Products have no unique key: rows may multiply.'),
      findsNWidgets(2),
    );
    verifyNever(() => service.executePreparedPreview(
          generated: any(named: 'generated'),
          spec: any(named: 'spec'),
          sheets: any(named: 'sheets'),
        ));

    await tester.tap(find.byKey(const ValueKey('join_risk_cancel')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('join_risk_confirmation_dialog')),
        findsNothing);
    verifyNever(() => service.executePreparedPreview(
          generated: any(named: 'generated'),
          spec: any(named: 'spec'),
          sheets: any(named: 'sheets'),
        ));

    await tester.tap(find.byKey(const ValueKey('join_run_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('join_risk_confirm')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('join_risk_confirmation_dialog')),
        findsNothing);
    verify(() => service.executePreparedPreview(
          generated: any(named: 'generated'),
          spec: any(named: 'spec'),
          sheets: any(named: 'sheets'),
        )).called(1);
  });

  testWidgets('risk dialog localizes unknown and low-confidence warnings',
      (tester) async {
    when(() => service.loadSheets(any())).thenAnswer((_) async => [
          sheet(1, 'Sales', ['Qty']),
          sheet(2, 'Products', ['Price']),
        ]);
    when(() => service.buildQuery(
          datasetId: any(named: 'datasetId'),
          spec: any(named: 'spec'),
          sheets: any(named: 'sheets'),
          relationshipsById: any(named: 'relationshipsById'),
        )).thenReturn(const GeneratedMultiSheetQuery(
      sql: 'SELECT 1',
      outputColumns: [],
      displayLabelsByAlias: {},
      warnings: [
        JoinRiskWarning(
          code: JoinRiskWarning.unknownCardinalityRiskCode,
          relationshipId: 1,
          leftSheetLabel: 'Sales',
          rightSheetLabel: 'Products',
        ),
        JoinRiskWarning(
          code: JoinRiskWarning.lowCardinalityConfidenceRiskCode,
          relationshipId: 2,
          leftSheetLabel: 'Orders',
          rightSheetLabel: 'Customers',
        ),
      ],
    ));

    final container = containerWith(service);
    addTearDown(container.dispose);
    await pumpView(tester, container);

    await tester.tap(find.byKey(const ValueKey('join_sheet_1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('join_sheet_2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('join_run_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('join_risk_warning_0')), findsOneWidget);
    expect(find.byKey(const ValueKey('join_risk_warning_1')), findsOneWidget);
    expect(find.textContaining('cardinality is unknown'), findsNWidgets(2));
    expect(find.textContaining('limited sample'), findsNWidgets(2));

    await tester.tap(find.byKey(const ValueKey('join_risk_cancel')));
    await tester.pumpAndSettle();
  });

  testWidgets('shows a localized error banner when the graph is invalid',
      (tester) async {
    when(() => service.loadSheets(any())).thenAnswer((_) async => [
          sheet(1, 'Sales', ['Product ID']),
          sheet(2, 'Products', ['Product']),
        ]);
    when(() => service.buildQuery(
          datasetId: any(named: 'datasetId'),
          spec: any(named: 'spec'),
          sheets: any(named: 'sheets'),
          relationshipsById: any(named: 'relationshipsById'),
        )).thenThrow(const MultiSheetGraphException(
      MultiSheetGraphValidator.disconnectedGraphCode,
    ));

    final container = containerWith(service);
    addTearDown(container.dispose);
    await pumpView(tester, container);

    await tester.tap(find.byKey(const ValueKey('join_sheet_1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('join_sheet_2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('join_run_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('join_error_banner')), findsOneWidget);
    expect(find.text('Every sheet must be connected to the others.'),
        findsOneWidget);
  });

  testWidgets('lays out on a narrow phone width without overflowing',
      (tester) async {
    when(() => service.loadSheets(any())).thenAnswer((_) async => [
          sheet(1, 'Sales', ['Product ID', 'Qty']),
          sheet(2, 'Products', ['Product', 'Price']),
        ]);

    final container = containerWith(service);
    addTearDown(container.dispose);

    tester.view.physicalSize = const Size(360, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.runAsync(() async {
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('en')],
          path: 'assets/i18n',
          fallbackLocale: const Locale('en'),
          startLocale: const Locale('en'),
          child: UncontrolledProviderScope(
            container: container,
            child: Builder(
              builder: (context) => MaterialApp(
                locale: context.locale,
                supportedLocales: context.supportedLocales,
                localizationsDelegates: context.localizationDelegates,
                home: const Scaffold(body: SheetJoinsView(datasetId: 1)),
              ),
            ),
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('join_sheet_1')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull,
        reason: 'no overflow at 360px width');
  });

  // R4.5 — manual relationship dialog

  testWidgets(
      'tapping manual_relationship_open shows the dialog with all four dropdowns',
      (tester) async {
    when(() => service.loadSheets(any())).thenAnswer((_) async => [
          sheet(1, 'Sales', ['Product ID']),
          sheet(2, 'Products', ['Product']),
        ]);

    final container = containerWith(service);
    addTearDown(container.dispose);
    await pumpView(tester, container);

    await tester.tap(find.byKey(const ValueKey('join_sheet_1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('join_sheet_2')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('manual_relationship_open')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('manual_relationship_dialog')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('manual_left_sheet')), findsOneWidget);
    // Column/right-sheet keys encode the selected sheet id so Flutter recreates
    // the FormField when the sheet changes. Initial: left=1, right=2.
    expect(find.byKey(const ValueKey('manual_left_column_1')), findsOneWidget);
    expect(find.byKey(const ValueKey('manual_right_sheet_2')), findsOneWidget);
    expect(find.byKey(const ValueKey('manual_right_column_2')), findsOneWidget);
  });

  testWidgets(
      'submitting valid endpoints adds the join, closes the dialog, and shows the endpoint',
      (tester) async {
    when(() => service.loadSheets(any())).thenAnswer((_) async => [
          sheet(1, 'Sales', ['Product ID']),
          sheet(2, 'Products', ['Product']),
        ]);

    final container = containerWith(service);
    addTearDown(container.dispose);
    await pumpView(tester, container);

    await tester.tap(find.byKey(const ValueKey('join_sheet_1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('join_sheet_2')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('manual_relationship_open')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('manual_relationship_submit')));
    await tester.pumpAndSettle();

    // Dialog must be gone.
    expect(
        find.byKey(const ValueKey('manual_relationship_dialog')), findsNothing);
    // Endpoint description must appear in the Relationships section.
    expect(find.textContaining('Sales.Product ID'), findsOneWidget);
  });

  testWidgets('cancel closes the dialog and does not add a join',
      (tester) async {
    when(() => service.loadSheets(any())).thenAnswer((_) async => [
          sheet(1, 'Sales', ['Product ID']),
          sheet(2, 'Products', ['Product']),
        ]);

    final container = containerWith(service);
    addTearDown(container.dispose);
    await pumpView(tester, container);

    await tester.tap(find.byKey(const ValueKey('join_sheet_1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('join_sheet_2')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('manual_relationship_open')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('manual_relationship_cancel')));
    await tester.pumpAndSettle();

    expect(
        find.byKey(const ValueKey('manual_relationship_dialog')), findsNothing);
    expect(find.text('No relationship yet. Add one to combine the sheets.'),
        findsOneWidget);
    verifyNever(() => service.createRelationship(any()));
  });

  testWidgets(
      'a duplicate submission leaves the dialog open and exposes the error banner',
      (tester) async {
    when(() => service.loadSheets(any())).thenAnswer((_) async => [
          sheet(1, 'Sales', ['Product ID']),
          sheet(2, 'Products', ['Product']),
        ]);

    final container = containerWith(service);
    addTearDown(container.dispose);
    await pumpView(tester, container);

    await tester.tap(find.byKey(const ValueKey('join_sheet_1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('join_sheet_2')));
    await tester.pumpAndSettle();

    // First submission succeeds.
    await tester.tap(find.byKey(const ValueKey('manual_relationship_open')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('manual_relationship_submit')));
    await tester.pumpAndSettle();
    expect(
        find.byKey(const ValueKey('manual_relationship_dialog')), findsNothing);

    // Second submission with the same defaults → current-spec duplicate.
    await tester.tap(find.byKey(const ValueKey('manual_relationship_open')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('manual_relationship_submit')));
    await tester.pumpAndSettle();

    // Dialog must remain open.
    expect(find.byKey(const ValueKey('manual_relationship_dialog')),
        findsOneWidget);
    // Error banner must be visible in the underlying view.
    expect(find.byKey(const ValueKey('join_error_banner')), findsOneWidget);
  });

  testWidgets(
      'a persistence error keeps the dialog open and re-enables submission',
      (tester) async {
    when(() => service.loadSheets(any())).thenAnswer((_) async => [
          sheet(1, 'Sales', ['Product ID']),
          sheet(2, 'Products', ['Product']),
        ]);
    when(() => service.createRelationship(any()))
        .thenThrow(StateError('persistence failed'));

    final container = containerWith(service);
    addTearDown(container.dispose);
    await pumpView(tester, container);

    await tester.tap(find.byKey(const ValueKey('join_sheet_1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('join_sheet_2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('manual_relationship_open')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('manual_relationship_submit')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('manual_relationship_dialog')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('manual_relationship_error')),
        findsOneWidget);
    final submit = tester.widget<FilledButton>(
      find.byKey(const ValueKey('manual_relationship_submit')),
    );
    expect(submit.onPressed, isNotNull);
    expect(find.textContaining('Sales.Product ID'), findsNothing);
    verify(() => service.createRelationship(any())).called(1);
  });

  testWidgets(
      'dialog lays out without overflow on a narrow phone-sized surface',
      (tester) async {
    when(() => service.loadSheets(any())).thenAnswer((_) async => [
          sheet(1, 'Sales', ['Product ID']),
          sheet(2, 'Products', ['Product']),
        ]);

    final container = containerWith(service);
    addTearDown(container.dispose);

    tester.view.physicalSize = const Size(360, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.runAsync(() async {
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('en')],
          path: 'assets/i18n',
          fallbackLocale: const Locale('en'),
          startLocale: const Locale('en'),
          child: UncontrolledProviderScope(
            container: container,
            child: Builder(
              builder: (context) => MaterialApp(
                locale: context.locale,
                supportedLocales: context.supportedLocales,
                localizationsDelegates: context.localizationDelegates,
                home: const Scaffold(body: SheetJoinsView(datasetId: 1)),
              ),
            ),
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('join_sheet_1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('join_sheet_2')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('manual_relationship_open')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('manual_relationship_dialog')),
        findsOneWidget);
    expect(tester.takeException(), isNull,
        reason: 'no overflow when opening dialog at 360px width');
  });

  testWidgets(
      'changing left sheet resets column, repairs right, and submits updated endpoints',
      (tester) async {
    when(() => service.loadSheets(any())).thenAnswer((_) async => [
          sheet(1, 'Alpha', ['id']),
          sheet(2, 'Beta', ['ref']),
          sheet(3, 'Gamma', ['code']),
        ]);

    final container = containerWith(service);
    addTearDown(container.dispose);
    await pumpView(tester, container);

    // Select all three sheets.
    await tester.tap(find.byKey(const ValueKey('join_sheet_1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('join_sheet_2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('join_sheet_3')));
    await tester.pumpAndSettle();

    // Open dialog (default: left=Alpha, right=Beta).
    await tester.tap(find.byKey(const ValueKey('manual_relationship_open')));
    await tester.pumpAndSettle();

    // Change left sheet to Beta (id=2), collides with current right=Beta(2),
    // so right auto-repairs to Alpha (id=1). Left column resets to 'ref'.
    await tester.tap(find.byKey(const ValueKey('manual_left_sheet')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Beta').last);
    await tester.pumpAndSettle();

    // Submit with the updated dropdowns.
    await tester.tap(find.byKey(const ValueKey('manual_relationship_submit')));
    await tester.pumpAndSettle();

    // Dialog should close on success.
    expect(
        find.byKey(const ValueKey('manual_relationship_dialog')), findsNothing);

    // Verify the updated endpoints were sent: left=Beta(2,ref), right=Alpha(1,id).
    final calls =
        verify(() => service.createRelationship(captureAny())).captured;
    final rel = calls.single as DatasetRelationship;
    expect(rel.endpointATableId, 2,
        reason: 'left sheet should be Beta after change');
    expect(rel.endpointAColumnDbName, 'ref',
        reason: 'left column should reset to first column of Beta');
    expect(rel.endpointBTableId, 1,
        reason: 'right sheet should auto-repair to Alpha');
    expect(rel.endpointBColumnDbName, 'id',
        reason: 'right column should reset to first column of Alpha');
  });

  // R5.8 — saved configurations panel widget tests

  testWidgets('panel renders empty state and New / Save actions are reachable',
      (tester) async {
    when(() => service.loadSheets(any())).thenAnswer((_) async => [
          sheet(1, 'Sales', ['id']),
          sheet(2, 'Products', ['ref']),
        ]);

    final container = containerWith(service);
    addTearDown(container.dispose);
    await pumpView(tester, container);

    expect(find.byKey(const ValueKey('saved_configurations_panel')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('saved_configuration_empty')),
        findsOneWidget);
    expect(
        find.byKey(const ValueKey('saved_configuration_new')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('saved_configuration_save')), findsOneWidget);
  });

  testWidgets('save dialog rejects blank name without a service call',
      (tester) async {
    when(() => service.loadSheets(any())).thenAnswer((_) async => [
          sheet(1, 'Sales', ['id']),
          sheet(2, 'Products', ['ref']),
        ]);

    final container = containerWith(service);
    addTearDown(container.dispose);
    await pumpView(tester, container);

    await tester.tap(find.byKey(const ValueKey('saved_configuration_save')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('save_configuration_dialog')),
        findsOneWidget);

    // Submit with empty field.
    await tester.tap(find.byKey(const ValueKey('save_configuration_submit')));
    await tester.pumpAndSettle();

    // Dialog must stay open with an inline error.
    expect(find.byKey(const ValueKey('save_configuration_dialog')),
        findsOneWidget);
    expect(
        find.byKey(const ValueKey('save_configuration_error')), findsOneWidget);
    verifyNever(() => service.saveQuery(
          id: any(named: 'id'),
          datasetId: any(named: 'datasetId'),
          name: any(named: 'name'),
          spec: any(named: 'spec'),
        ));
  });

  testWidgets(
      'create save closes dialog, refreshes list and shows active indicator',
      (tester) async {
    when(() => service.loadSheets(any())).thenAnswer((_) async => [
          sheet(1, 'Sales', ['id']),
          sheet(2, 'Products', ['ref']),
        ]);
    final q = savedQ(id: 1, name: 'My Config');
    when(() => service.saveQuery(
          id: any(named: 'id'),
          datasetId: any(named: 'datasetId'),
          name: any(named: 'name'),
          spec: any(named: 'spec'),
        )).thenAnswer((_) async => q);
    when(() => service.listSavedQueries(any())).thenAnswer((_) async => [q]);

    final container = containerWith(service);
    addTearDown(container.dispose);
    await pumpView(tester, container);

    await tester.tap(find.byKey(const ValueKey('saved_configuration_save')));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const ValueKey('saved_configuration_name')), 'My Config');
    await tester.tap(find.byKey(const ValueKey('save_configuration_submit')));
    await tester.pumpAndSettle();

    // Dialog closed.
    expect(
        find.byKey(const ValueKey('save_configuration_dialog')), findsNothing);
    // Row and active indicator visible.
    expect(find.byKey(const ValueKey('saved_configuration_1')), findsOneWidget);
    expect(find.byKey(const ValueKey('saved_configuration_active_1')),
        findsOneWidget);
  });

  testWidgets(
      'save dialog is prefilled with active name and submits an overwrite',
      (tester) async {
    final q = savedQ(id: 5, name: 'Existing');
    when(() => service.loadSheets(any())).thenAnswer((_) async => [
          sheet(1, 'Sales', ['id']),
          sheet(2, 'Products', ['ref']),
        ]);
    when(() => service.listSavedQueries(any())).thenAnswer((_) async => [q]);
    when(() => service.loadSavedQuery(5)).thenAnswer((_) async => q);

    // Return the updated query after overwrite.
    when(() => service.saveQuery(
          id: any(named: 'id'),
          datasetId: any(named: 'datasetId'),
          name: any(named: 'name'),
          spec: any(named: 'spec'),
        )).thenAnswer((_) async => q);

    final container = containerWith(service);
    addTearDown(container.dispose);
    await pumpView(tester, container);

    // Load the saved configuration first.
    await tester.tap(find.byKey(const ValueKey('saved_configuration_open_5')));
    await tester.pumpAndSettle();

    // Open save dialog — should be prefilled.
    await tester.tap(find.byKey(const ValueKey('saved_configuration_save')));
    await tester.pumpAndSettle();

    final nameField = tester.widget<TextFormField>(
        find.byKey(const ValueKey('saved_configuration_name')));
    expect(
      (nameField.controller ?? TextEditingController()).text,
      'Existing',
      reason: 'dialog should be prefilled with the active name',
    );

    await tester.tap(find.byKey(const ValueKey('save_configuration_submit')));
    await tester.pumpAndSettle();

    expect(
        find.byKey(const ValueKey('save_configuration_dialog')), findsNothing);
    // Verify id=5 was passed (overwrite, not create).
    verify(() => service.saveQuery(
          id: 5,
          datasetId: any(named: 'datasetId'),
          name: any(named: 'name'),
          spec: any(named: 'spec'),
        )).called(1);
  });

  testWidgets('Open loads a configuration and moves the active indicator',
      (tester) async {
    final q = savedQ(id: 3, name: 'Loaded');
    when(() => service.loadSheets(any())).thenAnswer((_) async => [
          sheet(1, 'Sales', ['id']),
          sheet(2, 'Products', ['ref']),
        ]);
    when(() => service.listSavedQueries(any())).thenAnswer((_) async => [q]);
    when(() => service.loadSavedQuery(3)).thenAnswer((_) async => q);

    final container = containerWith(service);
    addTearDown(container.dispose);
    await pumpView(tester, container);

    // No active indicator before loading.
    expect(find.byKey(const ValueKey('saved_configuration_active_3')),
        findsNothing);

    await tester.tap(find.byKey(const ValueKey('saved_configuration_open_3')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('saved_configuration_active_3')),
        findsOneWidget);
  });

  testWidgets('New with non-empty config shows confirmation and resets editor',
      (tester) async {
    when(() => service.loadSheets(any())).thenAnswer((_) async => [
          sheet(1, 'Sales', ['id']),
          sheet(2, 'Products', ['ref']),
        ]);

    final container = containerWith(service);
    addTearDown(container.dispose);
    await pumpView(tester, container);

    // Select a sheet to make the spec non-empty.
    await tester.tap(find.byKey(const ValueKey('join_sheet_1')));
    await tester.pumpAndSettle();

    // New must show confirmation.
    await tester.tap(find.byKey(const ValueKey('saved_configuration_new')));
    await tester.pumpAndSettle();

    expect(
        find.byKey(const ValueKey('new_configuration_dialog')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('new_configuration_confirm')));
    await tester.pumpAndSettle();

    expect(
        find.byKey(const ValueKey('new_configuration_dialog')), findsNothing);
    // Sheet picker reverts to unselected.
    final chip =
        tester.widget<FilterChip>(find.byKey(const ValueKey('join_sheet_1')));
    expect(chip.selected, isFalse);
  });

  testWidgets('delete requires confirmation and removes the row',
      (tester) async {
    final q = savedQ(id: 2, name: 'To Delete');
    when(() => service.loadSheets(any())).thenAnswer((_) async => [
          sheet(1, 'Sales', ['id']),
          sheet(2, 'Products', ['ref']),
        ]);
    when(() => service.listSavedQueries(any())).thenAnswer((_) async => [q]);

    final container = containerWith(service);
    addTearDown(container.dispose);
    await pumpView(tester, container);

    expect(find.byKey(const ValueKey('saved_configuration_2')), findsOneWidget);

    await tester
        .tap(find.byKey(const ValueKey('saved_configuration_delete_2')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('delete_configuration_dialog')),
        findsOneWidget);

    // Stub the list to be empty after deletion.
    when(() => service.listSavedQueries(any())).thenAnswer((_) async => []);
    await tester
        .tap(find.byKey(const ValueKey('delete_configuration_confirm')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('delete_configuration_dialog')),
        findsNothing);
    expect(find.byKey(const ValueKey('saved_configuration_2')), findsNothing);
    verify(() => service.deleteSavedQuery(2)).called(1);
  });

  testWidgets(
      'deleting the active row removes the indicator but keeps editor selections',
      (tester) async {
    final q = savedQ(id: 4, name: 'Active');
    when(() => service.loadSheets(any())).thenAnswer((_) async => [
          sheet(1, 'Sales', ['id']),
          sheet(2, 'Products', ['ref']),
        ]);
    when(() => service.listSavedQueries(any())).thenAnswer((_) async => [q]);
    when(() => service.loadSavedQuery(4)).thenAnswer((_) async => q);

    final container = containerWith(service);
    addTearDown(container.dispose);
    await pumpView(tester, container);

    // Load the saved config first, then edit the spec so we can verify it is
    // preserved after deleting the active item.
    await tester.tap(find.byKey(const ValueKey('saved_configuration_open_4')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('join_sheet_1')));
    await tester.pumpAndSettle();

    // Active indicator is visible.
    expect(find.byKey(const ValueKey('saved_configuration_active_4')),
        findsOneWidget);

    // Delete the active item.
    when(() => service.listSavedQueries(any())).thenAnswer((_) async => []);
    await tester
        .tap(find.byKey(const ValueKey('saved_configuration_delete_4')));
    await tester.pumpAndSettle();
    await tester
        .tap(find.byKey(const ValueKey('delete_configuration_confirm')));
    await tester.pumpAndSettle();

    // Row and active indicator gone.
    expect(find.byKey(const ValueKey('saved_configuration_4')), findsNothing);
    expect(find.byKey(const ValueKey('saved_configuration_active_4')),
        findsNothing);
    // Sheet picker still selected (spec preserved).
    final chip =
        tester.widget<FilterChip>(find.byKey(const ValueKey('join_sheet_1')));
    expect(chip.selected, isTrue);
  });

  testWidgets('save failure keeps dialog open and re-enables submit',
      (tester) async {
    when(() => service.loadSheets(any())).thenAnswer((_) async => [
          sheet(1, 'Sales', ['id']),
          sheet(2, 'Products', ['ref']),
        ]);
    when(() => service.saveQuery(
          id: any(named: 'id'),
          datasetId: any(named: 'datasetId'),
          name: any(named: 'name'),
          spec: any(named: 'spec'),
        )).thenThrow(Exception('db error'));

    final container = containerWith(service);
    addTearDown(container.dispose);
    await pumpView(tester, container);

    await tester.tap(find.byKey(const ValueKey('saved_configuration_save')));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const ValueKey('saved_configuration_name')), 'Config');
    await tester.tap(find.byKey(const ValueKey('save_configuration_submit')));
    await tester.pumpAndSettle();

    // Dialog stays open.
    expect(find.byKey(const ValueKey('save_configuration_dialog')),
        findsOneWidget);
    // Inline error shown.
    expect(
        find.byKey(const ValueKey('save_configuration_error')), findsOneWidget);
    // Submit button re-enabled.
    final btn = tester.widget<FilledButton>(
        find.byKey(const ValueKey('save_configuration_submit')));
    expect(btn.onPressed, isNotNull);
  });

  testWidgets('delete failure keeps dialog open and re-enables confirmation',
      (tester) async {
    final q = savedQ(id: 6, name: 'Keep me');
    when(() => service.loadSheets(any())).thenAnswer((_) async => [
          sheet(1, 'Sales', ['id']),
          sheet(2, 'Products', ['ref']),
        ]);
    when(() => service.listSavedQueries(any())).thenAnswer((_) async => [q]);
    when(() => service.deleteSavedQuery(6))
        .thenThrow(StateError('delete failed'));

    final container = containerWith(service);
    addTearDown(container.dispose);
    await pumpView(tester, container);

    await tester
        .tap(find.byKey(const ValueKey('saved_configuration_delete_6')));
    await tester.pumpAndSettle();
    await tester
        .tap(find.byKey(const ValueKey('delete_configuration_confirm')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('delete_configuration_dialog')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('delete_configuration_error')),
        findsOneWidget);
    final confirm = tester.widget<FilledButton>(
      find.byKey(const ValueKey('delete_configuration_confirm')),
    );
    expect(confirm.onPressed, isNotNull);
    expect(find.byKey(const ValueKey('saved_configuration_6')), findsOneWidget);
    verify(() => service.deleteSavedQuery(6)).called(1);
  });

  testWidgets('panel and dialogs do not overflow at 360 px', (tester) async {
    final q = savedQ(id: 1, name: 'Configuration with a fairly long name');
    when(() => service.loadSheets(any())).thenAnswer((_) async => [
          sheet(1, 'Sales', ['id']),
          sheet(2, 'Products', ['ref']),
        ]);
    when(() => service.listSavedQueries(any())).thenAnswer((_) async => [q]);

    final container = containerWith(service);
    addTearDown(container.dispose);

    tester.view.physicalSize = const Size(360, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.runAsync(() async {
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('en')],
          path: 'assets/i18n',
          fallbackLocale: const Locale('en'),
          startLocale: const Locale('en'),
          child: UncontrolledProviderScope(
            container: container,
            child: Builder(
              builder: (context) => MaterialApp(
                locale: context.locale,
                supportedLocales: context.supportedLocales,
                localizationsDelegates: context.localizationDelegates,
                home: const Scaffold(body: SheetJoinsView(datasetId: 1)),
              ),
            ),
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull,
        reason: 'panel with a saved row must not overflow at 360 px');

    // Open save dialog and verify no overflow.
    await tester.tap(find.byKey(const ValueKey('saved_configuration_save')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull,
        reason: 'save dialog must not overflow at 360 px');
  });

  // --- Responsive / accessibility polish (graphic pass) ---

  testWidgets('long saved configuration names are ellipsized', (tester) async {
    const longName =
        'Configuration with an extremely long name that would otherwise '
        'overflow the row and collide with the action buttons';
    when(() => service.loadSheets(any())).thenAnswer((_) async => [
          sheet(1, 'Sales', ['id']),
          sheet(2, 'Products', ['ref']),
        ]);
    when(() => service.listSavedQueries(any()))
        .thenAnswer((_) async => [savedQ(id: 1, name: longName)]);

    final container = containerWith(service);
    addTearDown(container.dispose);
    await pumpView(tester, container);

    final titleText = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const ValueKey('saved_configuration_1')),
        matching: find.text(longName),
      ),
    );
    expect(titleText.overflow, TextOverflow.ellipsis);
    expect(titleText.maxLines, 1);
  });

  testWidgets('base sheet dropdown is expanded and handles long sheet labels',
      (tester) async {
    when(() => service.loadSheets(any())).thenAnswer((_) async => [
          sheet(
              1, 'A sheet with a very very very long descriptive name', ['id']),
          sheet(2, 'Another equally long descriptive sheet name here', ['ref']),
        ]);

    final container = containerWith(service);
    addTearDown(container.dispose);

    tester.view.physicalSize = const Size(360, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.runAsync(() async {
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('en')],
          path: 'assets/i18n',
          fallbackLocale: const Locale('en'),
          startLocale: const Locale('en'),
          child: UncontrolledProviderScope(
            container: container,
            child: Builder(
              builder: (context) => MaterialApp(
                locale: context.locale,
                supportedLocales: context.supportedLocales,
                localizationsDelegates: context.localizationDelegates,
                home: const Scaffold(body: SheetJoinsView(datasetId: 1)),
              ),
            ),
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('join_sheet_1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('join_sheet_2')));
    await tester.pumpAndSettle();

    // Items ellipsize long labels, and isExpanded keeps the field bounded so
    // nothing overflows at 360 px.
    final labelText = tester
        .widgetList<Text>(
          find.descendant(
            of: find.byKey(const ValueKey('join_base_sheet')),
            matching: find
                .text('A sheet with a very very very long descriptive name'),
          ),
        )
        .first;
    expect(labelText.overflow, TextOverflow.ellipsis);
    expect(tester.takeException(), isNull,
        reason: 'long base sheet labels must not overflow at 360 px');
  });

  testWidgets('confidence is conveyed by icon and text, not color alone',
      (tester) async {
    when(() => service.loadSheets(any())).thenAnswer((_) async => [
          sheet(1, 'Sales', ['Product ID']),
          sheet(2, 'Products', ['Product']),
        ]);
    when(() => service.suggestRelationships(
          sheets: any(named: 'sheets'),
          selectedTableIds: any(named: 'selectedTableIds'),
        )).thenAnswer((_) async => const [
          SheetRelationshipSuggestion(
            relationship: SheetJoinRelationship(
              leftTableId: 1,
              leftColumnDbName: 'product id',
              rightTableId: 2,
              rightColumnDbName: 'product',
            ),
            score: 0.9,
            confidence: SuggestionConfidence.high,
            reasons: [RelationshipReason.nameMatch],
          ),
        ]);

    final container = containerWith(service);
    addTearDown(container.dispose);
    await pumpView(tester, container);

    await tester.tap(find.byKey(const ValueKey('join_sheet_1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('join_sheet_2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('join_suggest_button')));
    await tester.pumpAndSettle();

    // The level is readable from the text label, so it does not depend on color.
    expect(find.text('High'), findsOneWidget);
    // A distinct icon shape reinforces the level.
    expect(find.byIcon(Icons.signal_cellular_alt), findsOneWidget);
  });

  testWidgets('an already-added suggestion exposes an "already added" tooltip',
      (tester) async {
    when(() => service.loadSheets(any())).thenAnswer((_) async => [
          sheet(1, 'Sales', ['Product ID']),
          sheet(2, 'Products', ['Product']),
        ]);
    when(() => service.suggestRelationships(
          sheets: any(named: 'sheets'),
          selectedTableIds: any(named: 'selectedTableIds'),
        )).thenAnswer((_) async => const [
          SheetRelationshipSuggestion(
            relationship: SheetJoinRelationship(
              leftTableId: 1,
              leftColumnDbName: 'product id',
              rightTableId: 2,
              rightColumnDbName: 'product',
            ),
            score: 0.9,
            confidence: SuggestionConfidence.high,
            reasons: [RelationshipReason.nameMatch],
          ),
        ]);

    final container = containerWith(service);
    addTearDown(container.dispose);
    await pumpView(tester, container);

    await tester.tap(find.byKey(const ValueKey('join_sheet_1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('join_sheet_2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('join_suggest_button')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Already added'), findsOneWidget);
  });
}
