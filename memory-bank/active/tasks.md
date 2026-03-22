# Task: Issue #11 rework — chart backgrounds + nested prefers-color-scheme config

* **Task ID:** `issue-11-rework-chart-backgrounds`
* **Complexity:** Level 3
* **Type:** enhancement (pre-PR scope expansion)

Unify light/dark SVG **root background** handling: mmdc always emits `background-color: white` on the root `<svg>`. Today the gem replaces that with `transparent` **only** for dark variants, leaving light opaque white — inconsistent. **New behavior:** replace `white` with **configurable CSS values** for light vs dark variants (defaults **`white`** and **`black`**), injected verbatim into the `style` attribute so authors can use `white`, `black`, `#fff0aa`, `rgb(...)`, etc.

Extend configuration to support a **nested** `prefers_color_scheme` map (`mode` + `background_color`) while keeping the existing **flat** string form (`prefers_color_scheme: auto`) working. Accept hyphenated YAML keys (`prefers-color-scheme`, `background-color`) as aliases when parsing.

## Pinned Info

### Config → post-process flow

```mermaid
flowchart LR
  subgraph C[Configuration]
    M[mode :light|:dark|:auto]
    BL[chart_background_light CSS string]
    BD[chart_background_dark CSS string]
  end
  subgraph G[Generator#post_process_svg]
    L[light variant file]
    D[dark variant file]
  end
  subgraph S[SvgPostProcessor]
    R[replace mmdc white with configured color]
  end
  C --> G
  L --> R
  D --> R
  BL --> R
  BD --> R
```

## Component Analysis

### Affected Components

- **`Configuration`** (`lib/jekyll-mermaid-prebuild/configuration.rb`): Parse `mermaid_prebuild` subsection `prefers_color_scheme` when it is a **Hash** (keys: string or symbol; support `prefers-color-scheme` at read time via a small helper that checks both). Fields: `mode` (required in hash form, default `light` if absent), `background_color` / `background-color` sub-hash with `light` and `dark` string values. **Legacy:** scalar string/symbol `prefers_color_scheme` → mode only, backgrounds default to `white` / `black`. Expose `attr_reader :prefers_color_scheme` (mode), `:chart_background_light`, `:chart_background_dark` (frozen strings after sanitize). Invalid mode → `:light` + warn (existing behavior).
- **`SvgPostProcessor`** (`lib/jekyll-mermaid-prebuild/svg_post_processor.rb`): Replace `ensure_transparent_background` with something like `apply_root_svg_background(svg_string, css_background)` that substitutes mmdc’s `background-color: white` (same regex anchor as today) with `background-color: <value>;` where `<value>` is sanitized. Module doc: remove “transparent for dark only”; describe symmetric light/dark behavior. Keep idempotent behavior when value already matches.
- **`Generator`** (`lib/jekyll-mermaid-prebuild/generator.rb`): In `post_process_svg`, always apply root background substitution for the appropriate variant: **light** SVG → `config.chart_background_light`; **dark** SVG → `config.chart_background_dark`. Remove `dark: true` branch that called transparent-only logic; pass explicit CSS string per variant. Single-theme `light` / `dark` modes use the matching background reader for their one file.
- **`Processor`** (`lib/jekyll-mermaid-prebuild/processor.rb`): Extend `digest_string_for_cache` to include stable serialization of `chart_background_light` and `chart_background_dark` (e.g. `bgL=...&bgD=...` or similar) so cache invalidates when colors change.
- **`README.md`**: Document flat vs nested config, defaults, hyphenated keys, security note (allowed characters / no raw quotes in values).
- **`devblog/_config.yaml`**: Migrate `prefers_color_scheme: auto` to nested form with explicit defaults (optional but recommended in plan step).

### Cross-Module Dependencies

- `Processor` digest → must track `Configuration` background strings.
- `Generator` → `SvgPostProcessor` + `Configuration` readers.

### Boundary Changes

- **Public config surface:** New nested hash accepted for `prefers_color_scheme`; new readers on `Configuration`. No change to `Generator#generate` return type or HTML contract.
- **`SvgPostProcessor`:** Public method rename / replacement — update all call sites and specs.

