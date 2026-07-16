//lib/data/repositories/saved_multi_sheet_query_repository_impl.dart

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:exlser/core/database/app_database.dart' as db;
import 'package:exlser/core/database/daos/saved_multi_sheet_queries_dao.dart';
import 'package:exlser/domain/entities/saved_multi_sheet_query.dart';
import 'package:exlser/domain/repositories/saved_multi_sheet_query_repository.dart';
import 'package:exlser/domain/value_objects/multi_sheet_query_spec.dart';

/// Drift-backed implementation of [SavedMultiSheetQueryRepository].
///
/// The database import is prefixed as `db` because Drift generates a row data
/// class also named `SavedMultiSheetQuery`, which would clash with the domain entity.
class SavedMultiSheetQueryRepositoryImpl
    implements SavedMultiSheetQueryRepository {
  final SavedMultiSheetQueriesDao dao;

  const SavedMultiSheetQueryRepositoryImpl(this.dao);

  @override
  Future<SavedMultiSheetQuery> create(SavedMultiSheetQuery query) async {
    final id = await dao.createQuery(
      db.SavedMultiSheetQueriesCompanion.insert(
        datasetId: query.datasetId,
        name: query.name,
        baseTableId: Value(query.spec.baseTableId),
        specificationJson: jsonEncode(query.spec.toJson()),
        schemaVersion: Value(query.spec.schemaVersion),
        createdAt: query.createdAt.millisecondsSinceEpoch,
        updatedAt: query.updatedAt.millisecondsSinceEpoch,
      ),
    );
    return query.copyWith(id: id);
  }

  @override
  Future<void> update(SavedMultiSheetQuery query) async {
    final id = query.id;
    if (id == null) {
      throw ArgumentError('Cannot update a query without an id');
    }
    await dao.updateQuery(
      db.SavedMultiSheetQueriesCompanion(
        id: Value(id),
        datasetId: Value(query.datasetId),
        name: Value(query.name),
        baseTableId: Value(query.spec.baseTableId),
        specificationJson: Value(jsonEncode(query.spec.toJson())),
        schemaVersion: Value(query.spec.schemaVersion),
        createdAt: Value(query.createdAt.millisecondsSinceEpoch),
        updatedAt: Value(query.updatedAt.millisecondsSinceEpoch),
      ),
    );
  }

  @override
  Future<SavedMultiSheetQuery?> getById(int id) async {
    final row = await dao.getById(id);
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<List<SavedMultiSheetQuery>> listForDataset(int datasetId) async {
    final rows = await dao.getForDataset(datasetId);
    return rows.map(_toDomain).toList();
  }

  @override
  Future<void> deleteById(int id) => dao.deleteById(id);

  @override
  Future<void> deleteForDataset(int datasetId) =>
      dao.deleteForDataset(datasetId);

  SavedMultiSheetQuery _toDomain(db.SavedMultiSheetQuery row) {
    return SavedMultiSheetQuery(
      id: row.id,
      datasetId: row.datasetId,
      name: row.name,
      spec: _parseSpec(row.specificationJson),
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt),
    );
  }

  MultiSheetQuerySpec _parseSpec(String rawJson) {
    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is Map<String, dynamic>) {
        return MultiSheetQuerySpec.fromJson(decoded);
      }
    } catch (_) {
      // Fall through to an empty spec on corrupt JSON.
    }
    return const MultiSheetQuerySpec();
  }
}
