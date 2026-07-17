//lib/application/services/multi_sheet_analysis_service.dart

import 'package:exlser/domain/entities/dataset_column.dart';
import 'package:exlser/domain/entities/dataset_relationship.dart';
import 'package:exlser/domain/entities/dataset_table.dart';
import 'package:exlser/domain/entities/saved_multi_sheet_query.dart';
import 'package:exlser/domain/repositories/query_repository.dart';
import 'package:exlser/domain/repositories/schema_repository.dart';
import 'package:exlser/domain/usecases/multisheet/execute_multi_sheet_preview_usecase.dart';
import 'package:exlser/domain/usecases/multisheet/manage_dataset_relationships_usecases.dart';
import 'package:exlser/domain/usecases/multisheet/manage_multi_sheet_queries_usecases.dart';
import 'package:exlser/domain/usecases/multisheet/multi_sheet_graph_validator.dart';
import 'package:exlser/domain/usecases/multisheet/multi_sheet_sql_builder.dart';
import 'package:exlser/domain/usecases/multisheet/relationship_value_normalizer.dart';
import 'package:exlser/domain/usecases/multisheet/save_multi_sheet_query_usecase.dart';
import 'package:exlser/domain/usecases/multisheet/suggest_sheet_relationships_usecase.dart';
import 'package:exlser/domain/value_objects/column_relationship_sample.dart';
import 'package:exlser/domain/value_objects/multi_sheet_query_spec.dart';
import 'package:exlser/domain/value_objects/sheet_relationship_suggestion.dart';

/// A sheet with its columns, resolved from the current schema.
class MultiSheetSheetInfo {
  final DatasetTable table;
  final List<DatasetColumn> columns;

  const MultiSheetSheetInfo({required this.table, required this.columns});

  int get tableId => table.id;

  String get label => table.displayName;
}

/// Orchestrates the guided multi-sheet join flow.
///
/// Composition point between schema metadata, the pure domain engines
/// (suggestions, graph validation, SQL generation) and bounded execution.
/// It never talks to the UI and never mutates dataset data.
class MultiSheetAnalysisService {
  final SchemaRepository schemaRepository;
  final QueryRepository queryRepository;
  final MultiSheetGraphValidator graphValidator;
  final MultiSheetSqlBuilder sqlBuilder;
  final ExecuteMultiSheetPreviewUseCase executePreview;
  final SaveMultiSheetQueryUseCase saveQueryUseCase;
  final ListMultiSheetQueriesUseCase listQueriesUseCase;
  final LoadMultiSheetQueryUseCase loadQueryUseCase;
  final DeleteMultiSheetQueryUseCase deleteQueryUseCase;
  final CreateDatasetRelationshipUseCase createRelationshipUseCase;
  final ListDatasetRelationshipsUseCase listRelationshipsUseCase;
  final UpdateDatasetRelationshipUseCase updateRelationshipUseCase;

  /// Distinct-sample size per column used by the suggestion engine.
  final int sampleLimit;

  MultiSheetAnalysisService({
    required this.schemaRepository,
    required this.queryRepository,
    required this.executePreview,
    required this.saveQueryUseCase,
    required this.listQueriesUseCase,
    required this.loadQueryUseCase,
    required this.deleteQueryUseCase,
    required this.createRelationshipUseCase,
    required this.listRelationshipsUseCase,
    required this.updateRelationshipUseCase,
    this.graphValidator = const MultiSheetGraphValidator(),
    this.sqlBuilder = const MultiSheetSqlBuilder(),
    this.sampleLimit = 200,
  });

  static const RelationshipValueNormalizer _normalizer =
      RelationshipValueNormalizer();

  late final SuggestSheetRelationshipsUseCase _suggest =
      SuggestSheetRelationshipsUseCase(
    sampleColumnValues: _sampleColumn,
    sampleLimit: sampleLimit,
  );

  /// Loads every sheet of a dataset together with its columns.
  Future<List<MultiSheetSheetInfo>> loadSheets(int datasetId) async {
    final tables = await schemaRepository.getTablesForDataset(datasetId);
    final sheets = <MultiSheetSheetInfo>[];
    for (final table in tables) {
      final columns = await schemaRepository.getColumnsForTable(table.id);
      sheets.add(MultiSheetSheetInfo(table: table, columns: columns));
    }
    return sheets;
  }

  /// Proposes candidate relationships between the selected sheets.
  Future<List<SheetRelationshipSuggestion>> suggestRelationships({
    required List<MultiSheetSheetInfo> sheets,
    required List<int> selectedTableIds,
  }) {
    final selected = sheets
        .where((sheet) => selectedTableIds.contains(sheet.tableId))
        .map((sheet) => SuggestSheetInput(
              tableId: sheet.tableId,
              sqlTableName: sheet.table.sqlTableName,
              columns: sheet.columns,
            ))
        .toList();

    if (selected.length < 2) {
      return Future.value(const []);
    }

    return _suggest(sheets: selected);
  }

  Future<List<DatasetRelationship>> loadRelationships(int datasetId) =>
      listRelationshipsUseCase(datasetId);

  Future<DatasetRelationship> createRelationship(
    DatasetRelationship relationship,
  ) =>
      createRelationshipUseCase(relationship);

