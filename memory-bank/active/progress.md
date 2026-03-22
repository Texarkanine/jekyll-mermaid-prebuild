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
