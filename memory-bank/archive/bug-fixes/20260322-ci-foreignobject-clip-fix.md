---
task_id: ci-foreignobject-clip-fix
complexity_level: 2
date: 2026-03-22
status: completed
---

# TASK ARCHIVE: CI foreignObject clip fix + postprocessing config restructure

## SUMMARY

Fixed cross-browser SVG label clipping when mmdc output is built in CI (e.g. GitHub Actions) vs local: injected `foreignObject { overflow: visible }` for node labels, kept opt-in edge-label width padding (renamed and generalized), and grouped all cross-browser workarounds under `mermaid_prebuild.postprocessing` with per-flag toggles (`text_centering`, `overflow_protection`, `edge_label_padding`, `emoji_width_compensation`). Breaking config change (pre-1.0). Follow-up: cache digest now includes `text_centering` / `overflow_protection` when disabled so toggling those flags cannot serve stale cached SVGs.

## REQUIREMENTS

- **R1:** Node label clipping — overflow protection via CSS injection.
- **R2:** Edge label clipping — `edge_label_padding` (formerly block-only `block_edge_label_padding`), all diagram types.
- **R3:** Config restructure — `postprocessing:` nested group; emoji compensation moved under it.
- **R4:** Each postprocessing fix individually disableable.
- **Constraints:** Latest mermaid-cli, bundled Chromium, no brittle hacks.
- **Acceptance:** Labels render without clipping; docs and tests updated; suite and RuboCop clean.

## IMPLEMENTATION

- **`lib/jekyll-mermaid-prebuild/svg_post_processor.rb`** — `ensure_foreignobject_overflow`; removed `BLOCK_ROOT_MARKER` from `.apply` so edge-label padding applies to any diagram with matching `edgeLabel` markup.
- **`lib/jekyll-mermaid-prebuild/generator.rb`** — `post_process_svg` applies centering/overflow/padding per config.
- **`lib/jekyll-mermaid-prebuild/configuration.rb`** — reads `postprocessing` sub-hash with defaults.
- **`lib/jekyll-mermaid-prebuild/processor.rb`** — `digest_string_for_cache` mixes in `edge_pad=` when padding is positive; later extended to append `tc=false` / `op=false` when booleans are off so cache keys stay coherent with `Generator` short-circuit on cache hit.
- **Specs** — `configuration_spec`, `generator_spec`, `processor_spec`, `svg_post_processor_spec` updated; 119 examples after digest fix.
- **Docs** — `README.md`, `CHANGELOG.md` (breaking change noted).
- **Consumer** — devblog `_config.yaml` migrated to `postprocessing:` (separate repo commit as applicable).

## TESTING

- RSpec full suite (119 examples, 0 failures after cache-digest follow-up).
- RuboCop clean.
- `/niko-qa` semantic review PASS; trivial fixes only (docstring, stale spec context name).
- User smoke-tested local Jekyll build (diagrams OK).

## LESSONS LEARNED

*(Inlined from reflection.)*

- **Overflow:visible vs padding** — Complementary, not redundant. Node labels sit in SVG shapes (background = shape); overflow visible is safe. Edge labels use foreignObject backgrounds; padding widens the box so text does not spill past the rect.
- **Scope expansion** — Original overflow-only fix was correct; user testing revealed node clipping with padding-only and drove config restructure. Re-planning after a QA-clean baseline kept risk low.
- **Cache keys** — Any config that changes `post_process_svg` output must affect the digest, or `File.exist?` cache hits skip reprocessing and serve stale SVGs. Padding was in the digest first; booleans were added in a follow-up (CodeRabbit review).

## PROCESS IMPROVEMENTS

- When adding toggleable build-time transforms behind a file cache, explicitly list “digest inputs” in the plan (all flags that affect post-mmdc SVG bytes).

## TECHNICAL IMPROVEMENTS

- Optional future: unify the three CSS-injection helpers in `SvgPostProcessor` if Mermaid output shape stabilizes (advisory from earlier preflight; deferred as YAGNI).

## NEXT STEPS

- None for this task. Release/version bump and consumer Gemfile updates are normal product follow-through outside this archive.