### Alignment with `systemPatterns.md`

- Config still loaded once in `:post_read`; content-based caching preserved with extended digest inputs.

### Invariants

- Omitting config entirely → same as today for **mode** (`light`); backgrounds default `white` / `black`.
- Nested hash with only `mode` → backgrounds default `white` / `black`.
- Invalid / unsanitizable color strings → fallback to defaults + `Jekyll.logger.warn` (match existing defensive config style).

## Open Questions

None — implementation approach is clear. **Deferred (YAGNI):** If a future mmdc drops `background-color: white` from root `<svg>`, we may need injection instead of substitution; not in scope unless specs fail against a new CLI version.

## Test Plan (TDD)

### Behaviors to Verify

- **Legacy flat config:** `prefers_color_scheme: "auto"` → mode `:auto`, backgrounds `white` / `black`.
- **Nested config:** `prefers_color_scheme: { "mode" => "dark", "background_color" => { "light" => "#fff0aa", "dark" => "black" } }` → parsed mode and strings; hyphenated keys equivalent.
- **Invalid nested mode:** unknown `mode` → `:light` + warn.
- **Sanitization:** value containing `"` or other breakout characters → rejected to default + warn (define rule in implementation).
- **SvgPostProcessor:** `apply_root_svg_background(svg_with_white, "black")` → `background-color: black`; `apply_root_svg_background(svg, "#fff0aa")` → includes hex; no-op safe on repeated apply.
- **Generator:** `:dark` and `auto` dark file get **black** (or configured dark), not `transparent`; light file gets configured light (default white).
- **Processor:** digest changes when `chart_background_light` or `chart_background_dark` changes (same mermaid body).

### Edge Cases

- Empty string for a color → treat as invalid or default (pick one, document, test).
- Very long color string → cap length or reject (document).

### Test Infrastructure

- **Framework:** RSpec (`spec/jekyll_mermaid_prebuild/`).
- **Files to extend:** `configuration_spec.rb`, `svg_post_processor_spec.rb`, `generator_spec.rb`, `processor_spec.rb`.

### Integration Tests

- Manual: `bundle exec jekyll build` in devblog after config migration.

## Implementation Plan

1. **Configuration + tests (TDD)**
   - **Files:** `configuration.rb`, `configuration_spec.rb`
   - **Changes:** Parse hash vs string for `prefers_color_scheme`; key alias helper; defaults; sanitization helper + tests; new readers `chart_background_light`, `chart_background_dark`.

2. **SvgPostProcessor + tests**
   - **Files:** `svg_post_processor.rb`, `svg_post_processor_spec.rb`
   - **Changes:** Implement `apply_root_svg_background`; remove or deprecate `ensure_transparent_background`; update module documentation.

3. **Generator + tests**
   - **Files:** `generator.rb`, `generator_spec.rb`
   - **Changes:** `post_process_svg` passes variant-appropriate background from config; update expectations that currently assert `transparent` for dark.

4. **Processor + tests**
   - **Files:** `processor.rb`, `processor_spec.rb`
   - **Changes:** Append background strings to digest components.

5. **README + devblog**
   - **Files:** `README.md`, `devblog/_config.yaml`
   - **Changes:** Document nested YAML (show both underscore and hyphen key examples); migrate devblog config.

6. **Verification**
   - **Commands:** `bundle exec rspec`, `bundle exec rubocop`; devblog `bundle exec jekyll build`.

## Technology Validation

No new technology — validation not required.

## Challenges & Mitigations

| Challenge | Mitigation |
|-----------|------------|
| XSS / attribute breakout via crafted color | Conservative sanitization; reject values with `"`, `<`, `>`, backticks, semicolon chains; document allowed patterns. |
| Breaking existing sites relying on transparent dark SVGs | Document behavior change in README / changelog; default `black` matches operator request; authors can set `dark: transparent` if they truly want transparency. |
| Digest explosion from whitespace in YAML | `.strip` and normalize before digest. |

## Status

- [x] Component analysis complete
- [x] Open questions resolved
- [x] Test planning complete (TDD)
- [x] Implementation plan complete
- [x] Technology validation complete
- [ ] Preflight
- [ ] Build
- [ ] QA
