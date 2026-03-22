# Progress

## ci-foreignobject-clip-fix

### Complexity Analysis — COMPLETE
- Level 2 determined
- Previous fix (block-edge-label-svg-pad) shipped but clipping returned on CI-built SVGs
- Both environments use bundled Chromium; difference is system font metrics

### Plan — COMPLETE
- Compared CI vs local SVGs: foreignObject widths differ 7–22% per label (non-uniform)
- Fix: `foreignObject{overflow:visible;}` CSS injection, same pattern as centering
- 2 TDD cycles: (1) SvgPostProcessor method + tests, (2) Generator wiring + integration test
- No new dependencies, no config changes, consumer needs no changes

### Preflight — PASS
- Convention, dependency, conflict, completeness all clear
- Advisory: centering + overflow could unify later; not worth scope change now

### Build — COMPLETE
- TDD Cycle 1: `ensure_foreignobject_overflow` + 6 tests → all green
- TDD Cycle 2: Generator wiring + 1 integration test → green
- Full suite: 110/110; RuboCop: 0 offenses
- README + CHANGELOG updated

### QA — PASS
- One trivial fix: module docstring "Two" → "Three" independent fixes
- All checks passed: KISS, DRY, YAGNI, completeness, regression, integrity, documentation

### Plan (Amended) — COMPLETE
- User requested: config restructure into `postprocessing:` group with boolean toggles
- Scope expanded: Configuration, SvgPostProcessor, Generator, Processor, docs
- 5 implementation steps, breaking config change (pre-1.0)

### Build (Amended) — COMPLETE
- Step 1: Configuration rewritten — `postprocessing:` group with `text_centering`, `overflow_protection`, `edge_label_padding`, `emoji_width_compensation`
- Step 2: SvgPostProcessor — removed `BLOCK_ROOT_MARKER`, padding now applies to all diagram types
- Step 3: Generator — conditional postprocessing based on config booleans
- Step 4: Processor — universal cache digest with `edge_pad=` prefix
- Step 5: README, CHANGELOG, devblog `_config.yaml` all updated
- 117/117 tests, 0 RuboCop offenses, 80% coverage

### QA (Amended) — PASS
- One trivial fix: stale context name "block edge label padding" → "edge label padding" in processor_spec
- All checks passed: KISS, DRY, YAGNI, completeness, regression, integrity, documentation
- User confirmed local smoke test — diagrams not ruined

### Reflect — COMPLETE
- All requirements delivered as specified; scope expanded mid-task (R1 only → R1-R4) and handled cleanly
- Key insight: overflow:visible and padding serve complementary roles for different label types (node vs edge)
- Million-dollar question: current design is close to "ideal from scratch"; the breaking rename was the cost of incremental discovery
