import 'package:exlser/domain/entities/dataset_relationship.dart';
import 'package:exlser/domain/value_objects/join_cardinality.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DatasetRelationship rel({
    int a = 1,
    String ac = 'product_id',
    int b = 2,
    String bc = 'product',
    JoinCardinality cardinality = JoinCardinality.manyToOne,
  }) {
    return DatasetRelationship(
      datasetId: 1,
      endpointATableId: a,
      endpointAColumnDbName: ac,
      endpointBTableId: b,
      endpointBColumnDbName: bc,
      cardinality: cardinality,
    );
  }

  group('JoinCardinality.fromUniqueness', () {
    test('maps duplicate/unique combinations directionally A -> B', () {
      expect(
        JoinCardinality.fromUniqueness(aUnique: true, bUnique: true),
        JoinCardinality.oneToOne,
      );
      expect(
        JoinCardinality.fromUniqueness(aUnique: false, bUnique: true),
        JoinCardinality.manyToOne,
      );
      expect(
        JoinCardinality.fromUniqueness(aUnique: true, bUnique: false),
        JoinCardinality.oneToMany,
      );
      expect(
        JoinCardinality.fromUniqueness(aUnique: false, bUnique: false),
        JoinCardinality.manyToMany,
      );
    });

    test('inverted swaps only the directional cardinalities', () {
      expect(JoinCardinality.manyToOne.inverted, JoinCardinality.oneToMany);
      expect(JoinCardinality.oneToMany.inverted, JoinCardinality.manyToOne);
      expect(JoinCardinality.oneToOne.inverted, JoinCardinality.oneToOne);
      expect(JoinCardinality.manyToMany.inverted, JoinCardinality.manyToMany);
    });

    test('many-to-many is associative, the others are not', () {
      expect(JoinCardinality.manyToMany.isAssociative, isTrue);
      expect(JoinCardinality.manyToOne.isAssociative, isFalse);
      expect(JoinCardinality.oneToOne.isAssociative, isFalse);
    });
  });

  group('DatasetRelationship', () {
    test('endpointKey is order-independent (A<->B are equivalent)', () {
      final forward = rel(a: 1, ac: 'product_id', b: 2, bc: 'product');
      final reversed = rel(a: 2, ac: 'product', b: 1, bc: 'product_id');
      expect(reversed.endpointKey, forward.endpointKey);
    });

    test('endpointKey distinguishes different endpoint pairs', () {
      expect(
        rel(ac: 'product_id').endpointKey,
        isNot(rel(ac: 'other_id').endpointKey),
      );
    });

    test('a many-to-many relationship is flagged associative', () {
      expect(
          rel(cardinality: JoinCardinality.manyToMany).isAssociative, isTrue);
    });

    test('involvesColumn matches either endpoint', () {
      final r = rel();
      expect(r.involvesColumn(1, 'product_id'), isTrue);
      expect(r.involvesColumn(2, 'product'), isTrue);
      expect(r.involvesColumn(1, 'product'), isFalse);
    });

    test('is unconfirmed until confirmedAt is set', () {
      expect(rel().isConfirmed, isFalse);
      expect(rel().copyWith(confirmedAt: DateTime(2026)).isConfirmed, isTrue);
    });
  });
}
