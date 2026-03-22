# Task: CI foreignObject edge label clipping fix

* Task ID: ci-foreignobject-clip-fix
* Complexity: Level 2
* Type: Bug fix (cross-environment rendering)

SVG edge labels AND node labels clip on the right edge when the SVG is built on GHA CI but viewed in a browser with wider font metrics than CI's headless Chromium used. Confirmed: with `block_edge_label_padding: 6` enabled, edge labels are fixed but node label "Specification" still clips to "Specificatior" — the existing padding only targets `<g class="edgeLabel">` foreignObjects. The root cause is that `<foreignObject>` defaults to `overflow: hidden` in SVG, so any text that renders wider than the foreignObject's baked-in width is silently clipped. The fix: inject `foreignObject{overflow:visible;}` into the SVG `<style>` block, using the same always-on idempotent pattern as the existing `ensure_text_centering` fix.

## Test Plan (TDD)

### Behaviors to Verify

- **Overflow rule injection**: `ensure_foreignobject_overflow(svg_with_style)` → SVG contains `foreignObject{overflow:visible;}` before `</style>`
- **Rule placement**: the injected rule lives inside the existing `<style>` element, not outside it
- **Idempotency**: calling `ensure_foreignobject_overflow` twice produces the same output as calling it once
- **No-op on missing `<style>`**: SVG without a `<style>` tag → returned unchanged
- **Non-string input**: `nil` → returns `nil`
- **Error resilience**: if an internal operation raises → returns original string
- **Generator integration**: freshly generated SVGs have the overflow rule injected (alongside existing centering rule)

### Edge Cases

- SVG that already has `foreignObject{overflow:visible;}` (from a previous run) → no duplicate
- SVG with `</style>` but no foreignObject elements → rule injected harmlessly (CSS has no effect on missing elements)

### Test Infrastructure

- Framework: RSpec
- Test location: `spec/jekyll_mermaid_prebuild/`
- Conventions: one `_spec.rb` per module, `describe ".method_name"` blocks, `let` for fixtures
- New test files: none — tests go in existing `svg_post_processor_spec.rb` and `generator_spec.rb`

## Implementation Plan

1. **Stub + test `SvgPostProcessor.ensure_foreignobject_overflow`** (TDD cycle 1)
   - Files: `lib/jekyll-mermaid-prebuild/svg_post_processor.rb`, `spec/jekyll_mermaid_prebuild/svg_post_processor_spec.rb`
   - Changes:
     - Add `OVERFLOW_RULE = "foreignObject{overflow:visible;}"` constant
     - Add `ensure_foreignobject_overflow(svg_string)` method (same pattern as `ensure_text_centering`)
     - Add `describe ".ensure_foreignobject_overflow"` test block with 6 test cases (injection, placement, idempotency, no-style, nil, error)

2. **Wire into Generator + integration test** (TDD cycle 2)
   - Files: `lib/jekyll-mermaid-prebuild/generator.rb`, `spec/jekyll_mermaid_prebuild/generator_spec.rb`
   - Changes:
     - Add `svg = SvgPostProcessor.ensure_foreignobject_overflow(svg)` call in `post_process_svg`, after centering and before padding
     - Add test case: freshly generated SVG contains `overflow:visible`

3. **Update docs**
   - Files: `README.md`, `CHANGELOG.md`
   - Changes: note the new always-on overflow fix in the cross-browser section

## Technology Validation

No new technology — validation not required. Pure CSS rule injection using existing `<style>` manipulation pattern.

## Dependencies

- None. No new gems, no new npm packages, no config changes required.
- Consumer (devblog) needs no changes — the fix is unconditional in the gem.

## Challenges & Mitigations

- **`overflow:visible` in `<img>` SVG context**: Some older browsers may not honor `overflow:visible` on foreignObject when the SVG is loaded via `<img src>`. Mitigation: modern browsers (Chrome, Firefox, Safari 15+) support this. The existing padding feature remains available as a belt-and-suspenders option for anyone who hits an edge case.
- **Cache invalidation**: Existing cached SVGs won't have the new rule until regenerated. Mitigation: clearing `.jekyll-cache/jekyll-mermaid-prebuild/` forces regeneration. This is standard for any post-processing change.

## Status

- [x] Initialization complete
- [x] Test planning complete (TDD)
- [x] Implementation plan complete
- [x] Technology validation complete
- [ ] Preflight
- [ ] Build
- [ ] QA
