# Task: mutation-testing-slobac-rework

* Task ID: mutation-testing-slobac-rework
* Complexity: Level 2
* Type: test-suite enhancement (SLOBAC remediations)

Remediate all 70 findings in `.slobac/2026-07-19T16-23-23/audit.md` across branch-changed specs on `feat/mutation-testing`, following each prescribed remediation. Test-only; keep RSpec green and Mutant at 100% kill.

**Audit source of truth:** treat finding numbers `#1`–`#70` in that report as the checklist. Clustered steps below map 1:1 to those findings.

## Test Plan (TDD)

This work *is* the test suite. Each TDD cycle = apply one remediation cluster → run the affected examples → confirm still green → spot-check that strengthened oracles would fail under the smell's stated failure mode (no-op, empty file, wrong width, etc.). Full suite + Mutant gate at the end.

### Behaviors to Verify

- **Rename alignment:** examples whose titles previously claimed `fetch` / routing / cumulative merge / etc. → titles match only what assertions observe.
- **Fossil-free suite:** no `# P*`, `# D*`, `# E*` checklist comments remain next to examples.
- **Structural HTML contract:** figure / dual-theme outputs assert via parsed DOM (`figure.mermaid-diagram`, nested `a`/`img` attrs, media-query presence) → attribute order / whitespace may change without failing.
- **Copy fidelity:** `Hooks.copy_svgs_to_site` / `copy_generated_svgs` destinations → byte-equal to seeded cache SVGs (not mere `File.exist?`).
- **Non-vacuous state machines:** `process_line` / `handle_line_at_top_level` examples → observe position / `fence_stack` deltas so no-op bodies fail.
- **Mock hygiene:** emoji / generate paths assert argument/outcome oracles; drop redundant `have_received` / `not_to receive(:compensate)` / `Generator.new` pins where product state is already asserted.
- **Mystery guests named:** edge-label expected width and mmdc probe diagram literals → named derivation or ≤3-line comment.
- **Processor file shape:** `processor_spec.rb` split by capability; total example count stable; shared doubles in `spec/support/` as needed.
- **Regression gate:** full `bundle exec rspec` + `bundle exec mutant run` still 100%.

### Edge Cases

- Dual-theme figure: two anchors + `prefers-color-scheme: dark` rule still covered after DOM parse.
- Partial generation failure (`processor_spec` continues later blocks): assert which source remains vs which is replaced, not only `count == 1`.
- Nil config/svgs on copy path: either rename to “does not raise” or spy forward of nils — pick one and make title match oracle.
- HTML fragment parse: REXML may need a wrapper root for fragments; helper must not invent false structure.

### Test Infrastructure

- Framework: RSpec (`spec/spec_helper.rb`, `.rspec`)
- Test location: `spec/jekyll_mermaid_prebuild/`
- Conventions: one file per module historically; describe-by-method; Mutant describe-prefix discipline (observations under the subject method describe)
- New test files: yes — split of `processor_spec.rb` into capability-shaped files (see Step 7); optional `spec/support/html_fragment.rb` helper for DOM asserts
- HTML parse: **REXML** (already loaded via Jekyll/bundle) as Nokogiri-equivalent — do **not** add nokogiri unless REXML proves inadequate during Build

## Implementation Plan

1. **Add HTML fragment helper (support)**
   - Files: `spec/support/html_fragment.rb` (new), require from `spec/spec_helper.rb` if not auto-loaded
   - Changes: `parse_html_fragment(str)` → REXML document/root; helpers to select `figure[@class='mermaid-diagram']`, nested `a`/`img` by class/href/src/alt; optional CSS-text presence check for `@media (prefers-color-scheme: dark)`
   - TDD: write a tiny example or exercise via the first presentation-coupled test

2. **Strip deliverable fossils (mechanical)**
   - Files: `emoji_compensator_spec.rb`, `processor_spec.rb` (and any other `# P/D/E` hits)
   - Changes: delete checklist-prefix comments; keep behavior notes only if they add product meaning without case IDs
   - Findings: `#14,#17,#19,#21,#34–#42,#46+` (all deliverable-fossils)

3. **Rename naming-lies (titles only where body is correct)**
   - Files: `configuration_spec.rb`, `processor_spec.rb`, `hooks_spec.rb`, others per audit
   - Changes: rename per prescriptions (e.g. drop `via fetch`; `collapses repeated internal slashes`; outcome-based fence titles). Where audit offers rename *or* strengthen, prefer strengthen only when kill-set clearly needs it (see Step 5); else rename.
   - Findings: `#1–#4,#10,#15,#26,#27,#30,#31,#65,#67,#69` (+ any remaining naming-lies)

4. **Name mystery guests**
   - Files: `generator_spec.rb` (`expected_width = 40 + 5`), `mmdc_wrapper_spec.rb` (named `PROBE_DIAGRAM` / comment for `test_render` body)
   - Findings: `#5,#59`

