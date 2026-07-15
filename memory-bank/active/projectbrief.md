# Project Brief

## User Story

As a maintainer, I want SimpleCov config to use `skip` instead of deprecated `add_filter` so that the test suite no longer emits SimpleCov 1.0 deprecation warnings.

## Use-Case(s)

### Use-Case 1

Run the RSpec suite and observe no `[DEPRECATION]` warnings from SimpleCov about `add_filter`.

## Requirements

1. In `spec/spec_helper.rb`, replace `add_filter "/spec/"` and `add_filter "/vendor/"` with `skip` (same path strings, or clearer `spec/` / `vendor/` forms if preferred by SimpleCov 1.0 style).
2. Work on a feature branch based on up-to-date `main`.
3. Open a GitHub pull request that fixes #41 when done.

## Constraints

1. SimpleCov / simplecov-cobertura version bump already landed in #40 — do not redo that work.
2. Follow TDD and Level 1 Niko workflow.
3. Use `git --no-pager` and `git commit --no-gpg-sign`; conventional commits referencing `#41`.
4. Do not force-push; do not amend unless amend rules are met.

## Acceptance Criteria

1. `spec/spec_helper.rb` uses `skip` instead of `add_filter` for both filters.
2. Test suite passes without SimpleCov `add_filter` deprecation warnings.
3. Pull request is open linking/fixing #41.
