# Guided Sheet Joins - Relationship Refactor Handoff

## Purpose

This document is the continuation plan for `feature/guided-sheet-joins` after the
Claude session ended during the `DatasetRelationship` refactor. It is intentionally
specific: follow the order below instead of re-exploring the repository.

Do not reset or discard the current working tree. The uncommitted files contain a
partially completed migration from inline `SheetJoinRelationship` objects to persisted
`DatasetRelationship` ids.

## Current Git State

- Branch: `feature/guided-sheet-joins`
- Last commit: `5487694 feat(joins): add DatasetRelationship semantic metadata`
- Previous cleanup: `7ac23e3 style(i18n): restore original 4-space formatting`
- `main` is at `7897faf fix(updates): hide desktop updater on web`
- The working tree is intentionally dirty.

Modified but not committed:

- `flutter_app/lib/application/services/multi_sheet_analysis_service.dart`
- `flutter_app/lib/domain/usecases/multisheet/multi_sheet_graph_validator.dart`
- `flutter_app/lib/domain/value_objects/multi_sheet_query_spec.dart`
- `flutter_app/lib/presentation/providers/service_providers.dart`
- `flutter_app/lib/presentation/views/sheet_joins/multi_sheet_join_controller.dart`
- `flutter_app/lib/presentation/views/sheet_joins/sheet_joins_view.dart`
- `flutter_app/test/domain/usecases/multisheet/multi_sheet_graph_validator_test.dart`
- `flutter_app/test/domain/usecases/multisheet/multi_sheet_sql_builder_test.dart`

New and untracked:

- `flutter_app/lib/domain/value_objects/multi_sheet_join.dart`

Current verification result:

```text
flutter analyze: 38 errors
```

All 38 analyzer errors are currently caused by tests and constructors still using the
old `MultiSheetQuerySpec.relationships` / `SheetJoinRelationship` contract. This does
not mean that only mechanical test updates remain: several product and domain items
listed below are still unfinished.

## Already Completed and Committed

Commit `5487694` is the stable foundation. Do not recreate it.

Implemented:

- `DatasetRelationship` domain entity with neutral A/B endpoints.
- Directional `JoinCardinality` read as A -> B.
- Separate relationship confidence, cardinality confidence and sample size.
- `RelationshipOrigin.suggested` and `RelationshipOrigin.userDefined`.
- Dedicated Drift table `dataset_relationships`.
- Database schema version 3.
- Upgrade paths from v1 and branch-local v2 to v3.
- DAO, repository and create/list/load/update use cases.
- Duplicate detection using the unordered endpoint pair.
- Immutable relationship endpoints on update.
- Explicit relationship cleanup in `DeleteDatasetUseCase`.
- Real migration tests for v1 -> v3 and v2 -> v3.
- Repository, entity and delete-flow tests.
- Drift generated files committed.

Key committed files:

- `flutter_app/lib/domain/entities/dataset_relationship.dart`
- `flutter_app/lib/domain/value_objects/join_cardinality.dart`
- `flutter_app/lib/core/database/tables/dataset_relationships.dart`
- `flutter_app/lib/core/database/daos/dataset_relationships_dao.dart`
- `flutter_app/lib/data/repositories/dataset_relationship_repository_impl.dart`
- `flutter_app/lib/domain/repositories/dataset_relationship_repository.dart`
- `flutter_app/lib/domain/usecases/multisheet/manage_dataset_relationships_usecases.dart`
- `flutter_app/test/core/database/app_database_migration_test.dart`
- `flutter_app/test/data/repositories/dataset_relationship_repository_test.dart`
- `flutter_app/test/domain/entities/dataset_relationship_test.dart`

### Small foundation corrections still required

The architecture in `5487694` is stable, but audit these details before treating the
commit as finished:

1. `CreateDatasetRelationshipUseCase.now` and
   `UpdateDatasetRelationshipUseCase.now` are injected but never used. Timestamps are
   currently generated inside the repository. Either remove the unused clocks or move
   timestamp ownership to the use cases consistently; do not keep misleading test hooks.
2. Validate `datasetId > 0`, non-empty endpoint column names, confidence values in
   `0..1`, and `sampleSize >= 0` before persistence.
