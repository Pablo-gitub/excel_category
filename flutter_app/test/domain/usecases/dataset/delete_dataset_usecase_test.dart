import 'package:exlser/domain/repositories/dataset_file_repository.dart';
import 'package:exlser/domain/repositories/datasets_repository.dart';
import 'package:exlser/domain/repositories/dataset_relationship_repository.dart';
import 'package:exlser/domain/repositories/saved_multi_sheet_query_repository.dart';
import 'package:exlser/domain/repositories/schema_repository.dart';
import 'package:exlser/domain/usecases/dataset/delete_dataset_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDatasetsRepository extends Mock implements DatasetsRepository {}

class MockSchemaRepository extends Mock implements SchemaRepository {}

class MockDatasetFileRepository extends Mock implements DatasetFileRepository {}

class MockSavedMultiSheetQueryRepository extends Mock
    implements SavedMultiSheetQueryRepository {}

class MockDatasetRelationshipRepository extends Mock
    implements DatasetRelationshipRepository {}

void main() {
  group('DeleteDatasetUseCase', () {
    late MockDatasetsRepository datasetsRepository;
    late MockSchemaRepository schemaRepository;
    late MockDatasetFileRepository datasetFileRepository;
    late MockSavedMultiSheetQueryRepository savedMultiSheetQueryRepository;
    late MockDatasetRelationshipRepository datasetRelationshipRepository;
    late DeleteDatasetUseCase useCase;

    setUp(() {
      datasetsRepository = MockDatasetsRepository();
      schemaRepository = MockSchemaRepository();
      datasetFileRepository = MockDatasetFileRepository();
      savedMultiSheetQueryRepository = MockSavedMultiSheetQueryRepository();
      datasetRelationshipRepository = MockDatasetRelationshipRepository();
      useCase = DeleteDatasetUseCase(
        datasetsRepository: datasetsRepository,
        schemaRepository: schemaRepository,
        datasetFileRepository: datasetFileRepository,
        savedMultiSheetQueryRepository: savedMultiSheetQueryRepository,
        datasetRelationshipRepository: datasetRelationshipRepository,
      );
    });

    test('should delete file reference, schema and dataset', () async {
      /// Arrange
      const datasetId = 123;

      when(() => datasetFileRepository.deleteByDatasetId(any()))
          .thenAnswer((_) async {});
      when(() => savedMultiSheetQueryRepository.deleteForDataset(any()))
          .thenAnswer((_) async {});
      when(() => datasetRelationshipRepository.deleteForDataset(any()))
          .thenAnswer((_) async {});
      when(() => schemaRepository.deleteSchemaForDataset(any()))
          .thenAnswer((_) async {});
      when(() => datasetsRepository.deleteDataset(any()))
          .thenAnswer((_) async {});

      /// Act
      await useCase(datasetId);

      /// Assert
      verifyInOrder([
        () => datasetFileRepository.deleteByDatasetId(datasetId),
        () => schemaRepository.deleteSchemaForDataset(datasetId),
        () => datasetsRepository.deleteDataset(datasetId),
      ]);

      verifyNoMoreInteractions(datasetFileRepository);
      verifyNoMoreInteractions(schemaRepository);
      verifyNoMoreInteractions(datasetsRepository);
    });

    test('should throw when dataset id is invalid', () async {
      expect(
        () => useCase(0),
        throwsException,
      );

      verifyNever(() => datasetFileRepository.deleteByDatasetId(any()));
      verifyNever(() => schemaRepository.deleteSchemaForDataset(any()));
      verifyNever(() => datasetsRepository.deleteDataset(any()));
    });

    /// TODO:
    /// Test per gestire cosa succede se l'eliminazione dello schema fallisce (es. DatabaseException)
  });
}
