import 'package:drift/native.dart';
// Drift generates a row class also named SavedMultiSheetQuery; hide it so the
// domain entity of the same name is unambiguous here.
import 'package:exlser/core/database/app_database.dart'
    hide SavedMultiSheetQuery;
import 'package:exlser/core/database/daos/datasets_dao.dart';
import 'package:exlser/core/database/daos/saved_multi_sheet_queries_dao.dart';
import 'package:exlser/data/repositories/saved_multi_sheet_query_repository_impl.dart';
import 'package:exlser/domain/entities/saved_multi_sheet_query.dart';
import 'package:exlser/domain/usecases/multisheet/save_multi_sheet_query_usecase.dart';
import 'package:exlser/domain/value_objects/multi_sheet_join.dart';
import 'package:exlser/domain/value_objects/multi_sheet_query_spec.dart';
import 'package:exlser/domain/value_objects/sheet_join_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late SavedMultiSheetQueryRepositoryImpl repository;
  late DatasetsDao datasetsDao;

  final spec = MultiSheetQuerySpec(
    baseTableId: 1,
    selectedTableIds: const [1, 2],
    selectedColumnsByTableId: const {
      1: ['product_id', 'qty'],
      2: ['product', 'price'],
    },
    joins: [
      MultiSheetJoin(
        relationshipId: 77,
        joinType: SheetJoinType.left,
        preservedTableId: 1,
      ),
    ],
    resultLimit: 50,
  );

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = SavedMultiSheetQueryRepositoryImpl(
      SavedMultiSheetQueriesDao(database),
    );
    datasetsDao = DatasetsDao(database);
  });

  tearDown(() async => database.close());

  Future<int> insertDataset() {
    return datasetsDao.createDataset(
      name: 'ds',
      sourceFileName: 'file.xlsx',
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  SavedMultiSheetQuery entry(int datasetId, {String name = 'Join vendite'}) {
    final now = DateTime.fromMillisecondsSinceEpoch(1700000000000);
    return SavedMultiSheetQuery(
      datasetId: datasetId,
      name: name,
      spec: spec,
      createdAt: now,
      updatedAt: now,
    );
  }

  test('round-trips the specification through the database', () async {
    final datasetId = await insertDataset();
    final created = await repository.create(entry(datasetId));

    expect(created.id, isNotNull);

    final loaded = await repository.getById(created.id!);
    expect(loaded, isNotNull);
    expect(loaded!.name, 'Join vendite');
    expect(loaded.datasetId, datasetId);
    expect(loaded.spec.baseTableId, 1);
    expect(loaded.spec.selectedTableIds, [1, 2]);
    expect(loaded.spec.selectedColumnsByTableId[2], ['product', 'price']);
    expect(loaded.spec.joins, hasLength(1));
    expect(loaded.spec.joins.first.relationshipId, 77);
    expect(loaded.spec.joins.first.joinType, SheetJoinType.left);
    expect(loaded.spec.joins.first.preservedTableId, 1);
    expect(loaded.spec.resultLimit, 50);
    expect(
        loaded.createdAt, DateTime.fromMillisecondsSinceEpoch(1700000000000));
  });

  test('supports multiple configurations per dataset, newest first', () async {
    final datasetId = await insertDataset();
    final save = SaveMultiSheetQueryUseCase(
      repository: repository,
      now: () => DateTime.fromMillisecondsSinceEpoch(1000),
    );
    await save(datasetId: datasetId, name: 'first', spec: spec);

    final saveLater = SaveMultiSheetQueryUseCase(
      repository: repository,
      now: () => DateTime.fromMillisecondsSinceEpoch(2000),
    );
    await saveLater(datasetId: datasetId, name: 'second', spec: spec);

    final list = await repository.listForDataset(datasetId);
    expect(list.map((q) => q.name), ['second', 'first']);
  });

  test('updates an existing configuration in place', () async {
    final datasetId = await insertDataset();
    final created = await repository.create(entry(datasetId));

    final save = SaveMultiSheetQueryUseCase(
      repository: repository,
      now: () => DateTime.fromMillisecondsSinceEpoch(9999),
    );
    final updated = await save(
      id: created.id,
      datasetId: datasetId,
      name: 'renamed',
      spec: spec.copyWith(resultLimit: 10),
    );

    expect(updated.id, created.id);
    final reloaded = await repository.getById(created.id!);
    expect(reloaded!.name, 'renamed');
    expect(reloaded.spec.resultLimit, 10);
    expect(reloaded.createdAt, created.createdAt,
        reason: 'createdAt preserved');
    expect(reloaded.updatedAt, DateTime.fromMillisecondsSinceEpoch(9999));

    final list = await repository.listForDataset(datasetId);
    expect(list, hasLength(1), reason: 'update must not insert a new row');
  });

  test('deletes a single configuration', () async {
    final datasetId = await insertDataset();
    final created = await repository.create(entry(datasetId));

    await repository.deleteById(created.id!);

    expect(await repository.getById(created.id!), isNull);
  });

  test('deletes every configuration owned by a dataset', () async {
    final datasetId = await insertDataset();
    final otherDatasetId = await insertDataset();
    await repository.create(entry(datasetId, name: 'a'));
    await repository.create(entry(datasetId, name: 'b'));
    await repository.create(entry(otherDatasetId, name: 'other'));

    await repository.deleteForDataset(datasetId);

    expect(await repository.listForDataset(datasetId), isEmpty);
    expect(
      await repository.listForDataset(otherDatasetId),
      hasLength(1),
      reason: 'other datasets are untouched',
    );
  });

  test('falls back to an empty spec on corrupt specification json', () async {
    final datasetId = await insertDataset();
    final created = await repository.create(entry(datasetId));

    await database.customStatement(
      "UPDATE saved_multi_sheet_queries SET specification_json = 'not json' "
      'WHERE id = ${created.id}',
    );

    final loaded = await repository.getById(created.id!);
    expect(loaded, isNotNull);
    expect(loaded!.spec.isEmpty, isTrue);
  });
}
