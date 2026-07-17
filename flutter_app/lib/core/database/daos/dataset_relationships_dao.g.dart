// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dataset_relationships_dao.dart';

// ignore_for_file: type=lint
mixin _$DatasetRelationshipsDaoMixin on DatabaseAccessor<AppDatabase> {
  $DatasetsTable get datasets => attachedDatabase.datasets;
  $DatasetRelationshipsTable get datasetRelationships =>
      attachedDatabase.datasetRelationships;
  DatasetRelationshipsDaoManager get managers =>
      DatasetRelationshipsDaoManager(this);
}

class DatasetRelationshipsDaoManager {
  final _$DatasetRelationshipsDaoMixin _db;
  DatasetRelationshipsDaoManager(this._db);
  $$DatasetsTableTableManager get datasets =>
      $$DatasetsTableTableManager(_db.attachedDatabase, _db.datasets);
  $$DatasetRelationshipsTableTableManager get datasetRelationships =>
      $$DatasetRelationshipsTableTableManager(
          _db.attachedDatabase, _db.datasetRelationships);
}
