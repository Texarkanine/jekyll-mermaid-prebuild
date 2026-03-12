# Task: svg-post-processing

* Task ID: svg-post-processing
* Complexity: Level 3
* Type: feature

## Summary

Fix mmdc-generated SVG rendering issues caused by headless Chromium undermeasuring emoji glyph widths.

**Emoji width compensation** (Mermaid source preprocessing): Headless Chromium (used by Puppeteer/mmdc) undermeasures emoji glyph widths on non-Mac platforms — a [known Chrome bug](https://stackoverflow.com/q/42016125). This produces foreignObject elements too narrow for the text, causing clipping. Fix: before passing Mermaid source to mmdc, detect emoji in node labels and append `&nbsp;` padding so Puppeteer allocates correct widths. Opt-in via config per diagram type.

### Why this belongs in the plugin (not manual `&nbsp;` in source)

The `&nbsp;` padding is **only correct for the mmdc rendering path.** Mermaid source with manual `&nbsp;` padding renders incorrectly in every other context:
- GitHub markdown preview (renders the trailing spaces visibly)
- IDE markdown preview (same)
- mermaid.live (same)
- Client-side mermaid.js rendering (doesn't have the headless Chrome bug)

The plugin is the only layer that sits between the author's clean Mermaid source and mmdc. It injects the compensation transparently — the source files stay clean and render correctly everywhere, while the mmdc-rendered output gets the padding it needs.

### Why this is opt-in with clear documentation

This is a workaround for a platform-specific headless Chromium bug, not a universal fix:
- **Mac mmdc builds**: don't need compensation (emoji measure correctly)
- **Linux/Windows mmdc builds**: need compensation (emoji undermeasured)
- **Upstream fix possible**: if Chromium or mermaid fixes the emoji width measurement, this feature should be disabled — excess `&nbsp;` padding would over-widen nodes

Documentation must clearly state: this compensates for a known headless Chromium emoji width measurement bug. Enable it only if you observe emoji text clipping in mmdc-rendered SVGs on your build platform.

## Pinned Info

### Why `&nbsp;` padding works

```
Puppeteer measures: "🔧 Code"       → 55.66px (emoji undermeasured)
Puppeteer measures: "🔧 Code\u00a0\u00a0" → ~71px (nbsp adds measured width)

Desktop browser renders "🔧 Code" at ~63-65px.
foreignObject at 71px → text fits with room to spare.
Trailing &nbsp; is invisible whitespace, clipped by overflow:hidden.
Puppeteer handles centering, rect sizing, transforms — all correct natively.
```

### Why other approaches failed

| Approach | Why it failed |
|----------|--------------|
| Widen foreignObject to rect_width | `display: table-cell` shrink-wraps; div doesn't fill wider fo → left/right misalignment |
| Per-emoji px compensation in SVG | Fragile for multi-line labels; can't know which line constrains width |
| `overflow: visible` on foreignObject | Asymmetric rightward overflow; centering wrong |
| `overflow: visible` + flex CSS | Invasive; `display: table-cell` → `display: flex` swap has uncertain browser compat |
| Root SVG max-width manipulation | User confirmed SVGs scale fine without it — was solving a non-problem. The real clipping was emoji width, not container compression. |

### Pipeline

```
Processor.process_content
  ├─ extract mermaid block
  ├─ EmojiCompensator.compensate(source)  ← NEW (before mmdc)
  ├─ compute cache_key (includes compensated source)
  ├─ Generator.generate(compensated_source, cache_key)
  │   └─ MmdcWrapper.render (gets correct widths from padded source)
  └─ build figure HTML
```

## Component Analysis

### Components to ADD

- **EmojiCompensator** (`lib/jekyll-mermaid-prebuild/emoji_compensator.rb`): **NEW** — Stateless module. Accepts a Mermaid source string and a diagram type. If the diagram type is enabled for compensation, detects emoji in node labels and appends `&nbsp;` padding. Each diagram type has its own label detection regex (flowcharts use `NodeId["label"]` patterns; other types have different syntax).
- **Configuration** (`lib/jekyll-mermaid-prebuild/configuration.rb`): Add `emoji_width_compensation` config — a map of diagram types to booleans. Example: `emoji_width_compensation: { flowchart: true }`. Accessor returns a frozen Hash; empty hash if not configured.
- **Processor** (`lib/jekyll-mermaid-prebuild/processor.rb`): Detect diagram type from Mermaid source, check if compensation is enabled for that type, call EmojiCompensator if so. Cache key includes the compensated source.

### Components to REMOVE (max_width / SvgPostProcessor — no longer needed)

User confirmed that removing mmdc's hardcoded `max-width` inline style is not needed: SVGs scale correctly without any manipulation. The original clipping symptom was caused by emoji width undermeasurement, not container compression.

- **SvgPostProcessor** (`lib/jekyll-mermaid-prebuild/svg_post_processor.rb`): DELETE entire module
- **SvgPostProcessor spec** (`spec/jekyll_mermaid_prebuild/svg_post_processor_spec.rb`): DELETE entire spec
- **Configuration** `max_width`: REMOVE `attr_reader :max_width` and `parse_max_width`
- **Configuration spec**: REMOVE max_width test cases (B9–B12)
- **Generator**: REMOVE `post_process_svg` method and `SvgPostProcessor` call
- **Generator spec**: REMOVE SvgPostProcessor integration tests (B13–B16)
- **Processor**: REMOVE `max_width` from cache key
- **Processor spec**: REMOVE max_width cache key tests (B17–B18)
- **Main require** (`lib/jekyll-mermaid-prebuild.rb`): REMOVE `require_relative "svg_post_processor"`
- **Gemspec**: REMOVE `nokogiri` runtime dependency (no longer needed — emoji compensation is string manipulation, not XML parsing)
- **README**: REMOVE max_width documentation

### Diagram Type Detection

Mermaid source can have YAML frontmatter (`---` delimited blocks) and comments (`%%` lines) before the diagram type keyword. Detection must skip these:

```
---
title: My Chart
---
%% This is a comment
flowchart LR        ← THIS is the diagram type line
  A --> B
```

Algorithm: scan lines, skip frontmatter (between `---` pairs), skip `%%` comment lines, skip blank lines. The first remaining line's first token is the diagram type keyword.

Known diagram type keywords relevant to emoji compensation:
- `graph`, `flowchart` → flowchart (both map to the same compensation logic)

**Scope for this build: flowchart only.** Other diagram types (sequenceDiagram, classDiagram, stateDiagram, etc.) are future enhancements. The config map structure supports them without code changes — just add label detection regex for the new type. Unrecognized types in the config are silently ignored (no-op).

## Emoji Detection Strategy

Ruby approach for counting emoji that need width compensation:

```ruby
# Match characters that render as wide pictographic emoji.
# \p{Extended_Pictographic} covers emoji from Unicode 11+.
# Excludes text-presentation symbols, variation selectors, ZWJ joiners.
EMOJI_RE = /\p{Extended_Pictographic}/

def count_emoji(text)
  text.scan(EMOJI_RE).length
end
```

Note: "no attempt to handle unicode funkiness" — we count individual Extended_Pictographic codepoints. ZWJ sequences (👨‍👩‍👧) count as multiple (each component is a codepoint). This over-compensates slightly for ZWJ sequences but is safe (extra trailing whitespace).

## Multi-Line Label Strategy

For labels with `<br/>` line breaks, only the **longest line** (by visual length) gets padded:

1. Split label content on `<br/>` / `<br>` / `<br />` variants
2. Compute visual length per line: `char_count + emoji_count` (each emoji counts as 2, since emoji render ~2x the width of a regular character)
3. Find the longest line by visual length
4. If the longest line has emoji → pad **that line** with `&nbsp;` × (emoji_count × 2)
5. If the longest line has no emoji → no padding at all (the container is correctly sized by Puppeteer's accurate measurement of the non-emoji line; shorter lines center naturally)

This avoids the problem where padding a short emoji line when a longer non-emoji line determines the container width causes the emoji text to shift left.

## Mermaid Label Detection Strategy

Node labels in Mermaid flowchart syntax appear as:
- `NodeId["label"]` (rect)
- `NodeId("label")` (rounded rect)
- `NodeId{"label"}` (diamond)
- `NodeId[/"label"/]` (parallelogram)
- `NodeId(("label"))` (circle)
- etc.

We need to find the label text within these delimiters and append `&nbsp;` padding after the last text character, before the closing delimiter.

Approach: regex to match node label patterns, extract the text content, count emoji, insert `&nbsp;` * (emoji_count * 2) before the closing delimiter.

## Test Plan (TDD) — New Tests

### EmojiCompensator

- **E1**: Flowchart label with single emoji → appends 2 `&nbsp;` at end of label text
- **E2**: Flowchart label with multiple emoji → appends 2 `&nbsp;` per emoji
- **E3**: Flowchart label with no emoji → returns source unchanged
- **E4**: Label with emoji and existing `&nbsp;` → adds compensation on top (doesn't strip existing)
- **E5**: Multi-line label where emoji line is longest → padding on that line only
- **E11**: Multi-line label where non-emoji line is longest → no padding at all
- **E12**: Emoji line is longest by visual length (emoji counts as 2) but not by raw char count → pads correctly
- **E6**: Multiple nodes in one diagram, some with emoji, some without → only emoji nodes get padding
- **E7**: Source that is not a compensated diagram type → returned unchanged
- **E8**: Node label with HTML entities preserved (doesn't corrupt `&amp;` etc.)
- **E9**: Various flowchart node shapes: `["..."]`, `("...")`, `{"..."}`, `(("..."))` → all compensated
- **E10**: `graph LR` keyword detected as flowchart (alias)

### Diagram Type Detection

- **D1**: Bare `flowchart LR` on first line → detected as `flowchart`
- **D2**: `graph TD` on first line → detected as `flowchart` (alias)
- **D3**: YAML frontmatter (`---` block) before diagram type → type detected after frontmatter
- **D4**: `%%` comment lines before diagram type → type detected after comments
- **D5**: Frontmatter + comments + blank lines before diagram type → correct detection
- **D6**: `sequenceDiagram` → detected as `sequence` (not flowchart)
- **D7**: Empty/whitespace-only source → returns nil (no type detected)

### Configuration

- **C1**: `emoji_width_compensation` not configured → returns empty hash
- **C2**: `emoji_width_compensation: { flowchart: true }` → returns `{ "flowchart" => true }`
- **C3**: `emoji_width_compensation: { flowchart: false }` → returns `{ "flowchart" => false }`
- **C4**: Non-hash value for `emoji_width_compensation` → returns empty hash (rejected)

### Processor (integration)

- **P1**: Flowchart with emoji + compensation enabled for flowchart → EmojiCompensator called
- **P2**: Flowchart with emoji + compensation NOT enabled for flowchart → EmojiCompensator NOT called
- **P3**: Sequence diagram + compensation enabled for flowchart only → EmojiCompensator NOT called
- **P4**: Cache key includes compensated source (different from uncompensated)

## Implementation Plan

### Step 0: Remove max_width / SvgPostProcessor (cleanup)

- Delete `lib/jekyll-mermaid-prebuild/svg_post_processor.rb`
- Delete `spec/jekyll_mermaid_prebuild/svg_post_processor_spec.rb`
- Remove `require_relative "svg_post_processor"` from `lib/jekyll-mermaid-prebuild.rb`
- Remove `nokogiri` runtime dependency from gemspec; `bundle install`
- Remove `max_width` from Configuration (attr_reader, parse method) and its tests (B9–B12)
- Remove `post_process_svg` from Generator and its tests (B13–B16)
- Remove `max_width` from Processor cache key and its tests (B17–B18)
- Update config doubles across all specs that reference `max_width`
- Remove max_width documentation from README
- Run full test suite — should pass with fewer tests (removal only, no new behavior)

### Step 1: Configuration — add `emoji_width_compensation` (TDD cycle)

- Files: `spec/jekyll_mermaid_prebuild/configuration_spec.rb`, `lib/jekyll-mermaid-prebuild/configuration.rb`
- Tests: C1, C2, C3, C4
- Changes: Add `attr_reader :emoji_width_compensation` + `parse_emoji_width_compensation` private method. Returns a frozen Hash mapping string diagram type names to booleans. Rejects non-Hash values.

### Step 2: EmojiCompensator — new module (TDD cycle)

- Files: `spec/jekyll_mermaid_prebuild/emoji_compensator_spec.rb` (NEW), `lib/jekyll-mermaid-prebuild/emoji_compensator.rb` (NEW), `lib/jekyll-mermaid-prebuild.rb`
- Tests: E1–E10, D1–D7
- Changes:
  - New module with `module_function` pattern
  - Public: `compensate(mermaid_source, diagram_type)` → returns padded source string
  - Public: `detect_diagram_type(mermaid_source)` → returns normalized type string or nil
  - Private: `compensate_flowchart_labels(source)` — regex finds node labels in flowchart syntax, counts emoji, appends `&nbsp;` padding
  - Type detection: skip `---` frontmatter, `%%` comments, blank lines; first remaining line's first token is the diagram type. Normalize `graph` → `flowchart`.

### Step 3: Processor — integrate emoji compensation (TDD cycle)

- Files: `spec/jekyll_mermaid_prebuild/processor_spec.rb`, `lib/jekyll-mermaid-prebuild/processor.rb`
- Tests: P1, P2, P3, P4
- Changes:
  - Detect diagram type via `EmojiCompensator.detect_diagram_type(source)`
  - Check `@config.emoji_width_compensation[diagram_type]`
  - If truthy, call `EmojiCompensator.compensate(source, diagram_type)` and use the result for cache key + mmdc rendering
  - If falsy, use original source unchanged

### Step 4: Documentation + cleanup

- Files: `README.md`
- Remove all max_width documentation
- Document `emoji_width_compensation` config with explicit guidance:
  - What it does: appends invisible `&nbsp;` padding to emoji-containing node labels before mmdc renders
  - Why it exists: headless Chromium undermeasures emoji glyph widths on non-Mac platforms ([Chrome bug](https://stackoverflow.com/q/42016125))
  - When to enable: only if you observe emoji text clipping in mmdc-rendered SVGs on your build platform
  - When NOT to enable: Mac build environments, or if upstream fixes land
  - Why it's in the plugin: manual `&nbsp;` in source would break GitHub preview, IDE preview, mermaid.live, and client-side rendering
- Example config:
  ```yaml
  mermaid_prebuild:
    emoji_width_compensation:
      flowchart: true
  ```

## Status

- [x] Component analysis complete
- [x] Open questions resolved (via user testing + investigation)
- [x] Test planning complete (TDD)
- [x] Implementation plan complete
- [x] Step 0 — Remove max_width / SvgPostProcessor
- [x] Step 1 — Configuration (emoji_width_compensation)
- [x] Step 2 — EmojiCompensator module
- [x] Step 3 — Processor integration
- [x] Step 4 — Documentation
- [x] Full test suite pass
- [x] QA review — PASS (1 trivial fix: dead circle regex removed)
