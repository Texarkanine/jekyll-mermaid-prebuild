---
task_id: issue-11-prefers-color-scheme
complexity_level: 3
date: 2026-03-22
status: completed
---

# TASK ARCHIVE: Issue #11 — prefers-color-scheme, dual SVGs, and chart backgrounds

## SUMMARY

Delivered [GitHub Issue #11](https://github.com/Texarkanine/jekyll-mermaid-prebuild/issues/11) for **jekyll-mermaid-prebuild**: site-level control over Mermaid theme and visitor color scheme (`light` / `dark` / `auto`), including dual SVG generation, figure HTML with `@media (prefers-color-scheme: dark)`, and cache-safe digests. A **pre-PR rework** then replaced asymmetric “transparent dark only” behavior with **configurable root SVG backgrounds** (defaults white / black), nested YAML under **`prefers-color-scheme`** and **`background-color`** (CSS-aligned keys), and digest fields `bgL` / `bgD`. Subsequent **hardening** (review / nitpicks) added `config_hash_fetch` presence semantics, explicit **`MmdcWrapper` theme validation**, and spec helpers wired to **`Configuration` constants**.

## REQUIREMENTS

**Original (project brief)**

1. Config for diagram color behavior: `light` (default), `dark`, `auto`.
2. `light`: single SVG, Mermaid default theme (no `mmdc -t dark`).
3. `dark`: single SVG with `mmdc -t dark`.
4. `auto`: two SVGs per diagram (`{digest}.svg`, `{digest}-dark.svg`); HTML/CSS so only the variant matching `prefers-color-scheme` is shown; correct link targets per variant.
5. Cache must include theme-affecting settings; hooks/copy must support `-dark` stems.
6. Integration: devblog + path gem + `jekyll build`.

**Rework (pre-PR)**

1. Symmetric root SVG background handling: replace mmdc’s root `background-color: white` with **per-variant** configured CSS (defaults white / dark black), not transparent-for-dark-only.
2. Nested YAML as the **only** PCS shape: `mode` plus optional `background-color` map (`light` / `dark` slots); sanitize values; document including **`transparent`** / RGBA.
3. Digest includes background strings so color changes bust cache.
4. README + devblog config + RSpec updated.

**Note:** Final shipped YAML uses **`prefers-color-scheme`** and **`background-color`** keys only (no underscore aliases; feature unshipped so no legacy migration path in code).

## IMPLEMENTATION

**Phase A — Initial feature**

- **`Configuration`:** Parsed mode; readers used by `Generator` / `Processor`.
- **`MmdcWrapper#render`:** `theme:` keyword → optional `-t dark`.
- **`Generator#generate`:** Returns `Hash` stem → path; `generate_auto` for two files; `build_figure_html` with optional `dark_url` and inline `<style>` + two `<a>` / `<img>` pairs.
- **`Processor`:** Digest includes `pcs=`; `auto` merges two SVG paths for copy.
- **`Hooks`:** Unchanged copy semantics (dynamic stem names).
- **Post-build fixes (discovered visually, not in original plan):** mmdc always emits root `background-color: white` even for dark theme → interim **`ensure_transparent_background`** for dark variants; **no inline `display:none`** on dark link (inline style overrode `@media` — visibility controlled only from the shared `<style>` block).

**Phase B — Rework**

- **`Configuration`:** Hash-only PCS block; `chart_background_light` / `chart_background_dark`; `config_hash_fetch`; constants `PREFERS_COLOR_SCHEME_YAML_KEY`, `BACKGROUND_COLOR_YAML_KEY`, `DEFAULT_PREFERS_COLOR_SCHEME_MODE`, etc.
- **`SvgPostProcessor`:** `apply_root_svg_background(svg, css_background)` replaces mmdc white token for **every** variant.
- **`Generator#post_process_svg`:** Passes configured background per render; removed dark-only transparent branch.
- **`Processor`:** Digest adds `bgL=` / `bgD=`.
- **`spec/support/configuration_helpers.rb`:** Shared `instance_double` defaults.

**Phase C — PR / review hardening**

- **`config_hash_fetch`:** Use `hash.key?` so falsy values like `false` are not dropped (`||` bug).
- **`MmdcWrapper`:** `ALLOWED_RENDER_THEMES` (`:default`, `:dark`); `ArgumentError` on invalid `theme:`.
- **Spec helpers:** Default attrs from `Configuration::DEFAULT_*` constants.
- **YAML surface:** Hyphen-only keys for PCS block; Ruby reader remains `#prefers_color_scheme`.

**Key files touched over the arc:** `configuration.rb`, `mmdc_wrapper.rb`, `generator.rb`, `processor.rb`, `svg_post_processor.rb`, `hooks.rb` (validation only), `emoji_compensator.rb` (frontmatter-aware type detection unchanged in behavior), specs, `README.md`, devblog `_config.yaml`.

## TESTING

- **`bundle exec rspec`** and **`bundle exec rubocop`** in the gem (counts grew from ~149 to 158+ examples through rework and hardening).
- **`bundle exec jekyll build`** on devblog with path gem (14 diagrams → 28 SVGs in `auto`).
- **Manual / visual:** Dark page + `auto` surfaced mmdc white background and CSS specificity issues; fixed before original QA. Rework validated against specs and rebuild.

**QA:** Level-3 semantic QA PASS on rework; `.qa-validation-status` recorded PASS before reflect.

## LESSONS LEARNED

**From reflection — initial feature (`reflection-issue-11-prefers-color-scheme`)**

- **mmdc output:** Root `<svg>` keeps `background-color: white` regardless of `-t dark`; any dark-mode story must account for that (substitution or transparency), ideally by inspecting real SVG output during investigation.
- **CSS:** Inline `style` beats author `<style>` including `@media`; toggling visibility for two links must not rely on inline display on one branch.
- **Process:** Visual browser checks catch failures RSpec cannot; investigation should open a real `mmdc` SVG, not only read CLI help.
- **Plan vs build:** Prescriptive HTML/CSS in the plan (`display:none` inline) caused a real bug; preflight helped `<picture>` → two-`<a>` but not specificity.

**From reflection — rework (`reflection-issue-11-rework-chart-backgrounds`)**

- **Coupling:** Post-process still assumes mmdc emits the `background-color: white` token; if CLI changes, substitution may need to become injection.
- **Digest discipline:** Any setting that changes pixels in cached SVGs must be in `digest_string_for_cache` (mode, backgrounds, padding, flags).
- **Preflight:** Advisories on spec double churn matched actual work—good signal for similar config expansions.

**Creative phase:** None run for either tranche; preflight + operator decisions handled HTML shape.

## PROCESS IMPROVEMENTS

- Treat **visual integration** as an explicit step for HTML/CSS/SVG deliverables.
- **Investigation:** Include **artifact inspection** (generated SVG/HTML), not only API/CLI flags.
- **Preflight advisories** on test fixture surface area: treat as a checklist during build.

## TECHNICAL IMPROVEMENTS

- Optional future: **`mermaid_theme`** (e.g. forest) if mmdc supports more `-t` values end-to-end; today wrapper only allows `:default` / `:dark`.
- If mmdc drops root `background-color: white`, revisit **`apply_root_svg_background`** (injection vs replace).
- **`Generator#post_process_svg`** unused `_diagram_type` parameter remains minor debt (noted in preflight).

## NEXT STEPS

None for this archive scope. Open the PR against upstream when ready; release gem version per project workflow.
