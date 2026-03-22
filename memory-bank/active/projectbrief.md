# Project Brief

## User Story

As a blog author using Mermaid **block** diagrams in Jekyll, I want edge labels (for example `Human -- "last touchpoint" --> Process`) to render fully in prebuilt SVGs so that readers never see clipped letters at the right edge of label boxes.

## Use-Case(s)

### Use-Case 1

Block diagrams in posts (e.g. `2026-03-21-the-load-bearing-pipeline-was-human.md`) with quoted edge strings between nodes.

### Use-Case 2

Local `jekyll-mermaid-prebuild` gem development: rebuild devblog, verify SVGs under `_site/assets/svg/` and visual output via `<img>`.

## Requirements

1. Determine why clipping appears on those edge labels and not on typical flowchart-v2 diagrams in the same site.
2. Decide whether the fix belongs in **jekyll-mermaid-prebuild** (preprocess / postprocess / config) and/or should be reported upstream to Mermaid.
3. Implement a fix in the gem when appropriate, with tests and documentation, following existing patterns (e.g. optional compensation, cache-key impact).

## Constraints

1. Site embeds SVG via `<img src="...">` (see `Generator#build_figure_html`); behavior must remain correct for that path.
2. Prior work removed generic SVG post-processing in favor of Mermaid-source preprocessing for emoji width; any post-processing reintroduction should be narrowly scoped and justified.
3. TDD and full test suite before calling work done.

## Acceptance Criteria

1. Edge labels such as `last touchpoint` and `refined` render without right-edge clipping in generated SVGs for block diagrams on Linux/WSL mmdc builds.
2. Flowchart and other diagram types are unchanged unless explicitly opted in.
3. Configuration is documented (README / CHANGELOG as appropriate).
4. RSpec and RuboCop pass for jekyll-mermaid-prebuild.
