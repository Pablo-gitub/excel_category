//lib/domain/value_objects/multi_sheet_query_spec.dart

import 'package:exlser/domain/value_objects/multi_sheet_join.dart';

/// Persistable description of a guided multi-sheet query.
///
/// It stores only **stable identifiers**: table ids, output column `dbName`s and
/// — for each join — the id of a persisted `DatasetRelationship`. The relationship
/// (its column pair and cardinality) is dataset metadata resolved at runtime; a
/// spec that references a missing relationship, table or column is reported as
/// *stale* by the graph validator rather than crashing.
class MultiSheetQuerySpec {
  /// Current serialization version, bumped when the JSON shape changes.
  ///
  /// v2 replaced the inline `relationships` array (endpoint columns duplicated in
  /// the spec) with `joins` that reference persisted `DatasetRelationship` ids.
  static const int currentSchemaVersion = 2;
  static const int defaultResultLimit = 100;

  /// Table preserved as the root of the join tree (FROM clause).
  final int? baseTableId;

  /// Tables participating, in a deterministic insertion order (no duplicates).
  final List<int> selectedTableIds;

  /// Output columns per table, as SQL column names (`dbName`).
  final Map<int, List<String>> selectedColumnsByTableId;

  /// Joins referencing dataset relationships (should be `selectedTableIds.length - 1`).
  final List<MultiSheetJoin> joins;

  final int resultLimit;
  final int schemaVersion;

  /// True when the spec was parsed from a serialization version this build does
  /// not understand (a legacy v1 inline-relationship spec, or a future version).
  /// Such a spec is unusable and must be surfaced as *stale*, never executed —
  /// it is deliberately distinguishable from a merely empty spec.
  final bool unsupportedVersion;

  const MultiSheetQuerySpec({
    this.baseTableId,
    this.selectedTableIds = const [],
    this.selectedColumnsByTableId = const {},
    this.joins = const [],
    this.resultLimit = defaultResultLimit,
    this.schemaVersion = currentSchemaVersion,
    this.unsupportedVersion = false,
  });

  /// A spec parsed from an unsupported serialization version.
  const MultiSheetQuerySpec.unsupported(int version)
      : baseTableId = null,
        selectedTableIds = const [],
        selectedColumnsByTableId = const {},
        joins = const [],
        resultLimit = defaultResultLimit,
        schemaVersion = version,
        unsupportedVersion = true;

  bool get isEmpty => selectedTableIds.isEmpty && joins.isEmpty;

  int get tableCount => selectedTableIds.length;

  List<String> columnsForTable(int tableId) =>
      selectedColumnsByTableId[tableId] ?? const [];

  /// Relationship ids referenced by the joins.
  Set<int> get referencedRelationshipIds =>
      {for (final join in joins) join.relationshipId};

  MultiSheetQuerySpec copyWith({
    int? baseTableId,
    bool clearBaseTableId = false,
    List<int>? selectedTableIds,
    Map<int, List<String>>? selectedColumnsByTableId,
    List<MultiSheetJoin>? joins,
    int? resultLimit,
    int? schemaVersion,
  }) {
    return MultiSheetQuerySpec(
      baseTableId: clearBaseTableId ? null : (baseTableId ?? this.baseTableId),
      selectedTableIds: selectedTableIds ?? this.selectedTableIds,
      selectedColumnsByTableId:
          selectedColumnsByTableId ?? this.selectedColumnsByTableId,
      joins: joins ?? this.joins,
      resultLimit: resultLimit ?? this.resultLimit,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      // An unsupported spec stays unsupported under edits, so a legacy/future
      // spec can never be silently mutated into a savable v2 one.
      unsupportedVersion: unsupportedVersion,
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
      'joins': [for (final join in joins) join.toJson()],
      'resultLimit': resultLimit,
    };
  }

  /// Parses a spec, tolerating malformed entries.
  ///
  /// Any [schemaVersion] other than [currentSchemaVersion] — a legacy v1
  /// inline-relationship spec or a future shape — yields an explicit
  /// [MultiSheetQuerySpec.unsupported] marker rather than silently misreading it
  /// as an empty-but-valid spec.
  static MultiSheetQuerySpec fromJson(Map<String, dynamic> json) {
    final version = _positiveIntOr(json['schemaVersion'], currentSchemaVersion);
    if (version != currentSchemaVersion) {
      return MultiSheetQuerySpec.unsupported(version);
    }

    final tableIdsJson = json['selectedTableIds'];
    final columnsJson = json['selectedColumnsByTableId'];
    final joinsJson = json['joins'];

    // Preserve order, drop duplicates from corrupt JSON.
    final selectedTableIds = <int>[];
    if (tableIdsJson is List) {
      for (final value in tableIdsJson) {
        final id = _intOrNull(value);
        if (id != null && !selectedTableIds.contains(id)) {
          selectedTableIds.add(id);
        }
      }
    }

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

    final joins = joinsJson is List
        ? [
            for (final joinJson in joinsJson)
              if (joinJson is Map<String, dynamic>)
                if (MultiSheetJoin.fromJson(joinJson) case final join?) join,
          ]
        : <MultiSheetJoin>[];

    return MultiSheetQuerySpec(
      baseTableId: _intOrNull(json['baseTableId']),
      selectedTableIds: selectedTableIds,
      selectedColumnsByTableId: selectedColumnsByTableId,
      joins: joins,
      resultLimit: _positiveIntOr(json['resultLimit'], defaultResultLimit),
      schemaVersion: version,
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
