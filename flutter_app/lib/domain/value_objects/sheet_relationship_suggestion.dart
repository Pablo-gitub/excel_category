//lib/domain/value_objects/sheet_relationship_suggestion.dart

import 'package:exlser/domain/value_objects/join_cardinality.dart';
import 'package:exlser/domain/value_objects/sheet_join_relationship.dart';

export 'package:exlser/domain/value_objects/join_cardinality.dart';

/// Coarse confidence bucket derived from the suggestion score.
enum SuggestionConfidence { high, medium, low }

/// Why a relationship was suggested (surfaced to the user as chips/reasons).
enum RelationshipReason {
  nameMatch,
  commonIdentifier,
  valueOverlap,
  typeMatch,
}

/// A suggested join between two sheets, awaiting user confirmation.
///
/// Nothing is applied automatically: the UI presents suggestions with their
/// [score], [reasons] and [cardinality] and the user confirms, edits or rejects.
class SheetRelationshipSuggestion {
  final SheetJoinRelationship relationship;

  /// 0..1 combined score used only for ranking. Distinct from
  /// [cardinalityConfidence]: a relationship can rank high yet have an
  /// uncertain cardinality (or vice versa).
  final double score;
  final SuggestionConfidence confidence;
  final List<RelationshipReason> reasons;

  /// Estimated A → B cardinality, observed from sampled data (never inferred
  /// from column names). [JoinCardinality.unknown] when evidence is insufficient.
  final JoinCardinality cardinality;

  /// 0..1 confidence in [cardinality] specifically, from sample completeness.
  final double cardinalityConfidence;

  /// Usable observations behind the estimate: `min(usableCount)` of both sides.
  final int sampleSize;

  /// Fraction (0..1) of overlapping distinct sampled values, when computed.
  final double? valueOverlap;

  const SheetRelationshipSuggestion({
    required this.relationship,
    required this.score,
    required this.confidence,
    required this.reasons,
    this.cardinality = JoinCardinality.unknown,
    this.cardinalityConfidence = 0,
    this.sampleSize = 0,
    this.valueOverlap,
  });

  bool get isManyToMany => cardinality == JoinCardinality.manyToMany;

  static SuggestionConfidence confidenceFromScore(double score) {
    if (score >= 0.75) return SuggestionConfidence.high;
    if (score >= 0.45) return SuggestionConfidence.medium;
    return SuggestionConfidence.low;
  }
}
