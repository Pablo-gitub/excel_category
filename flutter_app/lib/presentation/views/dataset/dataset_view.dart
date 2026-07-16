import 'package:easy_localization/easy_localization.dart';
import 'package:exlser/application/services/export_data_service.dart';
import 'package:exlser/core/constants/app_strings.dart';
import 'package:exlser/domain/entities/dataset.dart';
import 'package:exlser/domain/entities/dataset_column.dart';
import 'package:exlser/domain/entities/dataset_table.dart';
import 'package:exlser/domain/repositories/schema_repository.dart';
import 'package:exlser/domain/value_objects/dataset_filter.dart';
import 'package:exlser/domain/value_objects/dataset_query_mode.dart';
import 'package:exlser/domain/value_objects/dataset_sort.dart';
import 'package:exlser/domain/value_objects/export_format.dart';
import 'package:exlser/domain/value_objects/pdf_export_layout.dart';
import 'package:exlser/presentation/router/routes.dart';
import 'package:exlser/presentation/providers/repository_providers.dart';
import 'package:exlser/presentation/providers/service_providers.dart';
import 'package:exlser/presentation/providers/usecase_providers.dart';
import 'package:exlser/presentation/state/dataset_bloc.dart';
import 'package:exlser/presentation/state/dataset_event.dart';
import 'package:exlser/presentation/state/dataset_state.dart';
import 'package:exlser/presentation/state/dataset_workspace_ui_state.dart';
import 'package:exlser/presentation/widgets/dataset_sections/analytics_section.dart';
import 'package:exlser/presentation/widgets/dataset_views/dataset_card_view.dart';
import 'package:exlser/presentation/widgets/dataset_views/dataset_filter_panel.dart';
import 'package:exlser/presentation/widgets/dataset_views/dataset_table_view.dart';
import 'package:exlser/presentation/widgets/layout/app_shell_actions.dart';
import 'package:exlser/presentation/widgets/layout/scroll_bottom_spacer.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

class DatasetView extends ConsumerStatefulWidget {
  final int datasetId;

  const DatasetView({
    super.key,
    required this.datasetId,
  });

  @override
  ConsumerState<DatasetView> createState() => _DatasetViewState();
}

class _DatasetViewState extends ConsumerState<DatasetView> {
  late final DatasetBloc _bloc;
  late final ExportDataService _exportDataService;
  late final SchemaRepository _schemaRepository;
  late final AppShellActionsNotifier _shellActions;

  static const String _exportActionId = 'dataset_export_action';

  @override
  void initState() {
    super.initState();

    _shellActions = ref.read(appShellActionsProvider.notifier);
    _exportDataService = ref.read(exportDataServiceProvider);
    _schemaRepository = ref.read(schemaRepositoryProvider);
    _bloc = DatasetBloc(
      openDataset: ref.read(openDatasetUseCaseProvider),
      schemaRepository: ref.read(schemaRepositoryProvider),
      fetchRows: ref.read(fetchRowsUseCaseProvider),
      applyFilters: ref.read(applyFiltersUseCaseProvider),
      executeReadOnlyQuery: ref.read(executeReadOnlyQueryUseCaseProvider),
      updateDatasetUiState: ref.read(updateDatasetUiStateUseCaseProvider),
      analysisService: ref.read(analysisServiceProvider),
    )..add(LoadDatasetEvent(widget.datasetId));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _shellActions.setAction(
        AppShellAction(
          id: _exportActionId,
          builder: (_) => _DatasetExportAction(
            bloc: _bloc,
            exportDataService: _exportDataService,
            schemaRepository: _schemaRepository,
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_shellActions.mounted) {
        _shellActions.removeAction(_exportActionId);
      }
    });
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: BlocBuilder<DatasetBloc, DatasetState>(
        builder: (context, state) {
          return switch (state) {
            DatasetInitialState() ||
            DatasetLoadingState() =>
              const Center(child: CircularProgressIndicator()),
            DatasetEmptyState(:final dataset) => _EmptyWorkspace(
                dataset: dataset,
              ),
            DatasetLoadedState() => _LoadedWorkspace(state: state),
            DatasetErrorState(:final code) => _WorkspaceError(
                code: code,
                datasetId: widget.datasetId,
              ),
          };
        },
      ),
    );
  }
}

class _DatasetExportAction extends StatefulWidget {
  final DatasetBloc bloc;
  final ExportDataService exportDataService;
  final SchemaRepository schemaRepository;

  const _DatasetExportAction({
    required this.bloc,
    required this.exportDataService,
    required this.schemaRepository,
  });

  @override
  State<_DatasetExportAction> createState() => _DatasetExportActionState();
}