  Future<DatasetRelationship> updateRelationship(
    DatasetRelationship relationship,
  ) =>
      updateRelationshipUseCase(relationship);

  /// Validates the spec against the dataset's relationships and current schema,
  /// then generates the SQL.
  ///
  /// Throws [MultiSheetGraphException] (invalid/stale graph) or
  /// [MultiSheetSqlBuilderException] (nothing to select).
  GeneratedMultiSheetQuery buildQuery({
    required int datasetId,
    required MultiSheetQuerySpec spec,
    required List<MultiSheetSheetInfo> sheets,
    required Map<int, DatasetRelationship> relationshipsById,
  }) {
    final plan = resolvePlan(
      datasetId: datasetId,
      spec: spec,
      sheets: sheets,
      relationshipsById: relationshipsById,
    );

    return sqlBuilder.build(
      plan: plan,
      spec: spec,
      sqlTableNameByTableId: {
        for (final sheet in sheets) sheet.tableId: sheet.table.sqlTableName,
      },
      sheetLabelByTableId: {
        for (final sheet in sheets) sheet.tableId: sheet.label,
      },
      originalColumnNamesByTableId: {
        for (final sheet in sheets)
          sheet.tableId: {
            for (final column in sheet.columns)
              column.dbName: column.originalName,
          },
      },
    );
  }

  /// Resolves the current rooted join tree without generating or executing SQL.
  /// For a LEFT join, each step's [ResolvedJoinStep.existingTableId] is the side
  /// preserved by SQLite.
  ResolvedJoinPlan resolvePlan({
    required int datasetId,
    required MultiSheetQuerySpec spec,
    required List<MultiSheetSheetInfo> sheets,
    required Map<int, DatasetRelationship> relationshipsById,
  }) {
    return graphValidator.validate(
      datasetId: datasetId,
      spec: spec,
      relationshipsById: relationshipsById,
      availableTableIds: {for (final sheet in sheets) sheet.tableId},
      availableColumnsByTableId: {
        for (final sheet in sheets)
          sheet.tableId: {for (final column in sheet.columns) column.dbName},
      },
    );
  }

  /// Builds and runs the bounded preview for a spec.
  Future<MultiSheetPreviewResult> runPreview({
    required int datasetId,
    required MultiSheetQuerySpec spec,
    required List<MultiSheetSheetInfo> sheets,
    required Map<int, DatasetRelationship> relationshipsById,
  }) async {
    final generated = buildQuery(
      datasetId: datasetId,
      spec: spec,
      sheets: sheets,
      relationshipsById: relationshipsById,
    );
    final baseSheet = sheets.firstWhere(
      (sheet) =>
          sheet.tableId == (spec.baseTableId ?? spec.selectedTableIds.first),
    );

    return executePreview(
      generated: generated,
      baseSqlTableName: baseSheet.table.sqlTableName,
      allowedTableNames: {for (final sheet in sheets) sheet.table.sqlTableName},
      limit: spec.resultLimit,
    );
  }

  Future<List<SavedMultiSheetQuery>> listSavedQueries(int datasetId) =>
      listQueriesUseCase(datasetId);

  Future<SavedMultiSheetQuery?> loadSavedQuery(int id) => loadQueryUseCase(id);

  Future<SavedMultiSheetQuery> saveQuery({
    int? id,
    required int datasetId,
    required String name,
    required MultiSheetQuerySpec spec,
  }) {
    return saveQueryUseCase(
      id: id,
      datasetId: datasetId,
      name: name,
      spec: spec,
    );
  }

  Future<void> deleteSavedQuery(int id) => deleteQueryUseCase(id);

  /// Bounded, null-free sample that **retains duplicates**, used to estimate
  /// cardinality and value overlap from data.
  ///
  /// Uses a dedicated raw query on purpose: `QueryRepository.getDistinctValues`
  /// has no LIMIT, keeps nulls, and — crucially — collapses duplicates, which
  /// would destroy the uniqueness signal. We fetch `limit + 1` rows to detect
  /// truncation, then normalize/filter type-aware in Dart, keeping at most
  /// [limit] usable values. No unbounded follow-up query is issued to refill.
  Future<ColumnRelationshipSample> _sampleColumn({
    required String sqlTableName,
    required DatasetColumn column,
    required int limit,
  }) async {
    final quoted = _quote(column.dbName);
    final sql = 'SELECT $quoted AS sample_value '
        'FROM ${_quote(sqlTableName)} '
        'WHERE $quoted IS NOT NULL '
        'LIMIT ${limit + 1}';

    final rows = await queryRepository.executeRawQuery(sql, null);
    final isTruncated = rows.length > limit;

    final normalized = <String>[];
    for (final row in rows) {
      if (normalized.length >= limit) break;
      final value =
          _normalizer.normalize(row['sample_value'], column.inferredType);
      if (value != null) normalized.add(value);
    }

    return ColumnRelationshipSample(
      normalizedValues: normalized,
      requestedLimit: limit,
      isTruncated: isTruncated,
    );
  }

  String _quote(String identifier) => '"${identifier.replaceAll('"', '""')}"';
}
