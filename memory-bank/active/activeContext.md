# Active Context

## Current Task: issue-41-simplecov-skip
**Phase:** BUILD - COMPLETE

## What Was Done
- Added failing contract spec for SimpleCov `skip` vs deprecated `add_filter`
- Migrated `spec/spec_helper.rb` to `skip "spec/"` and `skip "vendor/"`
- Confirmed single test and full suite pass with no SimpleCov deprecation warnings

## Next Step
- Execute Level 1 QA phase (`niko-qa`)
