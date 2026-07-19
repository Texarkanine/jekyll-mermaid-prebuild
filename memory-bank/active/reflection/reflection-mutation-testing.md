---
task_id: mutation-testing
date: 2026-07-19
complexity_level: 3
---

# Reflection: mutation-testing

## Summary

Mutant + `mutant-rspec` is wired into jekyll-mermaid-prebuild on the auto-thumbnails pattern, mutation coverage is at 100%, and delivery stops after Reflect with a draft PR pending operator review (archive intentionally skipped).

## Requirements vs Outcome

All brief requirements met except the draft PR URL, which is opened immediately after this Reflect commit as the authorized delivery step. CI Mutant job correctly stayed out of scope. Line coverage remains 100% under normal RSpec.

## Plan Accuracy

Plan sequence (scaffold → docs → `def self.` → MmdcWrapper remodel → kill loop → PR) was right. Surprises were operational, not architectural: thin `processor_helpers_spec` starved mutant-rspec describe selection; RuboCop `IO.write`→`File.write` broke File.write spies shared with mmdc stubs; unused `diagram_type` forwarding produced a cluster of Generator survivors (Bucket A).

## Creative Phase Review

Skipped (approach fixed by reference archive). Correct call — no design ambiguity remained after plan PoC.

## Build & QA Observations

Kill loop dominated calendar time; parallel subject workers helped once describe-prefix hygiene was understood. QA was clean (no substantive findings). Final gates: RSpec 407/0, SimpleCov 100%, RuboCop clean, Mutant 100% (3756 kills).

## Cross-Phase Analysis

Preflight advisory to defer `rake mutant` held. Plan’s early remodel of SUT stubs prevented unkillable subjects. Describe-prefix starvation was the main planning-gap → build-pain chain; documenting it here for the next gem adoption.

## Insights

### Technical
- mutant-rspec selects examples by describe-prefix match to the subject; thin helper describes with no observations under `#method` / `.method` leave subjects unkillable even when “related” specs exist elsewhere.
- Prefer `def self.` over `module_function` so Mutant does not invent unused instance-method subjects.
- Unused kwargs forwarded “for API completeness” are pure Bucket A under Mutant — delete or observe; do not leave `_unused` parameters in the hot path.
- When stubs and SUT both call `File.write`, assert with `have_received` counts/content rather than `not_to receive(:write)`.

### Process
- Inventory-all-survivors once (or subject-scoped fail-fast) beats purely linear full runs when multiple structural causes share a subject family.
- Parent end-to-end authorization after preflight PASS worked; Reflect→Archive gate correctly left for the operator.