3. Validate table ids are positive and endpoints are different. The different-table
   check exists in create, but the entity/repository can still be called directly; keep
   domain-use-case tests explicit.
4. Define the meaning of the single `sampleSize` when the two bounded sides return
   different row counts. Recommended: store the smaller usable sample count and document
   it, or introduce separate A/B counts before release.
5. `DatasetRelationship.copyWith` cannot clear `confirmedAt` because null means "keep
   existing". Add an explicit clear flag only if unconfirming is a supported operation;
   otherwise document confirmation as irreversible.
6. Repository methods operating by id do not enforce dataset ownership. Enforce ownership
   in application use cases whenever an id originates from a route/controller.

## Target Domain Contract

Keep these concepts separate.

### DatasetRelationship

Dataset-level semantic metadata. It owns:

- endpoint A table and column;
- endpoint B table and column;
- A -> B cardinality;
- relationship confidence;
- cardinality confidence;
- sample size;
- origin;
- confirmation timestamp.

It does not own `INNER` versus `LEFT`; that is query behavior.

### MultiSheetJoin

One use of a persisted relationship in a saved query. It owns:

- `relationshipId`;
- `joinType`;
- `preservedTableId` only for `LEFT JOIN`.

The current untracked implementation in
`flutter_app/lib/domain/value_objects/multi_sheet_join.dart` is the intended starting
point. Add tests before committing it.

### MultiSheetQuerySpec

It owns:

- base table;
- selected tables;
- output columns;
- list of `MultiSheetJoin` objects;
- preview limit;
- specification schema version.

It must not duplicate relationship endpoints.

## Immediate Step 1 - Finish the In-Progress Contract Refactor

Finish this step before working on cardinality or UI. The goal is a compiling suite
with old tests migrated to the new contract.

### 1.1 Finalize MultiSheetJoin and spec serialization

Files:

- `flutter_app/lib/domain/value_objects/multi_sheet_join.dart`
- `flutter_app/lib/domain/value_objects/multi_sheet_query_spec.dart`
- `flutter_app/test/domain/value_objects/multi_sheet_join_test.dart`

Required corrections:

1. Bump `MultiSheetQuerySpec.currentSchemaVersion` from 1 to 2. The JSON shape changed
   from inline `relationships` to `joins`, so keeping version 1 silently misreads old
   stored JSON.
2. Decide explicitly how version-1 specs are handled:
   - recommended for this unreleased branch: parse them as unsupported/stale rather
     than silently returning a valid-looking spec with no joins;
   - do not invent relationship ids during pure JSON parsing because that requires DB
     writes.
3. Do not return an indistinguishable empty spec for a future schema version. Prefer a
   dedicated parse exception/result that the repository/controller can surface as
   stale. If retaining the empty-spec fallback, document and test the loss of reason.
4. Reject or drop invalid relationship ids (`<= 0`) in `MultiSheetJoin.fromJson`.
5. For `INNER`, always normalize `preservedTableId` to null.
6. Add equality/hashCode if tests or state comparisons need value semantics.
7. Preserve ordered de-duplication of `selectedTableIds` already implemented in the
   working tree.
8. Add tests for:
   - INNER round trip;
   - LEFT round trip with explicit table id;
   - INNER ignoring a persisted side;
   - missing/invalid relationship id;
   - duplicate selected table ids;
   - future schema version;
   - legacy version-1 behavior.

Update old tests by replacing:

```dart
relationships: [SheetJoinRelationship(...)]
```

with:

```dart
joins: [MultiSheetJoin(relationshipId: 10, ...)]
```

The corresponding `DatasetRelationship(id: 10, ...)` must be supplied separately to
validators/services.

### 1.2 Complete graph validator semantics

Files:

- `flutter_app/lib/domain/usecases/multisheet/multi_sheet_graph_validator.dart`
- `flutter_app/test/domain/usecases/multisheet/multi_sheet_graph_validator_test.dart`

The current refactor already resolves relationship ids and detects missing or duplicate
relationships. Keep that work.

Required corrections:

1. Verify that every resolved relationship belongs to the opened dataset. The current
   validator receives no dataset id. Either:
   - filter the map in the service and guarantee it only contains this dataset; and/or
   - pass `datasetId` to validation and reject a relationship owned by another dataset.
