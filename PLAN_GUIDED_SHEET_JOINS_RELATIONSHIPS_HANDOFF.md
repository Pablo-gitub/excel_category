# Guided Sheet Joins - R3 Cardinality Handoff

## Scope

Continue on branch `feature/guided-sheet-joins` after:

- `5487694` - persisted `DatasetRelationship` metadata and Drift v3;
- `96e76f9` - saved query specs reference relationships by id;
- `ce23285` - LEFT UI, dataset ownership and stale-spec safety checkpoint;
- `76951fd` - previous handoff document.

This document replaces the previous handoff. R1 and R2 are complete. The objective now
is R3 only:

1. sample bounded rows while retaining duplicates;
2. estimate relationship cardinality from data rather than column names;
3. persist cardinality evidence when a suggestion is confirmed;
4. make the risk analyzer consume persisted cardinality;
5. keep analyzer and the complete test suite green.

Do not start the manual-relationship UI, saved-query UI or pre-execution confirmation UI
in this step. Those are later commits.

## Current Baseline

Claude reported and the checkpoint review confirmed:

- `flutter analyze` clean;
- 535 tests passing;
- working tree clean before this document replacement;
- locale files have only the intended one-line additions;
- query specs use `MultiSheetJoin.relationshipId`;
- `ResolvedJoinStep` already carries `relationshipId`, oriented `cardinality`,
  `cardinalityConfidence` and `sampleSize`.

## Completed Before R3 - LEFT JOIN Derivation

LEFT preservation is already corrected in the working tree. Do not redesign it during
R3.

Current contract:

- `MultiSheetGraphValidator` derives the rooted plan;
- for a LEFT join, `ResolvedJoinStep.existingTableId` is the side preserved by SQLite;
- `preservedTableId` is not required by validation or execution;
- the controller asks `MultiSheetAnalysisService.resolvePlan()` for display metadata;
- the UI displays the resolved side read-only;
- changing the base rebuilds the plan naturally;
- selection order is not used as a proxy for graph accumulation order.

Coverage includes the non-trivial selection order `[1, 3, 2]`, where the graph grows
`1 -> 2 -> 3` and edge `2--3` correctly preserves table 2.

Claude should leave this behavior intact and start R3 at bounded sampling.

## R3.1 Introduce a Bounded Column Sample

### New value object

Create:

- `flutter_app/lib/domain/value_objects/column_relationship_sample.dart`

Suggested contract:

```dart
class ColumnRelationshipSample {
  final List<String> normalizedValues; // duplicates retained
  final int requestedLimit;
  final bool isTruncated;

  int get usableCount;
  int get distinctCount;
  bool get hasEnoughEvidence;
  bool get isUniqueInSample;
  Set<String> get distinctValues;
}
```

Rules:

- `normalizedValues` must retain duplicates;
- SQL NULL and normalized empty strings are absent;
- `usableCount == normalizedValues.length`;
- `distinctCount` is calculated from the normalized set;
- `isUniqueInSample` is true only when evidence is sufficient and
  `usableCount == distinctCount`;
- use a named minimum evidence constant, initially `2` for detecting duplicates;
- `isTruncated` means more usable DB rows existed than retained.

Do not call a one-row sample "unique" with meaningful confidence. It may produce
`unknown` cardinality instead.

Add value semantics only if tests/state comparisons need them.

### Sampling callback

Replace `SampleDistinctValues` in:

- `flutter_app/lib/domain/usecases/multisheet/suggest_sheet_relationships_usecase.dart`

with a callback returning `ColumnRelationshipSample`, for example:

```dart
typedef SampleColumnValues = Future<ColumnRelationshipSample> Function({
  required String sqlTableName,
  required DatasetColumn column,
  required int limit,
});
```

Passing `DatasetColumn` allows type-aware normalization without guessing from runtime
strings.

## R3.2 Change the Internal Sampling Query

Modify:

- `flutter_app/lib/application/services/multi_sheet_analysis_service.dart`

Remove/replace `_sampleDistinct`. It currently executes `SELECT DISTINCT`, which
destroys the duplicate information required for cardinality.

Use a bounded row query with duplicates retained:

```sql
SELECT "column" AS sample_value
FROM "table"
WHERE "column" IS NOT NULL
LIMIT sampleLimit + 1
```

Requirements:

- identifiers remain double-quoted with the existing `_quote` helper;
- limit is an internal positive integer, never raw user text;
- request `sampleLimit + 1` rows to determine `isTruncated`;
- normalize/filter in Dart;
- retain at most `sampleLimit` usable values;
- do not modify shared `QueryRepository.getDistinctValues`;
- continue using the dedicated internal raw query path already established for this
  feature.

### Empty text caveat

Filtering whitespace in Dart can mean the first `sampleLimit + 1` DB rows contain fewer
usable values. This is acceptable for R3 as long as:

- confidence uses the actual usable count;
- empty values never count toward uniqueness or overlap;
- tests cover the behavior.

