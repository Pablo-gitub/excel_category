import 'package:easy_localization/easy_localization.dart';
import 'package:exlser/application/services/multi_sheet_analysis_service.dart';
import 'package:exlser/domain/entities/dataset_column.dart';
import 'package:exlser/domain/entities/dataset_table.dart';
import 'package:exlser/domain/usecases/multisheet/execute_multi_sheet_preview_usecase.dart';
import 'package:exlser/domain/usecases/multisheet/multi_sheet_sql_builder.dart';
import 'package:exlser/domain/value_objects/column_type.dart';
import 'package:exlser/domain/value_objects/multi_sheet_query_spec.dart';
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
  });

  late MockService service;

  ProviderContainer containerWith(MockService service) {
    return ProviderContainer(
      overrides: [
        multiSheetAnalysisServiceProvider.overrideWithValue(service),
      ],
    );
  }

  setUp(() {
    service = MockService();
    when(() => service.listSavedQueries(any())).thenAnswer((_) async => []);
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
          spec: any(named: 'spec'),
          sheets: any(named: 'sheets'),
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
    when(() => service.runPreview(
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
}