2. Keep checks for missing relationship, stale table/column, disconnected graph, cycle,
   duplicate id and duplicate endpoint pair.
3. Add `relationshipId` and `JoinCardinality` (plus cardinality confidence if needed)
   to `ResolvedJoinStep`. The risk analyzer must not rediscover relationship semantics
   from column names.
4. Resolve the LEFT JOIN preserved-side problem before exposing both sides in the UI.

Current problem: SQL generation always adds the new table on the right. SQLite `LEFT
JOIN` therefore preserves the already accumulated side. The UI currently lets the user
select either endpoint, but the validator rejects the endpoint that happens to be added
later.

Recommended Step-1 behavior:

- preserve the accumulated/base side only;
- display that side clearly;
- if the user wants the other side preserved, change the base/join ordering first;
- do not show a control that produces a predictably invalid spec.

Do not attempt RIGHT JOIN emulation in this step. For a multi-edge tree, arbitrary
per-edge preserved-side requirements can conflict with a single root order.

Tests to retain/add:

- missing relationship id -> `missing_relationship`;
- relationship from another dataset rejected;
- relationship endpoint table not selected;
- stale endpoint column;
- duplicate relationship id;
- duplicate endpoint pair under different ids;
- connected two-table and three-table trees;
- disconnected graph and cycle;
- LEFT preserving accumulated side accepted;
- impossible/reversed LEFT side rejected with a clear code.

### 1.3 Update SQL builder tests

Files:

- `flutter_app/lib/domain/usecases/multisheet/multi_sheet_sql_builder.dart`
- `flutter_app/test/domain/usecases/multisheet/multi_sheet_sql_builder_test.dart`

The builder should continue receiving only a resolved plan. It should not query the
relationship repository itself.

Keep existing behavior:

- deterministic table aliases;
- quoted identifiers;
- technical output aliases;
- display labels independent from row data;
- explicit preview limit;
- generated SQL accepted by `ReadOnlySqlValidator`.

Update fixtures to build the plan through the new validator and relationship map.

### 1.4 Update service constructors and all broken tests

Files currently reported by analyzer:

- `flutter_app/test/application/service/multi_sheet_join_integration_test.dart`
- `flutter_app/test/data/repositories/saved_multi_sheet_query_repository_test.dart`
- `flutter_app/test/domain/usecases/multisheet/execute_multi_sheet_preview_test.dart`
- `flutter_app/test/domain/value_objects/multi_sheet_join_test.dart`
- `flutter_app/test/presentation/views/sheet_joins/multi_sheet_join_controller_test.dart`
- `flutter_app/test/presentation/views/sheet_joins/sheet_joins_view_test.dart`

For every `MultiSheetAnalysisService(...)` fixture provide mocks/real implementations
for:

- `createRelationshipUseCase`;
- `listRelationshipsUseCase`;
- `updateRelationshipUseCase`.

For every `buildQuery` / `runPreview` call provide `relationshipsById`.

For controller tests, replace direct synchronous `addRelationship` calls with either:

- `await addManualRelationship(...)`; or
- `await confirmSuggestion(...)`.

Mock `service.createRelationship` to return a persisted entity with a non-null id.

Commit target after Step 1:

```text
feat(joins): reference persisted relationships from saved queries
```

Do not commit until `flutter analyze` is clean and the focused domain/service/controller
tests pass.

## Step 2 - Replace Name-Based Cardinality with Bounded Data Sampling

This work has not started. The current implementation is still incorrect:

- `SuggestSheetRelationshipsUseCase._cardinality` uses identifier-like column names;
- `MultiSheetJoinRiskAnalyzer` decides risk from names;
- `MultiSheetAnalysisService._sampleDistinct` removes duplicates, so it cannot measure
  uniqueness.

Files to modify:

- `flutter_app/lib/domain/usecases/multisheet/suggest_sheet_relationships_usecase.dart`
- `flutter_app/lib/domain/value_objects/sheet_relationship_suggestion.dart`
- `flutter_app/lib/application/services/multi_sheet_analysis_service.dart`
- `flutter_app/lib/domain/usecases/multisheet/multi_sheet_join_risk_analyzer.dart`
- `flutter_app/lib/domain/usecases/multisheet/multi_sheet_graph_validator.dart`
- `flutter_app/lib/domain/usecases/multisheet/multi_sheet_sql_builder.dart`
- corresponding tests under `flutter_app/test/domain/usecases/multisheet/`
- integration test under `flutter_app/test/application/service/`