Do not issue unbounded follow-up queries to fill the sample.

## R3.3 Type-Aware Normalization

Move normalization into a small pure helper, either in the sample value object or:

- `flutter_app/lib/domain/usecases/multisheet/relationship_value_normalizer.dart`

Rules:

- text: trim and lowercase; never parse numeric-looking text into a number;
- integer: normalize numeric runtime values to canonical integer strings;
- real: normalize numeric runtime values consistently without locale formatting;
- boolean: canonical `true` / `false` only when the column is boolean;
- date: use the repository's established date representation; do not introduce fuzzy
  date parsing in R3;
- null/empty -> excluded.

The current `_normalizeValue` converts text such as `"001"` to `"1"`. Remove that
coercion: text business keys may rely on leading zeros.

Tests must include:

- text `"001"` remains `"001"`;
- integer `1` and numeric `1.0` normalize compatibly for numeric columns;
- text trimming/case folding;
- empty/whitespace exclusion;
- null exclusion.

## R3.4 Cache Samples Per Suggestion Run

Modify:

- `flutter_app/lib/domain/usecases/multisheet/suggest_sheet_relationships_usecase.dart`

Replace the current `Map<String, Set<String>>` cache with:

```dart
Map<String, ColumnRelationshipSample>
```

Cache key remains based on stable table and column identity, for example:

```text
tableId|column.dbName
```

Each column must be sampled at most once during one invocation, even when it participates
in several candidate pairs.

Do not persist this cache across runs or datasets.

## R3.5 Estimate Cardinality from Samples

Modify:

- `flutter_app/lib/domain/usecases/multisheet/suggest_sheet_relationships_usecase.dart`
- `flutter_app/lib/domain/value_objects/sheet_relationship_suggestion.dart`
- existing `flutter_app/lib/domain/value_objects/join_cardinality.dart` only if a pure
  helper belongs there.

Remove `_cardinality({aKey, bKey})`. Identifier-like names may remain a relationship
ranking signal, but never determine cardinality.

Use the existing A -> B rules:

```text
A unique, B unique       -> oneToOne
A duplicated, B unique   -> manyToOne
A unique, B duplicated   -> oneToMany
A duplicated, B duplicate-> manyToMany
insufficient evidence    -> unknown
```

Extend `SheetRelationshipSuggestion` with:

```dart
final double cardinalityConfidence;
final int sampleSize;
```

Define `sampleSize` consistently as:

```text
min(a.usableCount, b.usableCount)
```

This matches the existing single `DatasetRelationship.sampleSize` field.

### Confidence policy

Use one explicit pure function and named constants. Recommended baseline:

- either side has fewer than 2 usable values -> cardinality `unknown`, confidence 0;
- both sides are complete (`!isTruncated`) -> confidence 1;
- at least one side is truncated -> sampled estimate, confidence capped below 1;
- confidence increases with `min(sampleSize / sampleLimit, 1)`;
- do not conflate relationship score with cardinality confidence.

For example:

```text
complete samples: 1.0
truncated samples: 0.5 + 0.4 * coverage, capped at 0.9
```

The exact constants may differ, but they must be documented and directly tested. Avoid
pretending sampled uniqueness is mathematically guaranteed.

### Overlap

Continue calculating overlap over distinct normalized values:

```text
intersection / min(distinctCountA, distinctCountB)
```

Duplicates affect cardinality, not overlap ratio.

## R3.6 Persist the Evidence on Confirmation

Modify:

- `flutter_app/lib/presentation/views/sheet_joins/multi_sheet_join_controller.dart`

In `confirmSuggestion`, persist:

- `cardinality`;
- `relationshipConfidence = suggestion.score`;
- `cardinalityConfidence`;
- `sampleSize`;
- `origin = suggested`;
- `confirmedAt = now`.

The checkpoint already fixed `confirmedAt`; preserve that.

For manual relationships, keep cardinality `unknown`, confidence 0 and sample size 0 in
R3 unless the same estimator is explicitly invoked. Do not infer from names.

Add a controller test capturing the `DatasetRelationship` sent to
`createRelationship` and asserting every field.

## R3.7 Rewrite the Risk Analyzer

Modify:

- `flutter_app/lib/domain/usecases/multisheet/multi_sheet_join_risk_analyzer.dart`
- `flutter_app/lib/domain/usecases/multisheet/multi_sheet_sql_builder.dart`
- `flutter_app/test/domain/usecases/multisheet/execute_multi_sheet_preview_test.dart`
- `flutter_app/test/domain/usecases/multisheet/multi_sheet_sql_builder_test.dart`

Remove the dependency on `RelationshipHeuristics` and original column names.

`ResolvedJoinStep` already contains the required evidence. Analyze that directly.

Add warning codes:

```dart
manyToManyRiskCode
unknownCardinalityRiskCode
lowCardinalityConfidenceRiskCode
```

Use deterministic precedence with at most one primary cardinality warning per join:

