# Project Brief: Fix SLOBAC Audit Findings

Fix the 7 test smell findings from `.slobac/2026-05-13T17-16-51/audit.md`:

---

## Rework (PR #30 Review Feedback)

Two regressions were identified in the original fix by @llamapreview[bot] and @coderabbitai[bot]:

1. **`processor_spec.rb` — vacuous guard removed**: The `not_to be_empty` guard was replaced rather than supplemented. Ruby's `[].all? { ... }` is `true`, so shape assertions pass vacuously on `svgs = {}`. Restore `expect(svgs).not_to be_empty` before the shape assertions.
2. **`generator_spec.rb` L333-334 — attribute ordering dependency**: Regexes of the form `class="..."[^>]*href="..."` require `class` before `href`. Replace with lookahead patterns: `/<a(?=[^>]*class="mermaid-diagram__light")(?=[^>]*href="...")[^>]*>/` and similarly for the dark variant.

1. **vacuous-assertion** (4 findings): Strengthen weak assertions in `hooks_spec.rb`, `processor_spec.rb`, and `digest_calculator_spec.rb`
2. **naming-lies** (1 finding): Fix misleading test name in `digest_calculator_spec.rb`
3. **presentation-coupled** (2 findings): Decouple HTML assertions from presentation details in `generator_spec.rb`

All changes are test-only — no production code modifications.
