//lib/domain/value_objects/column_relationship_sample.dart

/// A bounded sample of one column's normalized values, used to estimate join
/// cardinality and value overlap from data rather than from column names.
///
/// Crucially it **retains duplicates**: uniqueness is the whole point, so a
/// `DISTINCT` sample would be useless here. NULLs and normalized empty values
/// are already excluded upstream, so every entry in [normalizedValues] is a
/// usable observation.
class ColumnRelationshipSample {
  /// Minimum usable observations before uniqueness/cardinality is trusted. One
  /// value can never prove a column is unique, so we require at least two.
  static const int minEvidence = 2;

  /// Normalized, non-null, non-empty values in DB order, duplicates retained.
  final List<String> normalizedValues;

  /// The cap requested from the database for this sample.
  final int requestedLimit;

  /// True when the database held more usable rows than were retained, so the
  /// sample is a lower bound and uniqueness cannot be asserted with certainty.
  final bool isTruncated;

  const ColumnRelationshipSample({
    required this.normalizedValues,
    required this.requestedLimit,
    required this.isTruncated,
  });

  const ColumnRelationshipSample.empty()
      : normalizedValues = const [],
        requestedLimit = 0,
        isTruncated = false;

  /// Number of usable (non-null, non-empty) observations retained.
  int get usableCount => normalizedValues.length;

  Set<String> get distinctValues => normalizedValues.toSet();

  int get distinctCount => distinctValues.length;

  /// Whether there are enough observations to reason about uniqueness at all.
  bool get hasEnoughEvidence => usableCount >= minEvidence;

  /// Unique **within the sample**: enough evidence and no duplicates observed.
  /// A truncated sample can still look unique here; callers temper the derived
  /// confidence accordingly rather than claiming guaranteed uniqueness.
  bool get isUniqueInSample =>
      hasEnoughEvidence && usableCount == distinctCount;
}
