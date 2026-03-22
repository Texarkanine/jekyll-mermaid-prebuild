# Progress

## ci-foreignobject-clip-fix

### Complexity Analysis — COMPLETE
- Level 2 determined
- Previous fix (block-edge-label-svg-pad) shipped but clipping returned on CI-built SVGs
- Both environments use bundled Chromium; difference is system font metrics

### Plan — COMPLETE
- Compared CI vs local SVGs: foreignObject widths differ 7–22% per label (non-uniform)
- Fix: `foreignObject{overflow:visible;}` CSS injection, same pattern as centering
- 2 TDD cycles: (1) SvgPostProcessor method + tests, (2) Generator wiring + integration test
- No new dependencies, no config changes, consumer needs no changes
