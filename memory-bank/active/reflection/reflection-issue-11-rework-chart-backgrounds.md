---
task_id: issue-11-rework-chart-backgrounds
date: 2026-03-22
complexity_level: 3
---

# Reflection: Issue #11 rework — chart backgrounds + nested `prefers_color_scheme`

## Summary

Pre-PR rework replaced asymmetric “transparent dark only” behavior with configurable per-variant root SVG backgrounds (`white` / `black` defaults), a hash-only `prefers_color_scheme` config shape, and cache-digest inputs for both background strings. Build and QA completed without substantive rework; one README transparency clarification landed during QA.

## Requirements vs Outcome

Delivered everything in `tasks.md`: nested PCS parsing with hyphen aliases, `chart_background_light` / `chart_background_dark`, `SvgPostProcessor#apply_root_svg_background`, generator wiring for every variant, processor digest extension, RSpec updates with shared doubles helper, README and devblog config migration. No planned requirements were dropped. The README **Transparency** subsection was an additive doc improvement during QA (operator-aligned), not a plan omission.

## Plan Accuracy

The ordered steps (Configuration → SvgPostProcessor → Generator → Processor → docs/integration) matched reality. Challenges materialized as expected: many `instance_double(Configuration, ...)` sites (mitigated by `spec/support/configuration_helpers.rb`, as preflight advised). No surprise dependencies. The plan’s deferred item—mmdc dropping `background-color: white`—did not surface.

## Creative Phase Review

No separate creative phase ran for this rework; open questions were already settled in pre-PR planning and preflight. The earlier Issue #11 implementation (two-`<a>` + `@media`) was left unchanged and did not conflict with the rework.

## Build & QA Observations

Build proceeded linearly with TDD; specs failed predictably until each layer was implemented. The shared configuration double helper paid off immediately (DRY, fewer merge conflicts). QA was clean on code; the only change was documentation (`transparent` / RGBA callout), which improved author guidance without touching behavior.

## Cross-Phase Analysis

Preflight advisories (double volume, generator expectations `transparent` → `black`) directly matched build work—good signal that preflight was calibrated to this codebase. Planning gaps did not force mid-build plan revisions. QA did not uncover hidden design debt beyond noting optional future cleanup (`_diagram_type` unused), already scoped out of the rework.

## Insights

### Technical

- **mmdc coupling:** Correct SVG output still depends on mmdc emitting `background-color: white` on the root `<svg>` for substitution to fire; if the CLI changes, we may need injection instead of replace (already noted in plan as deferred).
- **Digest completeness:** Any user-visible post-process setting that affects cached files must appear in `digest_string_for_cache`; backgrounds join `pcs`, padding, and flags in that pattern.

### Process

- **Preflight → build:** Calling out spec fixture churn in preflight made the build predictable; worth repeating for similar cross-cutting config changes.
- **Nothing notable** on workflow overhead for this task size—Level 3 steps were appropriate for four modules plus cache semantics.
