//lib/domain/value_objects/sheet_join_relationship.dart

import 'package:exlser/domain/value_objects/sheet_join_type.dart';

/// A single edge of the multi-sheet join graph.
///
/// The relationship is persisted through **stable identifiers** — the table id
/// and the SQL column name (`dbName`) — never through UI entities. Display names
/// and full [DatasetColumn]/[DatasetTable] objects are resolved at runtime.
///
/// For a [SheetJoinType.left] join the **left** side is the preserved table, so
/// direction is meaningful; [flipped] lets the user swap sides before running.
class SheetJoinRelationship {
  final String id;
  final int leftTableId;
  final String leftColumnDbName;
  final int rightTableId;
  final String rightColumnDbName;
  final SheetJoinType joinType;

  const SheetJoinRelationship({
    this.id = '',
    required this.leftTableId,
    required this.leftColumnDbName,
    required this.rightTableId,
    required this.rightColumnDbName,
    this.joinType = SheetJoinType.inner,
  });

  /// Deterministic id derived from the endpoints when none was assigned.
  ///
  /// Endpoint order does not change the identity, so the two directions of the
  /// same pair are considered the same relationship (used to reject duplicates).
  String get effectiveId {
    if (id.trim().isNotEmpty) {
      return id.trim();
    }

    final left = '$leftTableId.${leftColumnDbName.trim()}';
    final right = '$rightTableId.${rightColumnDbName.trim()}';
    final endpoints = [left, right]..sort();
    return endpoints.join('=');
  }

  /// The unordered pair of table ids this edge connects.
  Set<int> get tableIds => {leftTableId, rightTableId};

  bool connects(int tableId) =>
      leftTableId == tableId || rightTableId == tableId;

  /// Returns the same edge with left/right endpoints swapped, preserving
  /// [joinType]. Used to control which table a LEFT join preserves.
  SheetJoinRelationship flipped() {
    return SheetJoinRelationship(
      id: id,
      leftTableId: rightTableId,
      leftColumnDbName: rightColumnDbName,
      rightTableId: leftTableId,
      rightColumnDbName: leftColumnDbName,
      joinType: joinType,
    );
  }

  SheetJoinRelationship copyWith({
    String? id,
    int? leftTableId,
    String? leftColumnDbName,
    int? rightTableId,
    String? rightColumnDbName,
    SheetJoinType? joinType,
  }) {
    return SheetJoinRelationship(
      id: id ?? this.id,
      leftTableId: leftTableId ?? this.leftTableId,
      leftColumnDbName: leftColumnDbName ?? this.leftColumnDbName,
      rightTableId: rightTableId ?? this.rightTableId,
      rightColumnDbName: rightColumnDbName ?? this.rightColumnDbName,
      joinType: joinType ?? this.joinType,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': effectiveId,
      'leftTableId': leftTableId,
      'leftColumnDbName': leftColumnDbName,
      'rightTableId': rightTableId,
      'rightColumnDbName': rightColumnDbName,
      'joinType': joinType.name,
    };
  }

  static SheetJoinRelationship? fromJson(Map<String, dynamic> json) {
    final leftTableId = _intOrNull(json['leftTableId']);
    final rightTableId = _intOrNull(json['rightTableId']);
    final leftColumnDbName = json['leftColumnDbName']?.toString().trim() ?? '';
    final rightColumnDbName =
        json['rightColumnDbName']?.toString().trim() ?? '';

    if (leftTableId == null ||
        rightTableId == null ||
        leftColumnDbName.isEmpty ||
        rightColumnDbName.isEmpty) {
      return null;
    }

    return SheetJoinRelationship(
      id: json['id']?.toString().trim() ?? '',
      leftTableId: leftTableId,
      leftColumnDbName: leftColumnDbName,
      rightTableId: rightTableId,
      rightColumnDbName: rightColumnDbName,
      joinType: SheetJoinType.fromName(json['joinType']),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SheetJoinRelationship &&
      other.effectiveId == effectiveId &&
      other.joinType == joinType &&
      other.leftTableId == leftTableId &&
      other.leftColumnDbName == leftColumnDbName;

  @override
  int get hashCode => Object.hash(effectiveId, joinType, leftTableId);
}

int? _intOrNull(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}
