# Task: svg-post-processing

* Task ID: svg-post-processing
* Complexity: Level 3
* Type: feature

## Summary

Two-pronged fix for mmdc-generated SVG rendering issues:

1. **Emoji width compensation** (Mermaid source preprocessing): Puppeteer undermeasures emoji glyphs, producing foreignObject elements too narrow for the text. Fix: before passing Mermaid source to mmdc, detect emoji in node labels and append `&nbsp;` padding so Puppeteer allocates correct widths. Opt-in via config.

2. **Root SVG max-width handling** (SVG post-processing): mmdc hardcodes a `max-width` inline style tied to Puppeteer viewport width. Fix: remove it (or replace with user-configured value) and set `width="100%"` for responsive scaling. Already implemented and tested.

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

### Pipeline (Updated)

```
Processor.process_content
  ├─ extract mermaid block
  ├─ EmojiCompensator.compensate(source)  ← NEW (before mmdc)
  ├─ compute cache_key (includes compensated source + max_width)
  ├─ Generator.generate(compensated_source, cache_key)
  │   ├─ MmdcWrapper.render (gets correct widths from padded source)
  │   └─ SvgPostProcessor.process (root SVG max-width only)
  └─ build figure HTML
```

## Component Analysis

### Affected Components (NEW for emoji compensation)

- **EmojiCompensator** (`lib/jekyll-mermaid-prebuild/emoji_compensator.rb`): **NEW** — Stateless module. Accepts a Mermaid source string and a diagram type. If the diagram type is enabled for compensation, detects emoji in node labels and appends `&nbsp;` padding. Each diagram type has its own label detection regex (flowcharts use `NodeId["label"]` patterns; other types have different syntax).
- **Configuration** (`lib/jekyll-mermaid-prebuild/configuration.rb`): Add `emoji_width_compensation` config — a map of diagram types to booleans. Example: `emoji_width_compensation: { flowchart: true }`. Accessor returns a frozen Hash; empty hash if not configured.
- **Processor** (`lib/jekyll-mermaid-prebuild/processor.rb`): Detect diagram type from Mermaid source, check if compensation is enabled for that type, call EmojiCompensator if so. Cache key includes the compensated source.

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

### Already Complete (from prior build)

- **SvgPostProcessor**: Root SVG max-width handling — tested and working
- **Generator**: Post-processing integration — tested and working
- **Gemspec**: Nokogiri dependency — added
- **Configuration**: `max_width` parsing — tested and working

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
- **E5**: Multi-line label (contains `<br/>`) with emoji → padding appended at end of label
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
- Update feature description, config options table, known limitations
- Example config showing `emoji_width_compensation` map

## Status

- [x] Component analysis complete
- [x] Open questions resolved (via user testing + investigation)
- [x] Test planning complete (TDD)
- [x] Implementation plan complete
- [ ] Build — emoji compensation
- [ ] Full test suite pass
- [ ] Documentation update
