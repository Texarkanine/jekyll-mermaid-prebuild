# SLOBAC audit report

- **Scope invoked:** all
- **Target suite root:** `spec/`
- **Audit date:** 2026-05-13
- **Suite manifest:** 9 files, 66,053 chars, 158 tests

## Summary

Total findings: 7. Breakdown: `vacuous-assertion` (4), `presentation-coupled` (2), `naming-lies` (1). Orchestration shape: 2 batch assessors ran; input budget was approximately 544,000 source chars per batch (from 272k context-window planning with 60% content allocation) and output budget was 120 tests per batch at `full` richness; output budget was binding and drove sharding. Integrity gate passed cleanly on first pass (`158/158` behavior rows, no retry). Cross-suite assessor ran and consumed richness tier `full`.

No findings for scope `tautology-theatre`.
No findings for scope `deliverable-fossils`.
No findings for scope `implementation-coupled`.
No findings for scope `over-specified-mock`.
No findings for scope `pseudo-tested`.
No findings for scope `semantic-redundancy`.
No findings for scope `conditional-logic`.
No findings for scope `monolithic-test-file`.
No findings for scope `shared-state`.
No findings for scope `wrong-level`.
No findings for scope `mystery-guest`.
No findings for scope `rotten-green`.

## Findings

### 1. `jekyll_mermaid_prebuild/hooks_spec.rb → does nothing` — vacuous-assertion

- **Location:** `jekyll_mermaid_prebuild/hooks_spec.rb` → `does nothing`
- **Smell:** `vacuous-assertion`
- **Rationale:** The test asserts only `not_to raise_error` for the empty-SVG-map case; this matches the weak-oracle signal in the canonical definition because incorrect side effects can still pass. See [vacuous-assertion](https://texarkanine.github.io/slobac/taxonomy/vacuous-assertion/).
- **Prescribed remediation:** Keep no-exception as secondary and add primary assertions for no-op side effects (for example: destination output directory remains absent, no files created, no copy operations invoked).
- **Why this isn't a false positive:** This is not a complete negative-contract verification because the asserted behavior is "does nothing" but no side-effect channel is checked.

### 2. `jekyll_mermaid_prebuild/hooks_spec.rb → does nothing` — vacuous-assertion

- **Location:** `jekyll_mermaid_prebuild/hooks_spec.rb` → `does nothing`
- **Smell:** `vacuous-assertion`
- **Rationale:** The nil-input variant repeats the same weak-oracle pattern (`not_to raise_error` only), so wrong implementations still satisfy the assertion; this is a canonical vacuous-assertion signal. See [vacuous-assertion](https://texarkanine.github.io/slobac/taxonomy/vacuous-assertion/).
- **Prescribed remediation:** Assert that no destination artifacts are created and no copy side effects occur when `svgs` is `nil`, while keeping no-raise only as a secondary guard.
- **Why this isn't a false positive:** The negative-path false-positive guard requires explicit side-effect verification, which is absent here.

### 3. `jekyll_mermaid_prebuild/processor_spec.rb → tracks SVGs for copying` — vacuous-assertion

- **Location:** `jekyll_mermaid_prebuild/processor_spec.rb` → `tracks SVGs for copying`
- **Smell:** `vacuous-assertion`
- **Rationale:** The test only checks that `svgs` is non-empty, matching the canonical "non-empty as sole oracle" signal: malformed keys/paths or partial tracking still pass. See [vacuous-assertion](https://texarkanine.github.io/slobac/taxonomy/vacuous-assertion/).
- **Prescribed remediation:** Assert concrete tracking semantics (expected key shape, expected path suffix/extension, and correspondence to produced figure URL/cache artifact) instead of only non-emptiness.
- **Why this isn't a false positive:** This is not a preliminary type guard followed by stronger checks; non-emptiness is the only oracle.

### 4. `jekyll_mermaid_prebuild/digest_calculator_spec.rb → computes 8-character MD5 digest` — naming-lies

- **Location:** `jekyll_mermaid_prebuild/digest_calculator_spec.rb` → `computes 8-character MD5 digest`
- **Smell:** `naming-lies`
- **Rationale:** The title claims MD5-specific behavior, but assertions validate only generic shape (type, length, lowercase hex) and do not verify an MD5-known output; this matches title-body mismatch signals. See [naming-lies](https://texarkanine.github.io/slobac/taxonomy/naming-lies/).
- **Prescribed remediation:** Either rename to the verified behavior (for example, "returns an 8-character lowercase hex digest") or strengthen assertions to prove MD5-specific output for fixed fixtures.
- **Why this isn't a false positive:** This is not merely underspecified naming; the current title promises an algorithm guarantee the body does not test.

### 5. `jekyll_mermaid_prebuild/digest_calculator_spec.rb → returns a valid digest` — vacuous-assertion

- **Location:** `jekyll_mermaid_prebuild/digest_calculator_spec.rb` → `returns a valid digest`
- **Smell:** `vacuous-assertion`
- **Rationale:** For empty input, the test asserts only String type and length without strict value or stronger format-oracle checks, so many incorrect outputs pass; this is a weak-oracle pattern. See [vacuous-assertion](https://texarkanine.github.io/slobac/taxonomy/vacuous-assertion/).
- **Prescribed remediation:** Strengthen to the strongest available oracle (exact expected digest for empty input, or at least strict format plus deterministic-value checks).
- **Why this isn't a false positive:** The contract under test is a positive return value, not a side-effect-only behavior where minimal assertions could be sufficient.

### 6. `jekyll_mermaid_prebuild/generator_spec.rb → generates figure with linked image` — presentation-coupled

- **Location:** `jekyll_mermaid_prebuild/generator_spec.rb` → `generates figure with linked image`
- **Smell:** `presentation-coupled`
- **Rationale:** Assertions depend on rendered HTML substring fragments rather than semantic structure, matching rendered-string coupling signals that are brittle to cosmetic formatting changes. See [presentation-coupled](https://texarkanine.github.io/slobac/taxonomy/presentation-coupled/).
- **Prescribed remediation:** Parse the fragment and assert structural semantics (figure presence, anchor href, image src/alt) rather than exact serialized string fragments.
- **Why this isn't a false positive:** The tested behavior is HTML structure/linkage semantics, not byte-exact renderer formatting.

### 7. `jekyll_mermaid_prebuild/generator_spec.rb → emits two links and prefers-color-scheme CSS when dark_url is set` — presentation-coupled

- **Location:** `jekyll_mermaid_prebuild/generator_spec.rb` → `emits two links and prefers-color-scheme CSS when dark_url is set`
- **Smell:** `presentation-coupled`
- **Rationale:** The test hard-codes many CSS/HTML snippets and class fragments, matching long rendered-output coupling signals where harmless formatting/order changes can fail tests. See [presentation-coupled](https://texarkanine.github.io/slobac/taxonomy/presentation-coupled/).
- **Prescribed remediation:** Parse and assert semantic invariants (light/dark anchors exist, href/src mappings are correct, dark-mode media rule exists) independent of formatting details.
- **Why this isn't a false positive:** The product contract here is semantic content and linkage, not exact serialized presentation.

## Tests considered but not flagged

None.

## Out-of-scope requests

None.
