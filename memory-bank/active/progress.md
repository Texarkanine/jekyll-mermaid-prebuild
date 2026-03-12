# Progress

Add SVG post-processing to fix mmdc's foreignObject text clipping bug and support configurable width constraints. New `SvgPostProcessor` module, `Configuration` updates for `max_width`, and `Generator` integration.

**Complexity:** Level 3

## 2026-03-12 - COMPLEXITY ANALYSIS - COMPLETE

* Work completed
    - Reviewed full codebase structure and all source modules
    - Reviewed user-provided planning document with detailed SVG structure analysis
    - Determined Level 3 complexity: multiple components, design decisions needed, new dependency
    - Created ephemeral memory bank files
* Decisions made
    - Level 3 classification: affects Configuration, Generator, and introduces new SvgPostProcessor module
    - Nokogiri required as runtime dependency for XML parsing

## 2026-03-12 - PLAN - COMPLETE

* Work completed
    - Full component analysis: Configuration, SvgPostProcessor (new), Generator, Processor, gemspec, main require, README
    - Cross-module dependency mapping with boundary change assessment
    - Test plan: 18 behaviors across 4 modules, 1 new spec file
    - 6-step implementation plan ordered by dependency graph
    - Technology validation for Nokogiri runtime dependency
    - Challenges & mitigations documented (namespace handling, diverse diagram types, transform parsing, cache migration)
* Decisions made
    - Always post-process (foreignObject fix applies unconditionally; max_width is optional addition)
    - min_width deferred — CSS layout concern, not plugin responsibility
    - viewBox adjustment not needed — rect bounds already within viewBox
    - No mmdc invocation changes — fix is purely post-processing
    - Cache key format change handles migration automatically (one-time regen on upgrade)
    - No creative phase needed — all questions resolved with high confidence

## 2026-03-12 - PREFLIGHT - PASS

* Work completed
    - Convention compliance verified: SvgPostProcessor follows module_function pattern, naming conventions match
    - Dependency impact traced: existing instance_doubles in generator_spec and processor_spec need max_width
    - No conflicts detected, completeness precheck passed (all 7 requirements → concrete steps)
    - Added B9a behavior: defensive width="100%" on root SVG
* Decisions made
    - Plan amended with explicit notes about updating existing test doubles
    - Advisory flagged: pluggable post-processor architecture for future extensibility (out of scope)
