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

## Acceptance Criteria

- Edge labels like "last touchpoint" and "refined" render without right-edge clipping in both local and CI-built SVGs
- The fix is unconditional (not gated behind environment detection)
- Non-block diagram types also benefit if they have foreignObject labels
- All existing tests pass; new tests cover the fix
- No mermaid-cli version dependency introduced
