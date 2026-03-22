# Project Brief

## User Story

As a Jekyll site author using `jekyll-mermaid-prebuild`, I want diagrams to respect light/dark viewing preferences so that SVG output matches the rest of the site in any color scheme.

## Use-Case(s)

### Use-Case 1 — Light-only sites (default)

Site has no dark UI. Diagrams render with Mermaid’s default (light) theme; behavior matches today’s gem.

### Use-Case 2 — Dark-only sites

Site is always dark. Diagrams are generated once per diagram with Mermaid’s `dark` theme and published as a single SVG per hash.

### Use-Case 3 — Auto (prefers-color-scheme)

Site supports both schemes. Build generates **two** SVGs per diagram: `{hash}.svg` (light) and `{hash}-dark.svg` (dark). Embedded HTML/CSS ensures visitors only see the variant that matches `prefers-color-scheme`.

## Requirements

Source: [Issue #11 — dark-mode awareness](https://github.com/Texarkanine/jekyll-mermaid-prebuild/issues/11).

1. Add `mermaid_prebuild.prefers_color_scheme` (or equivalent) with values: `light` (default), `dark`, `auto`.
2. **`light`:** Current behavior — single SVG, default Mermaid theme (no `-t dark`).
3. **`dark`:** Single SVG per diagram using Mermaid CLI dark theme (`mmdc -t dark`).
4. **`auto`:** Two SVGs per diagram; naming `{digest}.svg` and `{digest}-dark.svg`; wrapper markup + CSS so only the appropriate asset is used for the user’s preference.
5. Integration validation: devblog uses the local path gem; `bundle exec jekyll build` should exercise the feature.

## Constraints

- Must remain compatible with existing cache layout and `post_write` copy step (extend, do not break single-SVG sites).
- `mmdc` availability and Puppeteer constraints unchanged; dark theme is standard CLI (`-t dark`).
- Cache invalidation: changing `prefers_color_scheme` must not reuse wrong-theme SVGs (digest / cache key must include this setting).

## Acceptance Criteria

1. Documented config key with safe default (`light`).
2. RSpec coverage for configuration parsing, generator/mmdc invocation (theme flag), processor output HTML, and `copy_svgs_to_site` when two files exist.
3. `bundle exec rspec` and `bundle exec rubocop` pass in `jekyll-mermaid-prebuild`.
4. Devblog builds successfully with local gem when feature is enabled.

## Investigation summary (technical)

| Area | Finding |
|------|---------|
| **MmdcWrapper** | `render` builds `["mmdc", "-i", path, "-o", output, "-e", "svg"]` with no theme. Add optional theme (e.g. `default` vs `dark`) and append `-t`, `dark` when needed. `test_render` can stay default or mirror production theme. |
| **Generator** | Single cache path `#{cache_key}.svg`. For `auto`, also `#{cache_key}-dark.svg`. On miss, run `render` once or twice; run **post-processing** on each file. `build_svg_url` / `build_figure_html` must branch on mode. |
| **Processor** | `digest_string_for_cache` should include serialized `prefers_color_scheme` (and any theme-affecting option) so cache busts on config change. `convert_block` / `svgs_to_copy`: for `auto`, merge two entries (`key` → light path, `key-dark` → dark path). |
| **Hooks** | `copy_svgs_to_site` already iterates `cache_key => path`; destination is `#{cache_key}.svg` — works if dark key is literally `abc12345-dark`. |
| **HTML (`auto`)** | ~~Originally considered `<picture>` but that prevents the `<a>` click-through link from matching the displayed variant.~~ **Decision (preflight):** Two `<a>` elements (`.mermaid-diagram__light` visible by default, `.mermaid-diagram__dark` hidden via `style="display:none"`) with inline `<style>` block containing `@media (prefers-color-scheme: dark)` to swap visibility. Each `<a>` wraps its own `<img>` and links to the correct SVG variant. Keep `<figure class="mermaid-diagram">` wrapper; BEM modifiers for styling hooks. |
| **Risk** | Doubles `mmdc` invocations and cache size for `auto`; document cost. |
