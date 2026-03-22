---
task_id: block-edge-label-svg-pad
date: 2026-03-22
complexity_level: 2
---

# Reflection: Block diagram edge label clipping (SVG post-processing)

## Summary

Added optional `block_edge_label_padding` to widen block-diagram edge-label `<foreignObject>` widths after mmdc, preventing stroked-text clipping on Linux/WSL builds. All acceptance criteria met; user confirmed fix via smoke testing.

## Requirements vs Outcome

All four acceptance criteria delivered as specified. No requirements dropped, descoped, or added. The fix is narrowly scoped to block diagram edge labels — flowcharts and other types are provably unchanged (enforced by `aria-roledescription="block"` gate + test coverage).

## Plan Accuracy

The plan was accurate with one significant amendment during Preflight: Nokogiri was dropped in favor of targeted regex. This was the correct call — avoided adding a C-extension runtime dependency for a narrow string operation on deterministic mmdc output. The file was also renamed from `block_edge_label_svg_post_processor.rb` to `svg_post_processor.rb` for consistency with existing module naming. All other plan items (config, digest integration, generator hook, documentation) executed as written in sequence.

Predicted challenges (regex fragility, prior post-processor removal context, centering offset) were all addressed as planned. No surprises.

## Build & QA Observations

Build was clean — straightforward implementation once the regex approach was validated against real mmdc output during Preflight. QA caught one trivial visibility issue: `Generator#maybe_pad_block_edge_labels` was unintentionally public (missing `private` keyword). Fixed immediately, tests and linter re-verified green.

## Insights

### Technical

- Block diagrams use `display: inline-block` for edge label foreignObject content, while flowcharts use `display: table-cell`. This is why the archived SvgPostProcessor removal (which found foreignObject widening futile for flowcharts) does not apply to block diagrams. The CSS display model determines whether foreignObject width is the clipping boundary. This distinction should inform any future SVG post-processing work.

### Process

- Preflight caught the Nokogiri dependency issue before any code was written, redirecting to a regex approach with zero new dependencies. For L2 tasks this is a meaningful gate — the 10 minutes spent on Preflight saved what would have been a mid-build dependency debate and potential gemspec change.

### Million-Dollar Question

The current design is already natural. Emoji compensation operates on Mermaid source (before mmdc), edge label padding operates on SVG output (after mmdc). These stages are different because the compensations have leverage at different points. A unified "post-processing pipeline" wouldn't simplify anything — it would force unrelated operations into a shared abstraction. Nothing notable here.
