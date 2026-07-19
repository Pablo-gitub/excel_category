//lib/presentation/views/sheet_joins/multi_sheet_join_controller.dart

import 'package:exlser/application/services/multi_sheet_analysis_service.dart';
import 'package:exlser/domain/entities/dataset_relationship.dart';
import 'package:exlser/domain/entities/saved_multi_sheet_query.dart';
import 'package:exlser/domain/usecases/multisheet/execute_multi_sheet_preview_usecase.dart';
import 'package:exlser/domain/usecases/multisheet/manage_dataset_relationships_usecases.dart';
import 'package:exlser/domain/usecases/multisheet/multi_sheet_graph_validator.dart';
import 'package:exlser/domain/usecases/multisheet/multi_sheet_sql_builder.dart';
import 'package:exlser/domain/value_objects/multi_sheet_join.dart';
import 'package:exlser/domain/value_objects/multi_sheet_query_spec.dart';
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

  /// Persisted relationships of the dataset, by id. The spec's joins reference these.
  final Map<int, DatasetRelationship> relationshipsById;

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
    this.relationshipsById = const {},
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

  DatasetRelationship? relationshipFor(MultiSheetJoin join) =>
      relationshipsById[join.relationshipId];

  MultiSheetJoinState copyWith({
    MultiSheetJoinStatus? status,
    List<MultiSheetSheetInfo>? sheets,
    MultiSheetQuerySpec? spec,
    Map<int, DatasetRelationship>? relationshipsById,
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
      relationshipsById: relationshipsById ?? this.relationshipsById,
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

  /// Error code set when a saved query was serialized by an unsupported version.
  static const String unsupportedSpecVersionCode = 'unsupported_spec_version';

  final MultiSheetAnalysisService service;
  final int datasetId;

  /// Incremented on every preview run so results of superseded runs are ignored.
  int _runToken = 0;

  /// Incremented on every suggestion request so stale results are ignored.
  int _suggestionToken = 0;

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
      final relationships = await service.loadRelationships(datasetId);
      if (!mounted) return;
      state = state.copyWith(
        status: MultiSheetJoinStatus.editing,
        sheets: sheets,
        savedQueries: saved,
        relationshipsById: {
          for (final r in relationships)
            if (r.id != null) r.id!: r,
        },
      );
    } catch (_) {
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

    // Drop joins whose relationship references a sheet no longer selected.
    final joins = [
      for (final join in state.spec.joins)
        if (_joinWithinSelection(join, selected)) join,
    ];

    final base = selected.contains(state.spec.baseTableId)
        ? state.spec.baseTableId
        : (selected.isEmpty ? null : selected.first);

    _updateSpec(state.spec.copyWith(
      selectedTableIds: selected,
      selectedColumnsByTableId: columns,
      joins: joins,
      baseTableId: base,
      // Deselecting the last sheet must actually drop the stale base id.
      clearBaseTableId: base == null,
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

    final token = ++_suggestionToken;
    state = state.copyWith(
      status: MultiSheetJoinStatus.generatingSuggestions,
      clearError: true,
    );
    try {
      final suggestions = await service.suggestRelationships(
        sheets: state.sheets,
        selectedTableIds: state.spec.selectedTableIds,
      );
      // Ignore a stale suggestion run superseded by a newer selection.
      if (!mounted || token != _suggestionToken) return;
      state = state.copyWith(
        status: MultiSheetJoinStatus.editing,
        suggestions: suggestions,
      );
    } catch (_) {
      if (!mounted || token != _suggestionToken) return;
      state = state.copyWith(
        status: MultiSheetJoinStatus.editing,
        errorCode: 'suggestions_failed',
      );
    }
  }

  /// Confirms a suggestion: persists the relationship (or reuses an equivalent
  /// one) and adds a join referencing it. Applied only on explicit confirmation.
  Future<void> confirmSuggestion(SheetRelationshipSuggestion suggestion) async {
    final r = suggestion.relationship;
    final relationship = DatasetRelationship(
      datasetId: datasetId,
      endpointATableId: r.leftTableId,
      endpointAColumnDbName: r.leftColumnDbName,
      endpointBTableId: r.rightTableId,
      endpointBColumnDbName: r.rightColumnDbName,
      cardinality: suggestion.cardinality,
      relationshipConfidence: suggestion.score,
      cardinalityConfidence: suggestion.cardinalityConfidence,
      sampleSize: suggestion.sampleSize,
      origin: RelationshipOrigin.suggested,
      // The user explicitly accepted this suggestion, so it is confirmed.
      confirmedAt: DateTime.now(),
    );
    await _persistAndAddJoin(relationship);
  }

  /// Creates a user-defined relationship between two columns and adds a join.
  ///
  /// Returns `true` only when the join is present in the spec after the call.
  /// Returns `false` and sets a validation error for invalid input or a
  /// relation already in the current spec.
  Future<bool> addManualRelationship({
    required int leftTableId,
    required String leftColumnDbName,
    required int rightTableId,
    required String rightColumnDbName,
  }) async {
    if (leftTableId == rightTableId ||
        leftColumnDbName.isEmpty ||
        rightColumnDbName.isEmpty) {
      state = state.copyWith(
        status: MultiSheetJoinStatus.validationError,
        errorCode: MultiSheetGraphValidator.incompleteRelationshipCode,
      );
      return false;
    }

    final selected = state.spec.selectedTableIds;
    final leftSheet =
        state.sheets.where((s) => s.tableId == leftTableId).firstOrNull;
    final rightSheet =
        state.sheets.where((s) => s.tableId == rightTableId).firstOrNull;

    if (!selected.contains(leftTableId) ||
        !selected.contains(rightTableId) ||
        leftSheet == null ||
        rightSheet == null ||
        !leftSheet.columns.any((c) => c.dbName == leftColumnDbName) ||
        !rightSheet.columns.any((c) => c.dbName == rightColumnDbName)) {
      state = state.copyWith(
        status: MultiSheetJoinStatus.validationError,
        errorCode: MultiSheetGraphValidator.unavailableTableOrColumnCode,
      );
      return false;
    }

    final relationship = DatasetRelationship(
      datasetId: datasetId,
      endpointATableId: leftTableId,
      endpointAColumnDbName: leftColumnDbName,
      endpointBTableId: rightTableId,
      endpointBColumnDbName: rightColumnDbName,
      origin: RelationshipOrigin.userDefined,
      confirmedAt: DateTime.now(),
    );
    return _persistAndAddJoin(relationship);
  }

  Future<bool> _persistAndAddJoin(DatasetRelationship relationship) async {
    if (state.spec.referencedRelationshipIds.any((id) =>
        state.relationshipsById[id]?.endpointKey == relationship.endpointKey)) {
      state = state.copyWith(
        status: MultiSheetJoinStatus.validationError,
        errorCode: MultiSheetGraphValidator.duplicateRelationshipCode,
      );
      return false;
    }

    DatasetRelationship persisted;
    try {
      persisted = await service.createRelationship(relationship);
    } on DuplicateRelationshipException catch (e) {
      // An equivalent relationship already exists; reuse it.
      final existing = state.relationshipsById[e.existingId] ??
          (await service.loadRelationships(datasetId))
              .where((r) => r.endpointKey == relationship.endpointKey)
              .firstOrNull;
      if (existing == null) return false;
      persisted = existing;
    }
    if (!mounted || persisted.id == null) return false;

    _updateSpec(
      state.spec.copyWith(
        joins: [
          ...state.spec.joins,
          MultiSheetJoin(relationshipId: persisted.id!),
        ],
      ),
      relationshipsById: {...state.relationshipsById, persisted.id!: persisted},
    );
    return true;
  }

  void removeJoin(int relationshipId) {
    _updateSpec(state.spec.copyWith(
      joins: [
        for (final join in state.spec.joins)
          if (join.relationshipId != relationshipId) join,
      ],
    ));
  }

  void setJoinType(int relationshipId, SheetJoinType joinType) {
    _updateSpec(state.spec.copyWith(
      joins: [
        for (final join in state.spec.joins)
          if (join.relationshipId == relationshipId)
            join.copyWith(
              joinType: joinType,
              // LEFT preservation is derived from the resolved rooted plan.
              // Never persist a second, potentially stale source of truth.
              clearPreservedTableId: true,
            )
          else
            join,
      ],
    ));
  }

  /// Returns the side actually preserved by the resolved rooted LEFT-join plan.
  /// An incomplete/invalid graph has no reliable preserved side yet.
  int? preservedSideFor(int relationshipId) {
    try {
      final plan = service.resolvePlan(
        datasetId: datasetId,
        spec: state.spec,
        sheets: state.sheets,
        relationshipsById: state.relationshipsById,
      );
      return plan.steps
          .where((step) => step.relationshipId == relationshipId)
          .map((step) => step.existingTableId)
          .firstOrNull;
    } catch (_) {
      return null;
    }
  }

  /// Validates and generates the SQL without running it, so the UI can show the
  /// query and its warnings before the user commits to a risky join.
  bool prepare() {
    try {
      final generated = service.buildQuery(
        datasetId: datasetId,
        spec: state.spec,
        sheets: state.sheets,
        relationshipsById: state.relationshipsById,
      );
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
        datasetId: datasetId,
        spec: state.spec,
        sheets: state.sheets,
        relationshipsById: state.relationshipsById,
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

  Future<bool> save(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      state = state.copyWith(
        status: MultiSheetJoinStatus.validationError,
        errorCode: 'save_name_required',
      );
      return false;
    }
    // A legacy/future spec must never be re-persisted; the user has to start a
    // clean v2 configuration first (see [startNewConfiguration]).
    if (state.spec.unsupportedVersion) {
      state = state.copyWith(
        status: MultiSheetJoinStatus.staleSpec,
        errorCode: unsupportedSpecVersionCode,
      );
      return false;
    }
    try {
      final saved = await service.saveQuery(
        id: state.activeSavedQueryId,
        datasetId: datasetId,
        name: trimmed,
        spec: state.spec,
      );
      final list = await service.listSavedQueries(datasetId);
      if (!mounted) return false;
      state = state.copyWith(
        savedQueries: list,
        activeSavedQueryId: saved.id,
        clearError: true,
        status: MultiSheetJoinStatus.editing,
      );
      return true;
    } catch (_) {
      if (!mounted) return false;
      state = state.copyWith(errorCode: 'save_failed');
      return false;
    }
  }

  /// Discards the current (possibly stale/unsupported) spec and starts a clean
  /// v2 configuration, detached from any saved query.
  void startNewConfiguration() {
    state = state.copyWith(
      spec: const MultiSheetQuerySpec(),
      clearActiveSavedQuery: true,
      clearPreview: true,
      clearGenerated: true,
      clearError: true,
      status: MultiSheetJoinStatus.editing,
    );
  }

  Future<bool> loadSaved(int id) async {
    if (!state.savedQueries.any((q) => q.id == id)) {
      state = state.copyWith(errorCode: 'load_saved_failed');
      return false;
    }
    try {
      final saved = await service.loadSavedQuery(id);
      if (!mounted) return false;
      if (saved == null || saved.datasetId != datasetId) {
        state = state.copyWith(errorCode: 'load_saved_failed');
        return false;
      }

      // A spec serialized by a version this build does not understand is stale
      // — never silently present it as an empty editable query.
      if (saved.spec.unsupportedVersion) {
        state = state.copyWith(
          spec: saved.spec,
          activeSavedQueryId: saved.id,
          clearPreview: true,
          clearGenerated: true,
          clearError: true,
          status: MultiSheetJoinStatus.staleSpec,
          errorCode: unsupportedSpecVersionCode,
        );
        return true;
      }

      state = state.copyWith(
        spec: saved.spec,
        activeSavedQueryId: saved.id,
        clearPreview: true,
        clearGenerated: true,
        clearError: true,
        status: MultiSheetJoinStatus.editing,
      );

      // A saved spec may reference relationships/tables/columns that no longer exist.
      try {
        service.buildQuery(
          datasetId: datasetId,
          spec: saved.spec,
          sheets: state.sheets,
          relationshipsById: state.relationshipsById,
        );
      } on MultiSheetGraphException catch (error) {
        if (error.code ==
                MultiSheetGraphValidator.unavailableTableOrColumnCode ||
            error.code == MultiSheetGraphValidator.missingRelationshipCode ||
            error.code == MultiSheetGraphValidator.foreignRelationshipCode) {
          state = state.copyWith(
            status: MultiSheetJoinStatus.staleSpec,
            errorCode: error.code,
          );
        }
      } catch (_) {
        // Other issues (e.g. no output columns) surface when the user runs it.
      }
      return true;
    } catch (_) {
      if (!mounted) return false;
      state = state.copyWith(errorCode: 'load_saved_failed');
      return false;
    }
  }

  Future<bool> deleteSaved(int id) async {
    if (!state.savedQueries.any((q) => q.id == id)) {
      state = state.copyWith(errorCode: 'delete_saved_failed');
      return false;
    }
    final wasActive = state.activeSavedQueryId == id;
    try {
      await service.deleteSavedQuery(id);
      final list = await service.listSavedQueries(datasetId);
      if (!mounted) return false;
      state = state.copyWith(
        savedQueries: list,
        clearActiveSavedQuery: wasActive,
        clearError: true,
      );
      return true;
    } catch (_) {
      if (!mounted) return false;
      state = state.copyWith(errorCode: 'delete_saved_failed');
      return false;
    }
  }

  bool _joinWithinSelection(MultiSheetJoin join, List<int> selected) {
    final relationship = state.relationshipsById[join.relationshipId];
    if (relationship == null) return false;
    return selected.contains(relationship.endpointATableId) &&
        selected.contains(relationship.endpointBTableId);
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
  void _updateSpec(
    MultiSheetQuerySpec spec, {
    Map<int, DatasetRelationship>? relationshipsById,
  }) {
    state = state.copyWith(
      spec: spec,
      relationshipsById: relationshipsById,
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