Recommended sampling contract:

```dart
class ColumnRelationshipSample {
  final List<Object?> values; // bounded, duplicates retained
  final int nonNullCount;
  final int distinctCount;
  final bool isUnique;
}
```

Sampling requirements:

- execute a dedicated bounded internal query;
- retain duplicates;
- exclude SQL NULL;
- exclude empty/whitespace-only text after normalization;
- cap rows, not only distinct values;
- cache once per `(tableId, columnDbName)` during one suggestion run;
- keep numeric and text normalization type-aware;
- do not coerce arbitrary text to numeric.

A suitable query shape is:

```sql
SELECT sample_value
FROM (
  SELECT "column" AS sample_value
  FROM "table"
  WHERE "column" IS NOT NULL
  LIMIT ?
)
```

Compute counts in Dart from the bounded rows, or use a bounded subquery with
`COUNT(*)` and `COUNT(DISTINCT ...)`. If overlap values and uniqueness are both needed,
one bounded row sample calculated in Dart is simpler and avoids two queries.

Cardinality rules, read A -> B:

- A unique, B unique -> `oneToOne`;
- A duplicated, B unique -> `manyToOne`;
- A unique, B duplicated -> `oneToMany`;
- A duplicated, B duplicated -> `manyToMany`;
- insufficient sample -> `unknown`.

Suggestion output must carry:

- relationship confidence/score;
- estimated cardinality;
- cardinality confidence;
- sample size;
- overlap ratio;
- reasons.

When confirming a suggestion, persist all of those fields and set `confirmedAt` because
the user has explicitly confirmed it. The current controller omits `confirmedAt` for
suggested relationships; fix it.

For a manual relationship:

- `origin = userDefined`;
- `confirmedAt = now`;
- cardinality may initially be `unknown`, or run the same bounded estimator before
  persistence;
- do not fabricate high confidence.

### Risk analyzer correction

`MultiSheetJoinRiskAnalyzer` must use persisted cardinality from the resolved join plan,
not `RelationshipHeuristics.isIdentifierName`.

Warn at minimum when:

- cardinality is `manyToMany`;
- cardinality is `unknown`;
- cardinality confidence/sample is below an agreed threshold.

Avoid calling every non-identifier pair many-to-many and avoid suppressing warnings only
because a column is named `id`.

Commit target:

```text
feat(joins): estimate relationship cardinality from bounded samples
```

## Step 3 - Finish Controller Correctness

File:

- `flutter_app/lib/presentation/views/sheet_joins/multi_sheet_join_controller.dart`

Work already partially present:

- relationship map in state;
- loading relationships with sheets and saved queries;
- relationship-id joins;
- stale suggestion token;
- manual relationship controller method;
- persisted suggestion confirmation;
- LEFT join type and preserved side methods.

Required corrections:

1. Increment `_suggestionToken` on every selection/spec edit, not only when starting a
   new suggestion request. Otherwise changing sheets while one request runs does not
   necessarily invalidate it until another request starts.
2. Capture immutable request inputs before `await`. Do not read mutable `state.spec` after
   asynchronous work returns.
3. Add a token or equivalent guard to `load()` and `loadSaved()` if repeated loads can
   overlap.
4. In `_persistAndAddJoin`, expose persistence errors instead of silently returning when
   duplicate reload fails.
5. Confirmed suggestions must set `confirmedAt`.
6. Validate that a loaded saved query belongs to `datasetId`; current load APIs are by id
   only.
7. Validate before save. Decide whether drafts are allowed. Recommended: allow saving a
   named draft only if the UI labels it as draft; otherwise require a valid connected
   spec.
8. `MultiSheetQuerySpec.copyWith` currently cannot clear `baseTableId`. Add an explicit
   clear flag or nullable wrapper. Deselecting all sheets must not retain an old base id.
9. When removing a sheet, remove joins whose persisted relationship references it (the
   working tree already starts this).
10. Do not delete a `DatasetRelationship` when removing it from one query. Removing a join
    and deleting dataset metadata are different actions.
11. Add explicit state for `saving` / `deleting` or prevent repeated taps during those
    operations.
