# CLAUDE.md

The instructions for this repository live in **[AGENTS.md](AGENTS.md)**, so that every agent
reads the same source of truth. This file imports them and adds Claude-specific notes.

@AGENTS.md

## Token economy

Context here is expensive and easy to waste. These are the actual offenders in this repo, in
rough order of cost:

- **`flutter test` is the worst offender.** It writes progress with carriage returns, so the
  whole run is *one huge line* and a plain `grep` re-prints all of it. Collapse it first:

  ```bash
  flutter test 2>&1 | tr '\r' '\n' | tail -3
  flutter test test/path/to/file_test.dart 2>&1 | tr '\r' '\n' | grep -E "All tests passed|Some tests failed|Expected:|Actual:"
  ```

  While iterating run only the file under test; run the full suite once before committing, not
  after every edit. The owner may prefer to run the full suite themselves and report back only
  warnings/errors — ask rather than assume.
- **Pipe every verbose command** through `tail`/`grep`: `build_runner`, `flutter analyze`,
  `npm run build`, `git log`.
- **Never read a large file whole.** `ROADMAP.md` (~1300 lines), `dataset_view.dart` (~1800),
  `dataset_bloc.dart` (~1300), `dataset_workspace_ui_state.dart` (~700). Use `grep -rn` for the
  symbol first, then Read with `offset`/`limit` around the hit.
- **Screenshots are very expensive.** Take them only for genuinely visual work (the landing
  page), and prefer asserting on the DOM/text instead. One screenshot to confirm, not a series.
- **Don't re-read a file you just wrote or edited** — the edit already failed loudly if it
  didn't apply.
- Prefer one targeted `grep -rn "Symbol" lib` over listing or reading whole directories.
- Don't paste long file contents back into the reply; reference `path:line` instead.
