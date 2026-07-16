//lib/domain/usecases/multisheet/relationship_heuristics.dart

import 'package:exlser/domain/entities/dataset_column.dart';

/// Pure, dependency-free heuristics for scoring candidate join relationships by
/// column metadata (no database access). The value-overlap part lives in the use
/// case because it needs sampling.
class RelationshipHeuristics {
  RelationshipHeuristics._();

  /// Column names that strongly suggest a join key.
  static const Set<String> _identifierTokens = {
    'id',
    'code',
    'sku',
    'ean',
    'upc',
    'email',
    'uuid',
    'key',
  };

  /// Lowercases, trims and collapses separators so `Product ID`, `product_id`
  /// and `productId` normalise to the same token.
  static String normalizeName(String name) {
    final lower = name.trim().toLowerCase();
    final collapsed = lower.replaceAll(RegExp(r'[\s\-]+'), '_');
    return collapsed
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  /// Normalised name without a trailing `_id`/`id` suffix, so `product_id` and
  /// `product` compare as related.
  static String stripIdSuffix(String normalized) {
    if (normalized.endsWith('_id')) {
      return normalized.substring(0, normalized.length - 3);
    }
    if (normalized.length > 2 && normalized.endsWith('id')) {
      return normalized.substring(0, normalized.length - 2);
    }
    return normalized;
  }

  /// Whether the column name looks like a stable identifier / business key.
  static bool isIdentifierName(String name) {
    final normalized = normalizeName(name);
    if (_identifierTokens.contains(normalized)) return true;
    if (normalized.endsWith('_id')) return true;
    for (final token in _identifierTokens) {
      if (normalized.endsWith('_$token')) return true;
    }
    return false;
  }

  /// Two columns can be compared/joined only if their types are compatible.
  /// integer and real are both treated as numeric; text↔text, date↔date,
  /// boolean↔boolean. No fuzzy numeric↔text coercion in this first version.
  static bool typesCompatible(DatasetColumn a, DatasetColumn b) {
    if (a.isNumeric && b.isNumeric) return true;
    return a.declaredType == b.declaredType;
  }

  /// 0..1 affinity from the names alone. Exact normalised equality scores
  /// highest; matching after stripping an `id` suffix scores a bit less.
  static double nameAffinity(String a, String b) {
    final na = normalizeName(a);
    final nb = normalizeName(b);
    if (na.isEmpty || nb.isEmpty) return 0;
    if (na == nb) return 1;

    final sa = stripIdSuffix(na);
    final sb = stripIdSuffix(nb);
    if (sa.isNotEmpty && sa == sb) return 0.8;
    if (sa == nb || sb == na) return 0.7;
    return 0;
  }

  /// Base score (0..1) from names, types and identifier tokens, before any
  /// value sampling. Returns 0 when the pair is not a plausible candidate.
  static double baseScore(DatasetColumn a, DatasetColumn b) {
    if (!typesCompatible(a, b)) return 0;

    final affinity = nameAffinity(a.originalName, b.originalName);
    final dbAffinity = nameAffinity(a.dbName, b.dbName);
    final nameScore = affinity > dbAffinity ? affinity : dbAffinity;

    final bothIdentifiers =
        isIdentifierName(a.originalName) && isIdentifierName(b.originalName);

    if (nameScore == 0 && !bothIdentifiers) return 0;

    var score = nameScore * 0.6;
    if (bothIdentifiers) score += 0.2;
    return score.clamp(0.0, 1.0);
  }
}
