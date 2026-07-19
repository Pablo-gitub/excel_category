//lib/presentation/views/sheet_joins/sheet_joins_view.dart

import 'package:easy_localization/easy_localization.dart';
import 'package:exlser/application/services/multi_sheet_analysis_service.dart';
import 'package:exlser/core/constants/app_strings.dart';
import 'package:exlser/domain/usecases/multisheet/multi_sheet_graph_validator.dart';
import 'package:exlser/domain/usecases/multisheet/multi_sheet_join_risk_analyzer.dart';
import 'package:exlser/domain/usecases/multisheet/multi_sheet_sql_builder.dart';
import 'package:exlser/domain/entities/dataset_relationship.dart';
import 'package:exlser/domain/value_objects/multi_sheet_join.dart';
import 'package:exlser/domain/value_objects/sheet_join_relationship.dart';
import 'package:exlser/domain/value_objects/sheet_join_type.dart';
import 'package:exlser/domain/value_objects/sheet_relationship_suggestion.dart';
import 'package:exlser/presentation/views/sheet_joins/manual_relationship_dialog.dart';
import 'package:exlser/presentation/views/sheet_joins/join_risk_confirmation_dialog.dart';
import 'package:exlser/presentation/views/sheet_joins/multi_sheet_join_controller.dart';
import 'package:exlser/presentation/views/sheet_joins/saved_join_configurations_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Guided workspace to combine two or more sheets of the same dataset.
///
/// Takes only a [datasetId]: it reads everything through
/// [MultiSheetJoinController] and never touches `DatasetBloc`.
class SheetJoinsView extends ConsumerStatefulWidget {
  final int datasetId;

  const SheetJoinsView({super.key, required this.datasetId});

  @override
  ConsumerState<SheetJoinsView> createState() => _SheetJoinsViewState();
}

class _SheetJoinsViewState extends ConsumerState<SheetJoinsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(multiSheetJoinControllerProvider(widget.datasetId).notifier)
          .load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = multiSheetJoinControllerProvider(widget.datasetId);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);

    if (state.status == MultiSheetJoinStatus.initial ||
        state.status == MultiSheetJoinStatus.loadingMetadata) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              AppStrings.datasetJoinsLoading.tr(),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    if (!state.canConfigure) {
      return _Message(
        icon: Icons.grid_view_outlined,
        text: AppStrings.datasetJoinsErrorNotEnoughTables.tr(),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = constraints.maxWidth >= 720 ? 24.0 : 12.0;
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: ListView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 16,
              ),
              children: [
                Text(
                  AppStrings.datasetJoinsSubtitle.tr(),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                SavedJoinConfigurationsPanel(
                    state: state, controller: controller),
                const SizedBox(height: 16),
                _SheetPicker(state: state, controller: controller),
                const SizedBox(height: 16),
                if (state.hasEnoughSheets) ...[
                  _BaseSheetPicker(state: state, controller: controller),
                  const SizedBox(height: 16),
                  _SuggestionsSection(state: state, controller: controller),
                  const SizedBox(height: 16),
                  _RelationshipsSection(state: state, controller: controller),
                  const SizedBox(height: 16),
                  _OutputColumnsSection(state: state, controller: controller),
                  const SizedBox(height: 16),
                ],
                _ErrorBanner(state: state),
                _WarningsBanner(state: state),
                const SizedBox(height: 8),
                _RunBar(state: state, controller: controller),
                const SizedBox(height: 16),
                _PreviewSection(state: state),
                const SizedBox(height: 16),
                _GeneratedSqlSection(state: state),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String? hint;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({
    required this.title,
    required this.child,
    this.hint,
    this.trailing,
  });

  Widget _buildHeader(BuildContext context) {
    final titleText = Text(
      title,
      style: Theme.of(context).textTheme.titleMedium,
    );
    if (trailing == null) return titleText;

    return LayoutBuilder(
      builder: (context, constraints) {
        // On roomy rows keep the action right-aligned; on narrow widths let it
        // wrap below the title instead of overflowing.
        if (constraints.maxWidth >= 420) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: titleText),
              const SizedBox(width: 8),
              trailing!,
            ],
          );
        }
        return Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [titleText, trailing!],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            if (hint != null) ...[
              const SizedBox(height: 4),
              Text(
                hint!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final String text;
  final IconData? icon;

  const _Message({required this.text, this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 48,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 12),
            ],
            Text(text, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _SheetPicker extends StatelessWidget {
  final MultiSheetJoinState state;
  final MultiSheetJoinController controller;

  const _SheetPicker({required this.state, required this.controller});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: AppStrings.datasetJoinsSelectSheets.tr(),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final sheet in state.sheets)
            FilterChip(
              key: ValueKey('join_sheet_${sheet.tableId}'),
              label: Text(sheet.label),
              showCheckmark: false,
              selected: state.spec.selectedTableIds.contains(sheet.tableId),
              onSelected: (_) => controller.toggleSheet(sheet.tableId),
            ),
        ],
      ),
    );
  }
}

