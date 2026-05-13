# Project Brief: Fix SLOBAC Audit Findings

Fix the 7 test smell findings from `.slobac/2026-05-13T17-16-51/audit.md`:

1. **vacuous-assertion** (4 findings): Strengthen weak assertions in `hooks_spec.rb`, `processor_spec.rb`, and `digest_calculator_spec.rb`
2. **naming-lies** (1 finding): Fix misleading test name in `digest_calculator_spec.rb`
3. **presentation-coupled** (2 findings): Decouple HTML assertions from presentation details in `generator_spec.rb`

All changes are test-only — no production code modifications.
