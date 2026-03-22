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
