import 'package:easy_localization/easy_localization.dart';
import 'package:exlser/application/services/analysis_service.dart';
import 'package:exlser/application/services/export_data_service.dart';
import 'package:exlser/application/services/multi_sheet_analysis_service.dart';
import 'package:exlser/domain/entities/dataset.dart';
import 'package:exlser/domain/entities/dataset_column.dart';
import 'package:exlser/domain/entities/dataset_table.dart';
import 'package:exlser/domain/repositories/schema_repository.dart';
import 'package:exlser/domain/usecases/dataset/delete_dataset_usecase.dart';
import 'package:exlser/domain/usecases/dataset/get_datasets_usecase.dart';
import 'package:exlser/domain/usecases/dataset/open_dataset_usecase.dart';
import 'package:exlser/domain/usecases/dataset/update_dataset_ui_state_usecase.dart';
import 'package:exlser/domain/usecases/query/apply_filters_usecase.dart';
import 'package:exlser/domain/usecases/query/execute_read_only_query_usecase.dart';
import 'package:exlser/domain/usecases/query/fetch_rows_usecase.dart';
import 'package:exlser/domain/value_objects/column_type.dart';
import 'package:exlser/domain/value_objects/dataset_filter.dart';
import 'package:exlser/presentation/providers/repository_providers.dart';
import 'package:exlser/presentation/providers/service_providers.dart';
import 'package:exlser/presentation/providers/usecase_providers.dart';
import 'package:exlser/presentation/router/app_router.dart';
import 'package:exlser/presentation/router/router_notifier.dart';
import 'package:exlser/presentation/router/routes.dart';
import 'package:exlser/presentation/views/dataset/dataset_view.dart';
import 'package:exlser/presentation/views/sheet_joins/sheet_joins_view.dart';
import 'package:exlser/presentation/views/dataset_list/datasets_list_view.dart';
import 'package:exlser/presentation/views/home/home_view.dart';
import 'package:exlser/presentation/views/settings/settings_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockOpenDatasetUseCase extends Mock implements OpenDatasetUseCase {}

class MockGetDatasetsUseCase extends Mock implements GetDatasetsUseCase {}

class MockDeleteDatasetUseCase extends Mock implements DeleteDatasetUseCase {}

class MockSchemaRepository extends Mock implements SchemaRepository {}

class MockFetchRowsUseCase extends Mock implements FetchRowsUseCase {}

class MockApplyFiltersUseCase extends Mock implements ApplyFiltersUseCase {}

class MockExecuteReadOnlyQueryUseCase extends Mock
    implements ExecuteReadOnlyQueryUseCase {}

class MockUpdateDatasetUiStateUseCase extends Mock
    implements UpdateDatasetUiStateUseCase {}

class MockAnalysisService extends Mock implements AnalysisService {}

class MockExportDataService extends Mock implements ExportDataService {}

