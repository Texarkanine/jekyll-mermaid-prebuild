---
task_id: log-elapsed-time
complexity_level: 2
date: 2026-08-13
status: completed
---

# TASK ARCHIVE: log-elapsed-time

## SUMMARY

MermaidPrebuild completion logs now include elapsed time. `Total: N diagram(s) converted` (when emitted) and `Copied N SVG(s) to …` append `in Xs` under a minute and `in X m Y s` at a minute or more. Per-document Converted lines stay untimed. Operator verified on a local devblog build.

## REQUIREMENTS

- Elapsed suffix on the Total conversion line from `Hooks.process_site` when that line is emitted
- Elapsed suffix on the Copied SVG line from `Hooks.copy_svgs_to_site`
- Sub-minute: `in Xs`; 60s+: `in X m Y s`
- Do not time per-document Converted lines
- No new runtime dependencies; existing hook behavior unchanged aside from the log suffixes

## IMPLEMENTATION

`Hooks.format_elapsed` rounds to integer seconds and formats the suffix. Monotonic clocks wrap document/page processing and the SVG copy loop. Elapsed is stored in a local before logging to satisfy Layout/LineLength. The Total log uses a trailing guard clause.

Key files: `lib/jekyll-mermaid-prebuild/hooks.rb`, `spec/jekyll_mermaid_prebuild/hooks_spec.rb`.

## TESTING

- TDD: empty `format_elapsed` went red, then exact-string Copied/Total updates plus clock stubs
- Full suite: 418 examples, 0 failures, 100% line coverage
- RuboCop clean on the changed files
- QA PASS
- Operator: local devblog build with path gems showed the timing lines

## LESSONS LEARNED

Exact log-string specs are the entire cost of changing a `Jekyll.logger.info` message in this gem. `Hooks.format_elapsed` plus two clock spans is the right shape; a shared duration gem across Jekyll plugins would be a worse foundation for a log suffix.

## PROCESS IMPROVEMENTS

None. Level 2 plan → preflight → build → QA → reflect held.

## TECHNICAL IMPROVEMENTS

None beyond the shipped change.

## NEXT STEPS

None. Draft PR #49; operator merges after this archive lands.
