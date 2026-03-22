# Task: CI foreignObject clip fix + postprocessing config restructure

* Task ID: ci-foreignobject-clip-fix
* Complexity: Level 2
* Type: Bug fix + config restructure

Overflow protection (already built) fixes node labels. Edge label padding (existing) fixes edge labels. All cross-browser workarounds move under `postprocessing:` config group with boolean/numeric toggles. `block_edge_label_padding` renamed to `edge_label_padding` and block-only restriction dropped.

## Test Plan (TDD)

### Behaviors to Verify

**Configuration (new/changed):**
- `postprocessing.text_centering` defaults to `true` when absent
- `postprocessing.text_centering: false` → returns `false`
- `postprocessing.overflow_protection` defaults to `true` when absent
- `postprocessing.overflow_protection: false` → returns `false`
- `postprocessing.edge_label_padding` defaults to `0` when absent
- `postprocessing.edge_label_padding: 6` → returns `6`
- `postprocessing.edge_label_padding` preserves existing validation (false→0, negative→0, non-numeric→0, float OK)
- `postprocessing.emoji_width_compensation` reads from nested location, same parsing rules
- Old top-level `block_edge_label_padding` and `emoji_width_compensation` keys ignored (no back-compat)

**Generator (changed):**
- `text_centering: false` → SVG does NOT get centering CSS
- `overflow_protection: false` → SVG does NOT get overflow CSS
- `text_centering: true` (default) → SVG gets centering CSS (existing, unchanged behavior)
- `overflow_protection: true` (default) → SVG gets overflow CSS (existing, unchanged behavior)
- Padding applies regardless of `diagram_type` (no block restriction)

**SvgPostProcessor (changed):**
- `.apply` widens edge label foreignObjects in ANY diagram type (not just block)
- `.apply` no longer checks for `BLOCK_ROOT_MARKER`

**Processor (changed):**
- `digest_string_for_cache` includes padding for ALL diagram types (not just block)
- Digest string uses `edge_pad=` prefix (not `block_edge_pad=`)

### Test Infrastructure

- Framework: RSpec
- Test location: `spec/jekyll_mermaid_prebuild/`
- New test files: none
- Modified specs: `configuration_spec.rb`, `generator_spec.rb`, `processor_spec.rb`, `svg_post_processor_spec.rb`

## Implementation Plan

### Step 1: Configuration — new `postprocessing` group (TDD cycle)
- Files: `lib/jekyll-mermaid-prebuild/configuration.rb`, `spec/jekyll_mermaid_prebuild/configuration_spec.rb`
- Changes:
  - Parse `config["postprocessing"]` sub-hash
  - New attrs: `text_centering` (bool, default true), `overflow_protection` (bool, default true)
  - Rename: `block_edge_label_padding` → `edge_label_padding` (read from `postprocessing.edge_label_padding`)
  - Move: `emoji_width_compensation` reads from `postprocessing.emoji_width_compensation`
  - Update all spec `site_config` hashes to nest under `"postprocessing"`

### Step 2: SvgPostProcessor — remove block restriction (TDD cycle)
- Files: `lib/jekyll-mermaid-prebuild/svg_post_processor.rb`, `spec/jekyll_mermaid_prebuild/svg_post_processor_spec.rb`
- Changes:
  - Remove `BLOCK_ROOT_MARKER` constant and its check from `.apply`
  - Update test: "does not modify flowchart-v2 SVGs" → now it DOES widen edge labels in flowcharts

### Step 3: Generator — conditional postprocessing (TDD cycle)
- Files: `lib/jekyll-mermaid-prebuild/generator.rb`, `spec/jekyll_mermaid_prebuild/generator_spec.rb`
- Changes:
  - `post_process_svg` reads `config.text_centering`, `config.overflow_protection`
  - Centering called only when `text_centering` is truthy
  - Overflow called only when `overflow_protection` is truthy
  - Padding: drop `diagram_type == "block"` condition; use `config.edge_label_padding`
  - Update all `instance_double` configs: `block_edge_label_padding:` → `edge_label_padding:`, add `text_centering: true, overflow_protection: true`
  - Add tests for disabled centering/overflow

### Step 4: Processor — update digest + config refs (TDD cycle)
- Files: `lib/jekyll-mermaid-prebuild/processor.rb`, `spec/jekyll_mermaid_prebuild/processor_spec.rb`
- Changes:
  - `digest_string_for_cache`: use `config.edge_label_padding`, remove `diagram_type == "block"` check, change digest prefix to `edge_pad=`
  - Update all `instance_double` configs: `block_edge_label_padding:` → `edge_label_padding:`
  - Update padding digest tests to reflect all-diagram-type behavior

### Step 5: Docs
- Files: `README.md`, `CHANGELOG.md`
- Changes: config examples, options table, cross-browser section, breaking change note

## Technology Validation

No new technology — validation not required.

## Dependencies

- None. Consumer (devblog) needs config YAML update: move `emoji_width_compensation` under `postprocessing:` and optionally add `edge_label_padding`.

## Challenges & Mitigations

- **Breaking config change**: Pre-1.0, clean break. Document in CHANGELOG and README.
- **Cache invalidation**: Digest string change (`block_edge_pad=` → `edge_pad=`) invalidates cached SVGs with padding. Standard for any postprocessing change.
- **Padding now hits all diagram types**: Could widen edge labels in diagrams that don't need it. Low risk — padding is opt-in (default 0).

## Status

- [x] Initialization complete
- [x] Test planning complete (TDD)
- [x] Implementation plan complete
- [x] Technology validation complete
- [ ] Preflight
- [ ] Build
- [ ] QA
