import 'package:exlser/application/services/analysis_service.dart';
import 'package:exlser/application/usecases/file/save_uploaded_file_usecase.dart';
import 'package:exlser/data/adapters/normalizers/boolean_normalizer.dart';
import 'package:exlser/data/adapters/normalizers/date_normalizer.dart';
import 'package:exlser/data/adapters/normalizers/number_normalizer.dart';
import 'package:exlser/domain/usecases/analytics/get_category_distribution_usecase.dart';
import 'package:exlser/domain/usecases/analytics/get_column_statistics_usecase.dart';
import 'package:exlser/domain/usecases/analytics/get_time_series_usecase.dart';
import 'package:exlser/domain/usecases/analytics/suggest_charts_usecase.dart';
import 'package:exlser/domain/usecases/dataset/create_dataset_usecase.dart';
import 'package:exlser/domain/usecases/dataset/delete_dataset_usecase.dart';
import 'package:exlser/domain/usecases/dataset/get_datasets_usecase.dart';
import 'package:exlser/domain/usecases/dataset/open_dataset_usecase.dart';
import 'package:exlser/domain/usecases/dataset/register_dataset_file_usecase.dart';
import 'package:exlser/domain/usecases/dataset/update_dataset_ui_state_usecase.dart';
import 'package:exlser/domain/usecases/export/export_csv_usecase.dart';
import 'package:exlser/domain/usecases/export/export_excel_usecase.dart';
import 'package:exlser/domain/usecases/export/export_json_usecase.dart';
import 'package:exlser/domain/usecases/export/export_pdf_usecase.dart';
import 'package:exlser/domain/usecases/export/export_sql_usecase.dart';
import 'package:exlser/domain/usecases/query/apply_filters_usecase.dart';
import 'package:exlser/domain/usecases/query/execute_read_only_query_usecase.dart';
import 'package:exlser/domain/usecases/query/fetch_rows_usecase.dart';
import 'package:exlser/domain/usecases/query/get_distinct_values_usecase.dart';
import 'package:exlser/domain/usecases/schema/build_dynamic_table_usecase.dart';
import 'package:exlser/domain/usecases/schema/create_dataset_table_usecase.dart';
import 'package:exlser/domain/usecases/schema/infer_schema_usecase.dart';
import 'package:exlser/domain/usecases/schema/insert_rows_usecase.dart';
import 'package:exlser/domain/usecases/schema/register_columns_usecase.dart';
import 'package:exlser/presentation/providers/database_providers.dart';
import 'package:exlser/presentation/providers/repository_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final numberNormalizerProvider = Provider<NumberNormalizer>((ref) {
  return NumberNormalizer();
});

final dateNormalizerProvider = Provider<DateNormalizer>((ref) {
  return DateNormalizer();
});

final booleanNormalizerProvider = Provider<BooleanNormalizer>((ref) {
  return BooleanNormalizer();
});

final inferSchemaUseCaseProvider = Provider<InferSchemaUseCase>((ref) {
  return InferSchemaUseCase(
    numberNormalizer: ref.watch(numberNormalizerProvider),
    dateNormalizer: ref.watch(dateNormalizerProvider),
    booleanNormalizer: ref.watch(booleanNormalizerProvider),
  );
});

final saveUploadedFileUseCaseProvider =
    Provider<SaveUploadedFileUseCase>((ref) {
  return SaveUploadedFileUseCase(
    datasource: ref.watch(fileDatasourceProvider),
  );
});

final createDatasetUseCaseProvider = Provider<CreateDatasetUseCase>((ref) {
  return CreateDatasetUseCase(
    repository: ref.watch(datasetsRepositoryProvider),
  );
});

final registerDatasetFileUseCaseProvider =
    Provider<RegisterDatasetFileUseCase>((ref) {
  return RegisterDatasetFileUseCase(
    repository: ref.watch(datasetFileRepositoryProvider),
  );
});

final getDatasetsUseCaseProvider = Provider<GetDatasetsUseCase>((ref) {
  return GetDatasetsUseCase(
    repository: ref.watch(datasetsRepositoryProvider),
  );
});

final openDatasetUseCaseProvider = Provider<OpenDatasetUseCase>((ref) {
  return OpenDatasetUseCase(
    repository: ref.watch(datasetsRepositoryProvider),
  );
});

