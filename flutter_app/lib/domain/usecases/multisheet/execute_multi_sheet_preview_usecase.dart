//lib/domain/usecases/multisheet/execute_multi_sheet_preview_usecase.dart

import 'package:exlser/domain/repositories/query_repository.dart';
import 'package:exlser/domain/usecases/multisheet/multi_sheet_join_risk_analyzer.dart';
import 'package:exlser/domain/usecases/multisheet/multi_sheet_sql_builder.dart';
import 'package:exlser/domain/usecases/query/read_only_sql_validator.dart';

/// Outcome of a bounded multi-sheet preview.
///
/// Headers ([outputColumns]) come from the generated query, so they are present
/// even when [rows] is empty. There is deliberately **no total row count**: a
/// join can multiply rows and counting the full result is expensive.
class MultiSheetPreviewResult {
  final List<Map<String, dynamic>> rows;
  final List<MultiSheetOutputColumn> outputColumns;
  final Map<String, String> displayLabelsByAlias;
  final List<JoinRiskWarning> warnings;
  final String executedSql;
  final int limit;

  const MultiSheetPreviewResult({
    required this.rows,
    required this.outputColumns,
    required this.displayLabelsByAlias,
    required this.warnings,
    required this.executedSql,
    required this.limit,
  });

  /// True when the preview hit the limit and more rows may exist.
  bool get isTruncated => rows.length >= limit;

  bool get isEmpty => rows.isEmpty;
}

/// Runs a generated multi-sheet join as a bounded preview.
///
/// Deliberately separate from `ExecuteReadOnlyQueryUseCase`: that one always
/// runs a parallel `COUNT(*)`, which is exactly what we must avoid here. This
/// use case reuses the same [ReadOnlySqlValidator] safety net (SELECT-only,
/// single statement, known tables) and then executes only the limited query.
class ExecuteMultiSheetPreviewUseCase {
  final QueryRepository repository;
  final ReadOnlySqlValidator validator;

  const ExecuteMultiSheetPreviewUseCase({
    required this.repository,
    this.validator = const ReadOnlySqlValidator(),
  });

  Future<MultiSheetPreviewResult> call({
    required GeneratedMultiSheetQuery generated,
    required String baseSqlTableName,
    required Set<String> allowedTableNames,
    required int limit,
  }) async {
    final validation = validator.validate(
      sql: generated.sql,
      activeTableName: baseSqlTableName,
      allowedTableNames: allowedTableNames,
      limit: limit,
    );

    final rows =
        await repository.executeRawQuery(validation.executableSql, null);

    return MultiSheetPreviewResult(
      rows: rows,
      outputColumns: generated.outputColumns,
      displayLabelsByAlias: generated.displayLabelsByAlias,
      warnings: generated.warnings,
      executedSql: validation.executableSql,
      limit: limit,
    );
  }
}
