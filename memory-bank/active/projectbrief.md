# Project Brief

## User Story

As a gem maintainer in the Texarkanine Jekyll plugin family, I want Mutant + `mutant-rspec` wired into jekyll-mermaid-prebuild with the same discipline as jekyll-auto-thumbnails, so that mutation coverage can be driven to 100% and kept green without ignore-list cheats.

## Use-Case(s)

### Use-Case 1

A developer runs `bundle exec mutant test` / `bundle exec mutant run` locally and gets a green, fully-killing mutation report against `JekyllMermaidPrebuild*`.

### Use-Case 2

Contributors and agents follow CONTRIBUTING (and memory-bank techContext) for A/B survivor buckets and hard constraints (no matcher ignores, no SUT stubs, no private-method `send`).

## Requirements

1. Add Mutant using RSpec integration (`mutant-rspec` / `mutant` `~> 0.16`), mirroring jekyll-auto-thumbnails.
2. Add `config/mutant.yml`, `spec/support/mutant_setup.rb`, and SimpleCov skip when `defined?(Mutant)` in `spec/spec_helper.rb`.
3. Document Mutation Testing discipline in `CONTRIBUTING.md` (A/B buckets, no ignore cheats, no SUT stubs).
4. Update `memory-bank/techContext.md` Testing Process for Mutant CLI.
5. Drive mutation coverage to 100% (`bundle exec mutant run` green) while keeping line coverage / RSpec green.
6. Deliver on branch `feat/mutation-testing` as a **draft** PR. CI Mutant job is out of scope.

## Constraints

1. No matcher ignores; no `coverage_criteria:` tweaks.
2. No `send` / `__send__` for private methods just to satisfy Mutant.
3. No stubbing or mocking the system under test (stub collaborators instead).
4. Prefer `def self.` over `module_function` if Mutant invents unused instance subjects.
5. Work only in this gem (read-only reference to jekyll-auto-thumbnails).
6. Do not run `/niko-archive`; stop after REFLECT COMPLETE.

## Acceptance Criteria

1. `bundle exec rspec` (project suite) green with coverage at project target.
2. `bundle exec mutant run` reports 100% kill.
3. Config/docs match the auto-thumbnails reference pattern.
4. Draft PR exists on `feat/mutation-testing` for operator review.
