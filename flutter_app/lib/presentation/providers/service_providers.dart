import 'package:exlser/application/services/create_dataset_service.dart';
import 'package:exlser/application/services/export_data_service.dart';
import 'package:exlser/application/services/import_data_service.dart';
import 'package:exlser/application/services/multi_sheet_analysis_service.dart';
import 'package:exlser/application/services/update_service.dart';
import 'package:exlser/core/constants/app_info.dart';
import 'package:exlser/core/constants/app_links.dart';
import 'package:exlser/data/adapters/parsers/parser_factory.dart';
import 'package:exlser/data/services/drift_transaction_runner.dart';
import 'package:exlser/data/services/github_release_client.dart';
import 'package:exlser/data/services/github_release_models.dart';
import 'package:exlser/domain/usecases/multisheet/execute_multi_sheet_preview_usecase.dart';
import 'package:exlser/domain/usecases/multisheet/manage_multi_sheet_queries_usecases.dart';
import 'package:exlser/domain/usecases/multisheet/save_multi_sheet_query_usecase.dart';
import 'package:exlser/presentation/providers/database_providers.dart';
import 'package:exlser/presentation/providers/repository_providers.dart';
import 'package:exlser/presentation/providers/usecase_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final parserFactoryProvider = Provider<ParserFactory>((ref) {
  return ParserFactory();
});

final importDataServiceProvider = Provider<ImportDataService>((ref) {
  return ImportDataService(
    parserFactory: ref.watch(parserFactoryProvider),
    inferSchemaUseCase: ref.watch(inferSchemaUseCaseProvider),
  );
});

final createDatasetServiceProvider = Provider<CreateDatasetService>((ref) {
  return CreateDatasetService(
    transactionRunner:
        DriftTransactionRunner(ref.watch(driftDatasourceProvider)),
    createDatasetUseCase: ref.watch(createDatasetUseCaseProvider),
    registerDatasetFileUseCase: ref.watch(registerDatasetFileUseCaseProvider),
    createDatasetTableUseCase: ref.watch(createDatasetTableUseCaseProvider),
    registerColumnsUseCase: ref.watch(registerColumnsUseCaseProvider),
    buildDynamicTableUseCase: ref.watch(buildDynamicTableUseCaseProvider),
    insertRowsUseCase: ref.watch(insertRowsUseCaseProvider),
    updateDatasetUiStateUseCase: ref.watch(updateDatasetUiStateUseCaseProvider),
  );
});

final exportDataServiceProvider = Provider<ExportDataService>((ref) {
  return ExportDataService(
    schemaRepository: ref.watch(schemaRepositoryProvider),
    queryRepository: ref.watch(queryRepositoryProvider),
    applyFiltersUseCase: ref.watch(applyFiltersUseCaseProvider),
    exportCsvUseCase: ref.watch(exportCsvUseCaseProvider),
    exportExcelUseCase: ref.watch(exportExcelUseCaseProvider),
    exportPdfUseCase: ref.watch(exportPdfUseCaseProvider),
    exportSqlUseCase: ref.watch(exportSqlUseCaseProvider),
    exportJsonUseCase: ref.watch(exportJsonUseCaseProvider),
  );
});

final githubReleaseClientProvider = Provider<GitHubReleaseClient>((ref) {
  return createGitHubReleaseClient();
});

final updateServiceProvider = Provider<UpdateService>((ref) {
  return UpdateService(
    releaseClient: ref.watch(githubReleaseClientProvider),
    owner: AppLinks.githubOwner,
    repo: AppLinks.githubRepo,
    currentVersion: '${AppInfo.versionName}+${AppInfo.buildNumber}',
  );
});

final multiSheetAnalysisServiceProvider =
    Provider<MultiSheetAnalysisService>((ref) {
  final savedQueryRepository =
      ref.watch(savedMultiSheetQueryRepositoryProvider);
  final queryRepository = ref.watch(queryRepositoryProvider);

  return MultiSheetAnalysisService(
    schemaRepository: ref.watch(schemaRepositoryProvider),
    queryRepository: queryRepository,
    executePreview:
        ExecuteMultiSheetPreviewUseCase(repository: queryRepository),
    saveQueryUseCase:
        SaveMultiSheetQueryUseCase(repository: savedQueryRepository),
    listQueriesUseCase:
        ListMultiSheetQueriesUseCase(repository: savedQueryRepository),
    loadQueryUseCase:
        LoadMultiSheetQueryUseCase(repository: savedQueryRepository),
    deleteQueryUseCase:
        DeleteMultiSheetQueryUseCase(repository: savedQueryRepository),
  );
});
