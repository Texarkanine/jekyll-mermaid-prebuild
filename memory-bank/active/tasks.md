# Task: log-elapsed-time

* Task ID: log-elapsed-time
* Complexity: Level 2
* Type: simple enhancement

Append elapsed-time suffixes to MermaidPrebuild completion log lines: `Total: N diagram(s) converted` when emitted, and `Copied N SVG(s) to …`. Format as `in Xs` under 60 seconds and `in X m Y s` at 60 seconds or more. Do not time per-document `Converted N diagram(s) in path` lines.

## Test Plan (TDD)

### Behaviors to Verify

- Format under a minute: `format_elapsed(12)` → `"in 12s"`
- Format zero: `format_elapsed(0)` → `"in 0s"`
- Format 59 seconds: `format_elapsed(59)` → `"in 59s"`
- Format exactly one minute: `format_elapsed(60)` → `"in 1 m 0 s"`
- Format minutes plus seconds: `format_elapsed(62)` → `"in 1 m 2 s"`; `format_elapsed(422)` → `"in 7 m 2 s"`
- Round fractional seconds: `format_elapsed(12.4)` → `"in 12s"`; `format_elapsed(12.6)` → `"in 13s"`
- Conversion total: `process_site` logs `Total: N diagram(s) converted in Xs` (or `in X m Y s`) when total_count is positive
- No total line: `process_site` still does not emit a Total line when conversion count is zero
- Copy completion: `copy_svgs_to_site` logs `Copied N SVG(s) to DIR/ in Xs` (or `in X m Y s`)
- Per-document Converted lines remain untimed

### Test Infrastructure

- Framework: RSpec
- Test location: `spec/jekyll_mermaid_prebuild/`
- Conventions: `spec/jekyll_mermaid_prebuild/hooks_spec.rb` mirrors `lib/jekyll-mermaid-prebuild/hooks.rb`; logger is an `instance_double(Jekyll::LogAdapter)`
- New test files: none

## Implementation Plan

1. Add `Hooks.format_elapsed` with tests first
   - Files: `spec/jekyll_mermaid_prebuild/hooks_spec.rb`, `lib/jekyll-mermaid-prebuild/hooks.rb`
   - Tests first: `spec/jekyll_mermaid_prebuild/hooks_spec.rb` — describe `.format_elapsed` cases for 0, 12, 59, 60, 62, 422, 12.4, 12.6
   - Changes: module function on `Hooks` that rounds to integer seconds and returns `in Xs` or `in X m Y s`. No new file, no new dependency.

2. Time `process_site` and append elapsed to the Total line
   - Files: `spec/jekyll_mermaid_prebuild/hooks_spec.rb`, `lib/jekyll-mermaid-prebuild/hooks.rb`
   - Tests first: change the exact `"Total: 2 diagram(s) converted"` assertion to require an elapsed suffix; add a clock-stubbed case for `Total: 2 diagram(s) converted in 12s`; keep per-document Converted matchers without elapsed
   - Changes: monotonic clock around document/page processing; Total log uses `format_elapsed`

3. Time `copy_svgs_to_site` and append elapsed to the Copied line
   - Files: `spec/jekyll_mermaid_prebuild/hooks_spec.rb`, `lib/jekyll-mermaid-prebuild/hooks.rb`
   - Tests first: update exact `"Copied N SVG(s) to assets/svg/"` assertions to include an elapsed suffix (regex or clock stub); add a clock-stubbed case for `Copied 2 SVG(s) to assets/svg/ in 1s`
   - Changes: monotonic clock around the copy loop; Copied log uses `format_elapsed`

## Technology Validation

No new technology - validation not required

## Dependencies

- `Process.clock_gettime(Process::CLOCK_MONOTONIC)` (Ruby stdlib)
- Existing `Jekyll.logger.info` calls in `Hooks`

## Challenges & Mitigations

- Several Copied and Total assertions use exact strings and will fail until updated to include the suffix
- Mutant covers `JekyllMermaidPrebuild*`; `format_elapsed` rounding and the 60-second boundary need explicit examples so mutants cannot weaken the threshold

## Pre-Mortem

- Timing copy but not conversion (the expensive work): plan times `process_site` onto the Total line, not only copy
- Forgetting to update exact-string specs: Step 2 and Step 3 list those assertions as Tests first
- `Float#round` half-even at `x.5`: avoid `.5` examples; test 12.4 / 12.6

## Status

- [x] Initialization complete
- [x] Test planning complete (TDD)
- [x] Implementation plan complete
- [x] Technology validation complete
- [x] Pre-Mortem complete
- [x] Preflight
- [x] Build
- [x] QA

## QA Results

PASS. KISS: `format_elapsed` on Hooks, no extra type. Completeness: Total and Copied carry elapsed; per-document Converted lines do not. No README log-string contract to update.

