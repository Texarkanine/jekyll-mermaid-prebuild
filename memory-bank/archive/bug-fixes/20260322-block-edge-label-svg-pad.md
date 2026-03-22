---
task_id: block-edge-label-svg-pad
complexity_level: 2
date: 2026-03-22
status: completed
---

# TASK ARCHIVE: Block diagram edge label clipping & cross-browser SVG fixes

## SUMMARY

Delivered SVG post-processing in **jekyll-mermaid-prebuild** for Mermaid **block** diagrams: optional `block_edge_label_padding` widens edge-label `<foreignObject>` widths after mmdc; unconditional `SvgPostProcessor.ensure_text_centering` injects CSS so HTML inside `<foreignObject>` centers (`display:block !important;text-align:center`). Cache digests for block diagrams include padding when positive. **Devblog CI** was aligned to Puppeteer’s bundled Chromium by removing `PUPPETEER_SKIP_CHROMIUM_DOWNLOAD` / `PUPPETEER_EXECUTABLE_PATH` overrides in `deploy.yaml` (consumer repo). Generator uses a single read → `ensure_text_centering` → optional `apply(padding:)` → single conditional `File.write` for efficiency. README anchor for the options table points at `#cross-browser-text-rendering-fixes`.

## REQUIREMENTS

- **User story:** Block diagram edge labels (e.g. quoted strings on edges) must not clip in prebuilt SVGs when viewed via `<img>`.
- **Investigation:** Explain why block edge labels clip vs flowcharts; decide gem vs upstream.
- **Implementation:** Narrowly scoped post-process + tests + docs; TDD; RSpec + RuboCop green.
- **Acceptance:** Labels like `last touchpoint` / `refined` render without right-edge clipping on Linux/WSL mmdc; non-block types unchanged unless opted in; README/CHANGELOG; tests pass.

**Added during /refresh:** Correct root cause narrative (font-metrics / measurement mismatch, not stroke overhang); CI Chrome vs bundled Chromium; text centering for left-shifted labels after mmdc/Chromium updates.

## IMPLEMENTATION

- **`lib/jekyll-mermaid-prebuild/configuration.rb`** — `block_edge_label_padding` (numeric; `0` / `false` / omit = off).
- **`lib/jekyll-mermaid-prebuild/svg_post_processor.rb`** — `apply(svg_string, padding:)` (regex on `<g class="edgeLabel">…<foreignObject` width); `ensure_text_centering` injects minified rule before `</style>`; idempotent via constant substring check.
- **`lib/jekyll-mermaid-prebuild/processor.rb`** — `digest_string_for_cache` appends `\0block_edge_pad=#{pad}` for `diagram_type == "block"` and positive padding.
- **`lib/jekyll-mermaid-prebuild/generator.rb`** — After `MmdcWrapper.render`, `post_process_svg` reads once, applies centering then optional padding, writes if changed.
- **`lib/jekyll-mermaid-prebuild.rb`** — require post-processor module.
- **Specs:** `configuration_spec`, `svg_post_processor_spec`, `processor_spec`, `generator_spec`.
- **Docs:** `README.md` (cross-browser section, CI tip), `CHANGELOG.md`.

**Consumer (devblog):** `.github/workflows/deploy.yaml` — remove Puppeteer skip + system Chrome path so mmdc uses bundled Chromium.

**Design choices:** No Nokogiri (regex on deterministic mmdc output); padding only for block + positive config; centering always on.

## TESTING

- Full RSpec suite (103 examples at archive time); RuboCop clean.
- `/niko-qa` PASS; smoke tests on devblog SVGs (`e412bbe8.svg`, `c9949931.svg`).
- Manual: user verified clipping/centering in browser; empirical SVG edits disproved stroke-only hypothesis.

## LESSONS LEARNED

*(Inlined from reflection — ephemeral reflection file removed.)*

- **`display:table-cell` inside `<foreignObject>`:** Anonymous table shrink-wraps; `text-align:center` and `width:100%` on the cell don’t center content in a wider foreignObject. Fix: override to `display:block !important` so the div fills the foreignObject, then `text-align:center`.
- **CI Chrome vs Puppeteer’s Chromium:** System Chrome on GitHub Actions measured text ~11–16% narrower than bundled Chromium in this project’s scenario — major source of deployed vs local mismatch. Prefer default Puppeteer Chromium unless you have a strong reason not to.
- **Hypothesis testing:** User removed stroke from a clipped SVG and clipping persisted — proved stroke-overhang was not the root cause; true issue was zero-padding foreignObject + cross-context measurement mismatch (and CI engine mismatch).
- **SVG in `<img>`:** Hard to iterate CSS via DevTools; prototype on a standalone SVG in a tab when possible.

## PROCESS IMPROVEMENTS

- Preflight caught adding Nokogiri early — saved dependency churn.
- For visual/CSS fixes, pair automated tests with real-site smoke checks; string-level tests won’t catch layout.

## TECHNICAL IMPROVEMENTS

- Optional: upstream Mermaid/mmdc could improve foreignObject sizing and HTML/CSS for labels so consumers need less patching.
- Digest normalization for `4` vs `4.0` was intentionally not implemented — YAML types differ; low practical cost.

## NEXT STEPS

- **Publish** a new **jekyll-mermaid-prebuild** gem version when ready; point devblog `Gemfile` at the release (not a local path).
- **Commit** devblog `deploy.yaml` (and any gem version bump) in the consumer repo if not already on `main`.
- **Optional:** Add a focused processor spec that asserts `diagram_type:` is forwarded to `Generator#generate` if contract tests are desired (deferred).

---

## REFLECTION RECORD (inlined)

**Summary:** Two post-process paths (centering + optional padding) plus CI alignment to bundled Chromium addressed clipping and left-shifted labels.

**Requirements vs outcome:** Original acceptance criteria met; CI workflow change and unconditional centering added post-plan.

**Plan accuracy:** Original plan held for padding; refresh corrected narrative and uncovered CI + `table-cell` centering work.

**Build & QA:** Padding build straightforward; centering needed CSS iterations; QA caught trivial `private` visibility once.

**Insights — Technical:** `table-cell` + foreignObject; CI Chrome vs bundled Chromium.

**Insights — Process:** Empirical disproof of wrong hypothesis; slow iteration for `<img>` SVG.

**Million-dollar question:** A small “SVG normalization” pipeline (centering + optional tight-container padding) matches what shipped; split methods remain clearer than one monolithic normalizer.
