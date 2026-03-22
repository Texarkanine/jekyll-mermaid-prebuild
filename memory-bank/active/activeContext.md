# Active Context

## Current Task

Fix (plan and implement) SVG edge-label clipping for Mermaid **block** diagrams produced by jekyll-mermaid-prebuild + mmdc. Extended to include cross-browser text centering fix and CI environment alignment.

## Phase

REFLECT — COMPLETE (second pass, post-refresh). Next: `/niko-archive` (operator-initiated).

## What Was Done

- **Original build:** `block_edge_label_padding` config (numeric, `0`/`false`/omit = off), `SvgPostProcessor.apply` (regex on mmdc block `edgeLabel` → `label` → `foreignObject` width), digest suffix `\0block_edge_pad=` for block + positive padding, `Generator#generate(..., diagram_type:)` post-writes cached SVG after successful mmdc when rules apply.
- **Refresh discoveries & fixes:**
  - Root cause corrected: font-metrics mismatch (not stroke overhang).
  - CI environment fix: removed `PUPPETEER_SKIP_CHROMIUM_DOWNLOAD` and `PUPPETEER_EXECUTABLE_PATH` from devblog `deploy.yaml` to use Puppeteer's bundled Chromium.
  - Text centering fix: `SvgPostProcessor.ensure_text_centering` injects `foreignObject > div{display:block !important;text-align:center;}` into every SVG. Unconditional, idempotent, no config flag.
  - Generator calls `ensure_text_centering` before `maybe_pad_block_edge_labels`.
  - README updated with "Cross-browser text rendering fixes" section covering both fixes + CI tip.
  - CHANGELOG updated with bug fix entry for text centering.
  - Troubleshooting doc updated with CSS iteration details.
  - Reflection rewritten to cover full journey.

## Next Step

1. Run `/niko-archive` to create the archive document and finalize the current project.

## Key Artifacts

- Example SVGs: `devblog/_site/assets/svg/e412bbe8.svg`, `c9949931.svg`
- Screenshots: `memory-bank/active/refined-clipped.png`, `touchpoint-clipped.png`
- Source post: `devblog/blog/fable/_posts/2026-03-21-the-load-bearing-pipeline-was-human.md`
- Troubleshooting log: `memory-bank/troubleshooting/troubleshooting-20260322-refresh.md`
