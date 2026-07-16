// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saved_multi_sheet_queries_dao.dart';

// ignore_for_file: type=lint
mixin _$SavedMultiSheetQueriesDaoMixin on DatabaseAccessor<AppDatabase> {
  $DatasetsTable get datasets => attachedDatabase.datasets;
  $SavedMultiSheetQueriesTable get savedMultiSheetQueries =>
      attachedDatabase.savedMultiSheetQueries;
  SavedMultiSheetQueriesDaoManager get managers =>
      SavedMultiSheetQueriesDaoManager(this);
}

class SavedMultiSheetQueriesDaoManager {
  final _$SavedMultiSheetQueriesDaoMixin _db;
  SavedMultiSheetQueriesDaoManager(this._db);
  $$DatasetsTableTableManager get datasets =>
      $$DatasetsTableTableManager(_db.attachedDatabase, _db.datasets);
  $$SavedMultiSheetQueriesTableTableManager get savedMultiSheetQueries =>
      $$SavedMultiSheetQueriesTableTableManager(
          _db.attachedDatabase, _db.savedMultiSheetQueries);
}
