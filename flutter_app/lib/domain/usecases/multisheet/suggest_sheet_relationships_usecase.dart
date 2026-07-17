//lib/domain/usecases/multisheet/suggest_sheet_relationships_usecase.dart

import 'package:exlser/domain/entities/dataset_column.dart';
import 'package:exlser/domain/usecases/multisheet/relationship_heuristics.dart';
import 'package:exlser/domain/value_objects/column_relationship_sample.dart';
import 'package:exlser/domain/value_objects/sheet_join_relationship.dart';
import 'package:exlser/domain/value_objects/sheet_relationship_suggestion.dart';

/// Fetches a bounded sample of one column's values, duplicates retained and
/// NULL/empty excluded, already normalized type-aware.
///
/// Implemented over `QueryRepository.executeRawQuery` in the data/application
/// layer; injected here as a function so the engine stays easy to test. The
/// [column] is passed so normalization can be type-aware.
typedef SampleColumnValues = Future<ColumnRelationshipSample> Function({
  required String sqlTableName,
  required DatasetColumn column,
  required int limit,
});

/// One sheet fed to the suggestion engine.
class SuggestSheetInput {
  final int tableId;
  final String sqlTableName;
  final List<DatasetColumn> columns;

  const SuggestSheetInput({
    required this.tableId,
    required this.sqlTableName,
    required this.columns,
  });
}

/// Proposes candidate join relationships between sheets. Name/type/identifier
/// heuristics only *rank* candidates; the estimated cardinality and its
/// confidence come exclusively from a bounded sample of the actual values.
class SuggestSheetRelationshipsUseCase {
  /// Below this the sampled cardinality is `unknown`.
  static const int minEvidence = ColumnRelationshipSample.minEvidence;

  /// Confidence assigned when both samples cover the whole column.
  static const double completeConfidence = 1.0;

  /// Confidence floor and span for a truncated (sampled) estimate.
  static const double truncatedConfidenceBase = 0.5;
  static const double truncatedConfidenceSpan = 0.4;
  static const double truncatedConfidenceCap = 0.9;

  final SampleColumnValues sampleColumnValues;
  final int sampleLimit;
  final int maxColumnsPerTable;
  final int maxCandidatePairsPerTablePair;

  const SuggestSheetRelationshipsUseCase({
    required this.sampleColumnValues,
    this.sampleLimit = 200,
    this.maxColumnsPerTable = 40,
    this.maxCandidatePairsPerTablePair = 6,
  });

  Future<List<SheetRelationshipSuggestion>> call({
    required List<SuggestSheetInput> sheets,
  }) async {
    // One sample per (table, column) for the whole run, even across pairs.
    final sampleCache = <String, ColumnRelationshipSample>{};
    final best = <String, SheetRelationshipSuggestion>{};

    for (var i = 0; i < sheets.length; i++) {
      for (var j = i + 1; j < sheets.length; j++) {
        final a = sheets[i];
        final b = sheets[j];

        final candidates = _candidatePairs(a, b);
        for (final candidate in candidates) {
          final aSample = await _sample(sampleCache, a, candidate.aColumn);
          final bSample = await _sample(sampleCache, b, candidate.bColumn);

          final suggestion = _buildSuggestion(
            a: a,
            b: b,
            candidate: candidate,
            aSample: aSample,
            bSample: bSample,
          );

          final id = suggestion.relationship.effectiveId;
          final existing = best[id];
          if (existing == null || suggestion.score > existing.score) {
            best[id] = suggestion;
          }
        }
      }
    }

    final result = best.values.toList()
      ..sort((x, y) => y.score.compareTo(x.score));
    return result;
  }

  List<_CandidatePair> _candidatePairs(
      SuggestSheetInput a, SuggestSheetInput b) {
    final colsA = a.columns.take(maxColumnsPerTable);
    final colsB = b.columns.take(maxColumnsPerTable);

    final pairs = <_CandidatePair>[];
    for (final ca in colsA) {
      for (final cb in colsB) {
        final base = RelationshipHeuristics.baseScore(ca, cb);
        if (base <= 0) continue;
        pairs.add(_CandidatePair(aColumn: ca, bColumn: cb, baseScore: base));
      }
    }

    pairs.sort((x, y) => y.baseScore.compareTo(x.baseScore));
    if (pairs.length > maxCandidatePairsPerTablePair) {
      return pairs.sublist(0, maxCandidatePairsPerTablePair);
    }
    return pairs;
  }

