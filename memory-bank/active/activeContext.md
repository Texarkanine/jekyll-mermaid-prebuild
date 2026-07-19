# Active Context

## Current Task: mutation-testing-slobac-rework
**Phase:** BUILD - COMPLETE

## What Was Done
- Remediated SLOBAC audit findings across branch-changed specs; RSpec 407/0, SimpleCov 100%, RuboCop clean, Mutant 100%.
- Added `spec/support/html_fragment_helpers.rb` (REXML structural figure asserts).
- Split `processor_spec.rb` → `processor_process_content_spec.rb`, `processor_convert_and_digest_spec.rb`, `processor_fence_parsing_spec.rb` (94 examples preserved).
- Small lib tweaks for kill/SLOBAC alignment: documented `pad_label_content` identity return; simplified `MmdcWrapper.render` invalid-theme message (Bucket A).

## Files Modified
- `spec/support/html_fragment_helpers.rb` (new)
- `spec/jekyll_mermaid_prebuild/{configuration,emoji_compensator,generator,hooks,mmdc_wrapper}_spec.rb`
- `spec/jekyll_mermaid_prebuild/processor_{process_content,convert_and_digest,fence_parsing}_spec.rb` (split; `processor_spec.rb` removed)
- `lib/jekyll-mermaid-prebuild/{emoji_compensator,mmdc_wrapper}.rb`

## Key Decisions
- REXML + void-tag normalize instead of adding nokogiri.
- `#43`: keep `equal` after documenting same-object return on `pad_label_content` (Mutant + SLOBAC “document if identity matters”).
- `#60`: drop allowed-list sentence from production error (Bucket A) rather than re-pin presentation.

## Next Step
- QA review (automatic per L2 workflow).
