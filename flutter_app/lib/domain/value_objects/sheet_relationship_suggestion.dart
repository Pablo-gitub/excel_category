//lib/domain/value_objects/sheet_relationship_suggestion.dart

import 'package:exlser/domain/value_objects/sheet_join_relationship.dart';

/// Best-effort estimate of how rows relate across a candidate join.
enum JoinCardinality {
  oneToOne,
  oneToMany,
  manyToOne,
  manyToMany,
  unknown,
}

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

  /// 0..1 combined score used only for ranking.
  final double score;
  final SuggestionConfidence confidence;
  final List<RelationshipReason> reasons;
  final JoinCardinality cardinality;

  /// Fraction (0..1) of overlapping distinct sampled values, when computed.
  final double? valueOverlap;

  const SheetRelationshipSuggestion({
    required this.relationship,
    required this.score,
    required this.confidence,
    required this.reasons,
    this.cardinality = JoinCardinality.unknown,
    this.valueOverlap,
  });

  bool get isManyToMany => cardinality == JoinCardinality.manyToMany;

  static SuggestionConfidence confidenceFromScore(double score) {
    if (score >= 0.75) return SuggestionConfidence.high;
    if (score >= 0.45) return SuggestionConfidence.medium;
    return SuggestionConfidence.low;
  }
}
