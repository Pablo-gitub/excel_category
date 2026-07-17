import 'package:exlser/domain/value_objects/multi_sheet_join.dart';
import 'package:exlser/domain/value_objects/multi_sheet_query_spec.dart';
import 'package:exlser/domain/value_objects/sheet_join_relationship.dart';
import 'package:exlser/domain/value_objects/sheet_join_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SheetJoinType', () {
    test('maps to the correct SQL keyword', () {
      expect(SheetJoinType.inner.sqlKeyword, 'INNER JOIN');
      expect(SheetJoinType.left.sqlKeyword, 'LEFT JOIN');
    });

    test('parses persisted names and falls back to inner', () {
      expect(SheetJoinType.fromName('left'), SheetJoinType.left);
      expect(SheetJoinType.fromName('LEFT'), SheetJoinType.left);
      expect(SheetJoinType.fromName('inner'), SheetJoinType.inner);
      expect(SheetJoinType.fromName('bogus'), SheetJoinType.inner);
      expect(SheetJoinType.fromName(null), SheetJoinType.inner);
    });
  });

  group('SheetJoinRelationship', () {
    const relationship = SheetJoinRelationship(
      leftTableId: 1,
      leftColumnDbName: 'product_id',
      rightTableId: 2,
      rightColumnDbName: 'product',
      joinType: SheetJoinType.left,
    );

    test('json round-trip preserves all fields', () {
      final restored = SheetJoinRelationship.fromJson(relationship.toJson());
      expect(restored, isNotNull);
      expect(restored!.leftTableId, 1);
      expect(restored.leftColumnDbName, 'product_id');
      expect(restored.rightTableId, 2);
      expect(restored.rightColumnDbName, 'product');
      expect(restored.joinType, SheetJoinType.left);
    });

    test('effectiveId is independent of endpoint order (duplicate detection)',
        () {
      final flipped = relationship.flipped();
      expect(flipped.effectiveId, relationship.effectiveId);
    });

    test('flipped swaps endpoints but keeps the join type', () {
      final flipped = relationship.flipped();
      expect(flipped.leftTableId, 2);
      expect(flipped.leftColumnDbName, 'product');
      expect(flipped.rightTableId, 1);
      expect(flipped.rightColumnDbName, 'product_id');
      expect(flipped.joinType, SheetJoinType.left);
    });

    test('fromJson returns null on incomplete data', () {
      expect(
        SheetJoinRelationship.fromJson({
          'leftTableId': 1,
          'leftColumnDbName': '',
          'rightTableId': 2,
          'rightColumnDbName': 'product',
        }),
        isNull,
      );
      expect(
        SheetJoinRelationship.fromJson({
          'leftTableId': 1,
          'leftColumnDbName': 'a',
          'rightColumnDbName': 'b',
        }),
        isNull,
      );
    });
  });

  group('MultiSheetJoin', () {
    test('INNER json round-trip drops any preserved side', () {
      final join = MultiSheetJoin(
        relationshipId: 10,
        joinType: SheetJoinType.inner,
        // Passing a preserved side on an INNER join must be normalized away.
        preservedTableId: 3,
      );
      expect(join.preservedTableId, isNull);

      final restored = MultiSheetJoin.fromJson(join.toJson());
      expect(restored, isNotNull);
      expect(restored!.relationshipId, 10);
      expect(restored.joinType, SheetJoinType.inner);
      expect(restored.preservedTableId, isNull);
    });

    test('LEFT json round-trip preserves the explicit table id', () {
      final join = MultiSheetJoin(
        relationshipId: 7,
        joinType: SheetJoinType.left,
        preservedTableId: 2,
      );

      final restored = MultiSheetJoin.fromJson(join.toJson());
      expect(restored!.joinType, SheetJoinType.left);
      expect(restored.preservedTableId, 2);
    });

    test('fromJson rejects a missing or non-positive relationship id', () {
      expect(MultiSheetJoin.fromJson(const {'joinType': 'inner'}), isNull);
      expect(MultiSheetJoin.fromJson(const {'relationshipId': 0}), isNull);
      expect(MultiSheetJoin.fromJson(const {'relationshipId': -3}), isNull);
    });

    test('value equality ignores object identity', () {
      expect(
        MultiSheetJoin(
            relationshipId: 1,
            joinType: SheetJoinType.left,
            preservedTableId: 2),
        MultiSheetJoin(
            relationshipId: 1,
            joinType: SheetJoinType.left,
            preservedTableId: 2),
      );
    });
  });

  group('MultiSheetQuerySpec', () {
    final spec = MultiSheetQuerySpec(
      baseTableId: 1,
      selectedTableIds: const [1, 2],
      selectedColumnsByTableId: const {
        1: ['name', 'product_id'],
        2: ['product', 'price'],
      },
      joins: [
        MultiSheetJoin(
            relationshipId: 42,
            joinType: SheetJoinType.left,
            preservedTableId: 1),
      ],
      resultLimit: 50,
    );

    test('json round-trip preserves the spec and its joins', () {
      final restored = MultiSheetQuerySpec.fromJson(spec.toJson());
      expect(restored.unsupportedVersion, isFalse);
      expect(restored.baseTableId, 1);
      expect(restored.selectedTableIds, [1, 2]);
      expect(restored.selectedColumnsByTableId[1], ['name', 'product_id']);
      expect(restored.selectedColumnsByTableId[2], ['product', 'price']);
      expect(restored.joins, hasLength(1));
      expect(restored.joins.first.relationshipId, 42);
      expect(restored.joins.first.preservedTableId, 1);
      expect(restored.referencedRelationshipIds, {42});
      expect(restored.resultLimit, 50);
      expect(restored.schemaVersion, MultiSheetQuerySpec.currentSchemaVersion);
    });

    test('fromJson applies safe defaults on missing/invalid fields', () {
      final restored = MultiSheetQuerySpec.fromJson(const {});
      expect(restored.baseTableId, isNull);
      expect(restored.selectedTableIds, isEmpty);
      expect(restored.joins, isEmpty);
      expect(restored.resultLimit, MultiSheetQuerySpec.defaultResultLimit);
      expect(restored.isEmpty, isTrue);
      expect(restored.unsupportedVersion, isFalse);
    });

    test('fromJson drops malformed joins, duplicate tables and empty columns',
        () {
      final restored = MultiSheetQuerySpec.fromJson({
        'schemaVersion': MultiSheetQuerySpec.currentSchemaVersion,
        'selectedTableIds': [1, 'bad', 2, 1], // duplicate 1 collapsed
        'selectedColumnsByTableId': {
          '1': ['a', '', 'b'],
          'nope': ['x'],
        },
        'joins': [
          {'joinType': 'inner'}, // no id -> dropped
          {'relationshipId': 0}, // non-positive -> dropped
          {'relationshipId': 5, 'joinType': 'inner'},
        ],
      });
      expect(restored.selectedTableIds, [1, 2]);
      expect(restored.selectedColumnsByTableId[1], ['a', 'b']);
      expect(restored.selectedColumnsByTableId.containsKey(-1), isFalse);
      expect(restored.joins, hasLength(1));
      expect(restored.joins.first.relationshipId, 5);
    });

    test('a future schema version parses as an explicit unsupported marker',
        () {
      final restored = MultiSheetQuerySpec.fromJson({
        'schemaVersion': MultiSheetQuerySpec.currentSchemaVersion + 1,
        'selectedTableIds': [1, 2],
        'joins': [
          {'relationshipId': 5},
        ],
      });
      expect(restored.unsupportedVersion, isTrue);
      expect(restored.isEmpty, isTrue,
          reason: 'an unsupported spec exposes no usable content');
    });

    test('a legacy v1 (inline relationships) spec is treated as unsupported',
        () {
      final restored = MultiSheetQuerySpec.fromJson({
        'schemaVersion': 1,
        'selectedTableIds': [1, 2],
        'relationships': [
          {
            'leftTableId': 1,
            'leftColumnDbName': 'a',
            'rightTableId': 2,
            'rightColumnDbName': 'b',
          },
        ],
      });
      expect(restored.unsupportedVersion, isTrue);
      expect(restored.joins, isEmpty);
    });
  });
}
