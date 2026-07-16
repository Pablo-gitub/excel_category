//lib/domain/entities/saved_multi_sheet_query.dart

import 'package:exlser/domain/value_objects/multi_sheet_query_spec.dart';

/// A named, persisted multi-sheet join configuration owned by a dataset.
///
/// Reusable application entity: multiple can exist per dataset. The [spec] holds
/// only stable identifiers and is re-validated against the current schema on load.
class SavedMultiSheetQuery {
  /// Null until the row has been persisted.
  final int? id;
  final int datasetId;
  final String name;
  final MultiSheetQuerySpec spec;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SavedMultiSheetQuery({
    this.id,
    required this.datasetId,
    required this.name,
    required this.spec,
    required this.createdAt,
    required this.updatedAt,
  });

  SavedMultiSheetQuery copyWith({
    int? id,
    int? datasetId,
    String? name,
    MultiSheetQuerySpec? spec,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SavedMultiSheetQuery(
      id: id ?? this.id,
      datasetId: datasetId ?? this.datasetId,
      name: name ?? this.name,
      spec: spec ?? this.spec,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
