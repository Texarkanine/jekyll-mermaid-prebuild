---
task_id: svg-post-processing
complexity_level: 3
date: 2026-03-12
status: completed
---

# TASK ARCHIVE: Emoji Width Compensation (svg-post-processing)

## SUMMARY

Added an **emoji width compensation** feature to the jekyll-mermaid-prebuild plugin. Headless Chromium (used by mermaid-cli/mmdc) [undermeasures emoji glyph widths](https://stackoverflow.com/q/42016125) on non-Mac platforms, producing `<foreignObject>` elements too narrow for the text and causing clipping. The fix: before passing Mermaid source to mmdc, the plugin detects emoji in node labels and appends `&nbsp;` (HTML entity) padding so Puppeteer allocates correct widths. Opt-in via config per diagram type (`emoji_width_compensation: { flowchart: true }`). Scope for this build: flowchart/graph only; config structure supports future diagram types.

The plugin is the only place this can live: manual `&nbsp;` in Mermaid source would render incorrectly in GitHub preview, IDE preview, mermaid.live, and client-side mermaid.js. Only the mmdc path has the bug; the plugin injects padding transparently so source stays clean everywhere.

**Context:** The task started as "SVG post-processing" (SvgPostProcessor + max_width to fix clipping). That implementation was built, QA'd, and reflected on — then discarded when user testing proved the root cause was emoji width undermeasurement, not container compression. max_width/SvgPostProcessor were removed (Step 0); the revised implementation is Mermaid source preprocessing only (no SVG post-processing, no Nokogiri).

## REQUIREMENTS

- Accept an optional `emoji_width_compensation` configuration parameter (Hash mapping diagram types to booleans) under `mermaid_prebuild`.
- Detect diagram type from Mermaid source (skipping frontmatter `---`, `%%` comments, blank lines).
- When compensation is enabled for the detected type, preprocess source before mmdc: detect emoji in node labels and append `&nbsp;` padding (2 per emoji).
- When not enabled or not configured, pass source to mmdc unchanged.
- Cache keys must include compensated source so toggling compensation invalidates cache.
- Flowchart/graph only for initial implementation; config map supports future types.
- Constraints: no mmdc invocation changes; no SVG output modification; stateless modules use `module_function`; emoji via `\p{Extended_Pictographic}` count.
- Acceptance: emoji labels render without clipping when enabled; non-emoji labels unchanged; non-enabled types unchanged; config optional; cache invalidates on toggle; tests and RuboCop pass.

**Refinements (post–initial plan):** Use `&nbsp;` HTML entity, not `\u00a0` (Unicode is stripped by mmdc). For multi-line labels (`<br>` variants), pad only the **visually longest line** (emoji counts as 2 for length); if that line has no emoji, no padding. Document constraints: double-quoted labels, `<br>` for line breaks, flowchart only; manual `&nbsp;` as fallback for unsupported patterns.

## IMPLEMENTATION

**Pipeline:** `Processor.process_content` → extract mermaid block → `EmojiCompensator.detect_diagram_type(source)` → if type enabled in config, `EmojiCompensator.compensate(source, diagram_type)` → cache key from `DigestCalculator.content_digest(source_for_render)` → `Generator.generate(compensated_source, cache_key)` → MmdcWrapper.render → build figure HTML.

**Key files:**

- **EmojiCompensator** (`lib/jekyll-mermaid-prebuild/emoji_compensator.rb`): New stateless module, `module_function`. `detect_diagram_type(mermaid_source)` skips frontmatter/comments/blanks, returns first token (normalizes `graph` → `flowchart`). `compensate(mermaid_source, diagram_type)` for flowchart calls `compensate_flowchart_labels`: regex matches node label patterns (`["..."]`, `('...')`, `{"..."}`, `(("..."))` via rounded-rect match, `[/"..."\/]` parallelogram), extracts content, splits on `<br>` variants, finds visually longest line (`visual_length = length + count_emoji`), pads that line with `&nbsp;` × (emoji_count × 2) if it has emoji. Uses `EMOJI_RE = /\p{Extended_Pictographic}/`, `NBSP = "&nbsp;"`.
- **Configuration** (`lib/jekyll-mermaid-prebuild/configuration.rb`): `attr_reader :emoji_width_compensation`; `parse_emoji_width_compensation` returns frozen Hash (string keys, boolean values), rejects non-Hash.
- **Processor** (`lib/jekyll-mermaid-prebuild/processor.rb`): In `convert_block`, detect type, branch on `@config.emoji_width_compensation[diagram_type]`, set `source_for_render` to compensated or original, compute cache_key from it, pass to generator.
- **Main require**: `require_relative "jekyll-mermaid-prebuild/emoji_compensator"` (no SvgPostProcessor; Nokogiri removed from gemspec).
- **README**: Emoji width compensation subsection: what/why/when, monkeypatch framing, requirements (double-quoted labels, `<br>`, flowchart only), multi-line behavior, manual `&nbsp;` fallback, example config, caching note.

**Removed:** SvgPostProcessor module and spec, max_width from Configuration/Generator/Processor, Nokogiri runtime dependency, post_process_svg and related tests/docs.

## TESTING

- **Automated:** 75 RSpec examples (Configuration C1–C4, EmojiCompensator E1–E12 + D1–D7, Processor P1–P4, plus existing specs). Full suite: `bundle exec rspec`. RuboCop: 0 offenses.
- **QA (niko-qa):** Semantic review against plan and acceptance criteria. One trivial fix applied: removed dead circle-shape regex (triple-paren pattern never matched valid Mermaid; circle `(("..."))` already handled by rounded-rect regex). PASS.
- **User validation:** Rebuilt devblog with `emoji_width_compensation: { flowchart: true }`; emoji nodes render correctly.

## LESSONS LEARNED

- **Mermaid’s `display: table-cell` layout makes foreignObject width manipulation futile.** The inner div shrink-wraps to content; widening foreignObject cannot fix centering. The only effective intervention is Mermaid source before Puppeteer measures.
- **`\u00a0` is stripped by the mmdc pipeline; `&nbsp;` survives.** Labels are rendered as HTML in `<foreignObject>`, so HTML entities work. This is external binary behavior and not unit-testable.
- **Multi-line labels:** Padding only the visually longest line (emoji counts as 2) avoids centering shift when a longer non-emoji line determines container width.
- **Regex-based preprocessing is acceptable as a documented monkeypatch.** Document constraints (double-quoted labels, `<br>`, flowchart only); manual `&nbsp;` for edge cases.
- **Hypothesis-driven work needs runtime validation early.** The original SvgPostProcessor plan was internally consistent but wrong; a short user test (e.g. DevTools) could have invalidated it before full build.
- **Loose test assertions can mask dead code.** E9 passed with `include(nbsp)` while a dead triple-paren regex existed; a strict shape-output assertion would have caught it in build.

## PROCESS IMPROVEMENTS

- For symptom-driven tasks involving CSS layout or external tools, **prototype and validate the root cause before committing to a full plan–preflight–build cycle.** The most expensive failure mode is executing that cycle cleanly on the wrong problem.
- Consider **stricter test assertions** for transformation logic (exact output where feasible) to catch dead or wrong code that still produces a desired substring.

## TECHNICAL IMPROVEMENTS

- None required for this task. Optional: stricter RuboCop for public/private ordering to catch method-placement issues; exact-match assertions in shape compensation specs for robustness.

## NEXT STEPS

None. For future diagram types (e.g. sequenceDiagram), add label-detection regex and enable in config; no structural changes needed.
