# Current Task: issue-41-simplecov-skip

**Complexity:** Level 1

## Bug Fix

- [x] **What broke:** SimpleCov 1.0 emits `[DEPRECATION]` warnings for `add_filter` on every suite run
- [x] **Root cause:** `spec/spec_helper.rb` still called `add_filter "/spec/"` and `add_filter "/vendor/"` after the #40 simplecov 1.0 bump
- [x] **Fix:** Replaced with `skip "spec/"` and `skip "vendor/"` (SimpleCov 1.0 API; clearer path forms per #41)
- [x] **Files:** `spec/spec_helper.rb`, `spec/jekyll_mermaid_prebuild/simplecov_config_spec.rb`
- [x] **Test:** Contract example asserts helper uses `skip` and not `add_filter`

## QA

- [x] Semantic review PASS — minimal migration, requirements complete, no debris