class _DatasetExportActionState extends State<_DatasetExportAction> {
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DatasetBloc, DatasetState>(
      bloc: widget.bloc,
      builder: (context, state) {
        final loadedState = state is DatasetLoadedState ? state : null;

        if (_isExporting) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        return IconButton(
          icon: const Icon(Icons.ios_share),
          tooltip: AppStrings.datasetWorkspaceExportTooltip.tr(),
          onPressed: loadedState == null
              ? null
              : () => _showExportDialog(context, loadedState),
        );
      },
    );
  }

  Future<void> _showExportDialog(
    BuildContext context,
    DatasetLoadedState state,
  ) async {
    final result = await showDialog<_ExportDialogResult>(
      context: context,
      builder: (context) => _ExportDialog(state: state),
    );

    if (result == null || !context.mounted) {
      return;
    }

    await _export(context, state, result);
  }

  Future<void> _export(
    BuildContext context,
    DatasetLoadedState state,
    _ExportDialogResult result,
  ) async {
    setState(() {
      _isExporting = true;
    });

    final messenger = ScaffoldMessenger.of(context);
    final renderBox = context.findRenderObject() as RenderBox?;
    messenger.showSnackBar(
      SnackBar(
        content: Text(AppStrings.datasetWorkspaceExportStarted.tr()),
      ),
    );

    try {
      final selectedTables = [
        for (final table in state.tables)
          if (result.tableIds.contains(table.id)) table,
      ];
      final workspaceState = DatasetWorkspaceUiState.fromJsonString(
        state.dataset.uiStateJson,
      );
      final visibleColumnsByTableId = <int, List<DatasetColumn>>{};
      final filtersByTableId = <int, List<DatasetFilter>>{};
      final sortByTableId = <int, DatasetSort?>{};

      for (final table in selectedTables) {
        final isActiveTable = table.id == state.activeTable.id;
        final columns = isActiveTable
            ? state.columns
            : await widget.schemaRepository.getColumnsForTable(table.id);
        final hiddenColumnDbNames = isActiveTable
            ? state.hiddenColumnDbNames
            : workspaceState.restoreHiddenColumnDbNames(
                columns,
                tableId: table.id,
              );

        visibleColumnsByTableId[table.id] = [
          for (final column in columns)
            if (!hiddenColumnDbNames.contains(column.dbName)) column,
        ];
        filtersByTableId[table.id] = isActiveTable
            ? state.filters
            : workspaceState.restoreFilters(columns, tableId: table.id);
        sortByTableId[table.id] = isActiveTable
            ? state.sort
            : workspaceState.restoreSort(columns, tableId: table.id);
      }

      final files = await widget.exportDataService.exportSelectedTables(
        dataset: state.dataset,
        selectedTables: selectedTables,
        visibleColumnsByTableId: visibleColumnsByTableId,
        filtersByTableId: filtersByTableId,
        sortByTableId: sortByTableId,
        format: result.format,
        pdfLayout: result.pdfLayout,
      );

      if (kIsWeb || defaultTargetPlatform == TargetPlatform.iOS) {
        await SharePlus.instance.share(
          ShareParams(
            files: [
              for (final file in files)
                XFile.fromData(
                  file.bytes,
                  mimeType: file.mimeType,
                  name: file.fileName,
                ),
            ],
            fileNameOverrides: [for (final file in files) file.fileName],
            sharePositionOrigin: renderBox == null
                ? null
                : renderBox.localToGlobal(Offset.zero) & renderBox.size,
            downloadFallbackEnabled: true,
          ),
        );
      } else {
        for (final file in files) {
          await FilePicker.platform.saveFile(
            dialogTitle: file.fileName,
            fileName: file.fileName,
            bytes: file.bytes,
          );
        }
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.datasetWorkspaceExportSuccess.tr(
              namedArgs: {'count': '${files.length}'},
            ),
          ),
        ),
      );
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(AppStrings.datasetWorkspaceExportFailed.tr()),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }
}

class _ExportDialogResult {
  final Set<int> tableIds;
  final ExportFormat format;
  final PdfExportLayout pdfLayout;

  const _ExportDialogResult({
    required this.tableIds,
    required this.format,
    required this.pdfLayout,
  });
}

class _ExportDialog extends StatefulWidget {
  final DatasetLoadedState state;

  const _ExportDialog({
    required this.state,
  });

