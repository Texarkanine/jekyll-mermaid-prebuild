# Task: Block diagram edge label clipping (SVG post-processing)

* Task ID: block-edge-label-svg-pad
* Complexity: Level 2
* Type: bug fix / simple enhancement

**Operator decision:** Fix via **SVG post-processing** after mmdc (not Mermaid source preprocessing). After a successful `mmdc` render, widen `<foreignObject>` elements under block-diagram edge labels so stroked text is not clipped at the right edge. Scope stays limited to SVGs whose root `<svg>` has `aria-roledescription="block"` (Mermaid block layout). Flowchart and other diagram types are untouched.

## Test Plan (TDD)

### Behaviors to Verify

- [B1] **Block diagram + padding enabled:** minimal fixture SVG with `aria-roledescription="block"` and `<g class="edgeLabel">` containing `<foreignObject width="W" ...>` → every such `foreignObject` gains `width="W+P"` where `P` is the configured padding (float math preserved).
- [B2] **Non-block SVG:** root `aria-roledescription="flowchart-v2"` (or absent / other) → output byte-for-byte or semantically unchanged `foreignObject` widths (no widening).
- [B3] **Padding disabled (0 / nil):** post-processor returns input unchanged for block SVGs.
- [B4] **Multiple edge labels:** several `edgeLabel` groups each with `foreignObject` → all targeted instances widened; node `foreignObject` labels (not under `edgeLabel`) must not be modified.
- [B5] **Round-trip safety:** inner XHTML inside `foreignObject` (e.g. `<div xmlns="http://www.w3.org/1999/xhtml">`) remains functional after processing — no mangled markup that breaks rendering (assert key substrings or parseability).
- [B6] **Cache / digest integration:** when `diagram_type == "block"` and padding > 0, content digest includes a stable suffix so toggling padding invalidates cache; when diagram is not `block`, digest does not include padding suffix (flowchart caches unaffected by enabling the feature).
- [B7] **Generator integration:** after `MmdcWrapper.render`, cached SVG on disk is post-processed when rules apply; when rules do not apply, file matches mmdc output.

### Edge Cases

- [E1] Invalid / unparseable SVG string → processor returns original string unchanged (or documents explicit behavior); generator should not crash.
- [E2] `foreignObject` missing `width` or non-numeric width → skip that node or leave unchanged (document choice).
- [E3] Very small width (0) → still apply pad only if safe; avoid negative widths.

### Test Infrastructure

- Framework: **RSpec** (`bundle exec rspec`)
- Test location: `spec/jekyll_mermaid_prebuild/`
- Conventions: one spec file per module (`*_spec.rb`), `describe`/`context`/`it` matching existing style
- New test files: `spec/jekyll_mermaid_prebuild/block_edge_label_svg_post_processor_spec.rb`; extend `spec/jekyll_mermaid_prebuild/configuration_spec.rb`, `spec/jekyll_mermaid_prebuild/processor_spec.rb`, and `spec/jekyll_mermaid_prebuild/generator_spec.rb` as needed

## Implementation Plan

1. **Configuration**  
   - Files: `lib/jekyll-mermaid-prebuild/configuration.rb`, `spec/jekyll_mermaid_prebuild/configuration_spec.rb`  
   - Changes: Parse `block_edge_label_padding` from `mermaid_prebuild` config (numeric: Integer or Float; `0`, `nil`, or `false` = off). Expose reader e.g. `#block_edge_label_padding` returning numeric or 0.

2. **Post-processor module (stub → implement)**  
   - Files: `lib/jekyll-mermaid-prebuild/block_edge_label_svg_post_processor.rb`, `require` from `lib/jekyll-mermaid-prebuild.rb`  
   - Changes: Module/class with `apply(svg_string, padding:)` — if `padding` not positive, return `svg_string`. Else parse SVG, detect block diagram via root `aria-roledescription="block"`, find `g` with `class` containing `edgeLabel`, descendant `foreignObject` elements, add `padding` to numeric `width` attribute only. Preserve document structure; prefer attribute-only mutation to minimize XHTML churn.

