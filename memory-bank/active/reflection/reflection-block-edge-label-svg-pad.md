---
task_id: block-edge-label-svg-pad
date: 2026-03-22
complexity_level: 2
---

# Reflection: Block diagram edge label clipping (SVG post-processing)

## Summary

Added two SVG post-processing fixes to jekyll-mermaid-prebuild: (1) optional `block_edge_label_padding` to widen block edge-label `<foreignObject>` widths, and (2) unconditional text centering via CSS injection (`display:block !important;text-align:center`) on foreignObject divs. Both address cross-browser text measurement mismatches between headless Chromium and the viewing browser. A CI environment fix (removing `PUPPETEER_SKIP_CHROMIUM_DOWNLOAD` overrides in devblog's `deploy.yaml`) resolved the primary clipping cause by aligning CI with Puppeteer's bundled Chromium.

## Requirements vs Outcome

All four original acceptance criteria were met. Two requirements were added during the /refresh investigation that were not in the original plan:

1. **CI environment fix** — discovered that GitHub Actions was using system Chrome (measuring text 11-16% narrower than the viewing browser), causing both node *and* edge label clipping. Removed the `PUPPETEER_SKIP_CHROMIUM_DOWNLOAD` and `PUPPETEER_EXECUTABLE_PATH` overrides from `deploy.yaml`.
2. **Text centering fix** — after aligning CI and local to Puppeteer's bundled Chromium, a new problem surfaced: labels shifted left in nodes because the foreignObject was wider than the text and Mermaid's `text-align:center` targets SVG `<g>` elements (not HTML divs). Added `SvgPostProcessor.ensure_text_centering` — unconditional, idempotent, no config flag needed.

## Plan Accuracy

The original plan was accurate for the edge label padding feature. The /refresh phase revealed that the initial root cause hypothesis (CSS stroke overhang) was wrong — the true cause was font-metrics mismatch — but this didn't change the implementation, only the documentation.

The surprises came from *outside* the plan: (a) the CI vs local environment divergence was the dominant cause of deployed clipping, not the edge label zero-padding, and (b) the centering issue only appeared after updating mmdc locally, exposing a `display:table-cell` layout that Mermaid emits for foreignObject content. This required three CSS iterations to solve (text-align alone, then width:100%, then display:block !important).

## Build & QA Observations

The original build (padding feature) was clean. The /refresh follow-on work was messier — the centering CSS required three attempts because `display:table-cell` behaves non-intuitively with `text-align` and `width:100%`. The winning approach (`display:block !important;text-align:center`) only became clear after understanding the anonymous table wrapper that `table-cell` creates. Empirical verification in the user's actual blog was essential — unit tests couldn't catch this because they don't exercise CSS rendering.

QA caught one trivial issue (missing `private` keyword) on the first pass. The centering fix was developed after QA, driven by the user's /refresh investigation.

## Insights

### Technical

- **`display:table-cell` inside foreignObject blocks both `text-align` centering and `width:100%` expansion.** The anonymous table wrapper shrink-wraps to content width, making the cell effectively the same width as the text regardless of the foreignObject's width. The only way to center text in a foreignObject whose div uses `table-cell` is to override the display model entirely (`display:block !important`). This is a subtle CSS interaction that will recur in any SVG-with-HTML post-processing work.

- **CI Chrome vs Puppeteer's bundled Chromium produce measurably different text widths.** GitHub Actions' `google-chrome-stable` measured text 11-16% narrower than Puppeteer's bundled Chromium on the same Linux runner. This isn't a font issue — it's a rendering engine version/config difference. Always let Puppeteer use its own Chromium for consistent cross-environment results.

### Process

- **User-driven empirical disproof is invaluable.** The /refresh cycle was triggered by the user manually editing a clipped SVG and observing that removing stroke didn't fix clipping — something no automated test could have discovered. This disproved the initial hypothesis and led to the correct diagnosis. Build automated verification where possible, but respect that some bugs only reveal themselves through manual experimentation in real environments.

- **CSS iteration in a non-inspectable context (SVG `<img>`) is slow.** Each CSS attempt required: edit code, rebuild blog, refresh browser, check visually. Unlike a normal web page, SVGs embedded via `<img>` can't be inspected with browser DevTools. Future CSS fixes for this plugin should be prototyped by editing a raw SVG in a browser tab first (where DevTools work), then codified.

### Million-Dollar Question

If cross-browser rendering differences had been a foundational assumption, the plugin would have a general-purpose "SVG normalization" post-processing pass that runs on every generated SVG: centering text, normalizing display models, and optionally padding tight containers. That's roughly what we ended up with — `ensure_text_centering` (unconditional) + `maybe_pad_block_edge_labels` (opt-in). The two-method approach is cleaner than a monolithic normalizer because the fixes are independent and have different opt-in semantics. The current design is already close to optimal.
