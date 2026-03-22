# Active Context

## Current Task

Fix (plan and implement) SVG edge-label clipping for Mermaid **block** diagrams produced by jekyll-mermaid-prebuild + mmdc.

## Phase

BUILD — COMPLETE. Next: `/niko-qa` (Level 2 QA phase).

## What Was Done

- **Build delivered:** `block_edge_label_padding` config (numeric, `0`/`false`/omit = off), `SvgPostProcessor.apply` (regex on mmdc block `edgeLabel` → `label` → `foreignObject` width), digest suffix `\0block_edge_pad=` for block + positive padding, `Generator#generate(..., diagram_type:)` post-writes cached SVG after successful mmdc when rules apply.
- **Paths touched:** `lib/jekyll-mermaid-prebuild/configuration.rb`, `svg_post_processor.rb` (new), `processor.rb`, `generator.rb`, `lib/jekyll-mermaid-prebuild.rb`; specs `configuration_spec.rb`, `svg_post_processor_spec.rb` (new), `processor_spec.rb`, `generator_spec.rb`; `README.md`, `CHANGELOG.md`; memory bank `tasks.md`, `activeContext.md`, `progress.md`.
- **Deviations from early plan text:** No Nokogiri (preflight amendment); implementation matches `tasks.md` post-preflight (regex post-processor, file `svg_post_processor.rb`).

## Next Step

1. Run `/niko-qa` for semantic review.

## Key Artifacts

- Example SVGs: `devblog/_site/assets/svg/e412bbe8.svg`, `c9949931.svg`
- Screenshots: `memory-bank/active/refined-clipped.png`, `touchpoint-clipped.png`
- Source post: `devblog/blog/fable/_posts/2026-03-21-the-load-bearing-pipeline-was-human.md` (diagrams start with `block`)
