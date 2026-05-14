---
task_id: slobac-audit-fix-rework
date: 2026-05-14
complexity_level: 2
---

# Reflection: Fix SLOBAC Audit Rework (PR #30 Feedback)

## Summary

Fixed two test regressions introduced by the original SLOBAC audit fix: a removed emptiness guard that allowed vacuous passes, and attribute-ordering constraints encoded in regexes. Both fixes are surgical (3 lines total), all 158 tests pass.

## Requirements vs Outcome

Delivered exactly what was asked. Both PR review findings addressed with no scope creep.

## Plan Accuracy

Plan was accurate. The lookahead regex approach was identified during planning (not discovered during build), so implementation was straight-line.

## Build & QA Observations

Trivially clean — 3 lines changed, passed lint and tests on first attempt. QA found nothing.

## Insights

### Technical

- **`[].all?` vacuous truth is a guard-removal trap**: When upgrading a blunt assertion (`not_to be_empty`) to structural shape assertions, Ruby's `Enumerable#all?` on an empty collection always returns `true`. The guard is not subsumed by the shape checks — it must be kept alongside them. This is worth checking any time a structural assertion replaces an existence check.
- **Lookahead regexes for order-independent element attribute checks**: `/<a(?=[^>]*attr1)(?=[^>]*attr2)[^>]*>/` is the correct pattern when you need both attributes present on the same element without constraining their order. The "split into separate checks" alternative (suggested by both bots) loses the co-location guarantee.

### Process

- Nothing notable.

### Million-Dollar Question

The original SLOBAC fix should have kept the emptiness guard and used lookahead patterns from the start. Both improvements were knowable at plan time with slightly more attention to Ruby semantics and regex ordering semantics. In future test-improvement tasks, it's worth explicitly asking: "does this structural assertion subsume the original check, or does vacuous truth create a gap?"