1. `manyToMany` -> many-to-many warning;
2. `unknown` -> unknown warning;
3. confidence/sample below threshold -> low-confidence warning;
4. otherwise no cardinality warning.

Do not warn merely because neither column name contains `id`. Do not suppress a warning
because a duplicated column is named `id`.

`MultiSheetSqlBuilder` can continue passing labels for user-facing warning text, but it
must no longer pass original column names to risk analysis.

The preview use case remains unchanged: it propagates generated warnings and executes
only one bounded query, with no COUNT.

## R3.8 Warning i18n and Current UI

The current warning widget assumes every warning is many-to-many. Update it minimally so
R3 warnings are truthful.

Modify:

- `flutter_app/lib/presentation/views/sheet_joins/sheet_joins_view.dart`
- `flutter_app/lib/core/constants/app_strings.dart`
- all nine `flutter_app/assets/i18n/*.json` files.

Add separate localized text for:

- many-to-many row multiplication;
- unknown cardinality;
- low-confidence sampled cardinality.

Keep the existing warning banner. The confirmation dialog remains R6, not R3.

Preserve four-space JSON indentation and verify locale key sets match. Do not rewrite
entire locale files.

## Required Tests

### Value object / normalization

Create or extend:

- `flutter_app/test/domain/value_objects/column_relationship_sample_test.dart`
- `flutter_app/test/domain/usecases/multisheet/relationship_value_normalizer_test.dart`
  if a separate normalizer is created.

Cover:

- duplicates retained;
- distinct count;
- uniqueness with sufficient evidence;
- one value is insufficient;
- truncation;
- text leading zeros;
- null/empty filtering;
- numeric normalization.

### Suggestion engine

Modify:

- `flutter_app/test/domain/usecases/multisheet/suggest_sheet_relationships_test.dart`

Cover all cardinalities:

- one-to-one;
- one-to-many;
- many-to-one;
- many-to-many;
- unknown for insufficient sample;
- overlap remains distinct-based;
- cache calls each column once;
- identifier names do not override observed duplicates;
- unrelated text/numeric types are not paired.

### Service sampling

Add focused coverage in:

- `flutter_app/test/application/service/multi_sheet_join_integration_test.dart`

Assert the real in-memory DB path:

- generated sample query contains no `DISTINCT`;
- duplicate rows influence cardinality;
- NULL and blank values do not influence evidence;
- query is bounded;
- repeated candidate use does not repeat sampling.

Prefer behavioral assertions over brittle full SQL string equality.

### Persistence/controller

Modify:

- `flutter_app/test/presentation/views/sheet_joins/multi_sheet_join_controller_test.dart`
- `flutter_app/test/data/repositories/dataset_relationship_repository_test.dart` only if
  needed.

Assert confirmed suggestion persists score, cardinality confidence, sample size and
confirmation timestamp, and survives repository round trip.

### Risk analyzer

Replace name-based tests with evidence-based tests:

- many-to-many warns even when columns are named `id`;
- one-to-many with adequate confidence does not warn;
- unknown warns;
- low confidence warns;
- cardinality orientation inversion does not change whether many-to-many is risky;
- labels and relationship id identify the affected join.

## Verification Commands

Run from `flutter_app/`. Format only touched files.

```bash
dart format <touched Dart files only>

flutter analyze

flutter test test/domain/value_objects/column_relationship_sample_test.dart
flutter test test/domain/usecases/multisheet/suggest_sheet_relationships_test.dart
flutter test test/domain/usecases/multisheet/multi_sheet_graph_validator_test.dart
flutter test test/domain/usecases/multisheet/execute_multi_sheet_preview_test.dart
flutter test test/domain/usecases/multisheet/multi_sheet_sql_builder_test.dart
flutter test test/application/service/multi_sheet_join_integration_test.dart
flutter test test/presentation/views/sheet_joins/multi_sheet_join_controller_test.dart
flutter test test/presentation/views/sheet_joins/sheet_joins_view_test.dart

flutter test
```

Do not run `dart format lib test`.

## Commit Sequence

The LEFT correction and this handoff update are currently in the working tree. Commit
them before starting cardinality, then use a separate R3 feature commit:

```text
fix(joins): derive LEFT preservation from resolved join plan
feat(joins): estimate relationship cardinality from bounded samples
```

Update this document in the second commit or a small `docs:` commit. Do not merge to
`main`.

## R3 Definition of Done

- Sampling query is bounded and retains duplicates.
- NULL and empty normalized values are excluded.
- Text leading zeros are preserved.
- Each column is sampled at most once per suggestion run.
- All five cardinality states are supported.
- Cardinality comes from observed data, never identifier-like names.
- Relationship confidence and cardinality confidence remain separate.
- Confirmed suggestions persist cardinality confidence and sample size.
- Risk warnings use persisted cardinality evidence.
- Warning text matches the warning code.
- Analyzer is clean.
- Full test suite is green.
- No unrelated formatting or locale churn.