class MockMultiSheetAnalysisService extends Mock
    implements MultiSheetAnalysisService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    registerFallbackValue(<DatasetFilter>[]);
    registerFallbackValue(<DatasetColumn>[]);
  });

  group('AppRouter shell navigation', () {
    late RouterNotifier routerNotifier;
    late GoRouter router;
    late MockOpenDatasetUseCase openDataset;
    late MockGetDatasetsUseCase getDatasets;
    late MockDeleteDatasetUseCase deleteDataset;
    late MockSchemaRepository schemaRepository;
    late MockFetchRowsUseCase fetchRows;
    late MockApplyFiltersUseCase applyFilters;
    late MockExecuteReadOnlyQueryUseCase executeReadOnlyQuery;
    late MockUpdateDatasetUiStateUseCase updateDatasetUiState;
    late MockAnalysisService analysisService;
    late MockExportDataService exportDataService;

    setUp(() {
      routerNotifier = RouterNotifier()
        ..setInitialState(
          isSplashCompleted: true,
          isOnboardingCompleted: true,
        );
      router = AppRouter.create(routerNotifier);
      openDataset = MockOpenDatasetUseCase();
      getDatasets = MockGetDatasetsUseCase();
      deleteDataset = MockDeleteDatasetUseCase();
      schemaRepository = MockSchemaRepository();
      fetchRows = MockFetchRowsUseCase();
      applyFilters = MockApplyFiltersUseCase();
      executeReadOnlyQuery = MockExecuteReadOnlyQueryUseCase();
      updateDatasetUiState = MockUpdateDatasetUiStateUseCase();
      analysisService = MockAnalysisService();
      exportDataService = MockExportDataService();

      when(() => updateDatasetUiState.call(
            datasetId: any(named: 'datasetId'),
            uiStateJson: any(named: 'uiStateJson'),
          )).thenAnswer((_) async {});
      when(() => getDatasets.call()).thenAnswer((_) async => const []);
      when(() => analysisService.suggestAllCharts(any())).thenReturn(const []);
      _mockDatasetWorkspace(
        openDataset: openDataset,
        schemaRepository: schemaRepository,
        fetchRows: fetchRows,
      );
    });

    testWidgets('hides Combine sheets when the dataset has a single sheet',
        (tester) async {
      await _pumpRouterApp(
        tester,
        router: router,
        overrides: _overrides(
          openDataset: openDataset,
          getDatasets: getDatasets,
          deleteDataset: deleteDataset,
          schemaRepository: schemaRepository,
          fetchRows: fetchRows,
          applyFilters: applyFilters,
          executeReadOnlyQuery: executeReadOnlyQuery,
          updateDatasetUiState: updateDatasetUiState,
          analysisService: analysisService,
          exportDataService: exportDataService,
        ),
      );
      await _openDatasetRoute(tester, router);

      expect(find.byKey(const ValueKey('combine_sheets_button')), findsNothing);
    });

    testWidgets(
        'shows Combine sheets with two sheets and opens the joins route',
        (tester) async {
      when(() => schemaRepository.getTablesForDataset(1)).thenAnswer(
        (_) async => [_table(), _secondTable()],
      );
      when(() => schemaRepository.getColumnsForTable(11)).thenAnswer(
        (_) async => [_column()],
      );

      final joinsService = MockMultiSheetAnalysisService();
      when(() => joinsService.loadSheets(any())).thenAnswer((_) async => []);
      when(() => joinsService.listSavedQueries(any()))
          .thenAnswer((_) async => []);

      await _pumpRouterApp(
        tester,
        router: router,
        overrides: _overrides(
          openDataset: openDataset,
          getDatasets: getDatasets,
          deleteDataset: deleteDataset,
          schemaRepository: schemaRepository,
          fetchRows: fetchRows,
          applyFilters: applyFilters,
          executeReadOnlyQuery: executeReadOnlyQuery,
          updateDatasetUiState: updateDatasetUiState,
          analysisService: analysisService,
          exportDataService: exportDataService,
          multiSheetAnalysisService: joinsService,
        ),
      );
      await _openDatasetRoute(tester, router);

      final button = find.byKey(const ValueKey('combine_sheets_button'));
      expect(button, findsOneWidget);

      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(find.byType(SheetJoinsView), findsOneWidget);
    });

    testWidgets('navigates from Dataset through mobile drawer destinations',
        (tester) async {
      await _pumpRouterApp(
        tester,
        router: router,
        overrides: _overrides(
          openDataset: openDataset,
          getDatasets: getDatasets,
          deleteDataset: deleteDataset,
          schemaRepository: schemaRepository,
          fetchRows: fetchRows,
          applyFilters: applyFilters,
          executeReadOnlyQuery: executeReadOnlyQuery,
          updateDatasetUiState: updateDatasetUiState,
          analysisService: analysisService,
          exportDataService: exportDataService,
        ),
      );

      await _expectDrawerNavigation(
        tester,
        router,
        label: 'Home',
        expectedPath: AppRoutes.homePath,
        expectedView: find.byType(HomeView),
      );
      await _expectDrawerNavigation(
        tester,
        router,
        label: 'Works',
        expectedPath: AppRoutes.datasetListPath,
        expectedView: find.byType(DatasetsListView),
      );
      await _expectDrawerNavigation(
        tester,
        router,
        label: 'Settings',
        expectedPath: AppRoutes.settingsPath,
        expectedView: find.byType(SettingsView),
      );
    });
  });
}

Future<void> _pumpRouterApp(
  WidgetTester tester, {
  required GoRouter router,
  required List<Override> overrides,
}) async {
  tester.view.physicalSize = const Size(430, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();

  // EasyLocalization reloads its assets asynchronously on every mount; without
  // runAsync the second test in this file never builds its router.
  await tester.runAsync(() async {
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en')],
        path: 'assets/i18n',
        fallbackLocale: const Locale('en'),
        startLocale: const Locale('en'),
        child: ProviderScope(
          overrides: overrides,
          child: Builder(
            builder: (context) {
              return MaterialApp.router(
                locale: context.locale,
                supportedLocales: context.supportedLocales,
                localizationsDelegates: context.localizationDelegates,
                routerConfig: router,
              );
            },
          ),
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 200));
  });
  await tester.pumpAndSettle();
}

