# Task: Fix SLOBAC Audit Rework (PR #30 Feedback)

* Task ID: slobac-audit-fix-rework
* Complexity: Level 2
* Type: Test regression fix

Fix two test regressions introduced by the original SLOBAC audit fix (PR #30), as identified by @llamapreview[bot] and @coderabbitai[bot]:

1. `processor_spec.rb` — shape-only assertions pass vacuously when `svgs = {}`; restore non-empty guard.
2. `generator_spec.rb` — regex patterns encode `class`-before-`href` attribute order; replace with lookahead patterns.

## Test Plan (TDD)

### Behaviors to Verify

- processor "tracks SVGs" guard: `process_content(content_with_mermaid, site)` → `svgs` is non-empty (guard fires if production returns `{}`)
- processor "tracks SVGs" shape: keys match `/\A[a-f0-9]{8}\z/`, values start with `cache_dir` and end with `.svg` (shape still verified on top of guard)
- generator dark mode light anchor: `build_figure_html(url, dark_url: url2)` → HTML contains an `<a>` element that has BOTH `class="mermaid-diagram__light"` AND `href="/assets/svg/abc.svg"`, regardless of attribute order
- generator dark mode dark anchor: same element check for `class="mermaid-diagram__dark"` AND `href="/assets/svg/abc-dark.svg"`
- Edge case — no regression: all 158 existing tests continue to pass

### Test Infrastructure

- Framework: RSpec
- Test location: `spec/jekyll_mermaid_prebuild/`
- Conventions: one file per module, `described_class`, `let` for fixtures, `%r{}` for regexes containing `/`
- New test files: none

## Implementation Plan

1. **Fix processor_spec.rb — restore emptiness guard**
   - Files: `spec/jekyll_mermaid_prebuild/processor_spec.rb`
   - Changes: Insert `expect(svgs).not_to be_empty` on a new line immediately before the `expect(svgs.keys)` assertion (~line 73). The shape assertions remain; the guard prevents them from passing vacuously.

2. **Fix generator_spec.rb — replace ordering-dependent regexes with lookaheads**
   - Files: `spec/jekyll_mermaid_prebuild/generator_spec.rb`
   - Changes: Replace lines 333-334 with lookahead patterns:
     ```ruby
     expect(html).to match(%r{<a(?=[^>]*class="mermaid-diagram__light")(?=[^>]*href="/assets/svg/abc\.svg")[^>]*>})
     expect(html).to match(%r{<a(?=[^>]*class="mermaid-diagram__dark")(?=[^>]*href="/assets/svg/abc-dark\.svg")[^>]*>})
     ```
   - Lookahead `(?=...)` asserts both attributes exist on the same `<a>` element without constraining their order.

3. **Run full test suite**
   - Command: `bundle exec rspec`
   - Expected: 158 examples, 0 failures

## Technology Validation

No new technology - validation not required.

## Dependencies

- None new

## Challenges & Mitigations

- Lookahead regex syntax: Ruby's Oniguruma engine supports `(?=...)` lookaheads — no issues expected.
- RuboCop `Style/RegexpLiteral`: lookahead patterns contain `/` so they must use `%r{}` delimiters — already required by existing conventions and the patterns above already use `%r{}`.

## Status

- [x] Initialization complete
- [x] Test planning complete (TDD)
- [x] Implementation plan complete
- [x] Technology validation complete
- [x] Preflight
- [x] Build
- [ ] QA
