# Task: mutation-testing-slobac-rework

* Task ID: mutation-testing-slobac-rework
* Complexity: Level 2
* Type: test-suite enhancement (SLOBAC remediations)

Remediate all 70 findings in `.slobac/2026-07-19T16-23-23/audit.md` across branch-changed specs on `feat/mutation-testing`, following each prescribed remediation. Test-only; keep RSpec green and Mutant at 100% kill.

**Audit source of truth:** treat finding numbers `#1`–`#70` in that report as the checklist. Clustered steps below map 1:1 to those findings.

## Test Plan (TDD)

**Test-only work:** there is no `lib/` production code in scope. Each implementable unit below is an example (or support helper used only by examples). Per-unit order is mandatory:

1. Apply the audit’s prescribed change to the example/helper (the deliverable *is* the test).
2. Run the affected example(s) (`bundle exec rspec path:line` preferred while iterating).
3. For strengthens: briefly confirm the smell’s failure mode would fail (empty file, no-op body, type-only hash, etc.) — mental or one-line local weaken then restore.
4. Mark the corresponding finding checkbox(es) done.

Full suite + Mutant gate only at Step 9.

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

**Convention note:** techContext’s “one file per module” is intentionally waived for Processor per audit `#8`; new files keep the `processor_*_spec.rb` prefix and `RSpec.describe JekyllMermaidPrebuild::Processor`. Support helpers follow `ConfigurationHelpers` (`module` + `RSpec.configure { include }`); `spec/support/**/*.rb` is already auto-required by `spec_helper`.

1. **Add HTML fragment helper (support)**
   - Files: `spec/support/html_fragment_helpers.rb` (new; auto-loaded)
   - Changes: `HtmlFragmentHelpers` with `parse_html_fragment(str)` (REXML + wrapper root), selectors for `figure[@class='mermaid-diagram']`, nested `a`/`img`, and style-text check for `prefers-color-scheme: dark`
   - Verify: exercise via Step 7’s first presentation-coupled example (do not land unused helper)

2. **Strip deliverable fossils (mechanical)**
   - Files: `emoji_compensator_spec.rb`, `processor_spec.rb`
   - Changes: delete `# P*`, `# D*`, `# E*` checklist comments; keep non-ID behavior notes only if useful
   - Verify: `rg '# [PDE][0-9]' spec/jekyll_mermaid_prebuild/` empty; run touched files
   - Findings: all deliverable-fossils (`#14,#17,#19,#21,#34–#39,#42,#46–#56,#58`)

3. **Rename naming-lies (titles only where body is correct)**
   - Files: `configuration_spec.rb`, `processor_spec.rb`, `hooks_spec.rb`, `emoji_compensator_spec.rb`
   - Changes: rename per prescriptions. Where audit offers rename *or* strengthen, defer strengthen to Step 5 when the product claim is load-bearing; else rename.
   - Verify: targeted examples green after each rename batch
   - Findings: `#1–#4,#10,#15,#26,#27,#30,#31,#40,#44,#65,#67,#69` (and any remaining naming-lies not folded into Step 5)

4. **Name mystery guests**
   - Files: `generator_spec.rb` (`expected_width = 40 + padding`), `mmdc_wrapper_spec.rb` (named probe constant/comment)
   - Verify: those two examples green
   - Findings: `#5,#59`

5. **Strengthen vacuous / pseudo-tested / loose oracles**
   - Files: `processor_spec.rb`, `emoji_compensator_spec.rb`, `hooks_spec.rb`, `mmdc_wrapper_spec.rb`
   - Per-finding changes (each: stronger oracle → run line → failure-mode spot-check):
     - `#11`: concrete svg key/value from stubbed generate (and/or two-call merge if keeping “cumulative”)
     - `#23`: which block converted vs retained + svg keys
     - `#28/#29`: `position` / unchanged blocks after plain text
     - `#32/#33`: `fence_stack` push for non-mermaid open
     - `#41,#45,#57`: emoji vacuous → concrete product oracles per finding text
     - `#43`: product outcome, not private shape
     - `#61,#62,#66`: destination SVG bytes == seeded cache
     - `#64/#65`: tighten puppeteer log to guidance topics (prefer over rename-only)
     - `#67/#68`: spy nil forward *or* rename to no-raise (title must match)
     - `#69/#70`: positive evidence `process_site` ran; keep empty-docs secondary claim
     - `#60`: `raise_error(ArgumentError)` + message mentions `:forest` (not full allowed-list sentence)

6. **Mock hygiene**
   - Files: `processor_spec.rb`, `hooks_spec.rb`
   - Changes: drop redundant `have_received(:generate)` (`#16,#18,#20`); drop `not_to receive(:compensate)` for generate-arg oracle (`#24,#25`); drop `Generator`/`Processor` `.new` receives (`#63`) keeping `site.data` asserts
   - Verify: affected examples green; kill-set preserved via later Mutant gate

7. **Structural HTML for presentation-coupled figure contracts**
   - Files: `generator_spec.rb`, `processor_spec.rb` (still monolith), using Step 1 helper
   - Findings: `#6,#7,#9,#12,#13,#22`
   - Keep fence-absence claims as separate behavioral asserts where audit says so
   - Verify: each converted example green; no attribute-order regex left for these

