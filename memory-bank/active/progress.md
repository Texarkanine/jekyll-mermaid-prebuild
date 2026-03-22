# Progress

## 2026-03-22 — Complexity analysis + investigation

- **Level:** 3 (Intermediate feature — multiple components, new config surface, CLI + HTML + cache).
- **Rationale:** Touches `Configuration`, `MmdcWrapper`, `Generator`, `Processor`, `Hooks`, README, and broad RSpec coverage; not a single-file bug fix.
- **Investigation:** Confirmed gem has no theme flag today; caching is `#{digest}.svg` under `.jekyll-cache/jekyll-mermaid-prebuild/`; `mmdc` supports `-t dark` per [@mermaid-js/mermaid-cli](https://www.npmjs.com/package/@mermaid-js/mermaid-cli) / CLI docs.
- **Design direction:** Config key `prefers_color_scheme` (values `light` | `dark` | `auto`); include mode in digest input; for `auto` emit `{key}.svg` and `{key}-dark.svg` and `<picture>` with `prefers-color-scheme` media query.
- **Next phase:** `/niko-plan` per `.cursor/rules/shared/niko/level3/level3-workflow.mdc`.