  @override
  State<_ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<_ExportDialog> {
  late Set<int> _selectedTableIds;
  ExportFormat _format = ExportFormat.excel;
  PdfExportLayout _pdfLayout = PdfExportLayout.table;

  @override
  void initState() {
    super.initState();
    _selectedTableIds = {widget.state.activeTable.id};
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppStrings.datasetWorkspaceExportDialogTitle.tr()),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.datasetWorkspaceExportSheets.tr(),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.article_outlined, size: 18),
                    label: Text(
                      AppStrings.datasetWorkspaceExportCurrentSheet.tr(),
                    ),
                    onPressed: () {
                      setState(() {
                        _selectedTableIds = {widget.state.activeTable.id};
                      });
                    },
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.dataset_outlined, size: 18),
                    label:
                        Text(AppStrings.datasetWorkspaceExportAllSheets.tr()),
                    onPressed: () {
                      setState(() {
                        _selectedTableIds = {
                          for (final table in widget.state.tables) table.id,
                        };
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              for (final table in widget.state.tables)
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: _selectedTableIds.contains(table.id),
                  title: Text(table.sheetNameOriginal),
                  subtitle: table.id == widget.state.activeTable.id
                      ? Text(
                          AppStrings.datasetWorkspaceExportCurrentSheet.tr(),
                        )
                      : null,
                  onChanged: (selected) {
                    setState(() {
                      if (selected ?? false) {
                        _selectedTableIds.add(table.id);
                      } else {
                        _selectedTableIds.remove(table.id);
                      }
                    });
                  },
                ),
              if (_selectedTableIds.isEmpty)
                Text(
                  AppStrings.datasetWorkspaceExportNoSheetSelected.tr(),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              const SizedBox(height: 16),
              Text(
                AppStrings.datasetWorkspaceExportFormat.tr(),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final format in ExportFormat.values)
                    ChoiceChip(
                      label: Text(_formatLabel(format).tr()),
                      selected: _format == format,
                      onSelected: (_) {
                        setState(() {
                          _format = format;
                        });
                      },
                    ),
                ],
              ),
              if (_format == ExportFormat.pdf) ...[
                const SizedBox(height: 16),
                Text(
                  AppStrings.datasetWorkspaceExportPdfLayout.tr(),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                SegmentedButton<PdfExportLayout>(
                  segments: [
                    ButtonSegment(
                      value: PdfExportLayout.table,
                      icon: const Icon(Icons.table_rows),
                      label: Text(
                        AppStrings.datasetWorkspaceExportPdfTable.tr(),
                      ),
                    ),
                    ButtonSegment(
                      value: PdfExportLayout.cards,
                      icon: const Icon(Icons.view_agenda),
                      label: Text(
                        AppStrings.datasetWorkspaceExportPdfCards.tr(),
                      ),
                    ),
                  ],
                  selected: {_pdfLayout},
                  onSelectionChanged: (selection) {
                    setState(() {
                      _pdfLayout = selection.single;
                    });
                  },
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppStrings.cancel.tr()),
        ),
        FilledButton.icon(
          onPressed: _selectedTableIds.isEmpty
              ? null
              : () {
                  Navigator.of(context).pop(
                    _ExportDialogResult(
                      tableIds: Set.unmodifiable(_selectedTableIds),
                      format: _format,
                      pdfLayout: _pdfLayout,
                    ),
                  );
                },
          icon: const Icon(Icons.ios_share),
          label: Text(AppStrings.datasetWorkspaceExportDialogTitle.tr()),
        ),
      ],
    );
  }

  String _formatLabel(ExportFormat format) {
    switch (format) {
      case ExportFormat.excel:
        return AppStrings.datasetWorkspaceExportExcel;
      case ExportFormat.csv:
        return AppStrings.datasetWorkspaceExportCsv;
      case ExportFormat.pdf:
        return AppStrings.datasetWorkspaceExportPdf;
      case ExportFormat.sql:
        return AppStrings.datasetWorkspaceExportSql;
      case ExportFormat.json:
        return AppStrings.datasetWorkspaceExportJson;
    }
  }
}

class _LoadedWorkspace extends StatelessWidget {
  final DatasetLoadedState state;

