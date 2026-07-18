//lib/presentation/views/sheet_joins/manual_relationship_dialog.dart

import 'package:easy_localization/easy_localization.dart';
import 'package:exlser/application/services/multi_sheet_analysis_service.dart';
import 'package:exlser/core/constants/app_strings.dart';
import 'package:exlser/presentation/views/sheet_joins/multi_sheet_join_controller.dart';
import 'package:flutter/material.dart';

/// Opens the manual relationship creation dialog.
///
/// Displays four dropdowns (left sheet, left column, right sheet, right column)
/// filtered to the currently selected sheets. Calls
/// [MultiSheetJoinController.addManualRelationship] and closes only on success.
Future<void> showManualRelationshipDialog({
  required BuildContext context,
  required MultiSheetJoinState state,
  required MultiSheetJoinController controller,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _ManualRelationshipDialog(
      state: state,
      controller: controller,
    ),
  );
}

class _ManualRelationshipDialog extends StatefulWidget {
  final MultiSheetJoinState state;
  final MultiSheetJoinController controller;

  const _ManualRelationshipDialog({
    required this.state,
    required this.controller,
  });

  @override
  State<_ManualRelationshipDialog> createState() =>
      _ManualRelationshipDialogState();
}

class _ManualRelationshipDialogState extends State<_ManualRelationshipDialog> {
  late MultiSheetSheetInfo _leftSheet;
  late MultiSheetSheetInfo _rightSheet;
  String? _leftColumnDbName;
  String? _rightColumnDbName;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final sheets = _selectedSheets();
    _leftSheet = sheets[0];
    _rightSheet = sheets[1];
    _leftColumnDbName =
        _leftSheet.columns.isNotEmpty ? _leftSheet.columns.first.dbName : null;
    _rightColumnDbName = _rightSheet.columns.isNotEmpty
        ? _rightSheet.columns.first.dbName
        : null;
  }

  List<MultiSheetSheetInfo> _selectedSheets() {
    return widget.state.sheets
        .where((s) => widget.state.spec.selectedTableIds.contains(s.tableId))
        .toList();
  }

  void _onLeftSheetChanged(int tableId) {
    final sheets = _selectedSheets();
    final newLeft = sheets.firstWhere((s) => s.tableId == tableId);
    setState(() {
      _leftSheet = newLeft;
      _leftColumnDbName = _leftSheet.columns.isNotEmpty
          ? _leftSheet.columns.first.dbName
          : null;
      // If the new left is the same as the current right, repair right.
      if (_rightSheet.tableId == tableId) {
        _rightSheet = sheets.firstWhere((s) => s.tableId != tableId);
        _rightColumnDbName = _rightSheet.columns.isNotEmpty
            ? _rightSheet.columns.first.dbName
            : null;
      }
    });
  }

  void _onRightSheetChanged(int tableId) {
    final sheets = _selectedSheets();
    setState(() {
      _rightSheet = sheets.firstWhere((s) => s.tableId == tableId);
      _rightColumnDbName = _rightSheet.columns.isNotEmpty
          ? _rightSheet.columns.first.dbName
          : null;
    });
  }

  Future<void> _submit() async {
    final leftColumnDbName = _leftColumnDbName;
    final rightColumnDbName = _rightColumnDbName;
    if (leftColumnDbName == null || rightColumnDbName == null) return;

    setState(() => _saving = true);

    final success = await widget.controller.addManualRelationship(
      leftTableId: _leftSheet.tableId,
      leftColumnDbName: leftColumnDbName,
      rightTableId: _rightSheet.tableId,
      rightColumnDbName: rightColumnDbName,
    );

    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop();
    } else {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sheets = _selectedSheets();
    final canSubmit =
        !_saving && _leftColumnDbName != null && _rightColumnDbName != null;

    return AlertDialog(
      key: const ValueKey('manual_relationship_dialog'),
      title: Text(AppStrings.datasetJoinsManualRelationshipTitle.tr()),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppStrings.datasetJoinsManualRelationshipHint.tr()),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              key: const ValueKey('manual_left_sheet'),
              isExpanded: true,
              initialValue: _leftSheet.tableId,
              items: [
                for (final s in sheets)
                  DropdownMenuItem(
                    value: s.tableId,
                    child: Text(
                      s.label,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (value) {
                if (value != null) _onLeftSheetChanged(value);
              },
              decoration: InputDecoration(
                labelText: AppStrings.datasetJoinsLeftSheet.tr(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: const ValueKey('manual_left_column'),
              isExpanded: true,
              initialValue: _leftColumnDbName,
              items: [
                for (final c in _leftSheet.columns)
                  DropdownMenuItem(
                    value: c.dbName,
                    child: Text(
                      c.originalName,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (value) => setState(() => _leftColumnDbName = value),
              decoration: InputDecoration(
                labelText: AppStrings.datasetJoinsLeftColumn.tr(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              key: const ValueKey('manual_right_sheet'),
              isExpanded: true,
              initialValue: _rightSheet.tableId,
              items: [
                for (final s in sheets)
                  if (s.tableId != _leftSheet.tableId)
                    DropdownMenuItem(
                      value: s.tableId,
                      child: Text(
                        s.label,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
              ],
              onChanged: (value) {
                if (value != null) _onRightSheetChanged(value);
              },
              decoration: InputDecoration(
                labelText: AppStrings.datasetJoinsRightSheet.tr(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: const ValueKey('manual_right_column'),
              isExpanded: true,
              initialValue: _rightColumnDbName,
              items: [
                for (final c in _rightSheet.columns)
                  DropdownMenuItem(
                    value: c.dbName,
                    child: Text(
                      c.originalName,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (value) => setState(() => _rightColumnDbName = value),
              decoration: InputDecoration(
                labelText: AppStrings.datasetJoinsRightColumn.tr(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const ValueKey('manual_relationship_cancel'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          key: const ValueKey('manual_relationship_submit'),
          onPressed: canSubmit ? _submit : null,
          child: Text(AppStrings.datasetJoinsConfirm.tr()),
        ),
      ],
    );
  }
}
