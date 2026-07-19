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

## Rework

### User Story

As a gem maintainer reviewing the mutation-testing draft PR, I want the branch-changed RSpec suite cleaned of SLOBAC-identified test smells so that the new/changed tests assert durable product behavior rather than presentation accidents, checklist fossils, or vacuous oracles.

### Feedback Source

SLOBAC audit report: `.slobac/2026-07-19T16-23-23/audit.md` (2026-07-19; scope `all`; 70 findings / 56 unique locations on `feat/mutation-testing` vs `main`).

### Requirements

1. Investigate and remediate all findings in the audit, following each finding's prescribed remediation (rename, strengthen oracle, structural/DOM assert, drop redundant mocks, strip checklist fossils, split monolithic file, etc.).
2. Keep changes test-only unless a remediation cannot be satisfied without a production change (prefer test-side fixes).
3. Preserve mutation kill discipline from the parent task: no matcher ignores, no SUT stubs, no private-method `send`; remediations must not regress `bundle exec mutant run` from 100%.
4. Keep RSpec green with project coverage target after remediations.

### Constraints

1. Do not weaken kill-sets when renaming or restructuring tests.
2. Prefer Nokogiri (or equivalent) structural asserts for HTML figure/link contracts over raw-string presentation pins, per audit prescriptions and prior SLOBAC fix lessons.
3. Split `processor_spec.rb` by product capability without dropping test count; move shared helpers to support as needed.
4. Stay on `feat/mutation-testing`; do not open a separate branch unless planning discovers a hard reason.

### Acceptance Criteria

1. Every audit finding has a corresponding remediation (or an explicit, documented false-positive deferral with rationale).
2. `bundle exec rspec` green at project coverage target.
3. `bundle exec mutant run` still reports 100% kill.
4. `bundle exec rubocop` clean on touched files.

## Rework (PR #44 feedback)

### User Story

As a gem maintainer reviewing the mutation-testing PR, I want the actionable CodeRabbit hygiene findings addressed so that page error logs are diagnosable and `test_render` does not leave tempfiles on disk.

### Feedback Source

GitHub PR #44 review feedback (LlamaPReview + CodeRabbit), judged 2026-07-19. Full triage in the initiating chat; only **fix in this PR** dispositions are requirements below.

### Requirements

1. In `Hooks.process_site`, include `page.relative_path` in the page-loop rescue error message (parity with the document loop and page success path). Update `hooks_spec.rb` expectations accordingly.
2. In `MmdcWrapper.test_render`, restore tempfile cleanup via `begin`/`ensure` unlinking input and output tempfiles (as on `main` / as `render` already does), without changing status classification behavior.
3. Preserve mutation kill discipline and suite greenness: remediations must not regress `bundle exec mutant run` from 100%, nor `bundle exec rspec` / RuboCop.

### Constraints

1. Do **not** restore a `Hooks.register` compatibility shim or treat its removal as a breaking-change blocker on `0.x`.
2. Do **not** revert `pad_label_content` to index-only replacement or `parse_output_dir` slash-preserving gsub solely for review aesthetics.
3. Do **not** churn `String#lines` → `each_line` unless a real deprecation/warning appears under the project's Ruby.
4. Stay on `feat/mutation-testing`.

### Acceptance Criteria

1. Page error logs include the page path; specs assert the path-inclusive message.
2. `test_render` unlinks its tempfiles in an `ensure` block.
3. `bundle exec rspec` green at project coverage target; `bundle exec rubocop` clean on touched files; `bundle exec mutant run` still 100% kill.
