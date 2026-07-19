//lib/presentation/views/sheet_joins/join_risk_confirmation_dialog.dart

import 'package:easy_localization/easy_localization.dart';
import 'package:exlser/core/constants/app_strings.dart';
import 'package:exlser/domain/usecases/multisheet/multi_sheet_join_risk_analyzer.dart';
import 'package:flutter/material.dart';

Future<bool> showJoinRiskConfirmationDialog({
  required BuildContext context,
  required List<JoinRiskWarning> warnings,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _JoinRiskConfirmationDialog(warnings: warnings),
  );
  return confirmed ?? false;
}

String localizedJoinRiskWarning(JoinRiskWarning warning) {
  final key = switch (warning.code) {
    JoinRiskWarning.unknownCardinalityRiskCode =>
      AppStrings.datasetJoinsWarningUnknownCardinality,
    JoinRiskWarning.lowCardinalityConfidenceRiskCode =>
      AppStrings.datasetJoinsWarningLowConfidence,
    _ => AppStrings.datasetJoinsWarningManyToMany,
  };
  return key.tr(namedArgs: {
    'left': warning.leftSheetLabel,
    'right': warning.rightSheetLabel,
  });
}

class _JoinRiskConfirmationDialog extends StatelessWidget {
  final List<JoinRiskWarning> warnings;

  const _JoinRiskConfirmationDialog({required this.warnings});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const ValueKey('join_risk_confirmation_dialog'),
      title: Text(AppStrings.datasetJoinsRiskConfirmationTitle.tr()),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.datasetJoinsRiskConfirmationMessage.tr()),
            const SizedBox(height: 16),
            for (var index = 0; index < warnings.length; index++)
              Padding(
                key: ValueKey('join_risk_warning_$index'),
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.warning_amber_outlined,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(localizedJoinRiskWarning(warnings[index]))),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const ValueKey('join_risk_cancel'),
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          key: const ValueKey('join_risk_confirm'),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(AppStrings.datasetJoinsRunAnyway.tr()),
        ),
      ],
    );
  }
}
