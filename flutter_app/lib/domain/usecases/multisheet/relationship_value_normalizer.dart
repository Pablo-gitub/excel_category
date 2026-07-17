//lib/domain/usecases/multisheet/relationship_value_normalizer.dart

import 'package:exlser/domain/value_objects/column_type.dart';

/// Type-aware normalization of raw column values for cardinality/overlap
/// sampling. Pure and side-effect free.
///
/// Text is trimmed and case-folded but **never** parsed as a number, so text
/// business keys keep their leading zeros (`"001"` stays `"001"`). Numeric
/// columns collapse `1` and `1.0` to the same canonical form so an integer and
/// a real key compare equal. NULL and empty/whitespace-only values normalize to
/// null and are dropped by callers (never counted toward uniqueness/overlap).
class RelationshipValueNormalizer {
  const RelationshipValueNormalizer();

  String? normalize(Object? value, ColumnType type) {
    if (value == null) return null;
    switch (type) {
      case ColumnType.integer:
      case ColumnType.real:
        return _numeric(value);
      case ColumnType.boolean:
        return _boolean(value);
      case ColumnType.text:
      case ColumnType.date:
        return _text(value);
    }
  }

  /// Canonical numeric string: whole values become integer strings so `1`,
  /// `1.0` and `"1"` all collapse together; genuine fractionals keep their
  /// value. Non-numeric content in a numeric column is dropped.
  String? _numeric(Object? value) {
    num? n;
    if (value is num) {
      n = value;
    } else {
      final text = value.toString().trim();
      if (text.isEmpty) return null;
      n = num.tryParse(text);
    }
    if (n == null) return null;
    if (n == n.roundToDouble()) return n.toInt().toString();
    return n.toString();
  }

  String? _boolean(Object? value) {
    if (value is bool) return value ? 'true' : 'false';
    final text = value.toString().trim().toLowerCase();
    if (text == 'true' || text == '1') return 'true';
    if (text == 'false' || text == '0') return 'false';
    if (text.isEmpty) return null;
    return text;
  }

  /// Trim and case-fold, without any numeric coercion.
  String? _text(Object? value) {
    final text = value.toString().trim();
    if (text.isEmpty) return null;
    return text.toLowerCase();
  }
}
