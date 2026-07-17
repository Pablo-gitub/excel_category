import 'package:drift/native.dart';
import 'package:exlser/application/dto/confirmed_import.dart';
import 'package:exlser/application/services/create_dataset_service.dart';
import 'package:exlser/core/database/app_database.dart'
    hide DatasetColumn, DatasetTable;
import 'package:exlser/core/database/daos/dataset_files_dao.dart';
import 'package:exlser/core/database/daos/datasets_dao.dart';
import 'package:exlser/core/database/daos/dataset_relationships_dao.dart';
import 'package:exlser/core/database/daos/saved_multi_sheet_queries_dao.dart';
import 'package:exlser/data/datasources/drift_datasource.dart';
import 'package:exlser/data/repositories/dataset_file_repository_impl.dart';
import 'package:exlser/data/services/drift_transaction_runner.dart';
import 'package:exlser/data/repositories/dataset_repository_impl.dart';
import 'package:exlser/data/repositories/query_repository_impl.dart';
import 'package:exlser/data/repositories/dataset_relationship_repository_impl.dart';
import 'package:exlser/data/repositories/saved_multi_sheet_query_repository_impl.dart';
import 'package:exlser/data/repositories/schema_repository_impl.dart';
import 'package:exlser/data/schema/dynamic_table_builder.dart';
import 'package:exlser/domain/entities/dataset_column.dart';
import 'package:exlser/domain/entities/parsed_sheet.dart';
import 'package:exlser/domain/entities/source_file_reference.dart';
import 'package:exlser/domain/usecases/dataset/create_dataset_usecase.dart';
import 'package:exlser/domain/usecases/dataset/delete_dataset_usecase.dart';
import 'package:exlser/domain/usecases/dataset/register_dataset_file_usecase.dart';
import 'package:exlser/domain/usecases/dataset/update_dataset_ui_state_usecase.dart';
import 'package:exlser/domain/usecases/schema/build_dynamic_table_usecase.dart';
import 'package:exlser/domain/usecases/schema/create_dataset_table_usecase.dart';
import 'package:exlser/domain/usecases/schema/insert_rows_usecase.dart';
import 'package:exlser/domain/usecases/schema/register_columns_usecase.dart';
import 'package:exlser/domain/value_objects/column_type.dart';
import 'package:exlser/domain/value_objects/dataset_file_storage_mode.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('create/delete dataset flow', () {
    late AppDatabase database;
    late DatasetsRepositoryImpl datasetsRepository;
    late SchemaRepositoryImpl schemaRepository;
    late DatasetFileRepositoryImpl datasetFileRepository;
    late QueryRepositoryImpl queryRepository;
    late CreateDatasetService createDatasetService;
    late DeleteDatasetUseCase deleteDatasetUseCase;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());

      final datasource = DriftDatasource(database);
      datasetsRepository = DatasetsRepositoryImpl(
        dao: DatasetsDao(database),
      );
      schemaRepository = SchemaRepositoryImpl(
        datasource,
        DynamicTableBuilder(),
      );
      datasetFileRepository = DatasetFileRepositoryImpl(
        dao: DatasetFilesDao(database),
      );
      queryRepository = QueryRepositoryImpl(datasource);

      createDatasetService = CreateDatasetService(
        transactionRunner: DriftTransactionRunner(datasource),
        createDatasetUseCase: CreateDatasetUseCase(
          repository: datasetsRepository,
        ),
        registerDatasetFileUseCase: RegisterDatasetFileUseCase(
          repository: datasetFileRepository,
        ),
        createDatasetTableUseCase: CreateDatasetTableUseCase(
          repository: schemaRepository,
        ),
        registerColumnsUseCase: RegisterColumnsUseCase(
          repository: schemaRepository,
        ),
        buildDynamicTableUseCase: BuildDynamicTableUseCase(
          repository: schemaRepository,
        ),
        insertRowsUseCase: InsertRowsUseCase(queryRepository),
        updateDatasetUiStateUseCase: UpdateDatasetUiStateUseCase(
          repository: datasetsRepository,
        ),
      );

      deleteDatasetUseCase = DeleteDatasetUseCase(
        datasetsRepository: datasetsRepository,
        schemaRepository: schemaRepository,
        datasetFileRepository: datasetFileRepository,
        savedMultiSheetQueryRepository: SavedMultiSheetQueryRepositoryImpl(
          SavedMultiSheetQueriesDao(database),
        ),
        datasetRelationshipRepository: DatasetRelationshipRepositoryImpl(
          DatasetRelationshipsDao(database),
        ),
      );
    });

    tearDown(() async {
      await database.close();
    });

    test('persists and deletes dataset, schema, rows and file reference',
        () async {
      final sourceFileReference = SourceFileReference(
        fileName: 'sales.xlsx',
        storageMode: DatasetFileStorageMode.path,
        originalPath: '/tmp/sales.xlsx',
        importedAt: DateTime(2026, 1, 2),
        fileSize: 128,
      );

      final result = await createDatasetService.createDataset(
        confirmedImport: ConfirmedImport(
          datasetName: 'Sales',
          sourceFileName: 'sales.xlsx',
          sourceFileReference: sourceFileReference,
          sheets: [
            ConfirmedImportSheet(
              sheet: ParsedSheet(
                name: 'Sheet 1',
                rows: [
                  {'product': 'book', 'price': '10'},
                  {'product': 'pen', 'price': '2'},
                ],
              ),
              columns: [
                DatasetColumn(
                  id: 0,
                  datasetTableId: 0,
                  originalName: 'product',
                  dbName: 'product',
                  declaredType: ColumnType.text,
                  inferredType: ColumnType.text,
                  nullable: false,
                  statsJson: null,
                ),
                DatasetColumn(
                  id: 0,
                  datasetTableId: 0,
                  originalName: 'price',
                  dbName: 'price',
                  declaredType: ColumnType.integer,
                  inferredType: ColumnType.integer,
                  nullable: false,
                  statsJson: null,
                ),
              ],
            ),
          ],
        ),
      );

      final dataset = await datasetsRepository.getDatasetById(
        result.datasetId,
      );
      final fileReference = await datasetFileRepository.getByDatasetId(
        result.datasetId,
      );
      final tables = await schemaRepository.getTablesForDataset(
        result.datasetId,
      );
      final columns = await schemaRepository.getColumnsForTable(
        tables.single.id,
      );
      final rowCount = await queryRepository.countRows(
        tables.single.sqlTableName,
      );

      expect(result.datasetName, 'Sales');
      expect(result.tableCount, 1);
      expect(result.columnCount, 2);
      expect(result.rowCount, 2);
      expect(dataset?.name, 'Sales');
      expect(fileReference?.originalPath, '/tmp/sales.xlsx');
      expect(tables.single.sqlTableName, startsWith('ds_${result.datasetId}_'));
      expect(columns.map((column) => column.dbName), ['product', 'price']);
      expect(rowCount, 2);

      await deleteDatasetUseCase(result.datasetId);

      expect(await datasetsRepository.getDatasetById(result.datasetId), isNull);
      expect(
        await datasetFileRepository.getByDatasetId(result.datasetId),
        isNull,
      );
      expect(
        await schemaRepository.getTablesForDataset(result.datasetId),
        isEmpty,
      );
      expect(
        () => queryRepository.countRows(tables.single.sqlTableName),
        throwsA(anything),
      );
    });
  });
}
