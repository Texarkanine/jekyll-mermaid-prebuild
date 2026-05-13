# Task: Fix SLOBAC Audit Findings

* Task ID: slobac-audit-fix
* Complexity: Level 2
* Type: Test quality improvement

Fix 7 test smell findings per SLOBAC audit prescribed remediations. All changes are test-only.

## Test Plan (TDD)

### Behaviors to Verify

Since this is a test-quality task (improving existing tests), the "tests" ARE the deliverable. Verification is that all existing specs still pass after modifications and the assertions are stronger.

- hooks_spec empty SVGs: `copy_svgs_to_site({})` → no destination directory created, no files written
- hooks_spec nil SVGs: `copy_svgs_to_site(nil)` → no destination directory created, no files written
- processor_spec tracks SVGs: `process_content(mermaid)` → svgs hash contains expected key shape (`/[a-f0-9]{8}/`) and path suffix (`.svg`)
- digest_calculator_spec naming: test name matches actual verified behavior (rename or strengthen)
- digest_calculator_spec empty input: assert exact known MD5 digest for empty string
- generator_spec figure HTML: assert structural semantics (element presence, attributes) not string fragments
- generator_spec dark mode HTML: assert structural semantics (anchors, classes, media rule) not string fragments

### Test Infrastructure

- Framework: RSpec
- Test location: `spec/jekyll_mermaid_prebuild/`
- Conventions: one file per module, `described_class`, `let` for fixtures
- New test files: none
- HTML parsing: REXML (Ruby stdlib, available via Jekyll's transitive dependency)

## Implementation Plan

1. **Fix hooks_spec.rb vacuous assertions (findings 1 & 2)**
   - Files: `spec/jekyll_mermaid_prebuild/hooks_spec.rb`
   - Changes: Replace `not_to raise_error` with assertions that the destination directory does NOT exist and no files were created

2. **Fix processor_spec.rb vacuous assertion (finding 3)**
   - Files: `spec/jekyll_mermaid_prebuild/processor_spec.rb`
   - Changes: Replace `not_to be_empty` with assertions on key shape (`/^[a-f0-9]{8}$/`) and path values (end with `.svg`, contain cache_dir)

3. **Fix digest_calculator_spec.rb naming-lies (finding 4)**
   - Files: `spec/jekyll_mermaid_prebuild/digest_calculator_spec.rb`
   - Changes: Add assertion that verifies MD5-specific output for the known input `"graph TD\nA-->B"` (expected: `Digest::MD5.hexdigest("graph TD\nA-->B")[0,8]`)

4. **Fix digest_calculator_spec.rb vacuous assertion (finding 5)**
   - Files: `spec/jekyll_mermaid_prebuild/digest_calculator_spec.rb`
   - Changes: Assert exact expected digest for empty string (`Digest::MD5.hexdigest("")[0,8]` = `"d41d8cd9"`)

5. **Fix generator_spec.rb presentation-coupled assertions (findings 6 & 7)**
   - Files: `spec/jekyll_mermaid_prebuild/generator_spec.rb`
   - Changes: Parse HTML with REXML and assert semantic structure (element presence, href/src attributes, class names, media rule presence) instead of substring matching

## Technology Validation

No new technology - validation not required. REXML is Ruby stdlib.

## Dependencies

- None new

## Challenges & Mitigations

- REXML parsing HTML fragments: HTML from `build_figure_html` is well-formed XHTML-like output; REXML should handle it. If not, fall back to regex matching on attributes rather than full substrings.
- Maintaining test readability: use helper methods or clear variable names to keep parsed-DOM assertions readable.

## Status

- [x] Initialization complete
- [x] Test planning complete (TDD)
- [x] Implementation plan complete
- [x] Technology validation complete
- [ ] Preflight
- [ ] Build
- [ ] QA