3. **Unit specs for post-processor**  
   - Files: `spec/jekyll_mermaid_prebuild/block_edge_label_svg_post_processor_spec.rb`  
   - Changes: Implement B1–B5, E1–E3 with fixture strings (trimmed excerpts from real mmdc block SVG acceptable).

4. **Digest / Processor**  
   - Files: `lib/jekyll-mermaid-prebuild/processor.rb`, `spec/jekyll_mermaid_prebuild/processor_spec.rb`  
   - Changes: When `EmojiCompensator.detect_diagram_type(source) == "block"` and `config.block_edge_label_padding.positive?`, append a deterministic NUL-separated suffix to the string passed to `DigestCalculator.content_digest` (e.g. `"\0block_edge_pad=#{padding}"`) so cache keys change when padding changes. Non-block diagrams: no suffix.

5. **Generator hook**  
   - Files: `lib/jekyll-mermaid-prebuild/generator.rb`, `spec/jekyll_mermaid_prebuild/generator_spec.rb`  
   - Changes: After successful `MmdcWrapper.render`, if `config.block_edge_label_padding.positive?`, read `cache_path`, run post-processor, write back only when output differs or always rewrite processed string. **Detection:** either pass `diagram_type` from `Processor` into `generate(mermaid_source, cache_key, diagram_type:)` **or** run post-processor only when `BlockEdgeLabelSvgPostProcessor.block_diagram?(svg)` after first read — prefer passing `diagram_type` from `Processor` to avoid double-read and to skip XML parse for non-block diagrams.

6. **Generator API signature**  
   - Files: `processor.rb`, `generator.rb`, any internal callers of `generate`  
   - Changes: `Generator#generate(mermaid_source, cache_key, diagram_type: nil)` — when `diagram_type == "block"` and padding positive, post-process written file.

7. **Documentation**  
   - Files: `README.md`, `CHANGELOG.md`  
   - Changes: Document `block_edge_label_padding` (purpose: block edge label stroke clipping on mmdc/Linux), recommended starting value (e.g. 4–8 SVG user units), cache behavior when toggling.

8. **RuboCop + full suite**  
   - Run `bundle exec rubocop` and `bundle exec rspec`; fix issues.

## Technology Validation

- **Nokogiri:** Use for robust SVG attribute updates under namespaces. Jekyll already depends on Nokogiri transitively; add an **explicit** runtime dependency in `jekyll-mermaid-prebuild.gemspec` so standalone resolution and `require "nokogiri"` are reliable in CI and consumer bundles.  
- **Validation:** `bundle install` succeeds; one spec parses a real-world block SVG fragment after `bundle exec`.

## Dependencies

- New runtime gem: **nokogiri** (version floor aligned with Jekyll 4’s constraint, per `bundle exec ruby -e 'puts Gem.loaded_specs["jekyll"].dependencies'` or gemspec cross-check during build).

## Challenges & Mitigations

- **XML round-trip alters `foreignObject` HTML:** Mitigation: touch only `foreignObject` `width` attributes via DOM API; add B5 regression test; if LibXML still mangles, narrow to regex-based width replacement scoped with a lightweight state machine or Ox — only as fallback.  
- **Namespaces / default SVG namespace:** Mitigation: use Nokogiri namespaced queries (`svg|`, `xmlns`) as needed; test with real mmdc output.  
- **Reintroducing post-processing after emoji-only preprocess:** Mitigation: document narrow scope (block + edgeLabel `foreignObject` width only); no generic `max_width` or flowchart hacks.  
- **Padding too small/large:** Mitigation: configurable numeric; README suggests tuning; optional follow-up for height if multi-line edge labels clip vertically (not in current bug report).

## Status

- [x] Initialization complete
- [x] Test planning complete (TDD)
- [x] Implementation plan complete
- [x] Technology validation complete
- [ ] Preflight
- [ ] Build
- [ ] QA