  Future<ColumnRelationshipSample> _sample(
    Map<String, ColumnRelationshipSample> cache,
    SuggestSheetInput sheet,
    DatasetColumn column,
  ) async {
    final key = '${sheet.tableId}|${column.dbName}';
    final cached = cache[key];
    if (cached != null) return cached;

    final sample = await sampleColumnValues(
      sqlTableName: sheet.sqlTableName,
      column: column,
      limit: sampleLimit,
    );
    cache[key] = sample;
    return sample;
  }

  SheetRelationshipSuggestion _buildSuggestion({
    required SuggestSheetInput a,
    required SuggestSheetInput b,
    required _CandidatePair candidate,
    required ColumnRelationshipSample aSample,
    required ColumnRelationshipSample bSample,
  }) {
    final ca = candidate.aColumn;
    final cb = candidate.bColumn;

    final overlap = _overlapRatio(aSample, bSample);
    final cardinality = _cardinalityFromSamples(aSample, bSample);
    final sampleSize = aSample.usableCount < bSample.usableCount
        ? aSample.usableCount
        : bSample.usableCount;
    final cardinalityConfidence =
        _cardinalityConfidence(aSample, bSample, cardinality, sampleSize);

    final reasons = <RelationshipReason>[RelationshipReason.typeMatch];
    if (RelationshipHeuristics.nameAffinity(ca.originalName, cb.originalName) >
            0 ||
        RelationshipHeuristics.nameAffinity(ca.dbName, cb.dbName) > 0) {
      reasons.add(RelationshipReason.nameMatch);
    }
    // Identifier-like names still *rank* a candidate, but never decide cardinality.
    final aKey = RelationshipHeuristics.isIdentifierName(ca.originalName);
    final bKey = RelationshipHeuristics.isIdentifierName(cb.originalName);
    if (aKey && bKey) reasons.add(RelationshipReason.commonIdentifier);
    if (overlap > 0) reasons.add(RelationshipReason.valueOverlap);

    final score = (candidate.baseScore * 0.6 + overlap * 0.4).clamp(0.0, 1.0);

    return SheetRelationshipSuggestion(
      relationship: SheetJoinRelationship(
        leftTableId: a.tableId,
        leftColumnDbName: ca.dbName,
        rightTableId: b.tableId,
        rightColumnDbName: cb.dbName,
      ),
      score: score,
      confidence: SheetRelationshipSuggestion.confidenceFromScore(score),
      reasons: reasons,
      cardinality: cardinality,
      cardinalityConfidence: cardinalityConfidence,
      sampleSize: sampleSize,
      valueOverlap: overlap,
    );
  }

  /// A → B cardinality read from observed uniqueness. Insufficient evidence on
  /// either side yields [JoinCardinality.unknown].
  JoinCardinality _cardinalityFromSamples(
    ColumnRelationshipSample a,
    ColumnRelationshipSample b,
  ) {
    if (!a.hasEnoughEvidence || !b.hasEnoughEvidence) {
      return JoinCardinality.unknown;
    }
    return JoinCardinality.fromUniqueness(
      aUnique: a.isUniqueInSample,
      bUnique: b.isUniqueInSample,
    );
  }

  /// Confidence in the cardinality: full when both samples are complete, an
  /// explicitly capped estimate when either side was truncated, zero when the
  /// cardinality itself is unknown.
  double _cardinalityConfidence(
    ColumnRelationshipSample a,
    ColumnRelationshipSample b,
    JoinCardinality cardinality,
    int sampleSize,
  ) {
    if (cardinality == JoinCardinality.unknown) return 0;
    if (!a.isTruncated && !b.isTruncated) return completeConfidence;
    final coverage =
        sampleLimit <= 0 ? 0.0 : (sampleSize / sampleLimit).clamp(0.0, 1.0);
    return (truncatedConfidenceBase + truncatedConfidenceSpan * coverage)
        .clamp(0.0, truncatedConfidenceCap);
  }

  /// Overlap over **distinct** normalized values; duplicates drive cardinality,
  /// not overlap.
  double _overlapRatio(ColumnRelationshipSample a, ColumnRelationshipSample b) {
    final da = a.distinctValues;
    final db = b.distinctValues;
    if (da.isEmpty || db.isEmpty) return 0;
    final smaller = da.length <= db.length ? da : db;
    final larger = da.length <= db.length ? db : da;
    var matches = 0;
    for (final value in smaller) {
      if (larger.contains(value)) matches++;
    }
    return matches / smaller.length;
  }
}

class _CandidatePair {
  final DatasetColumn aColumn;
  final DatasetColumn bColumn;
  final double baseScore;

  const _CandidatePair({
    required this.aColumn,
    required this.bColumn,
    required this.baseScore,
  });
}
