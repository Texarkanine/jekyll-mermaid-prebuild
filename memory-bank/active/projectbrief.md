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

## Rework (2026-03-22 — pre-PR)

### User story (addendum)

As a site author, I want **consistent opaque chart backgrounds** for light and dark SVG variants and **configurable CSS background values** so diagrams match my theme without one variant being transparent and the other not.

### Requirements (addendum)

1. **Background behavior:** Stop replacing dark-variant root SVG backgrounds with `transparent`. Apply the **configured dark background** (default `black`) so dark charts match a dark UI. Light variant uses the **configured light background** (default `white`). Both paths should use the same mechanism (replace mmdc’s `background-color: white` on the root `<svg>` with the configured value).
2. **Config shape:** Support a nested mapping as the **only** form (flat string form dropped — feature hasn't shipped, no backward-compat needed), for example:

   ```yaml
   mermaid_prebuild:
     prefers_color_scheme:
       mode: auto   # light | dark | auto
       background_color:
         light: white
         dark: black
   ```

   - Values are **CSS fragments** inserted into the SVG `style` attribute (e.g. `#fff0aa`, `rgb(0,0,0)`, named colors). Document safe usage; validate/sanitize to avoid breaking out of the attribute.
   - **YAML key aliases:** Accept hyphenated keys (`prefers-color-scheme`, `background-color`) as equivalents when reading from `site.config`, matching common `_config.yml` style. Top-level key remains `mermaid_prebuild` (existing sites); optional: also accept `mermaid-prebuild` if the same hash is duplicated under that key (low priority if Jekyll never surfaces it).
3. **Cache / digest:** Include serialized background settings in the digest input so changing colors invalidates cached SVGs.
4. **Tests & docs:** Update `SvgPostProcessor` / `Generator` specs and README for the new defaults and nested config. Devblog `_config.yaml` updated to the new shape when the build lands.

### Acceptance criteria (addendum)

- RSpec covers nested config parsing, legacy flat string still works, invalid colors warned or rejected with safe fallback.
- Dark + `auto` dark branch produce root SVG background `black` by default (not `transparent`).
- README documents defaults and nested YAML with examples.
