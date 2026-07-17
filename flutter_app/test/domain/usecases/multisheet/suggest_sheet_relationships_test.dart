import 'package:exlser/domain/entities/dataset_column.dart';
import 'package:exlser/domain/usecases/multisheet/relationship_heuristics.dart';
import 'package:exlser/domain/usecases/multisheet/suggest_sheet_relationships_usecase.dart';
import 'package:exlser/domain/value_objects/column_relationship_sample.dart';
import 'package:exlser/domain/value_objects/column_type.dart';
import 'package:exlser/domain/value_objects/sheet_relationship_suggestion.dart';
import 'package:flutter_test/flutter_test.dart';

DatasetColumn col(
  String dbName,
  String original,
  ColumnType type, {
  int tableId = 0,
}) {
  return DatasetColumn(
    id: dbName.hashCode,
    datasetTableId: tableId,
    originalName: original,
    dbName: dbName,
    declaredType: type,
    inferredType: type,
    nullable: true,
  );
}

void main() {
  group('RelationshipHeuristics', () {
    test('normalizes assorted name styles to the same token', () {
      expect(RelationshipHeuristics.normalizeName('Product ID'), 'product_id');
      expect(RelationshipHeuristics.normalizeName('product-id'), 'product_id');
      expect(
          RelationshipHeuristics.normalizeName('  Product__ID '), 'product_id');
    });

    test('strips id suffix', () {
      expect(RelationshipHeuristics.stripIdSuffix('product_id'), 'product');
      expect(RelationshipHeuristics.stripIdSuffix('customerid'), 'customer');
    });

    test('detects identifier names', () {
      expect(RelationshipHeuristics.isIdentifierName('id'), isTrue);
      expect(RelationshipHeuristics.isIdentifierName('product_id'), isTrue);
      expect(RelationshipHeuristics.isIdentifierName('email'), isTrue);
      expect(RelationshipHeuristics.isIdentifierName('price'), isFalse);
    });

    test('requires compatible types (numeric family, or same type)', () {
      expect(
        RelationshipHeuristics.typesCompatible(
          col('a', 'a', ColumnType.integer),
          col('b', 'b', ColumnType.real),
        ),
        isTrue,
      );
      expect(
        RelationshipHeuristics.typesCompatible(
          col('a', 'a', ColumnType.text),
          col('b', 'b', ColumnType.integer),
        ),
        isFalse,
      );
    });

    test('baseScore rewards matching names and is zero for unrelated pairs',
        () {
      final strong = RelationshipHeuristics.baseScore(
        col('product_id', 'Product ID', ColumnType.text),
        col('product', 'Product', ColumnType.text),
      );
      final none = RelationshipHeuristics.baseScore(
        col('price', 'Price', ColumnType.real),
        col('stock', 'Stock', ColumnType.real),
      );
      expect(strong, greaterThan(0));
      expect(none, 0);
    });
  });

  group('SuggestSheetRelationshipsUseCase', () {
    // In-memory data keyed by "sqlTable|dbName"; duplicates are meaningful.
    late Map<String, int> sampleCalls;

    // The callback returns a bounded sample with duplicates retained, as the
    // service does; cardinality is then observed here, never from names.
    SampleColumnValues samplerFor(Map<String, List<Object?>> data) {
      sampleCalls = {};
      return ({
        required String sqlTableName,
        required DatasetColumn column,
        required int limit,
      }) async {
        final key = '$sqlTableName|${column.dbName}';
        sampleCalls[key] = (sampleCalls[key] ?? 0) + 1;
        final values = data[key] ?? const [];
        final normalized = [for (final v in values) v.toString()];
        final retained = normalized.take(limit).toList();
        return ColumnRelationshipSample(
          normalizedValues: retained,
          requestedLimit: limit,
          isTruncated: normalized.length > limit,
        );
      };
    }

    final sales = SuggestSheetInput(
      tableId: 1,
      sqlTableName: 'sales',
      columns: [
        col('product_id', 'Product ID', ColumnType.text, tableId: 1),
        col('qty', 'Qty', ColumnType.integer, tableId: 1),
      ],
    );
    final products = SuggestSheetInput(
      tableId: 2,
      sqlTableName: 'products',
      columns: [
        col('product', 'Product', ColumnType.text, tableId: 2),
        col('price', 'Price', ColumnType.integer, tableId: 2),
      ],
    );

    // A single name-matching pair, so cardinality is decided purely by the data.
    Future<SheetRelationshipSuggestion> suggestPair({
      required List<Object?> left,
      required List<Object?> right,
      String name = 'code',
      ColumnType type = ColumnType.text,
      int limit = 200,
    }) async {
      final a = SuggestSheetInput(
        tableId: 1,
        sqlTableName: 't1',
        columns: [col(name, name, type, tableId: 1)],
      );
      final b = SuggestSheetInput(
        tableId: 2,
        sqlTableName: 't2',
        columns: [col(name, name, type, tableId: 2)],
      );
      final useCase = SuggestSheetRelationshipsUseCase(
        sampleColumnValues: samplerFor({'t1|$name': left, 't2|$name': right}),
        sampleLimit: limit,
      );
      final suggestions = await useCase.call(sheets: [a, b]);
      return suggestions.single;
    }

    test('suggests the product_id <-> product join with value overlap',
        () async {
      final useCase = SuggestSheetRelationshipsUseCase(
        sampleColumnValues: samplerFor({
          'sales|product_id': ['A1', 'A2', 'A3', 'A2'],
          'products|product': ['A1', 'A2', 'A9'],
        }),
      );
      final suggestions = await useCase.call(sheets: [sales, products]);

      expect(suggestions, isNotEmpty);
      final top = suggestions.first;
      expect(top.relationship.leftColumnDbName, 'product_id');
      expect(top.relationship.rightColumnDbName, 'product');
      expect(top.reasons, contains(RelationshipReason.nameMatch));
      expect(top.reasons, contains(RelationshipReason.valueOverlap));
      expect(top.valueOverlap, greaterThan(0));
    });

    test('does not suggest incompatible-type pairs (integer vs text)',
        () async {
      final useCase = SuggestSheetRelationshipsUseCase(
        sampleColumnValues: samplerFor(const {}),
      );
      final suggestions = await useCase.call(sheets: [sales, products]);
      // qty (integer) vs product (text) must never be paired.
      final hasBadPair = suggestions.any((s) =>
          s.relationship.leftColumnDbName == 'qty' &&
          s.relationship.rightColumnDbName == 'product');
      expect(hasBadPair, isFalse);
    });

    test('samples each column at most once (cache)', () async {
      final useCase = SuggestSheetRelationshipsUseCase(
        sampleColumnValues: samplerFor({
          'sales|product_id': ['A1', 'A2'],
          'products|product': ['A1', 'A2'],
        }),
      );
      await useCase.call(sheets: [sales, products]);
      for (final entry in sampleCalls.entries) {
        expect(entry.value, lessThanOrEqualTo(1), reason: entry.key);
      }
    });

    test('one-to-one: both sides unique', () async {
      final s = await suggestPair(left: ['x1', 'x2'], right: ['x1', 'x3']);
      expect(s.cardinality, JoinCardinality.oneToOne);
      expect(s.cardinalityConfidence, 1.0);
      expect(s.sampleSize, 2);
    });

    test('many-to-one: A duplicated, B unique', () async {
      final s = await suggestPair(
        left: ['x1', 'x1', 'x2'],
        right: ['x1', 'x2', 'x3'],
      );
      expect(s.cardinality, JoinCardinality.manyToOne);
    });

    test('one-to-many: A unique, B duplicated', () async {
      final s = await suggestPair(
        left: ['x1', 'x2', 'x3'],
        right: ['x1', 'x1', 'x2'],
      );
      expect(s.cardinality, JoinCardinality.oneToMany);
    });

    test('many-to-many: both duplicated', () async {
      final s = await suggestPair(
        left: ['x1', 'x1', 'x2'],
        right: ['x1', 'x2', 'x2'],
      );
      expect(s.cardinality, JoinCardinality.manyToMany);
      expect(s.cardinalityConfidence, 1.0);
    });

    test('unknown when a side has insufficient evidence', () async {
      final s = await suggestPair(left: ['x1'], right: ['x1', 'x2']);
      expect(s.cardinality, JoinCardinality.unknown);
      expect(s.cardinalityConfidence, 0);
    });

    test('identifier names do not override observed duplicates', () async {
      // Both columns are named `id`; the left one has real duplicates, so the
      // cardinality must be many-to-one, not one-to-one.
      final s = await suggestPair(
        left: ['1', '1', '2'],
        right: ['1', '2', '3'],
        name: 'id',
      );
      expect(s.cardinality, JoinCardinality.manyToOne);
    });

    test('a truncated sample lowers cardinality confidence below 1', () async {
      final s = await suggestPair(
        left: ['x1', 'x2', 'x3'],
        right: ['x1', 'x2', 'x3'],
        limit: 2, // fewer than the 3 rows available -> truncated
      );
      expect(s.cardinalityConfidence, lessThan(1.0));
      expect(s.cardinalityConfidence, greaterThan(0));
    });

    test('overlap is distinct-based despite duplicates', () async {
      final s = await suggestPair(
        left: ['a', 'a', 'b'],
        right: ['a', 'b', 'b'],
      );
      expect(s.valueOverlap, 1.0);
    });
  });
}
