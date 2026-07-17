//lib/domain/value_objects/multi_sheet_join.dart

import 'package:exlser/domain/value_objects/sheet_join_type.dart';

/// One join inside a [MultiSheetQuerySpec].
///
/// It references a persisted `DatasetRelationship` by id — the column pair lives
/// on the relationship (dataset metadata), not here. A query only decides *how*
/// to use that relationship: the [joinType] and, for a LEFT join, which side to
/// preserve via [preservedTableId] (an explicit table id, one of the
/// relationship's endpoints). For an INNER join [preservedTableId] is ignored
/// and should be null.
class MultiSheetJoin {
  final int relationshipId;
  final SheetJoinType joinType;
  final int? preservedTableId;

  /// [preservedTableId] is forced to null for anything other than a LEFT join,
  /// so an INNER join can never carry a stale preserved side.
  MultiSheetJoin({
    required this.relationshipId,
    this.joinType = SheetJoinType.inner,
    int? preservedTableId,
  }) : preservedTableId =
            joinType == SheetJoinType.left ? preservedTableId : null;

  bool get isLeft => joinType == SheetJoinType.left;

  MultiSheetJoin copyWith({
    int? relationshipId,
    SheetJoinType? joinType,
    int? preservedTableId,
    bool clearPreservedTableId = false,
  }) {
    return MultiSheetJoin(
      relationshipId: relationshipId ?? this.relationshipId,
      joinType: joinType ?? this.joinType,
      preservedTableId: clearPreservedTableId
          ? null
          : (preservedTableId ?? this.preservedTableId),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'relationshipId': relationshipId,
      'joinType': joinType.name,
      // Only meaningful for LEFT joins.
      if (isLeft && preservedTableId != null)
        'preservedTableId': preservedTableId,
    };
  }

  /// Returns null for a missing or non-positive relationship id, so a corrupt
  /// entry is dropped rather than resolved against the relationship map.
  static MultiSheetJoin? fromJson(Map<String, dynamic> json) {
    final relationshipId = _intOrNull(json['relationshipId']);
    if (relationshipId == null || relationshipId <= 0) return null;

    final joinType = SheetJoinType.fromName(json['joinType']);
    return MultiSheetJoin(
      relationshipId: relationshipId,
      joinType: joinType,
      preservedTableId: joinType == SheetJoinType.left
          ? _intOrNull(json['preservedTableId'])
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is MultiSheetJoin &&
      other.relationshipId == relationshipId &&
      other.joinType == joinType &&
      other.preservedTableId == preservedTableId;

  @override
  int get hashCode => Object.hash(relationshipId, joinType, preservedTableId);
}

int? _intOrNull(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}
