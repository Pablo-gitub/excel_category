import 'package:exlser/domain/entities/dataset_column.dart';
import 'package:exlser/domain/usecases/multisheet/relationship_heuristics.dart';
import 'package:exlser/domain/usecases/multisheet/suggest_sheet_relationships_usecase.dart';
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
    // In-memory data keyed by "sqlTable|dbName".
    final data = {
      'sales|product_id': ['A1', 'A2', 'A3', 'A2'],
      'sales|qty': [1, 2, 3],
      'products|product': ['A1', 'A2', 'A9'],
      'products|price': [10, 20, 30],
    };

    late Map<String, int> sampleCalls;

    SampleDistinctValues sampler() {
      sampleCalls = {};
      return ({
        required String sqlTableName,
        required String dbName,
        required int limit,
      }) async {
        final key = '$sqlTableName|$dbName';
        sampleCalls[key] = (sampleCalls[key] ?? 0) + 1;
        final values = data[key] ?? const [];
        final distinct = <Object?>{...values}.toList();
        return distinct.take(limit).toList();
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

    test('suggests the product_id <-> product join with value overlap',
        () async {
      final useCase =
          SuggestSheetRelationshipsUseCase(sampleDistinctValues: sampler());
      final suggestions = await useCase.call(sheets: [sales, products]);

      expect(suggestions, isNotEmpty);
      final top = suggestions.first;
      expect(top.relationship.leftColumnDbName, 'product_id');
      expect(top.relationship.rightColumnDbName, 'product');
      expect(top.reasons, contains(RelationshipReason.nameMatch));
      expect(top.reasons, contains(RelationshipReason.valueOverlap));
      expect(top.valueOverlap, greaterThan(0));
    });

    test('does not suggest incompatible-type pairs (qty text vs ...)',
        () async {
      final useCase =
          SuggestSheetRelationshipsUseCase(sampleDistinctValues: sampler());
      final suggestions = await useCase.call(sheets: [sales, products]);
      // qty (integer) vs product (text) must never be paired.
      final hasBadPair = suggestions.any((s) =>
          s.relationship.leftColumnDbName == 'qty' &&
          s.relationship.rightColumnDbName == 'product');
      expect(hasBadPair, isFalse);
    });

    test('samples each column at most once (cache)', () async {
      final useCase =
          SuggestSheetRelationshipsUseCase(sampleDistinctValues: sampler());
      await useCase.call(sheets: [sales, products]);
      for (final entry in sampleCalls.entries) {
        expect(entry.value, lessThanOrEqualTo(1), reason: entry.key);
      }
    });
  });
}
