# Project Brief

## User Story

As a Jekyll site maintainer using jekyll-mermaid-prebuild, I want emoji-containing Mermaid node labels to render without clipping in mmdc-generated SVGs, so that my diagrams look correct on non-Mac build platforms without polluting my source files with rendering workarounds.

## Use-Case

### Emoji Text Clipping Fix

Mermaid node labels containing emoji characters are clipped because headless Chromium (on non-Mac platforms) undermeasures emoji glyph widths when sizing `<foreignObject>` elements — a [known Chrome bug](https://stackoverflow.com/q/42016125). The plugin compensates by padding emoji-containing labels with non-breaking spaces before mmdc rendering, so Puppeteer allocates correct foreignObject widths natively.

This MUST be done in the plugin (not manually in source) because `&nbsp;` padding in Mermaid source would render incorrectly in every non-mmdc context: GitHub preview, IDE preview, mermaid.live, and client-side mermaid.js. The blog content is bound to multiple rendering pipelines, and only the mmdc path has this bug. The plugin is the only layer that can inject padding transparently for mmdc while keeping source files clean.

## Requirements

1. Accept an optional `emoji_width_compensation` configuration parameter (Hash mapping diagram types to booleans) under the `mermaid_prebuild` config key.
2. Detect the diagram type from Mermaid source (skipping frontmatter, comments, blank lines).
3. When emoji compensation is enabled for the detected diagram type, preprocess the Mermaid source before mmdc: detect emoji in node labels and append `&nbsp;` padding.
4. When emoji compensation is not enabled (or not configured), pass source to mmdc unchanged.
5. Cache keys must account for compensated source (so enabling/disabling compensation invalidates the cache).
6. Scope: flowchart/graph only for initial implementation. Config map structure supports future diagram types.

## What was removed (and why)

### max_width / SvgPostProcessor — REMOVED

The original hypothesis was that mmdc's hardcoded `max-width` inline style was compressing SVGs and causing text clipping. User testing proved this wrong:
- Removing `max-width` via Chrome DevTools on the live site showed SVGs scale fine without any manipulation
- The actual clipping was caused by emoji width undermeasurement, not container compression
- The `SvgPostProcessor` module (root SVG max-width handling) and `max_width` configuration solved a non-problem

These are removed entirely: SvgPostProcessor module, Nokogiri dependency, max_width config, Generator post-processing integration. All in git history if ever needed.

## Constraints

1. Do not change how `mmdc` is invoked (flags, args) — the fix is Mermaid source preprocessing only.
2. Do NOT modify the SVG output (no post-processing of foreignObject, transforms, or root SVG attributes).
3. Must be robust across different Mermaid diagram types (only compensate types that are explicitly enabled).
4. Follow existing codebase patterns: stateless utility modules use `module_function`; stateful components are classes.
5. Emoji detection: count `\p{Extended_Pictographic}` codepoints. No attempt to handle ZWJ decomposition or other Unicode complexity.

## Acceptance Criteria

1. Node labels with emoji render without clipping when emoji compensation is enabled for their diagram type.
2. Node labels without emoji are not modified by the emoji compensator.
3. Diagrams whose type is not enabled for compensation pass through unchanged.
4. `emoji_width_compensation` configuration is optional — omitting it does not break existing behavior.
5. Cache invalidates when compensation is toggled.
6. All existing tests pass; new tests cover emoji compensation, diagram type detection, and configuration.
7. RuboCop passes with no new violations.
