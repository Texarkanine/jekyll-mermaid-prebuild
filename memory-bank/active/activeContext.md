# Active Context

## Current Task: Issue #11 rework — chart backgrounds + nested `prefers_color_scheme` config

**Phase:** BUILD — COMPLETE

## What Was Done

- Implemented nested-hash-only `prefers_color_scheme` with `mode`, optional `background_color` / `background-color` (`light` / `dark` slots), hyphen aliases at top level (`prefers-color-scheme`) and nested keys.
- Added `chart_background_light` / `chart_background_dark` readers with sanitization (length cap, rejected characters), defaults `white` / `black`.
- Replaced `SvgPostProcessor#ensure_transparent_background` with `#apply_root_svg_background(svg, css_background)`; generator always applies the correct variant background; processor digest includes `bgL` / `bgD`.
- Specs: `configuration_spec`, `svg_post_processor_spec`, `generator_spec`, `processor_spec`; shared `spec/support/configuration_helpers.rb` for Configuration doubles.
- README updated; devblog `_config.yaml` migrated to `prefers_color_scheme: { mode: auto }`.
- Verification: `bundle exec rspec` (158 examples), `bundle exec rubocop`, `bundle exec jekyll build` in devblog.

## Next Step

- Run **`/niko-qa`** on the rework.