12. Clear old suggestions when selected sheets or relevant columns change.

Update controller tests for all points above.

## Step 4 - Add Manual Relationship UI

The controller method exists, but no UI invokes it.

Primary file:

- `flutter_app/lib/presentation/views/sheet_joins/sheet_joins_view.dart`

Optional extraction if the existing file becomes too large:

- `flutter_app/lib/presentation/views/sheet_joins/widgets/manual_relationship_dialog.dart`

Required flow:

1. Add `Define relationship` next to the relationship section title.
2. Open a dialog/bottom sheet with:
   - left selected sheet;
   - left column;
   - right selected sheet;
   - right column;
   - validation that sheets differ;
   - validation that columns and types are compatible;
   - clear confirmation/cancel actions.
3. Call `await controller.addManualRelationship(...)`.
4. Disable the confirmation action while saving.
5. Surface duplicate/persistence errors.
6. Show cardinality as unknown/estimated; do not claim an FK unless measured.

Add keys for widget tests and tests for:

- manual relationship when suggestion list is empty;
- same-sheet rejection;
- duplicate endpoint rejection;
- successful persisted relationship and join addition;
- narrow layout with no overflow.

## Step 5 - Add Saved Query UI

The backend/controller methods already exist but are unreachable from the view.

Files:

- `flutter_app/lib/presentation/views/sheet_joins/sheet_joins_view.dart`
- optionally `flutter_app/lib/presentation/views/sheet_joins/widgets/saved_queries_section.dart`
- `flutter_app/test/presentation/views/sheet_joins/sheet_joins_view_test.dart`

Required controls:

- text field/dialog for a non-empty query name;
- Save new;
- Update current saved query;
- list/dropdown of saved queries;
- Load;
- Delete with confirmation;
- visible indication of active saved query;
- stale saved-query message if a referenced relationship/table/column is gone.

Behavior rules:

- saving must persist the v2 spec with relationship ids;
- loading must validate against current relationship and schema maps;
- deleting a saved query must not delete shared relationships;
- if active query is deleted, clear `activeSavedQueryId`;
- prevent update of a query owned by another dataset;
- do not silently overwrite after save failure.

## Step 6 - Require Confirmation Before Risky Execution

Current behavior is still wrong: `runPreview()` calls `prepare()` and immediately executes;
the warning is displayed only after execution.

Files:

- `flutter_app/lib/presentation/views/sheet_joins/multi_sheet_join_controller.dart`
- `flutter_app/lib/presentation/views/sheet_joins/sheet_joins_view.dart`
- related widget/controller tests.

Recommended API:

```dart
bool prepare();                 // builds SQL and warnings only
Future<void> executePrepared(); // executes current prepared query
```

UI flow:

1. Run button invokes `prepare()`.
2. If no warnings, execute immediately.
3. If warnings exist, show a confirmation dialog before DB execution.
4. Dialog names affected sheets and explains possible row multiplication.
5. Cancel leaves generated SQL visible and does not call the repository.
6. Confirm calls `executePrepared()`.
7. Any spec edit invalidates the prepared query.

Add tests proving that the query repository is not called before confirmation.

## Step 7 - Relationship Deletion Policy

The repository can delete relationships, but there is no delete use case or product flow.
Do not add a delete button until the policy is implemented.

Preferred policy for this step:

- relationships may be deleted as dataset metadata;
- saved queries that reference a deleted relationship become stale;
- deletion requires explicit confirmation and reports how many saved queries reference it;
- never silently rewrite a saved query to a different relationship.

Alternative acceptable policy:

- block deletion while any saved query references the relationship.

Whichever policy is selected, implement it atomically at application/use-case level and
test it. Do not put cross-repository business logic in the DAO.

Likely files:

- `flutter_app/lib/domain/usecases/multisheet/manage_dataset_relationships_usecases.dart`
- `flutter_app/lib/domain/repositories/saved_multi_sheet_query_repository.dart`
- repository implementation/DAO only if a reference query is needed;
- controller and UI only if relationship deletion is exposed now.

## Step 8 - i18n

New UI strings require updates in all nine locale files:

