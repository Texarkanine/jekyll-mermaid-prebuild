# Progress

## 2026-03-22 — Complexity analysis and technical diagnosis

- User reported clipping on block diagram edge labels (`last touchpoint`, `refined`); confirmed in PNGs and in generated SVG `foreignObject` widths vs stroked edge label HTML.
- Compared to flowchart-v2 SVG: different edge label structure; block uses inline stroked text inside fixed-size `foreignObject`.
- Confirmed `detect_diagram_type` returns `block` for diagrams starting with `block`; current compensation path only handles `flowchart` + emoji in node brackets.
- Recorded findings in `activeContext.md` and this file.

## 2026-03-22 — Level 2 Plan phase (post-processing)

- Operator selected **postprocessing** approach (not Mermaid source padding).
- Wrote full Level 2 plan to `memory-bank/active/tasks.md`: `BlockEdgeLabelSvgPostProcessor`, config `block_edge_label_padding`, Nokogiri + gemspec dependency, digest suffix for `block` + positive padding, `Generator#generate(..., diagram_type:)` hook, RSpec coverage and README/CHANGELOG updates.
- Updated `activeContext.md` phase to PLAN COMPLETE; next step Preflight.

## 2026-03-22 — Preflight PASS (with plan amendments)

- **Convention:** Renamed `block_edge_label_svg_post_processor.rb` → `svg_post_processor.rb` (shorter, consistent with existing module names).
- **Critical amendment — dropped Nokogiri:** Verified Nokogiri is NOT in the gem's bundle (only in consumer sites via other plugins). Adding a C-extension runtime dependency for a simple `width` attribute bump is disproportionate. Replaced with targeted regex on mmdc's deterministic SVG output — consistent with EmojiCompensator's regex approach, zero new dependencies.
- **Verified foreignObject widening is valid for block diagrams:** Block edge labels use `display: inline-block` (not `table-cell`). The archive's objection ("foreignObject width manipulation futile") applied specifically to flowchart `table-cell` layout where divs shrink-wrap; block edge labels clip at the foreignObject boundary, so widening it prevents clipping. No background `<rect>` exists in block edge labels — no secondary element to widen.
- **Centering offset noted:** Small rightward shift (~padding/2 px) is acceptable for 4–8px values.
- **All 6 block-type SVGs** in devblog confirmed to use identical structure: `<g class="edgeLabel"><g class="label"><foreignObject>` with stroked edge label text.
- Preflight status written to `.preflight-status`. Plan amendments incorporated into `tasks.md`.

## 2026-03-22 — Level 2 Build — COMPLETE

* Work completed
    - Added `Configuration#block_edge_label_padding` and `SvgPostProcessor` (regex widening of block edge-label `foreignObject` widths).
    - Extended cache digest for `diagram_type == "block"` when padding positive; `Generator#generate` accepts `diagram_type:` and rewrites new cache files after mmdc when applicable.
    - RSpec coverage for post-processor, config, processor digest behavior, generator hook; README + CHANGELOG `[Unreleased]`.
* Decisions made
    - Kept preflight choice: no XML parser dependency; targeted regex aligned with mmdc output.
* Verification
    - `bundle exec rspec` — 96 examples, 0 failures; `bundle exec rubocop` — clean.

## 2026-03-22 — Level 2 QA — PASS

* Findings
    - **Trivial fix applied:** `Generator#maybe_pad_block_edge_labels` was unintentionally public (no `private` keyword before it). Added `private` — consistent with all other internal helpers in the codebase.
    - No KISS, DRY, YAGNI, completeness, integrity, or documentation issues.
* Verification
    - `bundle exec rspec` — 96 examples, 0 failures; `bundle exec rubocop` — 0 offenses.

## 2026-03-22 — Level 2 Reflect — COMPLETE

* Reflection recorded in `memory-bank/active/reflection/reflection-block-edge-label-svg-pad.md`
* Key insight: Preflight gate caught Nokogiri dependency issue before build, redirecting to zero-dependency regex approach. Block vs flowchart `display` model distinction documented for future SVG work.

## 2026-03-22 — Refresh: Root Cause Corrected, Fix Revalidated

* **Root cause corrected:** Earlier sessions attributed clipping to CSS `stroke` overhang on edge label text. User disproved this empirically (removing stroke from baked SVG didn't fix clipping). True root cause is **zero-padding foreignObject + cross-context text measurement mismatch** — headless Chromium measures text width via `getBoundingClientRect()` and sets foreignObject to exactly that; the viewing browser's font rendering produces slightly wider text, causing overflow/clip. Node labels survive because their containing shapes (rect, circle) provide 4+ px of built-in padding.
* **Fix assessment: current approach is optimal.** The additive padding on edge-label foreignObject widths is the correct fix given our constraints (`<img>`-embedded SVGs, no control over viewing browser, environment-specific font stacks). Alternatives evaluated and rejected:
  - `overflow: visible` on foreignObject — unreliable in `<img>` SVG context
  - Percentage-based widening — unnecessary complexity; measurement error is roughly constant
  - Source preprocessing — can't target edge labels specifically in Mermaid source
  - Font installation — environment-dependent, fragile
* **Documentation corrected:** Updated `SvgPostProcessor` module comment, README description, CHANGELOG entry, and reflection summary to reflect the accurate root cause (cross-browser text measurement mismatch, not stroke overhang).
* **Verification:** 96 examples, 0 failures; RuboCop clean.

## 2026-03-22 — Refresh (continued): CI Chrome fix, text centering, updated reflection

* **CI environment fix:** Discovered devblog's `deploy.yaml` was overriding Puppeteer to use system Chrome (`PUPPETEER_SKIP_CHROMIUM_DOWNLOAD` + `PUPPETEER_EXECUTABLE_PATH`), causing 11-16% narrower text measurements and clipping in deployed SVGs. Removed overrides to align CI with Puppeteer's bundled Chromium.
* **Text centering fix:** After aligning to bundled Chromium, labels shifted left because foreignObject was wider than text and Mermaid's `text-align:center` targets SVG `<g>` (not HTML divs). Required three CSS iterations: (1) `text-align:center` alone (no effect on `table-cell`), (2) `width:100%;text-align:center` (no effect — anonymous table shrink-wraps), (3) `display:block !important;text-align:center` (works — overrides `table-cell`, div fills foreignObject, centering applies). Implemented as `SvgPostProcessor.ensure_text_centering` — unconditional, idempotent, no config flag. Generator calls it before edge-label padding.
* **Documentation updates:** README rewritten with "Cross-browser text rendering fixes" section (centering + padding + CI tip). CHANGELOG updated with bug fix entry. Troubleshooting doc updated with CSS iteration details. Reflection rewritten covering full journey.
* **Verification:** 103 examples, 0 failures; RuboCop clean.

## 2026-03-22 — Level 2 Reflect (second pass) — COMPLETE

* Reflection rewritten in `memory-bank/active/reflection/reflection-block-edge-label-svg-pad.md` covering all refinements: original build, /refresh root cause correction, CI Chrome discovery, text centering fix with CSS iteration details.
* Key insights: `display:table-cell` blocks both `text-align` and `width:100%` due to anonymous table wrapper; CI Chrome vs Puppeteer Chromium produce measurably different text widths; user empirical disproof invaluable for hypothesis correction.
