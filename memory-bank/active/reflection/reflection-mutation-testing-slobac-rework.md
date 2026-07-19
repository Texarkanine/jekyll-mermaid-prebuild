---
task_id: mutation-testing-slobac-rework
date: 2026-07-19
complexity_level: 2
---

# Reflection: mutation-testing-slobac-rework

## Summary

Remediated all 70 SLOBAC findings on the mutation-testing branch’s changed specs (fossils, naming, oracles, mocks, REXML figure contracts, processor split) while restoring Mutant to 100% kill. Small lib tweaks: document `pad_label_content` identity return; simplify invalid-theme ArgumentError text.

## Requirements vs Outcome

Delivered: every audit finding addressed; RSpec/coverage/RuboCop/Mutant gates green; stayed on `feat/mutation-testing`. No false-positive deferrals. Minor production edits were required where SLOBAC oracle changes would otherwise leave Mutant alive (#43 identity contract, #60 Bucket A message simplification).

## Plan Accuracy

Plan sequence held (helper → fossils → renames → mystery guests → oracles → mocks → structural HTML → split → verify). Surprise: Mutant regressions after dropping interaction mocks / identity / allowed-list message oracles — expected in Challenges, but the fail-continuation block order (last-to-first) needed an explicit oracle flip during Build.

## Build & QA Observations

Mechanical fossil/rename work was fast; kill-set restoration after mock hygiene took the most iteration. QA was clean — no substantive gaps vs plan.

## Insights

### Technical
- SLOBAC “drop over-specified mocks / presentation pins” and Mutant 100% pull opposite directions; the durable fix is stronger product-state oracles (or Bucket A deleting presentation from production), not re-adding the smell.
- When strengthening failure-path content oracles on `process_content`, assume last-to-first block conversion until proven otherwise.

### Process
- For post-Mutant SLOBAC reworks, budget an explicit “re-kill” step after mock/oracle hygiene — do not treat Mutant as a final checkbox only.

## Million-Dollar Question

If structural HTML asserts and capability-shaped processor specs had been the suite shape when mutation coverage was first driven to 100%, the audit remediations would have been mostly renames/fossil strips — not a second kill loop. The elegant baseline is: DOM/product oracles first, then Mutant, with interaction mocks only when call protocol *is* the contract.
