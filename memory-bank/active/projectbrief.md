# Project Brief

## Task: ci-foreignobject-clip-fix

## User Story

Edge labels and node labels in block diagrams clip when built via GHA CI. Root cause: `<foreignObject>` defaults to `overflow: hidden`, and different build environments produce foreignObject widths that differ by 7–22% for identical Mermaid source due to system font differences.

## Requirements (Amended)

### R1: Fix node label clipping (overflow protection)
Inject `foreignObject{overflow:visible;}` CSS into SVGs. This fixes node labels where the background is the node shape (SVG element), not the foreignObject.

### R2: Fix edge label clipping (edge label padding)
Existing `block_edge_label_padding` already works for edge labels. Rename to `edge_label_padding`, move under `postprocessing`, drop the block-only restriction (apply to all diagram types).

### R3: Config restructure — `postprocessing` group
All cross-browser rendering workarounds must live under a `postprocessing:` nested config, separated from plugin behavior config (`enabled`, `output_dir`):

```yaml
mermaid_prebuild:
  postprocessing:
    text_centering: true              # boolean, default: true
    overflow_protection: true         # boolean, default: true
    edge_label_padding: 0             # numeric, default: 0 (off)
    emoji_width_compensation:         # map, default: {} (off)
      flowchart: true
```

- `text_centering` and `overflow_protection`: booleans, default true, can be set to false to disable
- `edge_label_padding`: numeric, renamed from `block_edge_label_padding`, no longer block-specific
- `emoji_width_compensation`: map, moved from top-level to under `postprocessing`
- Breaking change (pre-1.0, clean break, no back-compat shimming)

### R4: All fixes must be individually disableable
Users with a perfect headless pipeline can disable any/all postprocessing.

## Constraints
- Stay on latest mermaid-cli (no version pinning)
- Use same bundled Chromium on both environments
- Not a brittle hack

## Acceptance Criteria
- All foreignObject labels (edge + node) render without clipping
- All postprocessing features togglable via config booleans
- `edge_label_padding` applies to all diagram types (not just block)
- All existing tests updated, all new behavior tested
- README, CHANGELOG updated
- Full suite green, RuboCop clean
