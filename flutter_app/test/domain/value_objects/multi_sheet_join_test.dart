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

  group('MultiSheetQuerySpec', () {
    final spec = MultiSheetQuerySpec(
      baseTableId: 1,
      selectedTableIds: const [1, 2],
      selectedColumnsByTableId: const {
        1: ['name', 'product_id'],
        2: ['product', 'price'],
      },
      relationships: const [
        SheetJoinRelationship(
          leftTableId: 1,
          leftColumnDbName: 'product_id',
          rightTableId: 2,
          rightColumnDbName: 'product',
        ),
      ],
      resultLimit: 50,
    );

    test('json round-trip preserves the spec', () {
      final restored = MultiSheetQuerySpec.fromJson(spec.toJson());
      expect(restored.baseTableId, 1);
      expect(restored.selectedTableIds, [1, 2]);
      expect(restored.selectedColumnsByTableId[1], ['name', 'product_id']);
      expect(restored.selectedColumnsByTableId[2], ['product', 'price']);
      expect(restored.relationships, hasLength(1));
      expect(restored.relationships.first.rightColumnDbName, 'product');
      expect(restored.resultLimit, 50);
      expect(restored.schemaVersion, MultiSheetQuerySpec.currentSchemaVersion);
    });

    test('fromJson applies safe defaults on missing/invalid fields', () {
      final restored = MultiSheetQuerySpec.fromJson(const {});
      expect(restored.baseTableId, isNull);
      expect(restored.selectedTableIds, isEmpty);
      expect(restored.relationships, isEmpty);
      expect(restored.resultLimit, MultiSheetQuerySpec.defaultResultLimit);
      expect(restored.isEmpty, isTrue);
    });

    test('fromJson filters out malformed relationships and column entries', () {
      final restored = MultiSheetQuerySpec.fromJson({
        'selectedTableIds': [1, 'bad', 2],
        'selectedColumnsByTableId': {
          '1': ['a', '', 'b'],
          'nope': ['x'],
        },
        'relationships': [
          {'leftTableId': 1, 'leftColumnDbName': 'a'}, // incomplete -> dropped
          {
            'leftTableId': 1,
            'leftColumnDbName': 'a',
            'rightTableId': 2,
            'rightColumnDbName': 'b',
          },
        ],
      });
      expect(restored.selectedTableIds, [1, 2]);
      expect(restored.selectedColumnsByTableId[1], ['a', 'b']);
      expect(restored.selectedColumnsByTableId.containsKey(-1), isFalse);
      expect(restored.relationships, hasLength(1));
    });
  });
}
