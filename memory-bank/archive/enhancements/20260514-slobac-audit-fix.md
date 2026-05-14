---
task_id: slobac-audit-fix
complexity_level: 2
date: 2026-05-14
status: completed
---

# TASK ARCHIVE: Fix SLOBAC Audit Findings

## SUMMARY

Fixed all 7 SLOBAC test-smell findings across 4 spec files (`hooks_spec.rb`, `processor_spec.rb`, `digest_calculator_spec.rb`, `generator_spec.rb`). Changes were test-only assertion improvements: strengthening weak oracles, fixing a naming lie, and decoupling HTML assertions from presentation details. A follow-up rework (3 lines) addressed two regressions identified in PR #30 code review: a removed emptiness guard that allowed vacuous passes, and attribute-ordering constraints baked into regexes.

All 158 tests pass, zero RuboCop offenses.

---

## REQUIREMENTS

### Original SLOBAC Audit Fix (`slobac-audit-fix`, 2026-05-13)

1. **vacuous-assertion** (4 findings) — Strengthen weak assertions in `hooks_spec.rb`, `processor_spec.rb`, and `digest_calculator_spec.rb` where assertions passed trivially on empty/no-op results.
2. **naming-lies** (1 finding) — Fix a misleading test name in `digest_calculator_spec.rb` that described a different behavior than what was being asserted.
3. **presentation-coupled** (2 findings) — Decouple HTML attribute assertions in `generator_spec.rb` from string literals encoding presentation details.
4. All changes must be test-only (no production code modifications).

### Rework (`slobac-audit-fix-rework`, 2026-05-14)

Per PR #30 review from @llamapreview[bot] and @coderabbitai[bot]:

1. **`processor_spec.rb` — vacuous guard restore**: The `not_to be_empty` guard was removed and replaced rather than supplemented by shape assertions. Ruby's `[].all? { ... }` is `true`, so the shape checks passed silently on `svgs = {}`. Restore `expect(svgs).not_to be_empty` before the shape assertions.
2. **`generator_spec.rb` L333-334 — attribute ordering dependency**: Regex patterns of the form `class="..."[^>]*href="..."` encode attribute order. Replace with lookahead patterns that assert both attributes exist on the same element regardless of order.

---

## IMPLEMENTATION

### Original Fix (2026-05-13)

| File | Finding Type | Change |
|---|---|---|
| `spec/jekyll_mermaid_prebuild/hooks_spec.rb` | vacuous-assertion | Added existence/non-empty guards before shape assertions on hook-registered callback collections |
| `spec/jekyll_mermaid_prebuild/processor_spec.rb` | vacuous-assertion | Added `not_to be_empty` guard before SHA/path shape assertions on `svgs` hash |
| `spec/jekyll_mermaid_prebuild/digest_calculator_spec.rb` | vacuous-assertion, naming-lies | Replaced `not_to be_nil` with exact MD5 digest value assertions; renamed test to accurately describe its verified behavior |
| `spec/jekyll_mermaid_prebuild/generator_spec.rb` | presentation-coupled | Replaced exact substring HTML assertions with regex-based structural assertions tolerant of whitespace and minor output variation |

**Key design decision:** Used regex-based structural matching for HTML assertions (not REXML) — more robust with HTML fragments and simpler to read. Identified and applied during preflight.

### Rework (2026-05-14)

| File | Change |
|---|---|
| `spec/jekyll_mermaid_prebuild/processor_spec.rb` | Restored `expect(svgs).not_to be_empty` guard (1 line added, ~L73) |
| `spec/jekyll_mermaid_prebuild/generator_spec.rb` | Replaced ordering-sensitive regexes on L333-334 with lookahead patterns (2 lines changed) |

**Lookahead pattern applied:**

```ruby
expect(html).to match(%r{<a(?=[^>]*class="mermaid-diagram__light")(?=[^>]*href="/assets/svg/abc\.svg")[^>]*>})
expect(html).to match(%r{<a(?=[^>]*class="mermaid-diagram__dark")(?=[^>]*href="/assets/svg/abc-dark\.svg")[^>]*>})
```

The "split into separate checks" approach (suggested by both bots) was rejected — it would lose the co-location guarantee (that both attributes exist on the *same* element).

---

## TESTING

- **Full RSpec suite:** `bundle exec rspec` — 158 examples, 0 failures (run after each phase: original build, rework build).
- **RuboCop:** 0 offenses — `%r{}` delimiters required for patterns containing `/` (consistent with project conventions).
- **`/niko-qa` semantic review:** Passed both rounds. Checked KISS, DRY, YAGNI, completeness, regression safety, integrity, and documentation.

---

## LESSONS LEARNED

- **`[].all?` vacuous truth is a guard-removal trap**: When upgrading a blunt assertion (`not_to be_empty`) to structural shape assertions, Ruby's `Enumerable#all?` on an empty collection always returns `true`. The guard is *not* subsumed by shape checks — it must be kept alongside them. This is worth checking any time a structural assertion replaces an existence check.
- **Lookahead regexes for order-independent element attribute checks**: `/<a(?=[^>]*attr1)(?=[^>]*attr2)[^>]*>/` is the correct pattern when both attributes must be present on the same element without constraining their relative order.
- **Plan-time preflight caught REXML → regex switch cleanly** — the original test plan initially proposed REXML for HTML structural checks, but preflight identified regex as simpler and more robust before any code was written.

---

## PROCESS IMPROVEMENTS

- When upgrading assertions from existence checks to structural/shape checks, **explicitly verify whether the new assertions are vacuous on the empty case** before considering the refactor complete. This would have prevented the rework entirely.
- In future test-improvement tasks: ask "does this structural assertion subsume the original check, or does vacuous truth create a gap?"

---

## TECHNICAL IMPROVEMENTS

- A custom RSpec matcher for order-independent HTML attribute assertions (e.g., `have_element_with_attrs`) could be worth adding if more HTML-generating components are introduced. The lookahead regex pattern works but is verbose and easy to misread.

---

## NEXT STEPS

None. Work is complete. PR #30 is ready for final review.
