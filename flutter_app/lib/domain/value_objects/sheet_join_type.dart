//lib/domain/value_objects/sheet_join_type.dart

/// Value object representing the kind of join between two dataset sheets.
///
/// Only the two safest, most understandable joins are supported in this first
/// guided step. `inner` keeps rows matched on both sides; `left` keeps every row
/// of the preserved (left) table and fills unmatched right rows with nulls.
enum SheetJoinType {
  inner,
  left;

  /// SQL keyword used when generating the join clause.
  String get sqlKeyword => switch (this) {
        SheetJoinType.inner => 'INNER JOIN',
        SheetJoinType.left => 'LEFT JOIN',
      };

  /// Parses a persisted name, falling back to [inner] for unknown values.
  static SheetJoinType fromName(Object? value) {
    final name = value?.toString().trim().toLowerCase();
    return switch (name) {
      'left' => SheetJoinType.left,
      _ => SheetJoinType.inner,
    };
  }
}