  const _LoadedWorkspace({
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final visibleColumns = state.visibleColumns;
    final isQueryMode = state.isReadOnlyQueryMode;
    final resultColumns =
        isQueryMode ? state.readOnlyQueryColumns : visibleColumns;
    final resultRows = isQueryMode ? state.readOnlyQueryRows : state.rows;

    return RefreshIndicator(
      onRefresh: () async {
        context.read<DatasetBloc>().add(const RefreshResultsEvent());
      },
      child: ListView(
        key: PageStorageKey(
          'dataset_workspace_${state.dataset.id}_'
          '${state.activeTable.id}_${state.queryMode.name}',
        ),
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _DatasetHeader(
                    dataset: state.dataset,
                    activeTable: state.activeTable,
                    tables: state.tables,
                    columns: state.columns,
                    visibleColumnCount: visibleColumns.length,
                    loadedRowCount: state.rows.length,
                    rowLimit: state.rowLimit,
                    totalRowCount: state.totalRowCount,
                    viewMode: state.viewMode,
                  ),
                  const SizedBox(height: 16),
                  _SheetSelector(
                    tables: state.tables,
                    activeTable: state.activeTable,
                  ),
                  if (state.tables.length >= 2) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        key: const ValueKey('combine_sheets_button'),
                        onPressed: () => context.pushNamed(
                          AppRoutes.sheetJoinsName,
                          pathParameters: {
                            AppRoutes.datasetIdParam: '${state.dataset.id}',
                          },
                        ),
                        icon: const Icon(Icons.account_tree_outlined),
                        label: Text(AppStrings.datasetJoinsAction.tr()),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _DatasetQueryModePanel(state: state),
                  const SizedBox(height: 16),
                  if (!isQueryMode) ...[
                    _ColumnVisibilitySection(
                      columns: state.columns,
                      hiddenColumnDbNames: state.hiddenColumnDbNames,
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (isQueryMode &&
                      resultRows.isEmpty &&
                      !state.hasReadOnlyQueryRun &&
                      state.readOnlyQueryErrorCode == null)
                    _QueryEmptyMessage()
                  else if (resultRows.isEmpty)
                    _NoRowsMessage(columns: resultColumns)
                  else if (state.viewMode == DatasetViewMode.table)
                    DatasetTableView(
                      columns: resultColumns,
                      rows: resultRows,
                      sort: isQueryMode ? null : state.sort,
                      onSortColumn: isQueryMode
                          ? null
                          : (column) {
                              context.read<DatasetBloc>().add(
                                    ToggleSortColumnEvent(column),
                                  );
                            },
                      columnCurrencySymbols: state.columnCurrencySymbols,
                    )
                  else
                    DatasetCardView(
                      columns: resultColumns,
                      rows: resultRows,
                      columnCurrencySymbols: state.columnCurrencySymbols,
                    ),
                  const SizedBox(height: 12),
                  if (!isQueryMode) ...[
                    _DatasetPaginationControls(state: state),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 8),
                    AnalyticsSection(state: state),
                  ] else if (resultRows.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 8),
                    AnalyticsSection(state: state),
                  ],
                ],
              ),
            ),
          ),
          const ScrollBottomSpacer(),
        ],
      ),
    );
  }
}

class _DatasetQueryModePanel extends StatelessWidget {
  final DatasetLoadedState state;

  const _DatasetQueryModePanel({
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: _QueryModeSelector(queryMode: state.queryMode),
        ),
        const SizedBox(height: 12),
        if (state.queryMode == DatasetQueryMode.filters)
          DatasetFilterPanel(
            columns: state.columns,
            rows: state.rows,
            filters: state.filters,
            onAddFilter: (filter) {
              context.read<DatasetBloc>().add(AddFilterEvent(filter));
            },
            onRemoveFilter: (filterId) {
              context.read<DatasetBloc>().add(RemoveFilterEvent(filterId));
            },
            onClearFilters: () {
              context.read<DatasetBloc>().add(const ClearFiltersEvent());
            },
          )
        else
          _ReadOnlyQueryPanel(state: state),
      ],
    );
  }
}

class _QueryModeSelector extends StatelessWidget {
  final DatasetQueryMode queryMode;

  const _QueryModeSelector({
    required this.queryMode,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 420) {
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _QueryModeChip(
                queryMode: DatasetQueryMode.filters,
                selectedQueryMode: queryMode,
                icon: Icons.filter_alt_outlined,
                label: AppStrings.datasetWorkspaceQueryTabFilters.tr(),
              ),
              _QueryModeChip(
                queryMode: DatasetQueryMode.sql,
                selectedQueryMode: queryMode,
                icon: Icons.terminal,
                label: AppStrings.datasetWorkspaceQueryTabSql.tr(),
              ),
            ],
          );
        }

        return SegmentedButton<DatasetQueryMode>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(
              value: DatasetQueryMode.filters,
              icon: const Icon(Icons.filter_alt_outlined),
              label: Text(AppStrings.datasetWorkspaceQueryTabFilters.tr()),
            ),
            ButtonSegment(
              value: DatasetQueryMode.sql,
              icon: const Icon(Icons.terminal),
              label: Text(AppStrings.datasetWorkspaceQueryTabSql.tr()),
            ),
          ],
          selected: {queryMode},
          onSelectionChanged: (selection) {
            context.read<DatasetBloc>().add(
                  ChangeQueryModeEvent(selection.single),
                );
          },
        );
      },
    );
  }
}

class _QueryModeChip extends StatelessWidget {
  final DatasetQueryMode queryMode;
  final DatasetQueryMode selectedQueryMode;
  final IconData icon;
  final String label;

  const _QueryModeChip({
    required this.queryMode,
    required this.selectedQueryMode,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      selected: selectedQueryMode == queryMode,
      onSelected: (_) {
        context.read<DatasetBloc>().add(ChangeQueryModeEvent(queryMode));
      },
    );
  }
}

class _SqlHighlightingTextEditingController extends TextEditingController {
  static final RegExp _keywordPattern = RegExp(
    r'\b(SELECT|FROM|WHERE|JOIN|LEFT|RIGHT|INNER|OUTER|ON|AS|AND|OR|NOT|IN|IS|NULL|LIKE|BETWEEN|GROUP|BY|ORDER|HAVING|LIMIT|OFFSET|DISTINCT|COUNT|SUM|AVG|MIN|MAX)\b',
    caseSensitive: false,
  );

