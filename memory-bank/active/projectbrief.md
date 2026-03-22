# Project Brief

## Task: ci-foreignobject-clip-fix

## User Story

Edge labels in block diagrams (e.g. "last touchpoint", "refined") render fully visible when built locally but are clipped on the right edge when built via GitHub Actions CI — despite both environments now using mmdc's bundled Chromium. The previous `block_edge_label_padding` fix (see archive `20260322-block-edge-label-svg-pad`) shipped and centering works, but the core clipping reappeared on the live site.

## Requirements

1. Fix SVG edge label clipping that occurs only in GHA CI-built SVGs
2. The fix must work identically regardless of build environment (local WSL vs GHA Ubuntu)
3. **Constraints:**
   - Stay on latest mermaid-cli locally & in CI (no version pinning, no divergent versions)
   - Use same Chromium on both (bundled with mmdc)
   - Not a brittle hack that breaks on the next mermaid update

## Root Cause (Hypothesis)

Even with the same Chromium binary, font metrics differ between local WSL and GHA Ubuntu because system font libraries (fontconfig, freetype) and available system fonts differ. mmdc measures text widths during rendering using the host's font stack, so the same Mermaid source produces different `<foreignObject>` widths on different machines. When a viewing browser renders text slightly wider than the generating environment measured, the foreignObject clips the overflow.

**Additional observations:**
- Font *sizes* themselves differ between local and remote SVG output (user-reported)
- Comparing actual SVGs (CI `c9949931.svg` vs local `85b6de46.svg`): foreignObject widths differ by **7–22%** across labels, with no uniform scale factor. Local measures wider → no clipping; CI measures narrower → clips when a viewer browser renders text wider than CI measured.
- The variation is per-label (not a simple DPI ratio), confirming different font stacks/metrics are in play.
- This eliminates any fixed-pixel or fixed-percentage padding as a robust solution — the delta varies per label and per environment.

## Additional Evidence

User enabled `block_edge_label_padding: 6` in devblog config. Result on CI:
- Edge labels: all fixed (padding worked)
- Node labels: "Specification" clips to "Specificatior" — the "n" is cut off

The existing padding fix only targets `<g class="edgeLabel">` foreignObjects. Node labels (`<g class="node">`) use the same foreignObject mechanism but aren't covered by the regex. This confirms the fix must target ALL foreignObjects, not just edge labels.

## Acceptance Criteria

- ALL foreignObject labels (edge AND node) render without clipping in both local and CI-built SVGs
- The fix is unconditional (not gated behind environment detection or diagram type)
- All existing tests pass; new tests cover the fix
- No mermaid-cli version dependency introduced
