# Active Context

## Current Task

Fix (plan and implement) SVG edge-label clipping for Mermaid **block** diagrams produced by jekyll-mermaid-prebuild + mmdc.

## Phase

PLAN — COMPLETE (post-processing approach). Next: Level 2 Preflight (`/niko-preflight`).

## What Was Done

- **Complexity:** Level 2 — contained to gem SVG pipeline, multiple implementation options, new tests/config likely.
- **Diagnosis:** Clipping is not from jekyll-mermaid-prebuild viewBox or CSS in the blog; it comes from Mermaid’s block renderer emitting `<foreignObject>` widths that are slightly too narrow for the **painted** edge label. Block edge labels use HTML/CSS **`stroke` + `stroke-width: 1.5px`** on the label text (faux outline); layout uses text metrics, while stroke extends outside the glyph box, so `foreignObject` clips the last glyph(s). Flowchart-v2 samples on the same site use different edge-label markup (`labelBkg`, `table-cell`) without that stroked-span pattern, so the issue shows up “there” (block edges) more than on flowcharts.
- **Existing gem:** `emoji_width_compensation` only applies to **flowchart** and only **emoji-containing node** labels — it does not run for `block` diagrams or edge strings.
- **Plan (operator choice):** Implement **SVG post-processing** after mmdc: optional `block_edge_label_padding` config; widen `foreignObject` width only under `g.edgeLabel` when root SVG has `aria-roledescription="block"`. Explicit **nokogiri** runtime dependency; cache digest suffix for `block` + positive padding. Details: `memory-bank/active/tasks.md`.

## Next Step

1. Run `/niko-preflight` against the plan in `tasks.md`, then Build (TDD) per Level 2 workflow.

## Key Artifacts

- Example SVGs: `devblog/_site/assets/svg/e412bbe8.svg`, `c9949931.svg`
- Screenshots: `memory-bank/active/refined-clipped.png`, `touchpoint-clipped.png`
- Source post: `devblog/blog/fable/_posts/2026-03-21-the-load-bearing-pipeline-was-human.md` (diagrams start with `block`)
