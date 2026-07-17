import 'package:exlser/domain/value_objects/column_relationship_sample.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ColumnRelationshipSample sample(
    List<String> values, {
    bool truncated = false,
    int limit = 200,
  }) {
    return ColumnRelationshipSample(
      normalizedValues: values,
      requestedLimit: limit,
      isTruncated: truncated,
    );
  }

  test('retains duplicates in the usable count', () {
    final s = sample(['a', 'a', 'b']);
    expect(s.usableCount, 3);
    expect(s.distinctCount, 2);
    expect(s.distinctValues, {'a', 'b'});
  });

  test('is unique only with enough evidence and no duplicates', () {
    expect(sample(['a', 'b', 'c']).isUniqueInSample, isTrue);
    expect(sample(['a', 'a']).isUniqueInSample, isFalse);
  });

  test('a single value is insufficient evidence', () {
    final s = sample(['a']);
    expect(s.hasEnoughEvidence, isFalse);
    expect(s.isUniqueInSample, isFalse);
  });

  test('an empty sample has no evidence and is not unique', () {
    const s = ColumnRelationshipSample.empty();
    expect(s.usableCount, 0);
    expect(s.hasEnoughEvidence, isFalse);
    expect(s.isUniqueInSample, isFalse);
  });

  test('truncation is reported', () {
    expect(sample(['a', 'b'], truncated: true).isTruncated, isTrue);
    expect(sample(['a', 'b']).isTruncated, isFalse);
  });
}
