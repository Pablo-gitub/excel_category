import 'package:drift/native.dart';
// Drift generates a row class also named DatasetRelationship; hide it.
import 'package:exlser/core/database/app_database.dart'
    hide DatasetRelationship;
import 'package:exlser/core/database/daos/dataset_relationships_dao.dart';
import 'package:exlser/core/database/daos/datasets_dao.dart';
import 'package:exlser/data/repositories/dataset_relationship_repository_impl.dart';
import 'package:exlser/domain/entities/dataset_relationship.dart';
import 'package:exlser/domain/usecases/multisheet/manage_dataset_relationships_usecases.dart';
import 'package:exlser/domain/value_objects/join_cardinality.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late DatasetRelationshipRepositoryImpl repository;
  late DatasetsDao datasetsDao;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = DatasetRelationshipRepositoryImpl(
      DatasetRelationshipsDao(database),
    );
    datasetsDao = DatasetsDao(database);
  });

  tearDown(() async => database.close());

  Future<int> insertDataset() => datasetsDao.createDataset(
        name: 'ds',
        sourceFileName: 'f.xlsx',
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

  DatasetRelationship entity(int datasetId) => DatasetRelationship(
        datasetId: datasetId,
        endpointATableId: 1,
        endpointAColumnDbName: 'product_id',
        endpointBTableId: 2,
        endpointBColumnDbName: 'product',
        cardinality: JoinCardinality.manyToOne,
        relationshipConfidence: 0.9,
        cardinalityConfidence: 0.7,
        sampleSize: 200,
        origin: RelationshipOrigin.suggested,
      );

  test('round-trips every field including the directional cardinality',
      () async {
    final datasetId = await insertDataset();
    final created = await repository.create(entity(datasetId));
    expect(created.id, isNotNull);

    final loaded = await repository.getById(created.id!);
    expect(loaded, isNotNull);
    expect(loaded!.endpointAColumnDbName, 'product_id');
    expect(loaded.endpointBColumnDbName, 'product');
    expect(loaded.cardinality, JoinCardinality.manyToOne);
    expect(loaded.relationshipConfidence, 0.9);
    expect(loaded.cardinalityConfidence, 0.7);
    expect(loaded.sampleSize, 200);
    expect(loaded.origin, RelationshipOrigin.suggested);
    expect(loaded.isConfirmed, isFalse);
  });

  test('create use case rejects an equivalent pair with swapped endpoints',
      () async {
    final datasetId = await insertDataset();
    final useCase = CreateDatasetRelationshipUseCase(repository: repository);
    final first = await useCase(entity(datasetId));

    final swapped = DatasetRelationship(
      datasetId: datasetId,
      endpointATableId: 2,
      endpointAColumnDbName: 'product',
      endpointBTableId: 1,
      endpointBColumnDbName: 'product_id',
    );

    expect(
      () => useCase(swapped),
      throwsA(isA<DuplicateRelationshipException>()
          .having((e) => e.existingId, 'existingId', first.id)),
    );
    expect(await repository.listForDataset(datasetId), hasLength(1));
  });

  test('update use case refuses to change endpoints', () async {
    final datasetId = await insertDataset();
    final created = await repository.create(entity(datasetId));
    final useCase = UpdateDatasetRelationshipUseCase(repository: repository);

    // Same endpoints, new metadata -> allowed.
    final confirmed = await useCase(
      created.copyWith(confirmedAt: DateTime(2026)),
    );
    expect(confirmed.isConfirmed, isTrue);

    // Different endpoints -> rejected.
    expect(
      () => useCase(created.copyWith(endpointBColumnDbName: 'other')),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('deleteForDataset removes only the owning dataset relationships',
      () async {
    final datasetId = await insertDataset();
    final otherId = await insertDataset();
    await repository.create(entity(datasetId));
    await repository.create(entity(otherId));

    await repository.deleteForDataset(datasetId);

    expect(await repository.listForDataset(datasetId), isEmpty);
    expect(await repository.listForDataset(otherId), hasLength(1));
  });
}