5. **Strengthen vacuous / pseudo-tested / loose oracles**
   - Files: `processor_spec.rb`, `emoji_compensator_spec.rb`, `hooks_spec.rb`, `mmdc_wrapper_spec.rb`
   - Changes per audit:
     - `#11`: assert concrete svg key/value from stubbed generate (and/or two-call merge if keeping “cumulative”)
     - `#23`: assert which block converted vs retained + svg keys
     - `#28/#29`: assert `position` / unchanged blocks after plain text
     - `#32/#33`: assert `fence_stack` push for non-mermaid open
     - `#41,#45,#57` (emoji vacuous): replace weak oracles per finding text
     - `#43` (implementation-coupled): assert product outcome, not private shape
     - `#61,#62,#66`: destination SVG bytes == seeded cache
     - `#64/#65`: tighten puppeteer log to guidance topics *or* rename; prefer strengthen to match title
     - `#67/#68`: spy nil forward *or* rename to no-raise claim
     - `#69/#70`: positive evidence `process_site` ran on pre_render, keep empty-docs secondary claim
     - `#60`: `raise_error(ArgumentError)` + message mentions `:forest` (not full allowed-list sentence)
   - TDD: after each strengthen, briefly confirm a deliberate weaken would fail (local mental/manual check)

6. **Mock hygiene**
   - Files: `processor_spec.rb`, `hooks_spec.rb`
   - Changes: drop redundant `have_received(:generate)` after stub-block oracles (`#16,#18,#20`); drop `not_to receive(:compensate)` in favor of generate-arg oracle (`#24,#25`); drop `Generator`/`Processor` `.new` receives in hooks init (`#63`) keeping `site.data` asserts

7. **Structural HTML for presentation-coupled figure contracts**
   - Files: `generator_spec.rb`, `processor_spec.rb` (pre-split), using helper from Step 1
   - Findings: `#6,#7,#9,#12,#13,#22` (+ `#7` dual-theme CSS via style/text node, not raw lookahead regexes)
   - Keep fence-absence claims as separate string/behavioral asserts where audit says so

8. **Split monolithic `processor_spec.rb`**
   - Files (proposed; adjust names only if Build finds a clearer cluster):
     - `processor_process_content_spec.rb` — `#process_content` (+ nested contexts)
     - `processor_convert_and_digest_spec.rb` — `#convert_block`, `#digest_string_for_cache`
     - `processor_fence_parsing_spec.rb` — `#find_top_level_mermaid_blocks`, `#process_line`, `#handle_fence_line`, `#handle_line_at_top_level`, `#handle_line_in_mermaid`, `#handle_line_in_nested_fence`
   - Shared: move `let`/helpers/doubles used across files into `spec/support/processor_spec_helpers.rb` (or keep thin duplicated lets if cheaper)
   - Constraint: total `it` count unchanged; Mutant subjects still under correct method `describe` prefixes
   - Finding: `#8`

9. **Verification gate**
   - Run: `bundle exec rspec`, `bundle exec rubocop`, `bundle exec mutant run`
   - Fix any fallout (Mutant describe-prefix starvation after split is the main risk)
   - Optionally re-scan fossils with `rg '# [PDE][0-9]' spec/` for leftover checklist tags

## Technology Validation

- **No new gem dependency planned.** Audit allows “Nokogiri (or equivalent)”; Jekyll 4.4 in this bundle does **not** ship nokogiri; REXML is available (`bundle exec ruby -e "require 'rexml/document'"` → 3.4.4).
- Validation: Build Step 1 proves REXML can parse the plugin’s figure HTML fragments (with a wrapper root if needed). Fallback: add `nokogiri` as a development dependency only if REXML cannot represent the dual-theme fragment reliably.

## Dependencies

- Existing: RSpec, RuboCop, Mutant, Jekyll, REXML
- Audit artifact (untracked local): `.slobac/2026-07-19T16-23-23/audit.md` — reference only; do not require committing `.slobac/` for the remediations to ship
- Prior art: `memory-bank/archive/enhancements/20260514-slobac-audit-fix.md` (regex approach now superseded for figure contracts by structural parse)

## Challenges & Mitigations

- **Mutant regression after oracle/mock changes or file split:** Re-run `mutant run` before declaring Build done; if describe-prefix starvation appears, keep method-level `describe` names identical to the public API methods and ensure examples remain nested under them.
- **REXML vs HTML fragments / CSS in `<style>`:** Use a fragment wrapper; for CSS, assert on the style element’s text content containing `prefers-color-scheme: dark` rather than a full CSS parse.
- **Rename vs strengthen ambiguity:** Prefer the audit’s primary prescription; when both are offered, strengthen if the title’s product claim is valuable for kill-set, else rename to match the cheaper correct oracle.
- **Scope creep on emoji fossils (25 findings):** Mechanical strip first; only open bodies when a fossil shares a line with vacuous/implementation-coupled findings.

## Pre-Mortem

- **Plan failed because we “fixed smells” but broke 100% Mutant kill:** Already covered by Challenge 1 + Step 9 gate — non-negotiable acceptance criterion.
- **Plan failed by adding nokogiri “for the audit wording” and fighting Bundler/CI noise:** Prefer REXML; only add nokogiri on demonstrated REXML failure (Technology Validation fallback).
- **Plan failed by splitting `processor_spec` into the wrong seams and spending the budget on file chess:** Split only after oracle/rename/mock work is green in the monolith; move blocks with `git mv` + require path updates; do not rewrite examples during the move.
- **Plan failed by treating regex lookaheads as “structural enough” again:** Explicitly forbidden for `#6/#7/#9/#12/#13/#22` — DOM helper is required.

## Status

- [x] Initialization complete
- [x] Test planning complete (TDD)
- [x] Implementation plan complete
- [x] Technology validation complete
- [x] Pre-Mortem complete
- [ ] Preflight
- [ ] Build
- [ ] QA
