//lib/domain/usecases/multisheet/suggest_sheet_relationships_usecase.dart

import 'package:exlser/domain/entities/dataset_column.dart';
import 'package:exlser/domain/usecases/multisheet/relationship_heuristics.dart';
import 'package:exlser/domain/value_objects/sheet_join_relationship.dart';
import 'package:exlser/domain/value_objects/sheet_relationship_suggestion.dart';

/// Fetches a bounded, null-free sample of distinct values for one column.
///
/// Implemented over `QueryRepository.executeRawQuery` in the data/application
/// layer; injected here as a function so the engine stays easy to test.
typedef SampleDistinctValues = Future<List<Object?>> Function({
  required String sqlTableName,
  required String dbName,
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

/// Proposes candidate join relationships between sheets by combining pure
/// name/type/identifier heuristics with a bounded sample of overlapping values.
class SuggestSheetRelationshipsUseCase {
  final SampleDistinctValues sampleDistinctValues;
  final int sampleLimit;
  final int maxColumnsPerTable;
  final int maxCandidatePairsPerTablePair;

  const SuggestSheetRelationshipsUseCase({
    required this.sampleDistinctValues,
    this.sampleLimit = 200,
    this.maxColumnsPerTable = 40,
    this.maxCandidatePairsPerTablePair = 6,
  });

  Future<List<SheetRelationshipSuggestion>> call({
    required List<SuggestSheetInput> sheets,
  }) async {
    final sampleCache = <String, Set<String>>{};
    final best = <String, SheetRelationshipSuggestion>{};

    for (var i = 0; i < sheets.length; i++) {
      for (var j = i + 1; j < sheets.length; j++) {
        final a = sheets[i];
        final b = sheets[j];

        final candidates = _candidatePairs(a, b);
        for (final candidate in candidates) {
          final aValues = await _sample(sampleCache, a, candidate.aColumn);
          final bValues = await _sample(sampleCache, b, candidate.bColumn);
          final overlap = _overlapRatio(aValues, bValues);

          final suggestion = _buildSuggestion(
            a: a,
            b: b,
            candidate: candidate,
            overlap: overlap,
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

  Future<Set<String>> _sample(
    Map<String, Set<String>> cache,
    SuggestSheetInput sheet,
    DatasetColumn column,
  ) async {
    final key = '${sheet.tableId}|${column.dbName}';
    final cached = cache[key];
    if (cached != null) return cached;

    final raw = await sampleDistinctValues(
      sqlTableName: sheet.sqlTableName,
      dbName: column.dbName,
      limit: sampleLimit,
    );
    final normalized = <String>{};
    for (final value in raw) {
      final norm = _normalizeValue(value);
      if (norm != null) normalized.add(norm);
    }
    cache[key] = normalized;
    return normalized;
  }

  SheetRelationshipSuggestion _buildSuggestion({
    required SuggestSheetInput a,
    required SuggestSheetInput b,
    required _CandidatePair candidate,
    required double overlap,
  }) {
    final ca = candidate.aColumn;
    final cb = candidate.bColumn;

    final reasons = <RelationshipReason>[RelationshipReason.typeMatch];
    if (RelationshipHeuristics.nameAffinity(ca.originalName, cb.originalName) >
            0 ||
        RelationshipHeuristics.nameAffinity(ca.dbName, cb.dbName) > 0) {
      reasons.add(RelationshipReason.nameMatch);
    }
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
      cardinality: _cardinality(aKey: aKey, bKey: bKey),
      valueOverlap: overlap,
    );
  }

  JoinCardinality _cardinality({required bool aKey, required bool bKey}) {
    if (aKey && bKey) return JoinCardinality.oneToOne;
    if (aKey && !bKey) return JoinCardinality.oneToMany;
    if (!aKey && bKey) return JoinCardinality.manyToOne;
    return JoinCardinality.manyToMany;
  }

  double _overlapRatio(Set<String> a, Set<String> b) {
    if (a.isEmpty || b.isEmpty) return 0;
    final smaller = a.length <= b.length ? a : b;
    final larger = a.length <= b.length ? b : a;
    var matches = 0;
    for (final value in smaller) {
      if (larger.contains(value)) matches++;
    }
    return matches / smaller.length;
  }

  String? _normalizeValue(Object? value) {
    if (value == null) return null;
    if (value is num) {
      if (value == value.roundToDouble()) {
        return value.toInt().toString();
      }
      return value.toString();
    }
    final text = value.toString().trim().toLowerCase();
    if (text.isEmpty) return null;
    final asNum = num.tryParse(text);
    if (asNum != null && asNum == asNum.roundToDouble()) {
      return asNum.toInt().toString();
    }
    return text;
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
