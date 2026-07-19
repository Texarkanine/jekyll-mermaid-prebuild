# Task: mutation-testing-pr44-feedback

* Task ID: mutation-testing-pr44-feedback
* Complexity: Level 2
* Type: bug fix / hygiene (PR review remediations)

Address two judged "fix in this PR" items from PR #44: path-inclusive page error logging in `Hooks.process_site`, and restore tempfile cleanup in `MmdcWrapper.test_render`.

## Test Plan (TDD)

### Behaviors to Verify

- Page process error logging: when `process_content` raises for a page → logger receives `Error processing #{page.relative_path}: …` (not pathless `Error processing page: …`).
- Page process error logging (nil path edge): when `page.relative_path` is nil → message still includes a path slot (current suite already covers a nil-path matcher; keep path-inclusive form).
- `test_render` tempfile cleanup: after `test_render` returns (success or classified failure) → both Tempfile paths are unlinked / do not remain on disk.
- Regression: document-loop error logging and `test_render` status symbols (`:ok` / `:puppeteer_error` / `:unknown_error`) unchanged.

### Test Infrastructure

- Framework: RSpec + SimpleCov; Mutant for kill gate
- Test location: `spec/jekyll_mermaid_prebuild/`
- Conventions: describe public methods (`.process_site`, `.test_render`); prefer product-observable asserts; no SUT stubs
- New test files: none

## Implementation Plan

1. **Failing/updated hooks specs for path-inclusive page errors**
   - Files: `spec/jekyll_mermaid_prebuild/hooks_spec.rb`
   - Changes: Update expectations that currently assert `"Error processing page: …"` to assert `"Error processing #{relative_path}: …"` (and the nil-path matcher).

2. **Implement page error log parity**
   - Files: `lib/jekyll-mermaid-prebuild/hooks.rb`
   - Changes: In `process_site` page-loop rescue, use `page.relative_path` like the document loop.

3. **Failing/updated mmdc_wrapper specs for tempfile cleanup**
   - Files: `spec/jekyll_mermaid_prebuild/mmdc_wrapper_spec.rb`
   - Changes: Add/extend `.test_render` example(s) that spy or observe Tempfile `#unlink` (or assert paths gone after call) without stubbing `MmdcWrapper` itself.

4. **Restore `test_render` ensure/unlink**
   - Files: `lib/jekyll-mermaid-prebuild/mmdc_wrapper.rb`
   - Changes: Wrap body in `begin`/`ensure`; `unlink` input and output tempfiles; preserve status classification.

5. **Verification gates**
   - Files: touched lib + specs only
   - Changes: `bundle exec rspec`, `bundle exec rubocop` on touched paths, `bundle exec mutant run` still 100%.

## Technology Validation

No new technology - validation not required

## Dependencies

- Existing RSpec suite and Mutant harness on `feat/mutation-testing`
- No gem / CI changes

## Challenges & Mitigations

- **Mutant survivors from tempfile ensure branches**: Prefer real unlink observability (or `Tempfile` collaborator injection already used in suite) over broad stubs; if `ensure` invents hard-to-kill paths, assert both success and error classification paths exercise cleanup.
- **Spec already pins pathless page error string**: Update those oracles in the same TDD cycle as the lib change so the suite encodes the new contract.

## Pre-Mortem

- **Scope creep into dismissed LlamaPReview items**: Plan response — brief + this checklist name only the two dispositions; do not touch `pad_label_content` / `parse_output_dir` / `Hooks.register`.
- **Tempfile cleanup test flakes on Windows-style close locking**: already covered by Challenge 1 — keep close-before-mmdc order from current code; only add unlink in ensure.

## Status

- [x] Initialization complete
- [x] Test planning complete (TDD)
- [x] Implementation plan complete
- [x] Technology validation complete
- [x] Pre-Mortem complete
- [x] Preflight
- [ ] Build
- [ ] QA