  _SqlHighlightingTextEditingController({super.text});

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final keywordStyle = style?.copyWith(
      color: const Color(0xFFC2185B),
      fontWeight: FontWeight.w600,
    );
    final spans = <TextSpan>[];
    var currentIndex = 0;

    for (final match in _keywordPattern.allMatches(text)) {
      if (match.start > currentIndex) {
        spans.add(TextSpan(text: text.substring(currentIndex, match.start)));
      }
      spans.add(TextSpan(
        text: text.substring(match.start, match.end),
        style: keywordStyle,
      ));
      currentIndex = match.end;
    }

    if (currentIndex < text.length) {
      spans.add(TextSpan(text: text.substring(currentIndex)));
    }

    return TextSpan(style: style, children: spans);
  }
}

class _ReadOnlyQueryPanel extends StatefulWidget {
  final DatasetLoadedState state;

  const _ReadOnlyQueryPanel({
    required this.state,
  });

  @override
  State<_ReadOnlyQueryPanel> createState() => _ReadOnlyQueryPanelState();
}

class _ReadOnlyQueryPanelState extends State<_ReadOnlyQueryPanel> {
  late final _SqlHighlightingTextEditingController _queryController;
  late final TextEditingController _limitController;
  final FocusNode _queryFocusNode = FocusNode();
  String? _limitError;

  @override
  void initState() {
    super.initState();
    _queryController = _SqlHighlightingTextEditingController(
      text: widget.state.readOnlyQuery.sql,
    );
    _limitController = TextEditingController(
      text: widget.state.readOnlyQuery.limit.toString(),
    );
  }

  @override
  void didUpdateWidget(covariant _ReadOnlyQueryPanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_queryController.text != widget.state.readOnlyQuery.sql) {
      _queryController.text = widget.state.readOnlyQuery.sql;
    }
    if (_limitController.text != widget.state.readOnlyQuery.limit.toString()) {
      _limitController.text = widget.state.readOnlyQuery.limit.toString();
      _limitError = null;
    }
  }

  @override
  void dispose() {
    _queryController.dispose();
    _limitController.dispose();
    _queryFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final errorCode = widget.state.readOnlyQueryErrorCode;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    AppStrings.datasetWorkspaceQueryTitle.tr(),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (widget.state.isReadOnlyQueryRunning)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              AppStrings.datasetWorkspaceQueryIntro.tr(),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _queryController,
              focusNode: _queryFocusNode,
              minLines: 4,
              maxLines: 8,
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(
                labelText: AppStrings.datasetWorkspaceQueryEditor.tr(),
                border: const OutlineInputBorder(),
                errorText: errorCode == null
                    ? null
                    : _readOnlyQueryErrorMessage(errorCode).tr(),
              ),
              onChanged: (value) {
                context.read<DatasetBloc>().add(
                      UpdateReadOnlyQueryEvent(value),
                    );
              },
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 140,
                  child: TextField(
                    controller: _limitController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: AppStrings.datasetWorkspaceQueryLimit.tr(),
                      border: const OutlineInputBorder(),
                      isDense: true,
                      errorText: _limitError,
                    ),
                    onSubmitted: (_) => _applyLimit(context),
                  ),
                ),
                FilledButton.icon(
                  onPressed: widget.state.isReadOnlyQueryRunning
                      ? null
                      : () {
                          if (_applyLimit(context)) {
                            context
                                .read<DatasetBloc>()
                                .add(const RunReadOnlyQueryEvent());
                          }
                        },
                  icon: const Icon(Icons.play_arrow),
                  label: Text(AppStrings.run.tr()),
                ),
                TextButton.icon(
                  onPressed: () {
                    context
                        .read<DatasetBloc>()
                        .add(const ResetReadOnlyQueryEvent());
                  },
                  icon: const Icon(Icons.restart_alt),
                  label: Text(AppStrings.datasetWorkspaceQueryReset.tr()),
                ),
                TextButton.icon(
                  onPressed: () {
                    context
                        .read<DatasetBloc>()
                        .add(const ClearReadOnlyQueryEvent());
                  },
                  icon: const Icon(Icons.clear),
                  label: Text(AppStrings.clear.tr()),
                ),
                if (widget.state.hasReadOnlyQueryRun &&
                    widget.state.readOnlyQueryErrorCode == null)
                  _QueryResultSummaryNotice(
                    shownRows: widget.state.readOnlyQueryRows.length,
                    totalRows: widget.state.readOnlyQueryTotalRowCount,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _QuerySchemaHelper(
              state: widget.state,
              onInsert: _insertIdentifier,
            ),
          ],
        ),
      ),
    );
  }

  bool _applyLimit(BuildContext context) {
    final limit = int.tryParse(_limitController.text.trim());
    if (limit == null || limit <= 0) {
      setState(() {
        _limitError = AppStrings.datasetWorkspaceQueryErrorInvalidLimit.tr();
      });
      return false;
    }

    setState(() {
      _limitError = null;
    });
    context.read<DatasetBloc>().add(ChangeReadOnlyQueryLimitEvent(limit));
    return true;
  }

  void _insertIdentifier(String text) {
    final selection = _queryController.selection;
    final start =
        selection.start < 0 ? _queryController.text.length : selection.start;
    final end =
        selection.end < 0 ? _queryController.text.length : selection.end;
    final updated = _queryController.text.replaceRange(start, end, text);

    _queryController.value = TextEditingValue(
      text: updated,
      selection: TextSelection.collapsed(offset: start + text.length),
    );
    _queryFocusNode.requestFocus();
    context.read<DatasetBloc>().add(UpdateReadOnlyQueryEvent(updated));
  }
}

