# Progress

## 2026-03-22 — Complexity analysis + investigation

- **Level:** 3 (Intermediate feature — multiple components, new config surface, CLI + HTML + cache).
- **Rationale:** Touches `Configuration`, `MmdcWrapper`, `Generator`, `Processor`, `Hooks`, README, and broad RSpec coverage; not a single-file bug fix.
- **Investigation:** Confirmed gem has no theme flag today; caching is `#{digest}.svg` under `.jekyll-cache/jekyll-mermaid-prebuild/`; `mmdc` supports `-t dark` per [@mermaid-js/mermaid-cli](https://www.npmjs.com/package/@mermaid-js/mermaid-cli) / CLI docs.
- **Design direction:** Config key `prefers_color_scheme` (values `light` | `dark` | `auto`); include mode in digest input; for `auto` emit `{key}.svg` and `{key}-dark.svg` and `<picture>` with `prefers-color-scheme` media query.
- **Next phase:** `/niko-plan` per `.cursor/rules/shared/niko/level3/level3-workflow.mdc`.

## 2026-03-22 — PLAN — COMPLETE

* **Work completed**
  - Authored full Level 3 plan in `memory-bank/active/tasks.md` (pinned sequence diagram, component analysis, TDD behaviors, ordered implementation steps, challenges).
  - Updated `activeContext.md` (phase PLAN complete; next: preflight).
* **Decisions made**
  - `Generator#generate` returns `Hash<String,String>|nil` (stems → cache paths); `build_figure_html` gains optional dark URL for `<picture>`.
  - Invalid `prefers_color_scheme` → `:light` + `Jekyll.logger.warn`.
  - No separate creative phase (no open questions).
* **Insights**
  - `Hooks.copy_svgs_to_site` already supports arbitrary stems including `digest-dark`.

## 2026-03-22 — PREFLIGHT — PASS

* **Work completed**
  - Validated plan against all 5 source modules (`Configuration`, `MmdcWrapper`, `Generator`, `Processor`, `Hooks`) and all 8 spec files.
  - Confirmed `Generator#generate` return-type change is safe — only caller is `Processor#convert_block`.
  - Confirmed `MmdcWrapper.render` `theme:` keyword param is backward-compatible (Ruby keyword with default).
  - Confirmed `Hooks.copy_svgs_to_site` handles `stem-dark` keys without modification (dynamic `#{cache_key}.svg`).
  - Confirmed all `instance_double(Configuration, ...)` in specs lack `prefers_color_scheme` — plan's mitigation (shared let / helper) is appropriate.
  - Confirmed devblog `_config.yaml` has `mermaid_prebuild:` section; default `:light` preserves current behavior.
* **Advisory findings (3 → 1 resolved, 2 remaining)**
  1. ~~`<a>` link target in `<picture>` mode~~ → **RESOLVED:** Operator chose two-`<a>` + CSS toggle approach. Plan updated: `build_figure_html` emits `.mermaid-diagram__light` and `.mermaid-diagram__dark` `<a>` elements with inline `<style>` `@media (prefers-color-scheme: dark)` to swap visibility. Each `<a>` links to its own SVG variant — link is always correct.
  2. Devblog integration: plan step 7 needs `prefers_color_scheme: auto` added to devblog's `_config.yaml` to exercise the feature beyond the default path.
  3. Future extensibility: hardcoded light=default/dark=dark themes. An optional `mermaid_theme` config could let users pick `forest`, `neutral`, etc. Scope expansion — noted for future.

## 2026-03-22 — BUILD — COMPLETE

* **Work completed**
  - Landed `prefers_color_scheme` end-to-end in the gem (config, mmdc `-t dark`, dual cache files for `auto`, two-`<a>` + `@media (prefers-color-scheme: dark)` HTML, digest includes `pcs`).
  - Extended RSpec (`configuration`, `mmdc_wrapper`, `generator`, `processor`, `hooks`); documented in README; set `prefers_color_scheme: auto` in devblog `_config.yaml`.
* **Decisions made**
  - `Generator#generate` returns `Hash{stem => path}` everywhere for a single call shape; `nil` on any required render failure in `auto`.
* **Verification**
  - `bundle exec rspec` and `bundle exec rubocop` in jekyll-mermaid-prebuild; `bundle exec jekyll build` in devblog with path gem.

## 2026-03-22 — QA — PASS

* **Work completed**
  - Semantic review of all implementation code against original plan.
  - Checked KISS, DRY, YAGNI, completeness, regression, integrity, documentation.
  - One trivial fix: `SvgPostProcessor` module doc said "Three independent fixes" — updated to "Four" to account for the new `ensure_transparent_background` method.
* **Findings**
  - All plan requirements fully implemented, no stubs/TODOs/placeholders.
  - No over-engineering, no duplicate logic, no speculative code.
  - Naming conventions, error handling, module organization all consistent with existing patterns.
  - No debug artifacts or magic numbers.
  - README and YARD docs complete.
* **Verification**
  - 149 RSpec examples, 0 failures; 21 files, 0 RuboCop offenses (after trivial doc fix).

## 2026-03-22 — REFLECT — COMPLETE

* **Work completed**
  - Full lifecycle review (plan accuracy, creative phase, build/QA observations, cross-phase analysis).
  - Reflection document: `memory-bank/active/reflection/reflection-issue-11-prefers-color-scheme.md`.
* **Key insights**
  - Technical: mmdc always emits `background-color: white` regardless of `-t dark`; inline `style` overrides `@media` queries.
  - Process: Visual integration testing is essential for CSS/SVG features; investigation phase should inspect actual tool output, not just CLI flags.

## 2026-03-22 — REWORK — initiated (pre-PR scope expansion)

* **Trigger:** Operator requested chart background consistency and a richer config shape before opening the PR.
* **Feedback captured**
  - Dark variants currently force `background-color: transparent` while light variants keep mmdc’s `white` — asymmetric and visually inconsistent on dark pages.
  - Desired default for dark charts: **opaque black** (`black`), not transparent.
  - Config should nest under a `prefers-color-scheme` (or equivalent) map: `mode` plus per-scheme `background-color` values that are pasted into the root SVG `style` as literal CSS (e.g. `#fff0aa`, `white`, `black`).
* **Next phase:** Fresh Level 3 plan in `tasks.md`; then `/niko-preflight` before build.

## 2026-03-22 — PREFLIGHT (rework) — PASS with ADVISORY

* **Work completed**
  - Validated rework plan against all 4 affected source modules (`Configuration`, `SvgPostProcessor`, `Generator`, `Processor`) and all 4 spec files.
  - Convention compliance: all proposed changes follow existing patterns (parse_* methods, module_function, digest parts). PASS.
  - Dependency impact: ~20 `instance_double(Configuration, ...)` declarations need new attrs. No unaccounted downstream. PASS.
  - Conflict detection: `ensure_transparent_background` removal safe (internal only). No duplication-in-waiting. PASS.
  - Completeness: all 4 rework requirements map to concrete implementation steps with files identified. PASS.
* **Decisions made**
  - **Operator decision:** Flat string `prefers_color_scheme` form **dropped** — dark mode hasn't shipped, no backward compat needed. `parse_prefers_color_scheme` is a clean rewrite (Hash-only); existing flat-string specs replaced; devblog config migration required.
* **Advisory findings**
  1. Spec instance_double volume (~20 locations) — recommend shared helper for default config attrs.
  2. Generator spec dark-background assertions change from `transparent` to `black`.
  3. Unused `_diagram_type` parameter in `post_process_svg` — minor tech debt, not in scope.

## 2026-03-22 — BUILD (rework chart backgrounds) — COMPLETE

* **Work completed**
  - `Configuration`: hash-only `prefers_color_scheme`, flexible keys, `chart_background_*` readers, sanitization + warnings.
  - `SvgPostProcessor#apply_root_svg_background`; `Generator#post_process_svg` passes per-variant background; `Processor` digest includes background strings.
  - RSpec helpers for doubles; README + devblog config migration.
* **Decisions made**
  - Reject chart background values matching control chars, quotes, backticks, `<`, `>`, `;`, `\`; max length 256.
* **Verification**
  - 158 RSpec examples, 0 failures; RuboCop clean; devblog `jekyll build` OK (path gem).

## 2026-03-22 — QA (rework chart backgrounds) — PASS

* **Work completed**
  - Semantic review against `tasks.md` plan: completeness, regression, docs; no blocking findings.
  - README: explicit **Transparency** subsection (`transparent`, `rgba(0, 0, 0, 0)`).
* **Verification**
  - `bundle exec rspec` (158 examples, 0 failures); `bundle exec rubocop` (clean).

## 2026-03-22 — REFLECT (rework chart backgrounds) — COMPLETE

* **Work completed**
  - Reflection: `memory-bank/active/reflection/reflection-issue-11-rework-chart-backgrounds.md`.
* **Key insights**
  - Technical: Root SVG post-process remains coupled to mmdc’s `background-color: white` token; digest must track every cache-affecting post-process input (backgrounds included).
  - Process: Preflight advisories on spec doubles matched actual build work—useful predictor for similar config surface changes.
