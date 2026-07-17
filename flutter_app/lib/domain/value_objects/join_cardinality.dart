//lib/domain/value_objects/join_cardinality.dart

/// How rows relate across the two endpoints of a relationship, read as **A → B**.
///
/// `manyToOne` means endpoint A is the "many" side and endpoint B the "one"
/// side; `oneToMany` is the reverse. `manyToMany` is an associative relationship
/// (neither side is unique) — never a semantic foreign key, and risky to join.
/// `unknown` means it has not been estimated yet.
enum JoinCardinality {
  oneToOne,
  oneToMany,
  manyToOne,
  manyToMany,
  unknown;

  /// True when neither side is unique, so a join can multiply rows.
  bool get isAssociative => this == JoinCardinality.manyToMany;

  /// Derives the A→B cardinality from whether each side's values are unique.
  ///
  /// Both unique → one-to-one · A duplicated, B unique → many-to-one ·
  /// A unique, B duplicated → one-to-many · both duplicated → many-to-many.
  static JoinCardinality fromUniqueness({
    required bool aUnique,
    required bool bUnique,
  }) {
    if (aUnique && bUnique) return JoinCardinality.oneToOne;
    if (!aUnique && bUnique) return JoinCardinality.manyToOne;
    if (aUnique && !bUnique) return JoinCardinality.oneToMany;
    return JoinCardinality.manyToMany;
  }

  static JoinCardinality fromName(Object? value) {
    final name = value?.toString().trim();
    for (final c in JoinCardinality.values) {
      if (c.name == name) return c;
    }
    return JoinCardinality.unknown;
  }

  /// Reversed view (A↔B swapped), so a cardinality stated for one endpoint
  /// order can be read from the other.
  JoinCardinality get inverted => switch (this) {
        JoinCardinality.oneToMany => JoinCardinality.manyToOne,
        JoinCardinality.manyToOne => JoinCardinality.oneToMany,
        _ => this,
      };
}
