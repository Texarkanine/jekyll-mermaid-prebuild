---
task_id: issue-11-prefers-color-scheme
date: 2026-03-22
complexity_level: 3
---

# Reflection: Dark mode / prefers-color-scheme (issue #11)

## Summary

Implemented `prefers_color_scheme` config (`light`/`dark`/`auto`) for the jekyll-mermaid-prebuild gem, generating theme-appropriate SVGs and toggling visibility via CSS media queries. Feature shipped successfully after fixing two post-build rendering bugs discovered during visual integration testing.

## Requirements vs Outcome

All five requirements from the project brief were delivered:

1. Config key with safe default — implemented and documented.
2. `light` mode — existing behavior preserved.
3. `dark` mode — single SVG with `mmdc -t dark`.
4. `auto` mode — dual SVGs with CSS `@media (prefers-color-scheme: dark)` toggle.
5. Integration validation — devblog built with 14 diagrams producing 28 SVGs.

Two requirements were *added* during build that were not in the original plan:

- **Transparent background post-processing**: mmdc embeds `background-color: white` regardless of theme. This was not anticipated in the plan and only discovered during visual testing. Added `SvgPostProcessor.ensure_transparent_background` to fix dark SVGs.
- **Removal of inline `style="display:none"`**: The plan specified inline `style="display:none"` on the dark `<a>` element, but this created a CSS specificity conflict where the inline style overrode the media query. Fixed by removing the inline style and controlling visibility entirely through the `<style>` block.

## Plan Accuracy

The plan was largely accurate — the 7-step implementation sequence, file list, component analysis, and cross-module dependency map all held up. Specific observations:

- **Correct**: `Generator#generate` return type change from `String` to `Hash` was safe (only caller is `Processor`). The plan identified this risk and the mitigation was exactly right.
- **Correct**: `Hooks` needed no logic changes. The plan predicted this and it held.
- **Correct**: `instance_double` stubs across all specs needed `prefers_color_scheme:` added. The plan flagged this as a challenge with a mitigation.
- **Missed**: The plan's HTML strategy specified `style="display:none"` on the dark element. This was wrong — inline styles override class-based CSS, which the plan didn't account for. The preflight phase *did* update the plan from `<picture>` to two-`<a>` based on operator feedback, but didn't catch the specificity issue.
- **Missed**: The plan didn't anticipate needing SVG background transparency. This was a property of mmdc's output that only became apparent during visual integration testing with a dark page background.

## Creative Phase Review

No creative phase was executed (no open questions at plan time). In hindsight, the HTML output strategy could have benefited from a brief creative exploration — the `<picture>` → two-`<a>` pivot happened during preflight, and the `style="display:none"` specificity bug happened during build. Both relate to the same design decision.

## Build & QA Observations

**What went well:**
- TDD structure caught the `Generator#generate` return type change cleanly — all callers updated in one pass.
- The `MmdcWrapper` theme keyword was backward-compatible, requiring no changes to existing callsites.
- Devblog integration build succeeded on first attempt (28 SVGs for 14 diagrams).

**What was hard:**
- Two post-build bugs required debugging with screenshots and SVG file inspection. Both were rendering issues invisible to unit tests — they only manifested visually in a real browser with dark mode.
- RuboCop's `Lint/UnusedBlockArgument` interacted poorly with RSpec's block-based stubs for keyword arguments. The initial `_theme:` fix broke the stub entirely; had to switch to `**_opts` splat.

**QA findings:**
- QA was clean except for one trivial documentation inconsistency (module doc count). The two real bugs were caught and fixed during the build phase itself, before QA ran.

## Cross-Phase Analysis

- **Plan → Build**: The plan's `style="display:none"` specification directly caused the first rendering bug. The plan was too prescriptive about a CSS detail without testing it — the build phase paid the cost.
- **Plan → Build**: The plan's omission of SVG background handling caused the second rendering bug. This was a gap in the investigation phase — checking the actual SVG output from `mmdc -t dark` would have revealed `background-color: white`.
- **Preflight → Build**: Preflight caught the `<picture>` → two-`<a>` pivot, which was valuable. It did not catch the specificity issue because preflight reviews the plan's logic, not the CSS rendering behavior.
- **Build → QA**: QA had nothing substantive to catch because the operator's visual testing during build surfaced both bugs. The QA phase confirmed code quality but didn't discover new issues.

## Insights

### Technical

- **mmdc always sets `background-color: white` on root SVG**: This is true regardless of the `-t dark` flag. Any dark-mode SVG embedding strategy needs to handle this. The `ensure_transparent_background` post-processor is the right fix for the gem, but this is worth noting for anyone else working with mmdc output.
- **CSS specificity with inline `style` vs `@media` rules**: Inline `style` attributes have higher specificity than any stylesheet rule, including `@media` queries. When generating HTML that uses media queries for display toggling, initial visibility must be set in the stylesheet, not as an inline style.

### Process

- **Visual integration testing catches what unit tests cannot**: Both bugs in this task were invisible to RSpec — they were rendering issues that only manifested in a real browser. For any feature that affects visual output (HTML structure, CSS, SVG post-processing), a manual browser check after the build phase is essential and should be an explicit step in the plan.
- **Investigation phase should include output inspection**: The plan's investigation checked mmdc's CLI flags but didn't examine the actual SVG output from `mmdc -t dark`. Reading a real dark SVG file during investigation would have revealed the `background-color: white` issue before the plan was finalized.
