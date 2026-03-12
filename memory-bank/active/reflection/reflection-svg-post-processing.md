---
task_id: svg-post-processing
date: 2026-03-12
complexity_level: 3
---

# Reflection: Emoji Width Compensation (née SVG Post-Processing)

## Summary

Built an emoji width compensation feature for the jekyll-mermaid-prebuild plugin that pads emoji-containing node labels with `&nbsp;` before mmdc rendering, fixing text clipping caused by headless Chromium's emoji width undermeasurement. The task succeeded, but only after a complete scope pivot — the original SvgPostProcessor / max_width approach was built, QA'd, reflected on, and then entirely discarded when user testing revealed the root cause was fundamentally different.

## Requirements vs Outcome

The **final** requirements (emoji compensation) were fully delivered: all 6 requirements and 7 acceptance criteria met, verified by automated tests (75/75) and user testing on the live blog. No requirements were dropped or reinterpreted from the revised plan.

However, the **original** requirements (SvgPostProcessor + max_width) were a complete miss. The entire first implementation — 29 new tests, Nokogiri dependency, foreignObject manipulation, max_width config — solved a non-problem. The original symptom (text clipping) was correctly identified, but the root cause analysis was wrong: it wasn't container compression, it was Puppeteer undermeasuring emoji glyphs.

Requirements that emerged during build (not in original plan):
- Multi-line label strategy (pad only visually longest line)
- `&nbsp;` HTML entity vs `\u00a0` Unicode (mmdc strips Unicode nbsp)
- Documented constraints: double-quoted labels, `<br>` for line breaks, flowchart only
- Manual `&nbsp;` fallback documentation

## Plan Accuracy

**Original plan accuracy: low.** The plan was internally consistent and well-structured — the right steps in the right order for the wrong problem. The foreignObject centering failure (table-cell shrink-wrap) was not anticipated because the plan was based on static SVG analysis without testing the runtime CSS layout behavior.

**Revised plan accuracy: high.** The emoji compensation plan (Steps 0–4) executed cleanly with only minor adjustments:
- Step 0 (cleanup) was additive scope not in the original task
- Multi-line label strategy was added during build based on user feedback
- `&nbsp;` vs `\u00a0` was a runtime discovery that required changing the padding mechanism

The file list and scope were correct. No steps needed reordering. The identified challenges (regex brittleness for Mermaid syntax) were real and accepted as a documented trade-off.

## Creative Phase Review

No creative phase was executed. For the original plan, creative was skipped with "all questions resolved with high confidence" — the confidence was justified given the information available, but the underlying hypothesis was wrong. No amount of design exploration would have revealed the foreignObject table-cell interaction without runtime testing.

For the revised scope, creative was appropriately skipped again — the user had already validated the `&nbsp;` approach by hand, so the design question was "how to automate" not "what approach to take."

## Build & QA Observations

**What went well:**
- TDD discipline held throughout: tests first, then implementation, across both the original and revised builds
- Scope removal (Step 0) was clean — deleting SvgPostProcessor + max_width + Nokogiri left no orphans
- EmojiCompensator's `module_function` pattern integrated naturally with the codebase
- Diagram type detection (frontmatter/comment skipping) was straightforward
- User feedback loop was fast and productive: each round narrowed the problem

**What was hard:**
- The original foreignObject approach: hours of work on something that fundamentally couldn't work (table-cell shrink-wrap prevents any foreignObject width manipulation from centering correctly)
- `\u00a0` vs `&nbsp;`: the Unicode non-breaking space was silently stripped by the mmdc pipeline. Only discovered through user testing on the live blog. No unit test could catch this because it's a behavior of the external mmdc binary.
- Multi-line label centering: the initial padding strategy (pad all emoji lines) caused short emoji lines to shift left when a longer non-emoji line determined the container width. Required the "pad only the longest line" refinement.

**QA findings:**
- Original QA (v1): 2 trivial fixes (private method placement, unused constant)
- Revised QA (v2): 1 trivial fix (dead circle regex with triple parens instead of double)
- The dead circle regex survived because the E9 test assertion was too loose — it checked `include(nbsp)` on the result, which passed because the rounded-rect regex accidentally compensated the inner `("...")` portion. A more precise assertion (exact match on the transformed shape string) would have caught it.

## Cross-Phase Analysis

**Planning → Build gap (original):** The plan's root cause analysis was wrong. This wasn't a planning methodology failure — it was a hypothesis error that could only be falsified by runtime testing. The plan correctly identified the symptom and proposed a plausible mechanism, but the mechanism was wrong. Static analysis of SVG structure can't predict CSS layout interactions (`display: table-cell` shrink-wrap).

**Build → User testing feedback loop (revised):** The most productive phase wasn't any formal phase — it was the iterative user testing between builds. Three rounds of feedback (centering failure → emoji root cause → `&nbsp;` fix → multi-line strategy) each delivered more value than the entire original plan-preflight-build-QA cycle.

**QA's dead regex catch:** The dead circle regex was introduced during build (likely a typo: triple parens instead of double) and survived to QA. The test was too loose to catch it. This is a minor but real example of how test assertions that check for the presence of an artifact (rather than the exact transformation) can mask bugs.

## Insights

### Technical

- **Mermaid's `display: table-cell` layout makes foreignObject manipulation futile.** The inner div shrink-wraps to content width regardless of the foreignObject's width. This means you cannot fix text clipping by widening the foreignObject — the only effective point of intervention is the Mermaid source itself (before Puppeteer measures).
- **`\u00a0` is stripped by the mmdc pipeline; `&nbsp;` survives.** Mermaid renders node labels as HTML inside `<foreignObject>`, so HTML entities work. Unicode characters may be normalized away during Mermaid's internal parsing. This distinction is critical and not unit-testable (it's an external binary behavior).
- **For multi-line labels, padding the visually longest line is sufficient.** Shorter lines center naturally within the container sized by the longest line. Padding non-constraining lines causes centering shift. The "emoji counts as 2 for visual length" heuristic is rough but effective.
- **Regex-based Mermaid source preprocessing is acceptable as a documented monkeypatch.** It's inherently fragile (can't handle all Mermaid syntax), but the alternative (parsing the Mermaid AST) is vastly disproportionate to the value. Documenting the constraints (double-quoted labels, `<br>` line breaks, flowchart only) is the right trade-off.

### Process

- **Hypothesis-driven development needs runtime validation early.** The original plan was internally sound but based on a wrong root cause. A 15-minute user test with Chrome DevTools invalidated hours of planning and implementation. For tasks involving CSS layout behavior or external tool interactions, prototype and validate before committing to a plan.
- **Loose test assertions can mask dead code.** The E9 test for circle shape `(("🔧"))` passed because it checked `include(nbsp)` — which was satisfied by the rounded-rect regex accidentally matching the inner portion. A stricter assertion (exact match on the shape output) would have caught the dead triple-paren regex during build, not QA.
- **The complete plan-preflight-build-QA cycle executing on the wrong problem is the most expensive failure mode.** All phases passed cleanly — for code that was entirely discarded. The workflow's value is in ensuring quality of implementation, but it can't validate whether the right thing is being built. That requires user testing / hypothesis validation, which should precede the formal build cycle for symptom-driven tasks.
