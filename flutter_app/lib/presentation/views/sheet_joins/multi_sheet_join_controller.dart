//lib/presentation/views/sheet_joins/multi_sheet_join_controller.dart

import 'package:exlser/application/services/multi_sheet_analysis_service.dart';
import 'package:exlser/domain/entities/saved_multi_sheet_query.dart';
import 'package:exlser/domain/usecases/multisheet/execute_multi_sheet_preview_usecase.dart';
import 'package:exlser/domain/usecases/multisheet/multi_sheet_graph_validator.dart';
import 'package:exlser/domain/usecases/multisheet/multi_sheet_sql_builder.dart';
import 'package:exlser/domain/value_objects/multi_sheet_query_spec.dart';
import 'package:exlser/domain/value_objects/sheet_join_relationship.dart';
import 'package:exlser/domain/value_objects/sheet_join_type.dart';
import 'package:exlser/domain/value_objects/sheet_relationship_suggestion.dart';
import 'package:exlser/presentation/providers/service_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Explicit lifecycle of the guided join workspace.
enum MultiSheetJoinStatus {
  initial,
  loadingMetadata,
  editing,
  generatingSuggestions,
  ready,
  executing,
  success,
  validationError,
  executionError,
  staleSpec,
}

class MultiSheetJoinState {
  final MultiSheetJoinStatus status;
  final List<MultiSheetSheetInfo> sheets;
  final MultiSheetQuerySpec spec;
  final List<SheetRelationshipSuggestion> suggestions;
  final GeneratedMultiSheetQuery? generated;
  final MultiSheetPreviewResult? preview;
  final List<SavedMultiSheetQuery> savedQueries;
  final int? activeSavedQueryId;

  /// Domain error code (graph/builder/execution), for localisation in the UI.
  final String? errorCode;

  const MultiSheetJoinState({
    this.status = MultiSheetJoinStatus.initial,
    this.sheets = const [],
    this.spec = const MultiSheetQuerySpec(),
    this.suggestions = const [],
    this.generated,
    this.preview,
    this.savedQueries = const [],
    this.activeSavedQueryId,
    this.errorCode,
  });

  bool get canConfigure => sheets.length >= 2;

  bool get hasEnoughSheets => spec.selectedTableIds.length >= 2;

  bool get isBusy =>
      status == MultiSheetJoinStatus.loadingMetadata ||
      status == MultiSheetJoinStatus.generatingSuggestions ||
      status == MultiSheetJoinStatus.executing;

  /// Warnings on the last generated query (e.g. many-to-many row multiplication).
  bool get hasRiskWarnings => generated?.hasWarnings ?? false;

  MultiSheetJoinState copyWith({
    MultiSheetJoinStatus? status,
    List<MultiSheetSheetInfo>? sheets,
    MultiSheetQuerySpec? spec,
    List<SheetRelationshipSuggestion>? suggestions,
    GeneratedMultiSheetQuery? generated,
    MultiSheetPreviewResult? preview,
    List<SavedMultiSheetQuery>? savedQueries,
    int? activeSavedQueryId,
    String? errorCode,
    bool clearError = false,
    bool clearPreview = false,
    bool clearGenerated = false,
    bool clearActiveSavedQuery = false,
  }) {
    return MultiSheetJoinState(
      status: status ?? this.status,
      sheets: sheets ?? this.sheets,
      spec: spec ?? this.spec,
      suggestions: suggestions ?? this.suggestions,
      generated: clearGenerated ? null : (generated ?? this.generated),
      preview: clearPreview ? null : (preview ?? this.preview),
      savedQueries: savedQueries ?? this.savedQueries,
      activeSavedQueryId: clearActiveSavedQuery
          ? null
          : (activeSavedQueryId ?? this.activeSavedQueryId),
      errorCode: clearError ? null : (errorCode ?? this.errorCode),
    );
  }
}

/// Drives the guided join workspace for one dataset.
///
/// Only needs a `datasetId`: it deliberately does not depend on `DatasetBloc`.
class MultiSheetJoinController extends StateNotifier<MultiSheetJoinState> {
  /// Auto-selecting every column would be unusable on very wide sheets.
  static const int maxAutoSelectedColumns = 8;

  final MultiSheetAnalysisService service;
  final int datasetId;