class _QueryResultSummaryNotice extends StatelessWidget {
  final int shownRows;
  final int totalRows;

  const _QueryResultSummaryNotice({
    required this.shownRows,
    required this.totalRows,
  });

  @override
  Widget build(BuildContext context) {
    final hasResults = totalRows > 0;
    final colorScheme = Theme.of(context).colorScheme;
    final color = hasResults ? Colors.green.shade700 : colorScheme.error;
    final background = hasResults
        ? Colors.green.withValues(alpha: 0.08)
        : colorScheme.errorContainer.withValues(alpha: 0.35);
    final icon = hasResults ? Icons.check_circle_outline : Icons.info_outline;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                AppStrings.datasetWorkspaceQueryResultSummary.tr(
                  namedArgs: {
                    'shown': '$shownRows',
                    'total': '$totalRows',
                  },
                ),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuerySchemaHelper extends StatelessWidget {
  final DatasetLoadedState state;
  final ValueChanged<String> onInsert;

  const _QuerySchemaHelper({
    required this.state,
    required this.onInsert,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.datasetWorkspaceQuerySchema.tr(),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 6),
            Text(
              AppStrings.datasetWorkspaceQueryActiveContext.tr(
                namedArgs: {'table': state.activeTable.sqlTableName},
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.short_text, size: 18),
                  label: const Text('sheet'),
                  tooltip: AppStrings.datasetWorkspaceQueryInsertTable.tr(),
                  onPressed: () => onInsert('sheet'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            for (final table in state.tables) ...[
              _QuerySchemaTableRow(
                table: table,
                columns: state.columnsByTableId[table.id] ??
                    (table.id == state.activeTable.id
                        ? state.columns
                        : const <DatasetColumn>[]),
                isActive: table.id == state.activeTable.id,
                onInsert: onInsert,
              ),
              if (table.id != state.tables.last.id) const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuerySchemaTableRow extends StatelessWidget {
  final DatasetTable table;
  final List<DatasetColumn> columns;
  final bool isActive;
  final ValueChanged<String> onInsert;

  const _QuerySchemaTableRow({
    required this.table,
    required this.columns,
    required this.isActive,
    required this.onInsert,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ActionChip(
          avatar: Icon(
            isActive ? Icons.article : Icons.article_outlined,
            size: 18,
          ),
          label: Text(table.sheetNameOriginal),
          tooltip: '${AppStrings.datasetWorkspaceQueryInsertTable.tr()}: '
              '${table.sqlTableName}',
          onPressed: () => onInsert(_quoteIdentifier(table.sqlTableName)),
        ),
        Text(
          ':',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        for (final column in columns)
          ActionChip(
            avatar: const Icon(Icons.view_column_outlined, size: 18),
            label: Text(column.originalName),
            tooltip: '${AppStrings.datasetWorkspaceQueryInsertColumn.tr()}: '
                '${table.sqlTableName}.${column.dbName}',
            onPressed: () => onInsert(_quoteIdentifier(column.dbName)),
          ),
      ],
    );
  }
}

class _DatasetHeader extends StatelessWidget {
  final Dataset dataset;
  final DatasetTable activeTable;
  final List<DatasetTable> tables;
  final List<DatasetColumn> columns;
  final int visibleColumnCount;
  final int loadedRowCount;
  final int rowLimit;
  final int totalRowCount;
  final DatasetViewMode viewMode;

  const _DatasetHeader({
    required this.dataset,
    required this.activeTable,
    required this.tables,
    required this.columns,
    required this.visibleColumnCount,
    required this.loadedRowCount,
    required this.rowLimit,
    required this.totalRowCount,
    required this.viewMode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dataset.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${AppStrings.datasetWorkspaceSourceFile.tr()}: '
                    '${dataset.sourceFileName}',
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _MetricTile(
              label: AppStrings.datasetWorkspaceSheets.tr(),
              value: '${tables.length}',
            ),
            _MetricTile(
              label: AppStrings.datasetWorkspaceColumns.tr(),
              value: visibleColumnCount == columns.length
                  ? '${columns.length}'
                  : '$visibleColumnCount / ${columns.length}',
            ),
            _MetricTile(
              label: AppStrings.datasetWorkspaceRows.tr(),
              value: '${activeTable.rowCount}',
            ),
            _MetricTile(
              label: AppStrings.datasetWorkspaceLoadedRows.tr(),
              value: '$loadedRowCount / $totalRowCount',
            ),
          ],
        ),
        const SizedBox(height: 16),
        _ViewModeSelector(viewMode: viewMode),
      ],
    );
  }
}

class _ViewModeSelector extends StatelessWidget {
  final DatasetViewMode viewMode;

  const _ViewModeSelector({
    required this.viewMode,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 420) {
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ViewModeChip(
                viewMode: DatasetViewMode.table,
                selectedViewMode: viewMode,
                icon: Icons.table_rows,
                label: AppStrings.datasetWorkspaceTableView.tr(),
              ),
              _ViewModeChip(
                viewMode: DatasetViewMode.cards,
                selectedViewMode: viewMode,
                icon: Icons.view_agenda,
                label: AppStrings.datasetWorkspaceCardView.tr(),
              ),
            ],
          );
        }

        return SegmentedButton<DatasetViewMode>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(
              value: DatasetViewMode.table,
              icon: const Icon(Icons.table_rows),
              label: Text(AppStrings.datasetWorkspaceTableView.tr()),
            ),
            ButtonSegment(
              value: DatasetViewMode.cards,
              icon: const Icon(Icons.view_agenda),
              label: Text(AppStrings.datasetWorkspaceCardView.tr()),
            ),
          ],
          selected: {viewMode},
          onSelectionChanged: (selection) {
            context.read<DatasetBloc>().add(
                  ChangeViewModeEvent(selection.single),
                );
          },
        );
      },
    );
  }
}