Future<void> _openDatasetRoute(
  WidgetTester tester,
  GoRouter router,
) async {
  router.go('/datasets/1');
  await tester.pumpAndSettle();

  final exception = tester.takeException();
  expect(
    exception,
    isNull,
    reason:
        'Current route: ${router.routerDelegate.currentConfiguration.uri.path}',
  );
  expect(
    find.byType(DatasetView),
    findsOneWidget,
    reason:
        'Current route: ${router.routerDelegate.currentConfiguration.uri.path}',
  );
}

Future<void> _navigateFromDrawer(
  WidgetTester tester,
  String label,
) async {
  await tester.tap(find.byIcon(Icons.menu));
  await tester.pumpAndSettle();
  expect(find.widgetWithText(ListTile, label), findsOneWidget);

  await tester.tap(find.widgetWithText(ListTile, label));
  await tester.pumpAndSettle();
}

Future<void> _expectDrawerNavigation(
  WidgetTester tester,
  GoRouter router, {
  required String label,
  required String expectedPath,
  required Finder expectedView,
}) async {
  await _openDatasetRoute(tester, router);
  await _navigateFromDrawer(tester, label);

  expect(expectedView, findsOneWidget);
  expect(find.byType(DatasetView), findsNothing);
  expect(router.routerDelegate.currentConfiguration.uri.path, expectedPath);
  expect(tester.takeException(), isNull);
}

List<Override> _overrides({
  required MockOpenDatasetUseCase openDataset,
  required MockGetDatasetsUseCase getDatasets,
  required MockDeleteDatasetUseCase deleteDataset,
  required MockSchemaRepository schemaRepository,
  required MockFetchRowsUseCase fetchRows,
  required MockApplyFiltersUseCase applyFilters,
  required MockExecuteReadOnlyQueryUseCase executeReadOnlyQuery,
  required MockUpdateDatasetUiStateUseCase updateDatasetUiState,
  required MockAnalysisService analysisService,
  required MockExportDataService exportDataService,
  MultiSheetAnalysisService? multiSheetAnalysisService,
}) {
  return [
    openDatasetUseCaseProvider.overrideWithValue(openDataset),
    getDatasetsUseCaseProvider.overrideWithValue(getDatasets),
    deleteDatasetUseCaseProvider.overrideWithValue(deleteDataset),
    schemaRepositoryProvider.overrideWithValue(schemaRepository),
    fetchRowsUseCaseProvider.overrideWithValue(fetchRows),
    applyFiltersUseCaseProvider.overrideWithValue(applyFilters),
    executeReadOnlyQueryUseCaseProvider.overrideWithValue(executeReadOnlyQuery),
    updateDatasetUiStateUseCaseProvider.overrideWithValue(updateDatasetUiState),
    analysisServiceProvider.overrideWithValue(analysisService),
    exportDataServiceProvider.overrideWithValue(exportDataService),
    if (multiSheetAnalysisService != null)
      multiSheetAnalysisServiceProvider
          .overrideWithValue(multiSheetAnalysisService),
  ];
}

void _mockDatasetWorkspace({
  required MockOpenDatasetUseCase openDataset,
  required MockSchemaRepository schemaRepository,
  required MockFetchRowsUseCase fetchRows,
}) {
  when(() => openDataset.call(1)).thenAnswer((_) async => _dataset());
  when(() => schemaRepository.getTablesForDataset(1)).thenAnswer(
    (_) async => [_table()],
  );
  when(() => schemaRepository.getColumnsForTable(10)).thenAnswer(
    (_) async => [_column()],
  );
  when(() => fetchRows.call(
        tableName: 'tbl_1',
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
      )).thenAnswer(
    (_) async => [
      {'id': 1, 'product': 'book'},
    ],
  );
}

Dataset _dataset() {
  return const Dataset(
    id: 1,
    name: 'Sales',
    sourceFileName: 'sales.csv',
    createdAt: 1,
  );
}

DatasetTable _secondTable() {
  return const DatasetTable(
    id: 11,
    datasetId: 1,
    sheetNameOriginal: 'Sheet 2',
    sqlTableName: 'tbl_2',
    rowCount: 1,
    colCount: 1,
  );
}

DatasetTable _table() {
  return const DatasetTable(
    id: 10,
    datasetId: 1,
    sheetNameOriginal: 'Sheet 1',
    sqlTableName: 'tbl_1',
    rowCount: 1,
    colCount: 1,
  );
}

DatasetColumn _column() {
  return const DatasetColumn(
    id: 20,
    datasetTableId: 10,
    originalName: 'product',
    dbName: 'product',
    declaredType: ColumnType.text,
    inferredType: ColumnType.text,
    nullable: false,
  );
}
