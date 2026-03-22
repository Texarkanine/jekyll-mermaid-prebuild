---
task_id: ci-foreignobject-clip-fix
date: 2026-03-22
complexity_level: 2
---

# Reflection: CI foreignObject clip fix + postprocessing config restructure

## Summary

Fixed cross-browser SVG label clipping (node + edge) via `overflow:visible` CSS injection and universal edge-label padding, then restructured all postprocessing config under a `postprocessing:` group with individual toggles. All 117 tests pass, user confirmed local smoke test.

## Requirements vs Outcome

All four requirements delivered as specified. No requirements dropped or descoped. The scope *expanded* mid-task: the original plan was a single `overflow:visible` fix (R1 only), but user feedback after the first build surfaced that node labels still clipped even with edge-label padding enabled, and that all postprocessing should be configurable. R2-R4 were added during the session. The amended plan covered the expansion cleanly.

## Plan Accuracy

The original plan (overflow fix only) was accurate and executed in two clean TDD cycles. The amended plan (5 steps across 4 source files + docs) was also accurate — no steps needed reordering or splitting, and the predicted file list was exactly right.

The one thing the original plan couldn't anticipate: the user would discover *during testing* that node labels still clipped and would want the whole config restructured. This is inherent to bug-fix work where the problem space reveals itself incrementally.

## Build & QA Observations

Build was smooth both times. The amended build benefited from the existing test infrastructure — every instance_double already had the right shape, so updating `block_edge_label_padding:` to `edge_label_padding:` was mechanical. QA caught only trivial naming debris in both rounds (docstring count, stale context name). No substantive issues.

## Insights

### Technical

- **Overflow:visible vs padding serve complementary roles for different label types.** Node labels sit inside SVG shapes (rect, diamond, etc.) whose background is the shape itself — overflow:visible lets text spill harmlessly. Edge labels have their own background rectangles inside the foreignObject, so overflow:visible would make text extend beyond the background. Padding widens the container so the background matches. This distinction wasn't obvious until comparing the two label types side by side in real SVGs.

### Process

- **Mid-task scope expansion worked well at L2 because the original build was already QA-clean.** Having a verified, committed baseline before re-planning meant the amended plan could focus purely on the new requirements without worrying about regressions from the first build. If the first build had been messy, the expansion would have been much harder to manage.

### Million-Dollar Question

If toggleable postprocessing had been a founding assumption, the three `ensure_*`/`apply` methods in SvgPostProcessor would still exist in roughly their current form — they're independent, idempotent transforms on an SVG string, which is the right abstraction. The main difference would be that `block_edge_label_padding` would never have been block-specific in the first place; there was no technical reason for the restriction, only an assumption that only block diagrams had the issue. The config would have started as a `postprocessing:` group from day one, avoiding the breaking rename. In practice, the current result is close to what the "ideal from scratch" design would look like — the breaking change was the cost of discovering the right abstraction incrementally.