class _ViewModeChip extends StatelessWidget {
  final DatasetViewMode viewMode;
  final DatasetViewMode selectedViewMode;
  final IconData icon;
  final String label;

  const _ViewModeChip({
    required this.viewMode,
    required this.selectedViewMode,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      selected: selectedViewMode == viewMode,
      onSelected: (_) {
        context.read<DatasetBloc>().add(ChangeViewModeEvent(viewMode));
      },
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;

  const _MetricTile({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: 120,
        maxWidth: 180,
        minHeight: 70,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColumnVisibilitySection extends StatelessWidget {
  final List<DatasetColumn> columns;
  final List<String> hiddenColumnDbNames;

  const _ColumnVisibilitySection({
    required this.columns,
    required this.hiddenColumnDbNames,
  });

  @override
  Widget build(BuildContext context) {
    if (columns.isEmpty) {
      return const SizedBox.shrink();
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.datasetWorkspaceVisibleColumns.tr(),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              AppStrings.datasetWorkspaceVisibleColumnsHint.tr(),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final column in columns)
                  FilterChip(
                    label: Text(column.originalName),
                    selected: !hiddenColumnDbNames.contains(column.dbName),
                    onSelected: (selected) {
                      context.read<DatasetBloc>().add(
                            SetColumnHiddenEvent(
                              columnDbName: column.dbName,
                              hidden: !selected,
                            ),
                          );
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DatasetPaginationControls extends StatefulWidget {
  final DatasetLoadedState state;

  const _DatasetPaginationControls({
    required this.state,
  });

  @override
  State<_DatasetPaginationControls> createState() =>
      _DatasetPaginationControlsState();
}

class _DatasetPaginationControlsState
    extends State<_DatasetPaginationControls> {
  late final TextEditingController _limitController;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _limitController = TextEditingController(
      text: widget.state.rowLimit.toString(),
    );
  }

  @override
  void didUpdateWidget(covariant _DatasetPaginationControls oldWidget) {
    super.didUpdateWidget(oldWidget);

    final currentText = _limitController.text.trim();
    final currentValue = int.tryParse(currentText);
    if (currentValue == oldWidget.state.rowLimit &&
        widget.state.rowLimit != oldWidget.state.rowLimit) {
      _limitController.text = widget.state.rowLimit.toString();
      _errorText = null;
    }
  }

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final firstRow =
        state.totalRowCount == 0 ? 0 : (state.pageIndex * state.rowLimit) + 1;
    final lastRow = state.totalRowCount == 0
        ? 0
        : (state.pageIndex * state.rowLimit + state.rows.length);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 150,
              child: TextField(
                controller: _limitController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: AppStrings.datasetWorkspaceRowsPerPage.tr(),
                  border: const OutlineInputBorder(),
                  isDense: true,
                  errorText: _errorText,
                ),
                onSubmitted: (_) => _applyLimit(context),
              ),
            ),
            FilledButton.tonal(
              onPressed: () => _applyLimit(context),
              child: Text(AppStrings.apply.tr()),
            ),
            Text(
              AppStrings.datasetWorkspacePaginationRange.tr(
                namedArgs: {
                  'from': '$firstRow',
                  'to': '$lastRow',
                  'total': '${state.totalRowCount}',
                },
              ),
            ),
            Text(
              AppStrings.datasetWorkspacePaginationPage.tr(
                namedArgs: {
                  'page': '${state.pageNumber}',
                  'pages': '${state.pageCount}',
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_left),
              tooltip: AppStrings.previous.tr(),
              onPressed: state.canGoToPreviousPage
                  ? () {
                      context
                          .read<DatasetBloc>()
                          .add(ChangePageEvent(state.pageIndex - 1));
                    }
                  : null,
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              tooltip: AppStrings.next.tr(),
              onPressed: state.canGoToNextPage
                  ? () {
                      context
                          .read<DatasetBloc>()
                          .add(ChangePageEvent(state.pageIndex + 1));
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  void _applyLimit(BuildContext context) {
    final value = int.tryParse(_limitController.text.trim());
    if (value == null || value <= 0) {
      setState(() {
        _errorText = AppStrings.datasetWorkspacePaginationInvalidLimit.tr();
      });
      return;
    }

    setState(() {
      _errorText = null;
    });
    context.read<DatasetBloc>().add(ChangeRowLimitEvent(value));
  }
}

class _SheetSelector extends StatelessWidget {
  final List<DatasetTable> tables;
  final DatasetTable activeTable;

  const _SheetSelector({
    required this.tables,
    required this.activeTable,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      initialValue: activeTable.id,
      decoration: InputDecoration(
        labelText: AppStrings.datasetWorkspaceSelectSheet.tr(),
        border: const OutlineInputBorder(),
      ),
      items: [
        for (final table in tables)
          DropdownMenuItem(
            value: table.id,
            child: Text(table.sheetNameOriginal),
          ),
      ],
      onChanged: (tableId) {
        if (tableId == null) return;

        context.read<DatasetBloc>().add(ChangeSheetEvent(tableId));
      },
    );
  }
}

class _NoRowsMessage extends StatelessWidget {
  final List<DatasetColumn> columns;

  const _NoRowsMessage({
    required this.columns,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.table_chart_outlined, size: 40),
            const SizedBox(height: 12),
            Text(AppStrings.datasetWorkspaceNoRows.tr()),
            if (columns.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final column in columns)
                    Chip(label: Text(column.originalName)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QueryEmptyMessage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.terminal, size: 40),
            const SizedBox(height: 12),
            Text(
              AppStrings.datasetWorkspaceQueryEmptyResult.tr(),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyWorkspace extends StatelessWidget {
  final Dataset dataset;

  const _EmptyWorkspace({
    required this.dataset,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.folder_open, size: 48),
            const SizedBox(height: 16),
            Text(
              dataset.name,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.datasetWorkspaceNoTables.tr(),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkspaceError extends StatelessWidget {
  final String code;
  final int datasetId;

  const _WorkspaceError({
    required this.code,
    required this.datasetId,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 16),
            Text(
              _workspaceErrorMessage(code).tr(),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.tonalIcon(
              onPressed: () {
                context.read<DatasetBloc>().add(LoadDatasetEvent(datasetId));
              },
              icon: const Icon(Icons.refresh),
              label: Text(AppStrings.retry.tr()),
            ),
          ],
        ),
      ),
    );
  }
}

String _workspaceErrorMessage(String code) {
  switch (code) {
    case 'filter_failed':
      return AppStrings.datasetWorkspaceFilterFailed;
    case 'sort_failed':
      return AppStrings.datasetWorkspaceSortFailed;
    case 'pagination_failed':
      return AppStrings.datasetWorkspacePaginationFailed;
    case 'sheet_failed':
      return AppStrings.datasetWorkspaceSheetFailed;
    case 'refresh_failed':
      return AppStrings.datasetWorkspaceRefreshFailed;
    case 'load_failed':
    default:
      return AppStrings.datasetWorkspaceLoadFailed;
  }
}

String _readOnlyQueryErrorMessage(String code) {
  switch (code) {
    case 'empty':
      return AppStrings.datasetWorkspaceQueryErrorEmpty;
    case 'not_select':
      return AppStrings.datasetWorkspaceQueryErrorNotSelect;
    case 'unsafe_statement':
      return AppStrings.datasetWorkspaceQueryErrorUnsafe;
    case 'multiple_statements':
      return AppStrings.datasetWorkspaceQueryErrorMultiple;
    case 'unknown_table':
      return AppStrings.datasetWorkspaceQueryErrorUnknownTable;
    case 'invalid_limit':
      return AppStrings.datasetWorkspaceQueryErrorInvalidLimit;
    case 'execution_failed':
    default:
      return AppStrings.datasetWorkspaceQueryErrorExecution;
  }
}

String _quoteIdentifier(String value) {
  return '"${value.replaceAll('"', '""')}"';
}
