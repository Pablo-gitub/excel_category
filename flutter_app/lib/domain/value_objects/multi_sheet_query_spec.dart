//lib/domain/value_objects/multi_sheet_query_spec.dart

import 'package:exlser/domain/value_objects/sheet_join_relationship.dart';

/// Persistable description of a guided multi-sheet join.
///
/// It stores only **stable identifiers** (table ids and column `dbName`s) so it
/// stays valid across app restarts; [DatasetTable]/[DatasetColumn] objects and
/// display names are resolved at runtime against the current schema. A spec that
/// references a table/column no longer present is detected as *stale* by the
/// graph validator rather than crashing.
class MultiSheetQuerySpec {
  /// Current serialization version, bumped when the JSON shape changes.
  static const int currentSchemaVersion = 1;
  static const int defaultResultLimit = 100;

  /// Table preserved as the root of the join tree (FROM clause).
  final int? baseTableId;

  /// Tables participating, in a deterministic insertion order.
  final List<int> selectedTableIds;

  /// Output columns per table, as SQL column names (`dbName`).
  final Map<int, List<String>> selectedColumnsByTableId;

  /// Edges of the join tree (should be `selectedTableIds.length - 1`).
  final List<SheetJoinRelationship> relationships;

  final int resultLimit;
  final int schemaVersion;

  const MultiSheetQuerySpec({
    this.baseTableId,
    this.selectedTableIds = const [],
    this.selectedColumnsByTableId = const {},
    this.relationships = const [],
    this.resultLimit = defaultResultLimit,
    this.schemaVersion = currentSchemaVersion,
  });

  bool get isEmpty => selectedTableIds.isEmpty && relationships.isEmpty;

  int get tableCount => selectedTableIds.length;

  List<String> columnsForTable(int tableId) =>
      selectedColumnsByTableId[tableId] ?? const [];

  MultiSheetQuerySpec copyWith({
    int? baseTableId,
    List<int>? selectedTableIds,
    Map<int, List<String>>? selectedColumnsByTableId,
    List<SheetJoinRelationship>? relationships,
    int? resultLimit,
    int? schemaVersion,
  }) {
    return MultiSheetQuerySpec(
      baseTableId: baseTableId ?? this.baseTableId,
      selectedTableIds: selectedTableIds ?? this.selectedTableIds,
      selectedColumnsByTableId:
          selectedColumnsByTableId ?? this.selectedColumnsByTableId,
      relationships: relationships ?? this.relationships,
      resultLimit: resultLimit ?? this.resultLimit,
      schemaVersion: schemaVersion ?? this.schemaVersion,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'schemaVersion': schemaVersion,
      if (baseTableId != null) 'baseTableId': baseTableId,
      'selectedTableIds': selectedTableIds,
      'selectedColumnsByTableId': {
        for (final entry in selectedColumnsByTableId.entries)
          entry.key.toString(): entry.value,
      },
      'relationships': [for (final r in relationships) r.toJson()],
      'resultLimit': resultLimit,
    };
  }

  static MultiSheetQuerySpec fromJson(Map<String, dynamic> json) {
    final tableIdsJson = json['selectedTableIds'];
    final columnsJson = json['selectedColumnsByTableId'];
    final relationshipsJson = json['relationships'];

    final selectedTableIds = tableIdsJson is List
        ? [
            for (final value in tableIdsJson)
              if (_intOrNull(value) != null) _intOrNull(value)!,
          ]
        : <int>[];

    final selectedColumnsByTableId = <int, List<String>>{};
    if (columnsJson is Map) {
      for (final entry in columnsJson.entries) {
        final tableId = _intOrNull(entry.key);
        if (tableId == null) continue;
        final value = entry.value;
        if (value is! List) continue;
        selectedColumnsByTableId[tableId] = [
          for (final column in value)
            if (column.toString().trim().isNotEmpty) column.toString().trim(),
        ];
      }
    }

    final relationships = relationshipsJson is List
        ? [
            for (final relationshipJson in relationshipsJson)
              if (relationshipJson is Map<String, dynamic>)
                if (SheetJoinRelationship.fromJson(relationshipJson)
                    case final relationship?)
                  relationship,
          ]
        : <SheetJoinRelationship>[];

    return MultiSheetQuerySpec(
      baseTableId: _intOrNull(json['baseTableId']),
      selectedTableIds: selectedTableIds,
      selectedColumnsByTableId: selectedColumnsByTableId,
      relationships: relationships,
      resultLimit: _positiveIntOr(json['resultLimit'], defaultResultLimit),
      schemaVersion:
          _positiveIntOr(json['schemaVersion'], currentSchemaVersion),
    );
  }
}

int? _intOrNull(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

int _positiveIntOr(Object? value, int fallback) {
  final parsed = _intOrNull(value);
  if (parsed == null || parsed <= 0) return fallback;
  return parsed;
}
