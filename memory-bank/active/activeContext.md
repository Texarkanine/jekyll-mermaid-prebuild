# Active Context

## Current Task: mutation-testing
**Phase:** BUILD - COMPLETE (PASS)

## What Was Done
- Mutant + `mutant-rspec` `~> 0.16` scaffold (`config/mutant.yml`, `mutant_setup`, SimpleCov skip, CONTRIBUTING + techContext).
- Converted utility modules `module_function` → `def self.`; Hooks extracted to public methods with thin register bodies.
- Remodeled MmdcWrapper SUT stubs to collaborator stubs; expanded observing specs across Configuration/Processor/Generator/Emoji/Svg/Hooks.
- Kill loop to **100%** mutation coverage (3756 kills, 0 alive). RSpec 407 examples, SimpleCov 100%, RuboCop clean.
- Bucket A cleanups: dropped unused `diagram_type` forwarding through Generator; always delegate edge padding to `SvgPostProcessor.apply`.

## Key Files
- `config/mutant.yml`, `spec/support/mutant_setup.rb`, `spec/spec_helper.rb`
- `CONTRIBUTING.md` (Mutation Testing), `memory-bank/techContext.md`
- Lib + matching specs under `lib/` / `spec/jekyll_mermaid_prebuild/`

## Deviations from Plan
- Removed unused `diagram_type:` kwarg from `Generator#generate` (and processor call site) — Bucket A; parameter was never observed by `post_process_svg`.
- Deleted thin `processor_helpers_spec.rb` (starved Mutant describe-prefix selection); observations live under `processor_spec` method describes.

## Next Step
- QA → Reflect → draft PR (no archive; parent instruction).
