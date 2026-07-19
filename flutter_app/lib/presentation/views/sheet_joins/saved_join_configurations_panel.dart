//lib/presentation/views/sheet_joins/saved_join_configurations_panel.dart

import 'package:easy_localization/easy_localization.dart';
import 'package:exlser/core/constants/app_strings.dart';
import 'package:exlser/domain/entities/saved_multi_sheet_query.dart';
import 'package:exlser/presentation/views/sheet_joins/multi_sheet_join_controller.dart';
import 'package:flutter/material.dart';

/// Displays saved join configurations and provides New / Save / Open / Delete actions.
///
/// Receives [state] and [controller] from the parent; no Riverpod inside this widget.
class SavedJoinConfigurationsPanel extends StatelessWidget {
  final MultiSheetJoinState state;
  final MultiSheetJoinController controller;

  const SavedJoinConfigurationsPanel({
    super.key,
    required this.state,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const ValueKey('saved_configurations_panel'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  AppStrings.datasetJoinsSavedQueries.tr(),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextButton(
                  key: const ValueKey('saved_configuration_new'),
                  onPressed: () => _onNew(context),
                  child: Text(AppStrings.datasetJoinsNewConfiguration.tr()),
                ),
                TextButton(
                  key: const ValueKey('saved_configuration_save'),
                  onPressed: () => _showSaveDialog(context),
                  child: Text(AppStrings.datasetJoinsSave.tr()),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (state.savedQueries.isEmpty)
              Text(
                AppStrings.datasetJoinsNoSavedQueries.tr(),
                key: const ValueKey('saved_configuration_empty'),
                style: Theme.of(context).textTheme.bodySmall,
              )
            else
              for (final query in state.savedQueries)
                if (query.id != null)
                  _SavedQueryTile(
                    key: ValueKey('saved_configuration_${query.id}'),
                    query: query,
                    isActive: query.id == state.activeSavedQueryId,
                    controller: controller,
                  ),
          ],
        ),
      ),
    );
  }

  void _onNew(BuildContext context) {
    final spec = state.spec;
    final isEffectivelyEmpty = spec.isEmpty && state.activeSavedQueryId == null;
    if (isEffectivelyEmpty) {
      controller.startNewConfiguration();
      return;
    }
    showDialog<void>(
      context: context,
      builder: (_) => _DiscardConfigurationDialog(controller: controller),
    );
  }

  void _showSaveDialog(BuildContext context) {
    final activeName = state.savedQueries
        .where((q) => q.id == state.activeSavedQueryId)
        .map((q) => q.name)
        .firstOrNull;
    showDialog<void>(
      context: context,
      builder: (_) => _SaveConfigurationDialog(
        controller: controller,
        initialName: activeName ?? '',
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Per-item tile
// ---------------------------------------------------------------------------

class _SavedQueryTile extends StatefulWidget {
  final SavedMultiSheetQuery query;
  final bool isActive;
  final MultiSheetJoinController controller;

  const _SavedQueryTile({
    super.key,
    required this.query,
    required this.isActive,
    required this.controller,
  });

  @override
  State<_SavedQueryTile> createState() => _SavedQueryTileState();
}

class _SavedQueryTileState extends State<_SavedQueryTile> {
  bool _loading = false;

  Future<void> _open() async {
    setState(() => _loading = true);
    await widget.controller.loadSaved(widget.query.id!);
    if (mounted) setState(() => _loading = false);
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => _DeleteConfigurationDialog(
        query: widget.query,
        controller: widget.controller,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.query.id!;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: widget.isActive
          ? Icon(
              Icons.check,
              key: ValueKey('saved_configuration_active_$id'),
              semanticLabel: AppStrings.datasetJoinsActiveConfiguration.tr(),
            )
          : const SizedBox(width: 24),
      selected: widget.isActive,
      title: Text(widget.query.name),
      subtitle: Text(
        MaterialLocalizations.of(context)
            .formatShortDate(widget.query.updatedAt),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            key: ValueKey('saved_configuration_open_$id'),
            tooltip: AppStrings.datasetJoinsOpenConfiguration.tr(),
            onPressed: _loading ? null : _open,
            icon: const Icon(Icons.folder_open_outlined),
          ),
          IconButton(
            key: ValueKey('saved_configuration_delete_$id'),
            tooltip: AppStrings.datasetJoinsDelete.tr(),
            onPressed: _loading ? null : () => _showDeleteDialog(context),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Save dialog
// ---------------------------------------------------------------------------

class _SaveConfigurationDialog extends StatefulWidget {
  final MultiSheetJoinController controller;
  final String initialName;

  const _SaveConfigurationDialog({
    required this.controller,
    required this.initialName,
  });

  @override
  State<_SaveConfigurationDialog> createState() =>
      _SaveConfigurationDialogState();
}

class _SaveConfigurationDialogState extends State<_SaveConfigurationDialog> {
  late final TextEditingController _nameController;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = AppStrings.datasetJoinsSaveNameRequired.tr());
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final success = await widget.controller.save(name);
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _saving = false;
        _error = AppStrings.datasetJoinsSaveFailed.tr();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const ValueKey('save_configuration_dialog'),
      title: Text(AppStrings.datasetJoinsSaveConfigurationTitle.tr()),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              key: const ValueKey('saved_configuration_name'),
              controller: _nameController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: AppStrings.datasetJoinsSaveName.tr(),
              ),
              onFieldSubmitted: (_) {
                if (!_saving) _submit();
              },
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _error!,
                  key: const ValueKey('save_configuration_error'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const ValueKey('save_configuration_cancel'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          key: const ValueKey('save_configuration_submit'),
          onPressed: _saving ? null : _submit,
          child: Text(AppStrings.datasetJoinsSave.tr()),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Discard (New) dialog
// ---------------------------------------------------------------------------

class _DiscardConfigurationDialog extends StatelessWidget {
  final MultiSheetJoinController controller;

  const _DiscardConfigurationDialog({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const ValueKey('new_configuration_dialog'),
      title: Text(AppStrings.datasetJoinsDiscardConfigurationTitle.tr()),
      content: Text(AppStrings.datasetJoinsDiscardConfigurationMessage.tr()),
      actions: [
        TextButton(
          key: const ValueKey('new_configuration_cancel'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          key: const ValueKey('new_configuration_confirm'),
          onPressed: () {
            controller.startNewConfiguration();
            Navigator.of(context).pop();
          },
          child: Text(AppStrings.datasetJoinsConfirm.tr()),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Delete dialog
// ---------------------------------------------------------------------------

class _DeleteConfigurationDialog extends StatefulWidget {
  final SavedMultiSheetQuery query;
  final MultiSheetJoinController controller;

  const _DeleteConfigurationDialog({
    required this.query,
    required this.controller,
  });

  @override
  State<_DeleteConfigurationDialog> createState() =>
      _DeleteConfigurationDialogState();
}

class _DeleteConfigurationDialogState
    extends State<_DeleteConfigurationDialog> {
  bool _deleting = false;
  String? _error;

  Future<void> _delete() async {
    setState(() {
      _deleting = true;
      _error = null;
    });
    final success = await widget.controller.deleteSaved(widget.query.id!);
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _deleting = false;
        _error = AppStrings.datasetJoinsDeleteSavedFailed.tr();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const ValueKey('delete_configuration_dialog'),
      title: Text(AppStrings.datasetJoinsDeleteConfigurationTitle.tr()),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppStrings.datasetJoinsDeleteConfigurationMessage.tr(
              namedArgs: {'name': widget.query.name},
            )),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _error!,
                  key: const ValueKey('delete_configuration_error'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const ValueKey('delete_configuration_cancel'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          key: const ValueKey('delete_configuration_confirm'),
          onPressed: _deleting ? null : _delete,
          child: Text(AppStrings.datasetJoinsDelete.tr()),
        ),
      ],
    );
  }
}
