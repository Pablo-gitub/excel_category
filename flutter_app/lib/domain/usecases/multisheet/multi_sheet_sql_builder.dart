//lib/domain/usecases/multisheet/multi_sheet_sql_builder.dart

import 'package:exlser/domain/usecases/multisheet/multi_sheet_graph_validator.dart';
import 'package:exlser/domain/usecases/multisheet/multi_sheet_join_risk_analyzer.dart';
import 'package:exlser/domain/value_objects/multi_sheet_query_spec.dart';

/// Raised when a validated spec cannot be turned into a SQL query.
class MultiSheetSqlBuilderException implements Exception {
  final String code;

  const MultiSheetSqlBuilderException(this.code);

  @override
  String toString() => 'MultiSheetSqlBuilderException($code)';
}

/// A single output column of the generated join query.
class MultiSheetOutputColumn {
  /// Stable technical alias used in the SQL (e.g. `t0__product_id`).
  final String alias;
  final int tableId;
  final String dbName;

  /// Human-readable label, e.g. `Prodotti.product_id`.
  final String label;

  const MultiSheetOutputColumn({
    required this.alias,
    required this.tableId,
    required this.dbName,
    required this.label,
  });
}

/// The result of [MultiSheetSqlBuilder.build].
class GeneratedMultiSheetQuery {
  final String sql;
  final List<MultiSheetOutputColumn> outputColumns;
  final Map<String, String> displayLabelsByAlias;

  /// Risks detected on the confirmed joins (e.g. many-to-many row multiplication).
  final List<JoinRiskWarning> warnings;

  const GeneratedMultiSheetQuery({
    required this.sql,
    required this.outputColumns,
    required this.displayLabelsByAlias,
    this.warnings = const [],
  });

  bool get hasWarnings => warnings.isNotEmpty;
}

/// Turns a validated [ResolvedJoinPlan] into a deterministic, read-only SELECT.
///
/// Pure and testable: it receives already-resolved names and never touches a
/// database. Every identifier is double-quoted; output columns are aliased with
/// stable technical names so headers survive even when the query returns no rows
/// and never collide across sheets. The generated SQL is still meant to be run
/// through `ReadOnlySqlValidator` before execution.
class MultiSheetSqlBuilder {
  static const String noOutputColumnsCode = 'no_output_columns';
  static const String missingTableNameCode = 'missing_table_name';

  final MultiSheetJoinRiskAnalyzer riskAnalyzer;

  const MultiSheetSqlBuilder({
    this.riskAnalyzer = const MultiSheetJoinRiskAnalyzer(),
  });

  GeneratedMultiSheetQuery build({
    required ResolvedJoinPlan plan,
    required MultiSheetQuerySpec spec,
    required Map<int, String> sqlTableNameByTableId,
    required Map<int, String> sheetLabelByTableId,
    required Map<int, Map<String, String>> originalColumnNamesByTableId,
  }) {
    final aliasByTableId = <int, String>{};
    for (var i = 0; i < plan.orderedTableIds.length; i++) {
      aliasByTableId[plan.orderedTableIds[i]] = 't$i';
    }

    String tableAlias(int tableId) => aliasByTableId[tableId]!;

    String sqlTableName(int tableId) {
      final name = sqlTableNameByTableId[tableId];
      if (name == null || name.trim().isEmpty) {
        throw const MultiSheetSqlBuilderException(missingTableNameCode);
      }
      return name.trim();
    }

    // Output columns follow table order, then selected-column order.
    final outputColumns = <MultiSheetOutputColumn>[];
    for (final tableId in plan.orderedTableIds) {
      final sheetLabel = sheetLabelByTableId[tableId] ?? 'sheet$tableId';
      final originalNames = originalColumnNamesByTableId[tableId] ?? const {};
      for (final dbName in spec.columnsForTable(tableId)) {
        final alias = 't${plan.orderedTableIds.indexOf(tableId)}__$dbName';
        final original = originalNames[dbName] ?? dbName;
        outputColumns.add(MultiSheetOutputColumn(
          alias: alias,
          tableId: tableId,
          dbName: dbName,
          label: '$sheetLabel.$original',
        ));
      }
    }

    if (outputColumns.isEmpty) {
      throw const MultiSheetSqlBuilderException(noOutputColumnsCode);
    }

    final selectClause = outputColumns
        .map((column) =>
            '${tableAlias(column.tableId)}.${_quote(column.dbName)} '
            'AS ${_quote(column.alias)}')
        .join(', ');

    final buffer = StringBuffer()
      ..write('SELECT $selectClause')
      ..write(
          ' FROM ${_quote(sqlTableName(plan.baseTableId))} ${tableAlias(plan.baseTableId)}');

    for (final step in plan.steps) {
      final existingAlias = tableAlias(step.existingTableId);
      final newAlias = tableAlias(step.newTableId);
      buffer.write(
        ' ${step.joinType.sqlKeyword} '
        '${_quote(sqlTableName(step.newTableId))} $newAlias '
        'ON $existingAlias.${_quote(step.existingColumnDbName)} = '
        '$newAlias.${_quote(step.newColumnDbName)}',
      );
    }

    buffer.write(' LIMIT ${spec.resultLimit}');

    return GeneratedMultiSheetQuery(
      sql: buffer.toString(),
      outputColumns: outputColumns,
      displayLabelsByAlias: {
        for (final column in outputColumns) column.alias: column.label,
      },
      warnings: riskAnalyzer.analyze(
        plan: plan,
        sheetLabelByTableId: sheetLabelByTableId,
      ),
    );
  }

  String _quote(String identifier) => '"${identifier.replaceAll('"', '""')}"';
}