final deleteDatasetUseCaseProvider = Provider<DeleteDatasetUseCase>((ref) {
  return DeleteDatasetUseCase(
    datasetsRepository: ref.watch(datasetsRepositoryProvider),
    schemaRepository: ref.watch(schemaRepositoryProvider),
    datasetFileRepository: ref.watch(datasetFileRepositoryProvider),
    savedMultiSheetQueryRepository:
        ref.watch(savedMultiSheetQueryRepositoryProvider),
  );
});

final updateDatasetUiStateUseCaseProvider =
    Provider<UpdateDatasetUiStateUseCase>((ref) {
  return UpdateDatasetUiStateUseCase(
    repository: ref.watch(datasetsRepositoryProvider),
  );
});

final createDatasetTableUseCaseProvider =
    Provider<CreateDatasetTableUseCase>((ref) {
  return CreateDatasetTableUseCase(
    repository: ref.watch(schemaRepositoryProvider),
  );
});

final registerColumnsUseCaseProvider = Provider<RegisterColumnsUseCase>((ref) {
  return RegisterColumnsUseCase(
    repository: ref.watch(schemaRepositoryProvider),
  );
});

final buildDynamicTableUseCaseProvider =
    Provider<BuildDynamicTableUseCase>((ref) {
  return BuildDynamicTableUseCase(
    repository: ref.watch(schemaRepositoryProvider),
  );
});

final insertRowsUseCaseProvider = Provider<InsertRowsUseCase>((ref) {
  return InsertRowsUseCase(
    ref.watch(queryRepositoryProvider),
  );
});

final fetchRowsUseCaseProvider = Provider<FetchRowsUseCase>((ref) {
  return FetchRowsUseCase(
    repository: ref.watch(queryRepositoryProvider),
  );
});

final applyFiltersUseCaseProvider = Provider<ApplyFiltersUseCase>((ref) {
  return ApplyFiltersUseCase(
    repository: ref.watch(queryRepositoryProvider),
  );
});

final executeReadOnlyQueryUseCaseProvider =
    Provider<ExecuteReadOnlyQueryUseCase>((ref) {
  return ExecuteReadOnlyQueryUseCase(
    repository: ref.watch(queryRepositoryProvider),
  );
});

final getDistinctValuesUseCaseProvider =
    Provider<GetDistinctValuesUseCase>((ref) {
  return GetDistinctValuesUseCase(
    repository: ref.watch(queryRepositoryProvider),
  );
});

final suggestChartsUseCaseProvider = Provider<SuggestChartsUseCase>((ref) {
  return const SuggestChartsUseCase();
});

final getColumnStatisticsUseCaseProvider =
    Provider<GetColumnStatisticsUseCase>((ref) {
  return GetColumnStatisticsUseCase(
    repository: ref.watch(queryRepositoryProvider),
  );
});

final getCategoryDistributionUseCaseProvider =
    Provider<GetCategoryDistributionUseCase>((ref) {
  return GetCategoryDistributionUseCase(
    repository: ref.watch(queryRepositoryProvider),
  );
});

final getTimeSeriesUseCaseProvider = Provider<GetTimeSeriesUseCase>((ref) {
  return GetTimeSeriesUseCase(
    repository: ref.watch(queryRepositoryProvider),
  );
});

final exportCsvUseCaseProvider = Provider<ExportCsvUseCase>((ref) {
  return const ExportCsvUseCase();
});

final exportExcelUseCaseProvider = Provider<ExportExcelUseCase>((ref) {
  return const ExportExcelUseCase();
});

final exportPdfUseCaseProvider = Provider<ExportPdfUseCase>((ref) {
  return const ExportPdfUseCase();
});

final exportSqlUseCaseProvider = Provider<ExportSqlUseCase>((ref) {
  return const ExportSqlUseCase();
});

final exportJsonUseCaseProvider = Provider<ExportJsonUseCase>((ref) {
  return const ExportJsonUseCase();
});

final analysisServiceProvider = Provider<AnalysisService>((ref) {
  return AnalysisService(
    suggestChartsUseCase: ref.watch(suggestChartsUseCaseProvider),
    getColumnStatisticsUseCase: ref.watch(getColumnStatisticsUseCaseProvider),
    getCategoryDistributionUseCase:
        ref.watch(getCategoryDistributionUseCaseProvider),
    getTimeSeriesUseCase: ref.watch(getTimeSeriesUseCaseProvider),
  );
});