  /// Incremented on every run so results of superseded runs are ignored.
  int _runToken = 0;

  MultiSheetJoinController({
    required this.service,
    required this.datasetId,
  }) : super(const MultiSheetJoinState());

  Future<void> load() async {
    state = state.copyWith(
      status: MultiSheetJoinStatus.loadingMetadata,
      clearError: true,
    );
    try {
      final sheets = await service.loadSheets(datasetId);
      final saved = await service.listSavedQueries(datasetId);
      if (!mounted) return;
      state = state.copyWith(
        status: MultiSheetJoinStatus.editing,
        sheets: sheets,
        savedQueries: saved,
      );
    } catch (error) {
      if (!mounted) return;
      state = state.copyWith(
        status: MultiSheetJoinStatus.executionError,
        errorCode: 'load_failed',
      );
    }
  }

  void toggleSheet(int tableId) {
    final selected = [...state.spec.selectedTableIds];
    final columns = {...state.spec.selectedColumnsByTableId};

    if (selected.contains(tableId)) {
      selected.remove(tableId);
      columns.remove(tableId);
    } else {
      selected.add(tableId);
      columns[tableId] = _defaultColumns(tableId);
    }

    // Drop relationships that reference a sheet no longer selected.
    final relationships = state.spec.relationships
        .where((r) =>
            selected.contains(r.leftTableId) &&
            selected.contains(r.rightTableId))
        .toList();

    final base = selected.contains(state.spec.baseTableId)
        ? state.spec.baseTableId
        : (selected.isEmpty ? null : selected.first);

    _updateSpec(state.spec.copyWith(
      selectedTableIds: selected,
      selectedColumnsByTableId: columns,
      relationships: relationships,
      baseTableId: base,
    ));
  }

  void setBaseTable(int tableId) {
    if (!state.spec.selectedTableIds.contains(tableId)) return;
    _updateSpec(state.spec.copyWith(baseTableId: tableId));
  }

  void setColumns(int tableId, List<String> dbNames) {
    final columns = {...state.spec.selectedColumnsByTableId};
    columns[tableId] = dbNames;
    _updateSpec(state.spec.copyWith(selectedColumnsByTableId: columns));
  }

  void setResultLimit(int limit) {
    if (limit <= 0) return;
    _updateSpec(state.spec.copyWith(resultLimit: limit));
  }

  Future<void> generateSuggestions() async {
    if (!state.hasEnoughSheets) return;

    state = state.copyWith(
      status: MultiSheetJoinStatus.generatingSuggestions,
      clearError: true,
    );
    try {
      final suggestions = await service.suggestRelationships(
        sheets: state.sheets,
        selectedTableIds: state.spec.selectedTableIds,
      );
      if (!mounted) return;
      state = state.copyWith(
        status: MultiSheetJoinStatus.editing,
        suggestions: suggestions,
      );
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(
        status: MultiSheetJoinStatus.editing,
        errorCode: 'suggestions_failed',
      );
    }
  }

  /// Applies a suggestion only when the user confirms it.
  void confirmSuggestion(
    SheetRelationshipSuggestion suggestion, {
    SheetJoinType joinType = SheetJoinType.inner,
  }) {
    addRelationship(
      suggestion.relationship.copyWith(joinType: joinType),
    );
  }

  void addRelationship(SheetJoinRelationship relationship) {
    final existing = state.spec.relationships;
    if (existing.any((r) => r.effectiveId == relationship.effectiveId)) {
      state = state.copyWith(
        status: MultiSheetJoinStatus.validationError,
        errorCode: MultiSheetGraphValidator.duplicateRelationshipCode,
      );
      return;
    }
    _updateSpec(state.spec.copyWith(
      relationships: [...existing, relationship],
    ));
  }

  void removeRelationship(String effectiveId) {
    _updateSpec(state.spec.copyWith(
      relationships: state.spec.relationships
          .where((r) => r.effectiveId != effectiveId)
          .toList(),
    ));
  }

  void flipRelationship(String effectiveId) {
    _updateSpec(state.spec.copyWith(
      relationships: [
        for (final r in state.spec.relationships)
          if (r.effectiveId == effectiveId) r.flipped() else r,
      ],
    ));
  }

