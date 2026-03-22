# Troubleshooting: Refresh — Reassess block edge label clipping fix

## Problem Statement

Block diagram edge labels clip at the right edge in mmdc-generated SVGs viewed as `<img>`. The fix we implemented (widening foreignObject) works, but we need to verify it's the best approach given that our earlier hypothesis (stroke overhang) was disproven.

## Evidence: Label Data from e412bbe8.svg

### Node Labels (inside `<g class="node">`)

| Text | FO width | FO height | Container | Container width | Slack (each side) | Style on div | Clips? |
|------|----------|-----------|-----------|-----------------|-------------------|--------------|--------|
| Human | 57.703 | 19 | circle r=32.85 | ~65.70 | ~4px | display:inline-block; white-space:nowrap | No |
| Requirements | 111.234 | 19 | rect | 119.234 | 4px | display:inline-block; white-space:nowrap | No |
| Specification | 102.734 | 19 | rect | 119.234 | ~8px | display:inline-block; white-space:nowrap | No |
| Code | 40.969 | 19 | rect | 119.234 | ~39px | display:inline-block; white-space:nowrap | No |
| Computers | 87.875 | 19 | rect | 119.234 | ~16px | display:inline-block; white-space:nowrap | No |

### Edge Labels (inside `<g class="edgeLabel">`)

| Text | FO width | FO height | Container | Slack | Style on div | Clips? |
|------|----------|-----------|-----------|-------|--------------|--------|
| last touchpoint | 119.891 | 19 | none (FO IS boundary) | 0 | stroke:rgb(51,51,51); stroke-width:1.5px; display:inline-block; white-space:nowrap | YES |
| refined | 56.297 | 19 | none (FO IS boundary) | 0 | same | YES |
| encoded\n(Engineer) | 83.75 | 38 | none (FO IS boundary) | 0 | same | ? |
| Executed By | 99.672 | 19 | none (FO IS boundary) | 0 | same | ? |

## Key Structural Finding

Node labels have a containing shape (rect, circle) that provides **4+ px of padding** around the foreignObject. Even if the viewing browser renders text slightly wider than headless Chromium measured, the padding absorbs the difference.

Edge labels have **zero padding**. The foreignObject IS the clip boundary, sized to exactly `getBoundingClientRect()` from headless Chromium. Any rendering difference — even sub-pixel — causes clipping.

## Root Cause (Revised)

The clipping is caused by a **cross-context text measurement mismatch**: `getBoundingClientRect()` in headless Chromium (Linux/WSL) measures text widths that are slightly too narrow for the same text rendered by the viewing browser (Windows). Edge labels have zero structural padding to absorb this difference, while node labels have shape padding.

The `stroke` style on edge labels was a red herring — removing it from a saved SVG doesn't fix clipping because the foreignObject width is already baked in from headless Chromium's measurement.

## Assessment of Current Fix

- [x] Correctly targets edgeLabel foreignObject only (not node labels)
- [x] Scoped to block diagrams only (aria-roledescription="block")
- [x] Configurable padding (user tunes for their environment)
- [x] Cache-key integration (changing padding invalidates block caches)
- [x] Zero new dependencies (regex on deterministic mmdc output)
- [x] Empirically verified: clipping gone in devblog SVGs

## Alternatives Considered

1. overflow:visible on foreignObject — unreliable in `<img>` SVG context
2. Percentage-based widening — unnecessary; error is likely per-glyph (roughly constant)
3. Source preprocessing — can't target edge labels specifically in Mermaid source
4. Font installation in headless Chromium — environment-dependent, fragile
5. Upstream Mermaid fix — desirable long-term, but out of our control timeline

## Conclusion

**The current fix is the best approach for this gem.** The root cause is structural: edge labels have zero padding between foreignObject boundary and text, making them vulnerable to any cross-context text measurement difference. Our additive padding compensates for this. The fix is well-scoped (only block edge labels), configurable (user tunes the padding), cache-aware, and empirically validated.

Documentation (README, CHANGELOG, SvgPostProcessor module comment, reflection) has been corrected to describe the true root cause (cross-browser text measurement mismatch) rather than the disproven stroke hypothesis.

Verification: 96 examples, 0 failures; RuboCop clean.

## 2026-03-22 — Second Discovery: CI Chrome Mismatch + Text Centering

### CI Chrome was the real clipping cause

Deployed SVGs (built by GitHub Actions) used system Chrome (`google-chrome-stable`) via `PUPPETEER_SKIP_CHROMIUM_DOWNLOAD` + `PUPPETEER_EXECUTABLE_PATH` overrides in `deploy.yaml`. This Chrome measured ALL text 11-16% narrower than the viewing browser, clipping both node AND edge labels. Fix: remove the overrides so CI uses Puppeteer's bundled Chromium (matching local behavior).

### Text centering issue

After switching to Puppeteer's bundled Chromium, the opposite problem appeared: Chromium on Linux measures text *wider* than Windows browsers render it. The foreignObject is wider than needed, and text left-aligns within it because Mermaid's CSS `text-align: center` targets SVG `<g>` elements where it has no effect on HTML inside foreignObject.

The centering fix required multiple iterations because the `<div>` inside foreignObject uses `display: table-cell` (mmdc 11.12.0+):

1. **`text-align:center` alone** — no visual effect; `table-cell` inside an anonymous table wrapper shrink-wraps, so centering the inline content within a cell that's already minimal-width does nothing.
2. **`width:100%;text-align:center`** — no visual effect; `width:100%` on a `display:table-cell` doesn't expand it past the anonymous table's shrink-wrap.
3. **`display:block !important;text-align:center`** — works. Overriding `display:table-cell` to `display:block` makes the div a block element that fills the foreignObject width; `text-align:center` then centers its inline content. The `!important` is needed to override Mermaid's inline `display:table-cell`.

Fix: `SvgPostProcessor.ensure_text_centering` — injects `foreignObject > div{display:block !important;text-align:center;}` into every SVG's `<style>` block. Unconditional, idempotent, no flag needed.

Verification: 103 examples, 0 failures; RuboCop clean.
