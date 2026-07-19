---
task_id: mutation-testing
complexity_level: 3
date: 2026-07-19
status: completed
---

# TASK ARCHIVE: Mutation Testing (PR #44)

## SUMMARY

Wired Mutant + `mutant-rspec` into jekyll-mermaid-prebuild on the jekyll-auto-thumbnails pattern, drove mutation coverage to 100%, then completed two post-reflect reworks on `feat/mutation-testing`: a full SLOBAC smell remediation of branch-changed specs, and two judged PR #44 hygiene fixes (path-inclusive page error logs; `test_render` tempfile cleanup).

Final gates on the branch: RSpec green with SimpleCov 100%, RuboCop clean, Mutant 100% kill. Draft PR #44 is the delivery artifact; CI Mutant job stayed out of scope.

## REQUIREMENTS

### Parent (`mutation-testing`, Level 3)

1. Add Mutant via RSpec integration (`mutant-rspec` / `mutant` `~> 0.16`), mirroring auto-thumbnails.
2. Add `config/mutant.yml`, `spec/support/mutant_setup.rb`, and SimpleCov skip when `defined?(Mutant)`.
3. Document Mutation Testing discipline in `CONTRIBUTING.md` (A/B buckets, no ignore cheats, no SUT stubs).
4. Update `memory-bank/techContext.md` Testing Process for Mutant CLI.
5. Drive `bundle exec mutant run` to 100% kill while keeping RSpec / line coverage green.
6. Deliver on `feat/mutation-testing` as a draft PR (no CI Mutant job).

### Rework 1 (`mutation-testing-slobac-rework`, Level 2)

1. Remediate all 70 SLOBAC findings on branch-changed specs vs `main` (fossils, naming, oracles, mocks, structural HTML, processor split).
2. Prefer test-only fixes; preserve Mutant 100% and RSpec/coverage/RuboCop green.
3. Prefer structural/DOM asserts (REXML) for figure/link contracts over presentation pins.

### Rework 2 (`mutation-testing-pr44-feedback`, Level 2)

1. Include `page.relative_path` in `Hooks.process_site` page-loop error logs; update `hooks_spec` oracles.
2. Restore `MmdcWrapper.test_render` tempfile `ensure`/`unlink` cleanup without changing status classification.
3. Do not restore `Hooks.register` shim or churn dismissed LlamaPReview aesthetic items; keep Mutant/RSpec/RuboCop green.

## IMPLEMENTATION

### Parent — Mutant harness and kill loop

| Area | Change |
|---|---|
| Gem / config | Mutant + `mutant-rspec` in gemspec/Gemfile; `config/mutant.yml`; `spec/support/mutant_setup.rb`; SimpleCov skip under Mutant |
| Docs | CONTRIBUTING Mutation Testing discipline; `techContext.md` Mutant CLI |
| Lib shape | Converted `module_function` modules to `def self.`; remodeled `MmdcWrapper` specs to stub collaborators (no SUT stubs) |
| Bucket A | Removed unused `diagram_type` through Generator; dropped redundant pad guards; folded thin processor helper describes into method-level describes |
| Specs | Large expansion of method-scoped examples so mutant-rspec describe-prefix selection can kill subjects |

### Rework 1 — SLOBAC remediations

| Area | Change |
|---|---|
| Specs | Fossils stripped; naming lies fixed; vacuous/over-specified mocks replaced with product-state oracles; REXML fragment helpers for figure contracts |
| Structure | Split monolithic `processor_spec` into capability-shaped files (`processor_process_content_spec`, `processor_fence_parsing_spec`, `processor_convert_and_digest_spec`) while keeping Mutant describe prefixes |
| Lib (minimal) | Documented `pad_label_content` identity return; simplified invalid-theme `ArgumentError` message (Bucket A vs Mutant) |

### Rework 2 — PR #44 judged fixes

| File | Change |
|---|---|
| `lib/jekyll-mermaid-prebuild/hooks.rb` | Page-loop rescue logs `Error processing #{page.relative_path}: …` (parity with documents) |
| `spec/jekyll_mermaid_prebuild/hooks_spec.rb` | Path-inclusive (and nil-path) message oracles |
| `lib/jekyll-mermaid-prebuild/mmdc_wrapper.rb` | `test_render` wrapped in `begin`/`ensure` with tempfile `unlink` (aligned with branch `render` style) |
| `spec/jekyll_mermaid_prebuild/mmdc_wrapper_spec.rb` | Cleanup coverage on success and classified-failure paths |

**Explicitly dismissed from PR feedback:** `Hooks.register` compat shim; `pad_label_content` / `parse_output_dir` aesthetic reversions; `String#lines`→`each_line` nit.

## TESTING

- **RSpec + SimpleCov:** green at 100% line coverage after parent and each rework (final pr44-feedback build: 409 examples, 0 failures).
- **RuboCop:** clean on touched paths after each build.
- **Mutant:** `bundle exec mutant run` → Coverage 100% after parent (3756 kills) and after reworks (final: 3755 kills, 0 alive).
- **`/niko-qa`:** PASS for parent and both reworks; no substantive semantic gaps vs plan/brief.

## LESSONS LEARNED

- **mutant-rspec describe-prefix starvation:** examples must sit under `#method` / `.method` describes matching the subject; thin helper describes leave subjects unkillable even when “related” specs exist elsewhere.
- Prefer `def self.` over `module_function` so Mutant does not invent unused instance-method subjects.
- Unused kwargs forwarded “for API completeness” are pure Bucket A — delete or observe.
- When stubs and SUT both call `File.write`, assert with `have_received` counts/content rather than `not_to receive(:write)`.
- SLOBAC “drop presentation mocks” and Mutant 100% pull opposite directions; durable fix is stronger product-state oracles (or Bucket A deleting presentation from production).
- `process_content` converts blocks last-to-first — failure-continuation content oracles must match that order.
- AI PR reviewers often flag intentional edge-case semantics on mutation-driven refactors; judge dispositions first before planning rework.
- Page vs document error-log asymmetry was a pre-existing smell that survived the Hooks extract — caught once the methods became reviewable public surface.

## PROCESS IMPROVEMENTS

- Inventory survivors once (or subject-scoped fail-fast) beats purely linear full Mutant runs when multiple structural causes share a subject family.
- For post-Mutant SLOBAC reworks, budget an explicit “re-kill” step after mock/oracle hygiene — do not treat Mutant as a final checkbox only.
- Ideal baseline for future gems: DOM/product oracles first, then Mutant, with interaction mocks only when call protocol *is* the contract.
- Parent end-to-end authorization after preflight PASS worked; Reflect→Archive and rework-instead-of-archive gates correctly stayed operator-driven.

## TECHNICAL IMPROVEMENTS

- Optional `rake mutant` wrapper was deferred (preflight advisory) and remains optional follow-up.
- CI Mutant job remains explicitly out of scope for this delivery; consider later once local 100% is stable on mainline.

## NEXT STEPS

None for this archive. PR #44 remains the review/merge vehicle on `feat/mutation-testing`.
