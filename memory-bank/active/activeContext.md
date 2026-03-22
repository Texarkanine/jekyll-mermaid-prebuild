# Active Context

## Current Task: ci-foreignobject-clip-fix
**Phase:** BUILD - COMPLETE

## What Was Done
- Built `SvgPostProcessor.ensure_foreignobject_overflow` — injects `foreignObject{overflow:visible;}` into SVG `<style>` block
- Wired into `Generator#post_process_svg` (after centering, before optional padding)
- 7 new tests (6 unit + 1 integration), all passing
- Full suite: 110 examples, 0 failures; RuboCop: 0 offenses
- Updated README (cross-browser section now lists 3 fixes) and CHANGELOG

## Files Modified
- `lib/jekyll-mermaid-prebuild/svg_post_processor.rb` — added `OVERFLOW_RULE` constant + `ensure_foreignobject_overflow` method
- `lib/jekyll-mermaid-prebuild/generator.rb` — added overflow call in `post_process_svg`
- `spec/jekyll_mermaid_prebuild/svg_post_processor_spec.rb` — 6 new test cases
- `spec/jekyll_mermaid_prebuild/generator_spec.rb` — 1 new integration test
- `README.md` — updated cross-browser section
- `CHANGELOG.md` — added overflow fix entry

## Deviations from Plan
None — built to plan.

## Next Step
- QA
