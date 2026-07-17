import 'package:exlser/domain/usecases/multisheet/relationship_value_normalizer.dart';
import 'package:exlser/domain/value_objects/column_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const n = RelationshipValueNormalizer();

  test('text keeps leading zeros (no numeric coercion)', () {
    expect(n.normalize('001', ColumnType.text), '001');
    expect(n.normalize('00A', ColumnType.text), '00a');
  });

  test('text is trimmed and case-folded', () {
    expect(n.normalize('  Hello ', ColumnType.text), 'hello');
  });

  test('numeric columns collapse 1 and 1.0 and "1" together', () {
    expect(n.normalize(1, ColumnType.integer), '1');
    expect(n.normalize(1.0, ColumnType.real), '1');
    expect(n.normalize('1', ColumnType.integer), '1');
    expect(n.normalize('001', ColumnType.integer), '1');
  });

  test('numeric columns keep genuine fractionals', () {
    expect(n.normalize(1.5, ColumnType.real), '1.5');
  });

  test('non-numeric content in a numeric column is dropped', () {
    expect(n.normalize('abc', ColumnType.integer), isNull);
  });

  test('boolean normalizes to canonical true/false', () {
    expect(n.normalize(true, ColumnType.boolean), 'true');
    expect(n.normalize('0', ColumnType.boolean), 'false');
    expect(n.normalize('TRUE', ColumnType.boolean), 'true');
  });

  test('null and empty/whitespace become null', () {
    expect(n.normalize(null, ColumnType.text), isNull);
    expect(n.normalize('   ', ColumnType.text), isNull);
    expect(n.normalize('', ColumnType.integer), isNull);
  });
}
