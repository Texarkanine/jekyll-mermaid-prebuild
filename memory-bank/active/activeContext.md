# Active Context

## Current Task: ci-foreignobject-clip-fix
**Phase:** COMPLEXITY-ANALYSIS - COMPLETE

## What Was Done
- Complexity level determined: Level 2 (bug fix with cross-environment investigation + design constraints)
- Reviewed archive of previous fix (block-edge-label-svg-pad)
- Compared local vs remote build screenshots: edge labels "last touchpoint" → "last touchpoin", "refined" → "refinec" on CI
- Confirmed devblog is using bundled Chromium (no system Chrome), has AppArmor workaround
- Confirmed devblog config has NO `block_edge_label_padding` set (defaults to 0 / disabled)
- Root cause: font metric differences between WSL and GHA Ubuntu cause foreignObject widths to be too narrow on CI

## Key Finding
- Compared CI SVG (`c9949931.svg`) vs local SVG (`85b6de46.svg`): foreignObject widths differ 7–22% per label (non-uniform)
- Root fix: inject `foreignObject { overflow: visible; }` CSS into SVG `<style>` block, same pattern as existing centering fix
- This is environment-agnostic, not tied to mermaid version, and handles any magnitude of measurement mismatch

## Next Step
- Commit complexity analysis → Plan phase