* Insights
    - hooks_spec.rb does NOT need max_width on its config double (hooks don't access it)

## 2026-03-12 - BUILD - COMPLETE

* Work completed
    - Step 1: Added Nokogiri >= 1.13 runtime dependency to gemspec; `bundle install` succeeded
    - Step 2: Configuration — `max_width` attr_reader + `parse_max_width` (B9–B12: 7 new tests)
    - Step 3: SvgPostProcessor — new module with `process`, `fix_foreign_object_widths`, `recenter_label_transform`, `adjust_root_svg_width` (B1–B9a: 15 new tests)
    - Step 4: Generator — `post_process_svg` private method integrates SvgPostProcessor after mmdc render (B13–B16: 5 new tests including max_width=640 context)
    - Step 5: Processor — cache key now includes `\x00max_width=#{@config.max_width}` suffix (B17–B18: 2 new tests)
    - Step 6: README — SVG post-processing feature documented, Options table updated, Caching section updated with cache key note
    - 76/76 tests pass (47 pre-existing + 29 new); RuboCop clean (0 offenses)
* Decisions made
    - XML declaration stripped from SvgPostProcessor output when source SVG lacked one (preserves original format)
    - `recenter_label_transform` extracted as named helper (cleaner than inline lambda)
    - B5 test uses `.to_s` on style to handle the nil-when-deleted case cleanly
* Insights
    - Nokogiri namespace-aware XPath works cleanly against mmdc SVG structure; SVG namespace is `http://www.w3.org/2000/svg`
    - `doc.root` is more reliable than XPath for finding the root svg element (works with or without namespace)

## 2026-03-12 - QA - PASS

* Work completed
    - Semantic review against all 7 requirements — all verified complete
    - Fixed generator.rb: moved post_process_svg to end of class (consistent private-at-bottom pattern)
    - Fixed svg_post_processor.rb: removed unused SVG_NS constant (YAGNI)
    - 76/76 tests pass; RuboCop 0 offenses after fixes
* Decisions made
    - Both fixes were trivial (style/cleanup) — no design decisions needed
* Insights
    - public/private alternation anti-pattern would have been caught by a stricter RuboCop config; worth noting for future

## 2026-03-12 - REFLECT - COMPLETE

* Work completed
    - Full lifecycle review: requirements, plan accuracy, build, QA, cross-phase analysis
    - Created `memory-bank/active/reflection/reflection-svg-post-processing.md`
* Decisions made
    - No retrospective plan changes needed — implementation matched plan cleanly
* Insights extracted
    - Technical: Nokogiri namespace-aware XPath, XML declaration handling, nil vs empty string for deleted attributes
    - Process: stub placement matters (put in final location from start); preflight's instance_double gap check was highest-value contribution

## 2026-03-12 - POST-BUILD INVESTIGATION: foreignObject centering failure

* Problem
    - User reported node label text was left-aligned after the foreignObject widening fix
    - Removing recenter made text right-shifted; restoring recenter made it left-aligned
    - Both directions wrong — original mmdc output (before our changes) was perfectly centered
* Root cause analysis
    - `display: table-cell` on the inner `<div>` causes it to shrink-wrap to content width
    - Widening foreignObject creates empty space the div doesn't fill
    - With recenter: fo is centered, but div left-aligns within it → text appears left-aligned
    - Without recenter: fo extends rightward, div left-aligns at original position → text appears right-shifted
    - **The foreignObject width manipulation was fundamentally wrong** — it can't work with table-cell layout
* Resolution
    - Removed ALL foreignObject manipulation (width changes, recenter, FOREIGN_OBJECT_MARGIN, TRANSLATE_RE)
    - SvgPostProcessor now only handles root SVG max-width/width
    - Node content passes through untouched — mmdc's centering is preserved
    - 73/73 tests pass, RuboCop clean

## 2026-03-12 - POST-BUILD INVESTIGATION: emoji width mismatch (actual root cause)

* Discovery
    - User tested `mmdc --width 680` on charts with emoji vs without emoji
    - Chart with emoji ("🔧 Code"): viewBox 632px — text clipped despite fitting in viewport
    - Chart without emoji ("Code"): viewBox 677px — renders perfectly, even wider chart
    - **Puppeteer undermeasures emoji glyphs.** It sees "🔧" as ~14.7px; real browsers render it at ~20-24px
    - The foreignObject is sized to Puppeteer's too-narrow measurement → clips in viewing browser
* Rejected approaches
    - Widen foreignObject to rect_width: breaks centering (table-cell shrink-wrap)
    - Per-emoji width compensation in SVG: fragile for multi-line labels (`"emoji<br/>wide text"`)
    - `overflow: visible`: doesn't fix centering (overflow is asymmetric rightward)
    - `overflow: visible` + flex centering: invasive CSS changes, uncertain browser compat
* Winning approach: `&nbsp;` padding in Mermaid source (user-discovered)
    - Add `&nbsp;` characters (non-breaking spaces) to node label text before mmdc renders
    - Each emoji gets ~2 `&nbsp;` appended to the label
    - Puppeteer now measures a wider string → foreignObject, rect, and translate all correct natively
    - In the viewing browser, emoji's wider rendering "consumes" the extra &nbsp; space
    - Trailing whitespace is invisible or overflow-clipped — no visual artifact
    - Centering handled naturally by Puppeteer (no SVG post-processing needed)
    - Multi-line labels: padding goes at end of label; if emoji is on a non-constraining line, the wider padding line gives all lines more room (graceful degradation, not surgical but not broken)
* Status: approach validated by user manually editing Mermaid source. Ready for automation in plugin.

## 2026-03-12 - PLAN REVISION: max_width removed, scope narrowed to emoji compensation

* Problem
    - User tested removing mmdc's `max-width` inline style via Chrome DevTools on the live site
    - SVGs scaled correctly without any manipulation — no compression, no clipping
    - The original clipping was 100% caused by emoji width undermeasurement, not container compression
    - `max_width` / `SvgPostProcessor` was solving a non-problem
* Key insight: `&nbsp;` padding must be in the plugin, not manual in source
    - Blog content is consumed by multiple rendering pipelines (GitHub preview, IDE preview, mermaid.live, client-side mermaid.js)
    - `&nbsp;` padding renders incorrectly in every non-mmdc context
    - The plugin is the only layer specific to the mmdc rendering path
* Resolution
    - Removed `max_width` and `SvgPostProcessor` from scope entirely
    - Removed Nokogiri dependency (no longer needed — emoji compensation is string manipulation)
    - New implementation plan: Step 0 (cleanup removal) → Steps 1-4 (emoji compensation feature)
    - Single focused feature: emoji width compensation via Mermaid source preprocessing

## 2026-03-12 - BUILD (REVISED SCOPE) - COMPLETE

* Work completed
    - Step 0: Deleted SvgPostProcessor and spec; removed max_width from Configuration/Generator/Processor; removed Nokogiri; updated README and all config doubles (48 tests)
    - Step 1: Configuration emoji_width_compensation (parse_emoji_width_compensation, frozen Hash); C1–C4
    - Step 2: EmojiCompensator (detect_diagram_type, compensate, compensate_flowchart_labels); E1–E10, D1–D7
    - Step 3: Processor integration (detect type → config check → compensate → cache key + generate); P1–P4
    - Step 4: README emoji width compensation option and subsection
* Decisions made
    - Flowchart label patterns: ["], ('), {"}, ((")), [/" "/] covered; regex %r for parallelogram to satisfy RuboCop
    - P4 example shortened for RSpec/ExampleLength (keys.uniq.size == 2)
* Insights
    - 73 examples, 0 failures; RuboCop clean

## 2026-03-12 - POST-BUILD REFINEMENTS

* Work completed
    - Changed NBSP constant from `"\u00a0"` (Unicode) to `"&nbsp;"` (HTML entity) — Unicode was stripped by mmdc pipeline, HTML entity works
    - Added multi-line label strategy: split on `<br>` variants, compute visual length (emoji counts as 2), pad only the longest line if it has emoji
    - Added `visual_length`, `pad_label_content` methods to EmojiCompensator
    - Added tests E5 (emoji line longest → pad that line), E11 (non-emoji line longest → no padding), E12 (visual length tiebreaker)
    - Updated all test expectations from `\u00a0` to `&nbsp;`
    - 75/75 tests pass; RuboCop 0 offenses
* Decisions made
    - Documented as a monkeypatch with specific input constraints: double-quoted labels, `<br>` for line breaks, flowchart only
    - Manual `&nbsp;` documented as fallback for unsupported patterns
* User verification
    - Rebuilt devblog with emoji width compensation enabled — emoji nodes render correctly

## 2026-03-12 - QA (REVISED SCOPE) - PASS

* Work completed
    - Semantic review against plan, project brief, and acceptance criteria
    - KISS: no over-engineering found
    - DRY: no duplication found
    - YAGNI: removed dead circle-shape regex (`\(\(\("(.*?)"\)\)\)` matched triple parens, not valid Mermaid; circle `(("..."))` already handled by rounded-rect regex matching inner `("...")`)
    - Completeness: all 6 requirements verified implemented, all 7 acceptance criteria met
    - Regression: no pattern violations — module_function, config parse pattern, test double updates all consistent
    - Integrity: no debug artifacts, TODOs, or magic numbers
    - Documentation: README updated, memory bank updated (activeContext had stale test count 73 → 75)
    - 75/75 tests pass; RuboCop 0 offenses after fix
* Decisions made
    - Dead circle regex removed rather than fixed — fixing it would cause double-compensation (rounded-rect regex already matches inner `("...")`)
    - Single-quote rect pattern `['']` kept — it's valid Mermaid syntax and a harmless broader match
