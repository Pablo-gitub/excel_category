# AGENTS.md

Operational guide for AI agents working on Exlser. Product overview, install steps and
repository layout live in [README.md](README.md); what to build next lives in
[ROADMAP.md](ROADMAP.md). This file only covers what those don't: conventions and traps.

Exlser is a **local-first** spreadsheet workspace: CSV/XLSX become persistent local datasets
with filters, read-only SQL, charts and exports. No server, no cloud account. Keep that
promise in mind — features that phone home or require an account are out of character.

Monorepo:

- `flutter_app/` — the Flutter app (Android, desktop, web demo)
- `landing_page/` — the React/Vite landing page

## Commands

Run Flutter commands **from `flutter_app/`**:

```bash
flutter pub get
flutter analyze                 # must be clean
flutter test                    # full suite must stay green
dart format lib test            # see the formatting caveat below
dart run build_runner build --delete-conflicting-outputs   # after touching Drift tables/DAOs
```

Landing page:

```bash
npm --prefix landing_page install
npm --prefix landing_page run dev
npm --prefix landing_page run build
```

## Architecture (Flutter app)

Layers and dependency direction (see ROADMAP.md for the full rules):

```text
presentation -> application/domain
application  -> domain
data         -> domain
core         -> shared infrastructure
```

State management is **split by purpose** — respect it:

- **BLoC** → the dataset workspace: opened dataset, active sheet, filters, sorting, rows,
  refresh, view mode, analytics.
- **Riverpod** → dependency wiring, routing, settings, lightweight ViewModels/controllers,
  temporary UI state, the import wizard, and standalone views.

Product rule: a persistent dataset is created **only after the final wizard confirmation**.
Before that the user must be able to review file, sheets, column names and types.

`DatasetBloc` and `DatasetView` are already large. Prefer a dedicated Riverpod controller +
view for a new standalone surface over growing them (see `presentation/views/sheet_joins/`).

## Conventions

- **Conventional commits**: `feat(scope): ...`, `fix(scope): ...`, `test(scope): ...`.
- **Never add `Co-Authored-By`, "generated with", or any AI/assistant attribution** to
  commits. The author is the repo owner, full stop.
- Small, coherent commits — do not bundle a whole feature into one commit.
- Work on a feature branch; do not merge to `main` until analyzer, tests and review pass.
- Pushing requires the owner's credentials — do not attempt it unattended.

## Traps that cost real time

**Drift codegen.** Adding or changing a table/DAO requires
`dart run build_runner build --delete-conflicting-outputs`. Generated `.g.dart` files are
committed.

**Drift name collisions.** Drift generates a row class named after the singularized table
(`SavedMultiSheetQueries` → `SavedMultiSheetQuery`), which clashes with a same-named domain
entity. Use a prefixed import (`import '...app_database.dart' as db;`) or `hide` — the
codebase already does `hide DatasetColumn, DatasetTable`.

**Migrations.** Adding a table means bumping `AppDatabase.schemaVersion` and extending
`MigrationStrategy.onUpgrade` with `m.createTable(...)`. `onCreate` calls `m.createAll()`.

**No database-level cascade.** SQLite's `foreign_keys` PRAGMA is **not** enabled, so
`references(...)` is documentation, not enforcement. Rows owned by a dataset are deleted
explicitly in `DeleteDatasetUseCase` (files → saved queries → schema → dataset). Add new
owned tables to that chain rather than enabling the PRAGMA, which would change existing
delete flows.

**All raw SQL goes through `ReadOnlySqlValidator`** (SELECT-only, single statement, no
comments/semicolons, tables restricted to `allowedTableNames`). Never bypass it, and never
let user input reach the database another way.

**`ExecuteReadOnlyQueryUseCase` always runs a parallel `COUNT(*)`.** That is fine for a
single sheet but not for joins, where counting the full result is expensive — use
`ExecuteMultiSheetPreviewUseCase`, which validates the same way but runs only the limited
query.

**`QueryRepository.getDistinctValues` is unbounded and keeps NULLs**, and it is shared with
the filter UI. Don't "fix" it; if you need a bounded sample, issue a dedicated raw query with
`LIMIT` and `IS NOT NULL` (see `MultiSheetAnalysisService`).

**Formatting churn.** The repo is not fully formatted with the current `dart format`, so
`dart format lib test` rewrites unrelated files. Format only the files you touched, or revert
the collateral before committing.

## i18n

- App strings: `flutter_app/assets/i18n/*.json` — **9 locales**: `en, it, es, fr, de, zh, ru, ja, pt`.
- Every key needs a constant in `lib/core/constants/app_strings.dart`, used as
  `AppStrings.someKey.tr()`.
- Placeholders are **named**: `{count}`, `{limit}` … passed via `tr(namedArgs: {'count': '3'})`.
- Adding a key means adding it to **all 9 locales**; verify the key sets match afterwards.
- The landing page has its own i18n in `landing_page/src/i18n.js` (same 9 languages).

## Testing

- The full suite must stay green; add tests with every behaviour change.
- Integration tests use a real in-memory Drift database (`AppDatabase(NativeDatabase.memory())`).
- Widget tests that render localized UI need `SharedPreferences.setMockInitialValues({})`
  **before** `await EasyLocalization.ensureInitialized()`.
- A lazy `ListView` does not build off-screen children, so `find.byKey` returns nothing for
  them. Give the test a tall surface (`tester.view.physicalSize`) or scroll first.
- Mocking uses `mocktail`; remember `registerFallbackValue` for custom types used with `any()`.

## Landing page

- Dark navy theme derived from the logo (`--bg: #071a33`), accents blue `#4da3ff` / green `#34d98a`.
- **Visuals must show the real app** — real screenshots or footage, never fabricated or
  AI-generated UI (an earlier asset shipped with garbled invented labels and was removed).
- The Android beta funnel is **contact-only by design**: no signup form and no database, to
  avoid handling personal data. Don't propose lead capture.
- Deploy: push a `landing-v*` tag → GitHub Action builds the landing + the Flutter web demo
  and publishes to Firebase Hosting. Both build in one job, so a broken Flutter build blocks
  the landing release too.
- Desktop download links use GitHub's stable latest redirect
  (`releases/latest/download/<os>-build.zip`), so they never go stale.