class _BaseSheetPicker extends StatelessWidget {
  final MultiSheetJoinState state;
  final MultiSheetJoinController controller;

  const _BaseSheetPicker({required this.state, required this.controller});

  @override
  Widget build(BuildContext context) {
    final selected = state.sheets
        .where((s) => state.spec.selectedTableIds.contains(s.tableId))
        .toList();

    return _SectionCard(
      title: AppStrings.datasetJoinsBaseSheet.tr(),
      hint: AppStrings.datasetJoinsBaseSheetHint.tr(),
      child: DropdownButtonFormField<int>(
        key: const ValueKey('join_base_sheet'),
        isExpanded: true,
        initialValue: state.spec.baseTableId,
        items: [
          for (final sheet in selected)
            DropdownMenuItem(
              value: sheet.tableId,
              child: Text(sheet.label, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: (value) {
          if (value != null) controller.setBaseTable(value);
        },
      ),
    );
  }
}

class _SuggestionsSection extends StatelessWidget {
  final MultiSheetJoinState state;
  final MultiSheetJoinController controller;

  const _SuggestionsSection({required this.state, required this.controller});

  @override
  Widget build(BuildContext context) {
    final busy = state.status == MultiSheetJoinStatus.generatingSuggestions;

    return _SectionCard(
      title: AppStrings.datasetJoinsSuggestions.tr(),
      trailing: TextButton.icon(
        key: const ValueKey('join_suggest_button'),
        onPressed: busy ? null : controller.generateSuggestions,
        icon: const Icon(Icons.auto_awesome_outlined),
        label: Text(AppStrings.datasetJoinsSuggest.tr()),
      ),
      child: busy
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(),
            )
          : state.suggestions.isEmpty
              ? Text(AppStrings.datasetJoinsNoSuggestions.tr())
              : Column(
                  children: [
                    for (final suggestion in state.suggestions)
                      _SuggestionTile(
                        suggestion: suggestion,
                        state: state,
                        controller: controller,
                      ),
                  ],
                ),
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  final SheetRelationshipSuggestion suggestion;
  final MultiSheetJoinState state;
  final MultiSheetJoinController controller;

  const _SuggestionTile({
    required this.suggestion,
    required this.state,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final key = _suggestionEndpointKey(suggestion.relationship);
    final already = state.spec.joins.any(
      (join) => state.relationshipFor(join)?.endpointKey == key,
    );

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(_describeRelationship(state, suggestion.relationship)),
      subtitle: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          _ConfidenceChip(confidence: suggestion.confidence),
          for (final reason in suggestion.reasons)
            Chip(
              label: Text(_reasonLabel(reason)),
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
      trailing: already
          ? Tooltip(
              message: AppStrings.datasetJoinsRelationshipAlreadyAdded.tr(),
              child: Icon(
                Icons.check_circle_outline,
                semanticLabel:
                    AppStrings.datasetJoinsRelationshipAlreadyAdded.tr(),
              ),
            )
          : FilledButton.tonal(
              onPressed: () => controller.confirmSuggestion(suggestion),
              child: Text(AppStrings.datasetJoinsConfirm.tr()),
            ),
    );
  }
}

/// Confidence indicator that does not rely on color alone: each level carries a
/// distinct icon shape and a text label, with color as reinforcement only.
class _ConfidenceChip extends StatelessWidget {
  final SuggestionConfidence confidence;

  const _ConfidenceChip({required this.confidence});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (icon, color) = switch (confidence) {
      SuggestionConfidence.high => (Icons.signal_cellular_alt, scheme.primary),
      SuggestionConfidence.medium => (
          Icons.signal_cellular_alt_2_bar,
          scheme.tertiary,
        ),
      SuggestionConfidence.low => (
          Icons.signal_cellular_alt_1_bar,
          scheme.outline,
        ),
    };
    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(_confidenceLabel(confidence)),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _RelationshipsSection extends StatelessWidget {
  final MultiSheetJoinState state;
  final MultiSheetJoinController controller;

  const _RelationshipsSection({required this.state, required this.controller});

  @override
  Widget build(BuildContext context) {
    final joins = state.spec.joins;
    return _SectionCard(
      title: AppStrings.datasetJoinsRelationships.tr(),
      trailing: TextButton.icon(
        key: const ValueKey('manual_relationship_open'),
        onPressed: () => showManualRelationshipDialog(
          context: context,
          state: state,
          controller: controller,
        ),
        icon: const Icon(Icons.add_link),
        label: Text(AppStrings.datasetJoinsAddRelationship.tr()),
      ),
      child: joins.isEmpty
          ? Text(AppStrings.datasetJoinsNoRelationships.tr())
          : Column(
              children: [
                for (final join in joins)
                  if (state.relationshipFor(join) case final relationship?)
                    _RelationshipTile(
                      join: join,
                      relationship: relationship,
                      state: state,
                      controller: controller,
                    ),
              ],
            ),
    );
  }
}

class _RelationshipTile extends StatelessWidget {
  final MultiSheetJoin join;
  final DatasetRelationship relationship;
  final MultiSheetJoinState state;
  final MultiSheetJoinController controller;

  const _RelationshipTile({
    required this.join,
    required this.relationship,
    required this.state,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(_describeEndpoints(state, relationship))),
              IconButton(
                tooltip: AppStrings.datasetJoinsRemove.tr(),
                icon: const Icon(Icons.delete_outline),
                onPressed: () => controller.removeJoin(join.relationshipId),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: SegmentedButton<SheetJoinType>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: SheetJoinType.inner,
                  label: Text(AppStrings.datasetJoinsJoinInner.tr()),
                ),
                ButtonSegment(
                  value: SheetJoinType.left,
                  label: Text(AppStrings.datasetJoinsJoinLeft.tr()),
                ),
              ],
              selected: {join.joinType},
              onSelectionChanged: (values) => controller.setJoinType(
                join.relationshipId,
                values.first,
              ),
            ),
          ),
          // The preserved side of a LEFT join is derived (SQL accumulates from
          // the base), so it is shown read-only. To preserve the other side the
          // user changes the base table rather than picking an invalid side.
          if (join.isLeft) ...[
            const SizedBox(height: 6),
            if (controller.preservedSideFor(join.relationshipId)
                case final preservedTableId?)
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      AppStrings.datasetJoinsLeftKeeps.tr(
                        namedArgs: {
                          'sheet': _sheetLabel(state, preservedTableId),
                        },
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }
}

class _OutputColumnsSection extends StatelessWidget {
  final MultiSheetJoinState state;
  final MultiSheetJoinController controller;

  const _OutputColumnsSection({required this.state, required this.controller});

  @override
  Widget build(BuildContext context) {
    final selected = state.sheets
        .where((s) => state.spec.selectedTableIds.contains(s.tableId))
        .toList();

    return _SectionCard(
      title: AppStrings.datasetJoinsOutputColumns.tr(),
      hint: AppStrings.datasetJoinsOutputColumnsHint.tr(),
      child: Column(
        children: [
          for (final sheet in selected)
            ExpansionTile(
              key: ValueKey('join_columns_${sheet.tableId}'),
              tilePadding: EdgeInsets.zero,
              title: Text(sheet.label),
              subtitle: Text(
                '${state.spec.columnsForTable(sheet.tableId).length}/${sheet.columns.length}',
              ),
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final column in sheet.columns)
                      FilterChip(
                        label: Text(column.originalName),
                        showCheckmark: false,
                        selected: state.spec
                            .columnsForTable(sheet.tableId)
                            .contains(column.dbName),
                        onSelected: (isSelected) {
                          final current = [
                            ...state.spec.columnsForTable(sheet.tableId)
                          ];
                          if (isSelected) {
                            current.add(column.dbName);
                          } else {
                            current.remove(column.dbName);
                          }
                          controller.setColumns(sheet.tableId, current);
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final MultiSheetJoinState state;

  const _ErrorBanner({required this.state});

  @override
  Widget build(BuildContext context) {
    final code = state.errorCode;
    if (code == null) return const SizedBox.shrink();

    final isStale = state.status == MultiSheetJoinStatus.staleSpec;
    final scheme = Theme.of(context).colorScheme;

    return Card(
      key: const ValueKey('join_error_banner'),
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: scheme.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isStale
                    ? AppStrings.datasetJoinsStaleSpec.tr()
                    : _errorMessage(code),
                style: TextStyle(color: scheme.onErrorContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WarningsBanner extends StatelessWidget {
  final MultiSheetJoinState state;

  const _WarningsBanner({required this.state});

  @override
  Widget build(BuildContext context) {
    final warnings = state.generated?.warnings ?? const <JoinRiskWarning>[];
    if (warnings.isEmpty) return const SizedBox.shrink();

    return Card(
      key: const ValueKey('join_warning_banner'),
      color: Theme.of(context).colorScheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < warnings.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_outlined),
                  const SizedBox(width: 12),
                  Expanded(child: Text(localizedJoinRiskWarning(warnings[i]))),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RunBar extends StatelessWidget {
  final MultiSheetJoinState state;
  final MultiSheetJoinController controller;

  const _RunBar({required this.state, required this.controller});

  Future<void> _requestPreview(BuildContext context) async {
    final generated = controller.prepare();
    if (generated == null) return;

    if (generated.hasWarnings) {
      final confirmed = await showJoinRiskConfirmationDialog(
        context: context,
        warnings: generated.warnings,
      );
      if (!confirmed || !context.mounted) return;
    }

    await controller.executePreparedPreview();
  }

  @override
  Widget build(BuildContext context) {
    final running = state.status == MultiSheetJoinStatus.executing;

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        key: const ValueKey('join_run_button'),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onPressed: (!state.hasEnoughSheets || running)
            ? null
            : () => _requestPreview(context),
        icon: running
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.play_arrow),
        label: Text(AppStrings.datasetJoinsRun.tr()),
      ),
    );
  }
}

class _PreviewSection extends StatelessWidget {
  final MultiSheetJoinState state;

  const _PreviewSection({required this.state});

  @override
  Widget build(BuildContext context) {
    final preview = state.preview;
    if (preview == null) return const SizedBox.shrink();

    return _SectionCard(
      title: AppStrings.datasetJoinsPreview.tr(),
      hint: AppStrings.datasetJoinsPreviewLimited.tr(
        namedArgs: {'limit': '${preview.limit}'},
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Headers exist even with zero rows, so the table is always meaningful.
          // DataTable asserts on an empty column list, so guard it.
          if (preview.outputColumns.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                key: const ValueKey('join_preview_table'),
                columns: [
                  for (final column in preview.outputColumns)
                    DataColumn(label: Text(column.label)),
                ],
                rows: [
                  for (final row in preview.rows)
                    DataRow(
                      cells: [
                        for (final column in preview.outputColumns)
                          DataCell(Text('${row[column.alias] ?? ''}')),
                      ],
                    ),
                ],
              ),
            ),
          if (preview.isEmpty) ...[
            const SizedBox(height: 12),
            Text(AppStrings.datasetJoinsEmptyResult.tr()),
          ],
          if (preview.isTruncated) ...[
            const SizedBox(height: 12),
            Text(
              AppStrings.datasetJoinsPreviewTruncated.tr(),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _GeneratedSqlSection extends StatelessWidget {
  final MultiSheetJoinState state;

  const _GeneratedSqlSection({required this.state});

  @override
  Widget build(BuildContext context) {
    final generated = state.generated;
    if (generated == null) return const SizedBox.shrink();

    return Card(
      child: ExpansionTile(
        key: const ValueKey('join_generated_sql'),
        title: Text(AppStrings.datasetJoinsGeneratedSql.tr()),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SelectableText(
                generated.sql,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _side(MultiSheetJoinState state, int tableId, String dbName) {
  final sheet = _sheetFor(state, tableId);
  final column = sheet?.columns
      .where((c) => c.dbName == dbName)
      .map((c) => c.originalName)
      .firstOrNull;
  return '${sheet?.label ?? tableId}.${column ?? dbName}';
}

String _describeRelationship(
  MultiSheetJoinState state,
  SheetJoinRelationship relationship,
) {
  return '${_side(state, relationship.leftTableId, relationship.leftColumnDbName)}'
      '  ↔  '
      '${_side(state, relationship.rightTableId, relationship.rightColumnDbName)}';
}

String _describeEndpoints(
  MultiSheetJoinState state,
  DatasetRelationship relationship,
) {
  return '${_side(state, relationship.endpointATableId, relationship.endpointAColumnDbName)}'
      '  ↔  '
      '${_side(state, relationship.endpointBTableId, relationship.endpointBColumnDbName)}';
}

String _suggestionEndpointKey(SheetJoinRelationship relationship) {
  final a =
      '${relationship.leftTableId}.${relationship.leftColumnDbName.trim()}';
  final b =
      '${relationship.rightTableId}.${relationship.rightColumnDbName.trim()}';
  final ends = [a, b]..sort();
  return ends.join('=');
}

String _sheetLabel(MultiSheetJoinState state, int tableId) {
  return _sheetFor(state, tableId)?.label ?? '$tableId';
}

MultiSheetSheetInfo? _sheetFor(MultiSheetJoinState state, int tableId) {
  return state.sheets.where((s) => s.tableId == tableId).firstOrNull;
}

String _confidenceLabel(SuggestionConfidence confidence) {
  return switch (confidence) {
    SuggestionConfidence.high => AppStrings.datasetJoinsConfidenceHigh.tr(),
    SuggestionConfidence.medium => AppStrings.datasetJoinsConfidenceMedium.tr(),
    SuggestionConfidence.low => AppStrings.datasetJoinsConfidenceLow.tr(),
  };
}

String _reasonLabel(RelationshipReason reason) {
  return switch (reason) {
    RelationshipReason.nameMatch => AppStrings.datasetJoinsReasonNameMatch.tr(),
    RelationshipReason.commonIdentifier =>
      AppStrings.datasetJoinsReasonCommonIdentifier.tr(),
    RelationshipReason.valueOverlap =>
      AppStrings.datasetJoinsReasonValueOverlap.tr(),
    RelationshipReason.typeMatch => AppStrings.datasetJoinsReasonTypeMatch.tr(),
  };
}

String _errorMessage(String code) {
  return switch (code) {
    MultiSheetGraphValidator.notEnoughTablesCode =>
      AppStrings.datasetJoinsErrorNotEnoughTables.tr(),
    MultiSheetGraphValidator.unavailableTableOrColumnCode =>
      AppStrings.datasetJoinsErrorUnavailableTableOrColumn.tr(),
    MultiSheetGraphValidator.incompleteRelationshipCode =>
      AppStrings.datasetJoinsErrorIncompleteRelationship.tr(),
    MultiSheetGraphValidator.duplicateRelationshipCode =>
      AppStrings.datasetJoinsErrorDuplicateRelationship.tr(),
    MultiSheetGraphValidator.disconnectedGraphCode =>
      AppStrings.datasetJoinsErrorDisconnectedGraph.tr(),
    MultiSheetGraphValidator.cycleDetectedCode =>
      AppStrings.datasetJoinsErrorCycleDetected.tr(),
    MultiSheetSqlBuilder.noOutputColumnsCode =>
      AppStrings.datasetJoinsErrorNoOutputColumns.tr(),
    'save_name_required' => AppStrings.datasetJoinsSaveNameRequired.tr(),
    'save_failed' => AppStrings.datasetJoinsSaveFailed.tr(),
    'load_saved_failed' => AppStrings.datasetJoinsLoadSavedFailed.tr(),
    'delete_saved_failed' => AppStrings.datasetJoinsDeleteSavedFailed.tr(),
    _ => AppStrings.datasetJoinsErrorGeneric.tr(),
  };
}