- `flutter_app/assets/i18n/en.json`
- `flutter_app/assets/i18n/it.json`
- `flutter_app/assets/i18n/es.json`
- `flutter_app/assets/i18n/fr.json`
- `flutter_app/assets/i18n/de.json`
- `flutter_app/assets/i18n/zh.json`
- `flutter_app/assets/i18n/ru.json`
- `flutter_app/assets/i18n/ja.json`
- `flutter_app/assets/i18n/pt.json`

Also update:

- `flutter_app/lib/core/constants/app_strings.dart`

Likely new keys:

- define/manual relationship;
- select left/right sheet and column;
- relationship duplicate/save failure;
- cardinality labels including unknown;
- relationship confidence/cardinality confidence/sample;
- saved query name/save/update/load/delete/delete confirmation;
- risky join confirmation title/body/continue;
- missing relationship/stale saved query;
- saving/deleting states.

Preserve four-space JSON indentation. Do not run a formatter that rewrites the full
locale files. Verify all locale key sets match.

## Step 9 - Tests and Verification Order

Run focused checks after each layer rather than repeatedly running the full suite.

From `flutter_app/`:

```bash
dart format <only touched Dart files>

flutter analyze

flutter test test/domain/value_objects/multi_sheet_join_test.dart
flutter test test/domain/entities/dataset_relationship_test.dart
flutter test test/domain/usecases/multisheet/multi_sheet_graph_validator_test.dart
flutter test test/domain/usecases/multisheet/multi_sheet_sql_builder_test.dart
flutter test test/domain/usecases/multisheet/suggest_sheet_relationships_test.dart
flutter test test/domain/usecases/multisheet/execute_multi_sheet_preview_test.dart
flutter test test/data/repositories/dataset_relationship_repository_test.dart
flutter test test/data/repositories/saved_multi_sheet_query_repository_test.dart
flutter test test/application/service/multi_sheet_join_integration_test.dart
flutter test test/presentation/views/sheet_joins/multi_sheet_join_controller_test.dart
flutter test test/presentation/views/sheet_joins/sheet_joins_view_test.dart
flutter test test/core/database/app_database_migration_test.dart
```

Then run:

```bash
flutter test
```

Do not run `dart format lib test`; repository-wide formatting causes unrelated churn.

Drift code generation is needed only if committed table/DAO definitions change again:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Commit generated `.g.dart` files when regenerated.

## Required Integration Scenarios

The final integration/widget coverage must include:

1. Suggested one-to-many relationship persisted and used by id.
2. Manual relationship persisted when no suggestion exists.
3. Relationship reused by two saved queries without endpoint duplication.
4. INNER preview.
5. LEFT preview preserving the valid accumulated side.
6. Empty result with headers.
7. Many-to-many warning blocks execution until confirmation.
8. Unknown/low-confidence cardinality warning.
9. Save, close/recreate controller, load, validate and run.
10. Missing relationship makes saved query stale.
11. Removed/renamed column makes saved query stale.
12. Dataset deletion removes files, saved queries, relationships, schema and dataset.
13. v1 -> v3 and v2 -> v3 database upgrades retain existing data.
14. A relationship from another dataset cannot be used.
15. Superseded suggestion and preview results cannot overwrite newer state.

## Suggested Commit Sequence

Keep the current committed foundation. Continue with small commits:

```text
feat(joins): reference persisted relationships from saved queries
feat(joins): estimate relationship cardinality from bounded samples
feat(joins): add manual relationship workflow
feat(joins): expose saved join configurations
feat(joins): confirm risky joins before execution
test(joins): cover relationship-backed guided join workflow
```

Do not commit all remaining work as one changeset. Do not merge to `main` until analyzer,
the full suite and manual desktop/mobile-width checks pass.

## Definition of Done for This Branch

- Analyzer clean.
- Full test suite green.
- Query specs persist relationship ids, not inline endpoints.
- Relationship cardinality comes from bounded data samples, not names.
- Suggested and manual relationships are persisted and explicitly confirmed.
- User can create a relationship without relying on suggestions.
- User can save, load, update and delete join configurations from the UI.
- LEFT JOIN behavior shown by the UI is executable and unambiguous.
- Risky joins require confirmation before any query runs.
- Missing relationships/tables/columns produce a stale state, not a crash.
- No full-file i18n churn.
- No physical SQLite foreign keys are added to imported dynamic data tables.
- No merge to `main` has been performed.