8. **Split monolithic `processor_spec.rb`**
   - **Only after Steps 2–7 are green in the monolith.** Move blocks; do not rewrite during the move.
   - Target files:
     - `processor_process_content_spec.rb` — `#process_content`
     - `processor_convert_and_digest_spec.rb` — `#convert_block`, `#digest_string_for_cache`
     - `processor_fence_parsing_spec.rb` — fence/state-machine method describes
   - Shared: `spec/support/processor_spec_helpers.rb` only if duplication hurts; else thin duplicated `let`s
   - Constraint: `it` count unchanged; method-level `describe "#foo"` prefixes preserved for Mutant
   - Verify: `rg -c '^\s*it ' spec/jekyll_mermaid_prebuild/processor*.rb` matches prior count; full processor specs green
   - Finding: `#8`

9. **Verification gate**
   - Run: `bundle exec rspec`, `bundle exec rubocop`, `bundle exec mutant run`
   - Confirm Findings Checklist all `[x]` (or documented FP deferral)
   - Re-scan: `rg '# [PDE][0-9]' spec/jekyll_mermaid_prebuild/`

## Findings Checklist

Track Build against the audit. Check off when remediated.

- [x] #1 `configuration_spec.rb:19` — naming-lies
- [x] #2 `configuration_spec.rb:25` — naming-lies
- [x] #3 `configuration_spec.rb:107` — naming-lies
- [x] #4 `configuration_spec.rb:707` — naming-lies
- [x] #5 `generator_spec.rb:334` — mystery-guest
- [x] #6 `generator_spec.rb:521` — presentation-coupled
- [x] #7 `generator_spec.rb:540` — presentation-coupled
- [x] #8 `processor_spec.rb` — monolithic-test-file
- [x] #9 `processor_spec.rb:62` — presentation-coupled
- [x] #10 `processor_spec.rb:78` — naming-lies
- [x] #11 `processor_spec.rb:78` — vacuous-assertion
- [x] #12 `processor_spec.rb:113` — presentation-coupled
- [x] #13 `processor_spec.rb:120` — presentation-coupled
- [x] #14 `processor_spec.rb:157` — deliverable-fossils
- [x] #15 `processor_spec.rb:157` — naming-lies
- [x] #16 `processor_spec.rb:157` — over-specified-mock
- [x] #17 `processor_spec.rb:183` — deliverable-fossils
- [x] #18 `processor_spec.rb:183` — over-specified-mock
- [x] #19 `processor_spec.rb:201` — deliverable-fossils
- [x] #20 `processor_spec.rb:201` — over-specified-mock
- [x] #21 `processor_spec.rb:227` — deliverable-fossils
- [x] #22 `processor_spec.rb:440` — presentation-coupled
- [x] #23 `processor_spec.rb:528` — vacuous-assertion
- [x] #24 `processor_spec.rb:730` — over-specified-mock
- [x] #25 `processor_spec.rb:739` — over-specified-mock
- [x] #26 `processor_spec.rb:840` — naming-lies
- [x] #27 `processor_spec.rb:848` — naming-lies
- [x] #28 `processor_spec.rb:884` — pseudo-tested
- [x] #29 `processor_spec.rb:884` — vacuous-assertion
- [x] #30 `processor_spec.rb:966` — naming-lies
- [x] #31 `processor_spec.rb:981` — naming-lies
- [x] #32 `processor_spec.rb:1018` — pseudo-tested
- [x] #33 `processor_spec.rb:1018` — vacuous-assertion
- [x] #34–#39, #42, #46–#56, #58 `emoji_compensator_spec.rb` — deliverable-fossils
- [x] #40 `emoji_compensator_spec.rb:60` — naming-lies
- [x] #41 `emoji_compensator_spec.rb:60` — vacuous-assertion
- [x] #43 `emoji_compensator_spec.rb:151` — implementation-coupled
- [x] #44 `emoji_compensator_spec.rb:156` — naming-lies
- [x] #45 `emoji_compensator_spec.rb:156` — vacuous-assertion
- [x] #57 `emoji_compensator_spec.rb:346` — vacuous-assertion
- [x] #59 `mmdc_wrapper_spec.rb:327` — mystery-guest
- [x] #60 `mmdc_wrapper_spec.rb:391` — presentation-coupled
- [x] #61 `hooks_spec.rb:44` — pseudo-tested
- [x] #62 `hooks_spec.rb:117` — pseudo-tested
- [x] #63 `hooks_spec.rb:202` — over-specified-mock
- [x] #64 `hooks_spec.rb:275` — loose-text-oracle
- [x] #65 `hooks_spec.rb:275` — naming-lies
- [x] #66 `hooks_spec.rb:548` — pseudo-tested
- [x] #67 `hooks_spec.rb:554` — naming-lies
- [x] #68 `hooks_spec.rb:554` — vacuous-assertion
- [x] #69 `hooks_spec.rb:590` — naming-lies
- [x] #70 `hooks_spec.rb:590` — vacuous-assertion

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
- [x] Preflight
- [x] Build
- [x] QA

## QA Results

PASS — no trivial or substantive fixes required. Completeness vs Findings Checklist verified; REXML helper is the only new abstraction (plan-aligned); lib deltas limited to documented identity contract + Bucket A error-message simplification.

## Preflight Amendments

- Clarified per-unit TDD order for test-only deliverables (no `lib/` code).
- Renamed helper file to `html_fragment_helpers.rb` to match `ConfigurationHelpers` pattern; confirmed auto-load via `spec_helper`.
- Added Findings Checklist for Build tracking.
- Documented intentional waiver of one-file-per-module for Processor split (`#8`).