  void setJoinType(String effectiveId, SheetJoinType joinType) {
    _updateSpec(state.spec.copyWith(
      relationships: [
        for (final r in state.spec.relationships)
          if (r.effectiveId == effectiveId)
            r.copyWith(joinType: joinType)
          else
            r,
      ],
    ));
  }

  /// Validates and generates the SQL without running it, so the UI can show the
  /// query and its warnings before the user commits to a risky join.
  bool prepare() {
    try {
      final generated =
          service.buildQuery(spec: state.spec, sheets: state.sheets);
      state = state.copyWith(
        status: MultiSheetJoinStatus.ready,
        generated: generated,
        clearError: true,
        clearPreview: true,
      );
      return true;
    } catch (error) {
      state = state.copyWith(
        status: MultiSheetJoinStatus.validationError,
        errorCode: _errorCode(error),
        clearGenerated: true,
      );
      return false;
    }
  }

  Future<void> runPreview() async {
    if (!prepare()) return;

    final token = ++_runToken;
    state = state.copyWith(
      status: MultiSheetJoinStatus.executing,
      clearError: true,
    );

    try {
      final preview = await service.runPreview(
        spec: state.spec,
        sheets: state.sheets,
      );
      // Ignore results of a superseded run.
      if (!mounted || token != _runToken) return;
      state = state.copyWith(
        status: MultiSheetJoinStatus.success,
        preview: preview,
      );
    } catch (error) {
      if (!mounted || token != _runToken) return;
      state = state.copyWith(
        status: MultiSheetJoinStatus.executionError,
        errorCode: _errorCode(error),
      );
    }
  }

  Future<void> save(String name) async {
    try {
      final saved = await service.saveQuery(
        id: state.activeSavedQueryId,
        datasetId: datasetId,
        name: name,
        spec: state.spec,
      );
      final list = await service.listSavedQueries(datasetId);
      if (!mounted) return;
      state = state.copyWith(
        savedQueries: list,
        activeSavedQueryId: saved.id,
        clearError: true,
      );
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(errorCode: 'save_failed');
    }
  }

  Future<void> loadSaved(int id) async {
    final saved = await service.loadSavedQuery(id);
    if (!mounted || saved == null) return;

    state = state.copyWith(
      spec: saved.spec,
      activeSavedQueryId: saved.id,
      clearPreview: true,
      clearGenerated: true,
      clearError: true,
      status: MultiSheetJoinStatus.editing,
    );

    // A saved spec may reference tables/columns that no longer exist.
    try {
      service.buildQuery(spec: saved.spec, sheets: state.sheets);
    } on MultiSheetGraphException catch (error) {
      if (error.code == MultiSheetGraphValidator.unavailableTableOrColumnCode) {
        state = state.copyWith(
          status: MultiSheetJoinStatus.staleSpec,
          errorCode: error.code,
        );
      }
    } catch (_) {
      // Other issues (e.g. no output columns) surface when the user runs it.
    }
  }

  Future<void> deleteSaved(int id) async {
    await service.deleteSavedQuery(id);
    final list = await service.listSavedQueries(datasetId);
    if (!mounted) return;
    state = state.copyWith(
      savedQueries: list,
      clearActiveSavedQuery: state.activeSavedQueryId == id,
    );
  }

  List<String> _defaultColumns(int tableId) {
    final sheet = state.sheets.where((s) => s.tableId == tableId).firstOrNull;
    if (sheet == null) return const [];
    return sheet.columns
        .take(maxAutoSelectedColumns)
        .map((column) => column.dbName)
        .toList();
  }

  /// Any spec edit invalidates a previously generated query/preview.
  void _updateSpec(MultiSheetQuerySpec spec) {
    state = state.copyWith(
      spec: spec,
      status: MultiSheetJoinStatus.editing,
      clearError: true,
      clearPreview: true,
      clearGenerated: true,
    );
  }

  String _errorCode(Object error) {
    if (error is MultiSheetGraphException) return error.code;
    if (error is MultiSheetSqlBuilderException) return error.code;
    return 'execution_failed';
  }
}

final multiSheetJoinControllerProvider = StateNotifierProvider.autoDispose
    .family<MultiSheetJoinController, MultiSheetJoinState, int>(
        (ref, datasetId) {
  return MultiSheetJoinController(
    service: ref.watch(multiSheetAnalysisServiceProvider),
    datasetId: datasetId,
  );
});
