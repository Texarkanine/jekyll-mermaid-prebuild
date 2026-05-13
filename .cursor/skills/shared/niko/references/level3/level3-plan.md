# Plan Phase - Level 3: Intermediate Feature

This document creates a concrete implementation plan for a Level 3 (Intermediate Feature) task. It includes component analysis, cross-module dependency mapping, and open question identification. If any aspect of the design is genuinely ambiguous, this phase flags it as an open question and invokes the `niko-creative` phase to resolve it before finalizing the plan.

## Step 1: Load Memory Bank Files

Read:
- `memory-bank/active/tasks.md`
- `memory-bank/active/projectbrief.md`
- `memory-bank/systemPatterns.md`
- `memory-bank/active/activeContext.md`
- `memory-bank/techContext.md`

Also read any existing creative phase documents in `memory-bank/active/creative/` - these contain decisions from previous creative phase invocations on this task (if the plan phase has already looped through creative once or more).

## Step 2: Verify Prerequisites

- Confirm `memory-bank/active/tasks.md` exists (stub created by `/niko`)
- Confirm `memory-bank/active/progress.md` exists and indicates Level 3
- Confirm `memory-bank/active/projectbrief.md` exists with the user story and requirements

🚨 If any prerequisites are missing, STOP and inform the operator (see "Output to Operator" below).

## Step 3: Component Analysis

L3 tasks touch multiple components or modules. Map the scope:
- **Affected components**: List every module, service, or subsystem this feature touches. For each, note what changes are needed and what its current responsibilities are.
- **Cross-module dependencies**: Identify how the affected components interact. Which components call which? What data flows between them? Are there shared state or concurrency concerns?
- **Boundary changes**: Will this feature change any component's public interface, API contract, or data schema? Flag these - they have higher blast radius and may need creative phase exploration.
- **Cross-reference against `memory-bank/systemPatterns.md`** to confirm the planned touchpoints align with established patterns. If they don't, that's an open question.
- **Invariants & Constraints:** List the invariants and constraints that the correct solution must preserve.

## Step 4: Identify Open Questions

Scan the requirements, component analysis, and your understanding of the implementation for genuine ambiguity. An open question exists when:
- You cannot confidently describe HOW to implement something without exploring alternatives
- Multiple viable approaches exist and the right choice depends on tradeoffs that need evaluation
- The requirements are ambiguous enough that two engineers might build different things

For each open question, document in `memory-bank/active/tasks.md`:
- A brief problem statement describing what needs to be decided
- Why it's ambiguous (what makes multiple approaches viable)
- Any constraints or requirements the decision must satisfy

**If there are no open questions**, skip to Step 6. Not every L3 task has ambiguity - some are complex but clear.

**If there are open questions**, proceed to Step 5.

## Step 5: Invoke Creative Phase

For each open question identified in Step 4, invoke the `niko-creative` skill.
The creative phase will:
- Route to the appropriate creative phase type (algorithm, architecture, uiux, or generic)
- Explore options and evaluate tradeoffs
- Return either a resolved decision (high confidence) or unresolved findings (low confidence)

**High confidence**: Integrate the decision into the plan. The creative document in `memory-bank/active/creative/` is the record. Continue to the next open question or to Step 6 if all open questions have been investigated..

**Low confidence**: The creative phase will surface findings to the operator and stop. When the operator provides direction, they will re-enter this plan phase by invoking the `niko-plan` skill. The creative document will contain the operator's decision, and Step 1 will pick it up.

Process open questions one at a time. After each creative phase completes, reassess: did the decision eliminate or create other open questions? Adjust the list before proceeding to the next one.

## Step 6: Test Planning (TDD)

- **Behavior Identification**: Enumerate the specific, observable behaviors this feature must exhibit when complete. Frame as `[input/action] → [expected outcome]`. For L3, this includes behaviors at component boundaries, not just the feature's public interface.
- **Edge Cases**: Invalid input, boundary values, empty/null states, interaction with existing behavior, cross-component failure modes, concurrency edge cases if applicable.
- **Test Infrastructure Survey**: Locate the project's existing test framework, runner, conventions, and directory structure. New tests must conform. If no test infrastructure exists, flag as a blocking question.
- **Test File Mapping**: For each behavior, specify the exact test file and describe the test case. Group by component/module. Distinguish unit tests (within a component) from integration tests (across components).

## Step 7: Create Implementation Plan

- Produce an **ordered** list of implementation steps, grouped by component/module.
- Each step names concrete files and functions.
- Each step maps to roughly one TDD cycle: write failing test → implement to pass → refactor.
- Steps must be sequenced so that each builds on the last. For multi-component features, start with the component that has the fewest dependencies and work outward.
- Document the specific changes per file: new functions, modified signatures, added exports, config changes.
- Include documentation update steps for any project documentation (README files, doc comments, configuration docs, user-facing guides) that would be affected by the implementation. Documentation changes are implementation work, not an afterthought.
- Reference creative phase decisions where they inform implementation choices.
- Identify key relationships or designs that would be more-clearly communicated with a diagram (flowchart, sequence diagram, entity relationship diagram, or UML diagram), than with prose. These diagrams will either be "pinned" at the top of the task list if they apply generally to the whole plan, or placed later on near the most-relevant section.

## Step 8: Identify Challenges & Mitigations

- For each non-trivial step, note what could go wrong and how to handle it
- Flag any dependency on external state (APIs, environment, config) that must be present during build
- Flag any cross-component integration risks
- If any challenge suggests the task is actually Level 4 (requires milestone decomposition, multiple independent workstreams): FAIL with recommendation to re-level

## Step 9: Technology Validation

- Document any new dependencies, build tool changes, or configuration additions
- If new technology is introduced: create a minimal proof-of-concept that verifies the dependency installs, builds, and runs in the project's environment
- If no new technology: skip this step and note "No new technology - validation not required"

## Step 10: Generate Plan Report

1. Write the complete plan to `memory-bank/active/tasks.md` using the format below
2. Update `memory-bank/active/activeContext.md` with planning outcome

### tasks.md Plan Format

~~~markdown
# Task: [Task name]

* Task ID: [task-id]
* Complexity: Level 3
* Type: [task type (feature, refactor, etc.)]

[Concrete description of the feature]

## Pinned Info

### [Diagram name]

[short description of the diagram, including why it needs to be pinned]

```mermaid
[diagram]
```

## Component Analysis

### Affected Components
- [Component 1]: [current responsibility] → [changes needed]
- [Component 2]: [current responsibility] → [changes needed]

### Cross-Module Dependencies
- [Component 1] → [Component 2]: [nature of dependency]

### Boundary Changes
- [Any interface, API, or schema changes]

## Open Questions

- [x] [Question 1] → Resolved: [decision summary] (see `memory-bank/active/creative/creative-[name].md`)
- [x] [Question 2] → Resolved: [decision summary]
- [ ] [Question 3] → Unresolved: awaiting operator input

(or "None - implementation approach is clear" if no open questions were identified)

## Test Plan (TDD)

### Behaviors to Verify

- [Behavior 1]: [input/action] → [expected outcome]
- [Behavior 2]: [input/action] → [expected outcome]
- [Edge case 1]: [input/action] → [expected outcome]

### Test Infrastructure

- Framework: [existing framework name]
- Test location: [path to test directory]
- Conventions: [naming/structure conventions observed]
- New test files: [list, or "none"]

### Integration Tests

- [Integration test 1]: [which components, what interaction]

## Implementation Plan

1. [Step 1 - component, TDD cycle]
    - Files: [file paths]
    - Changes: [specific changes]
    - Creative ref: [if applicable, link to creative decision]
2. [Step 2]
    - Files: [file paths]
    - Changes: [specific changes]

## Technology Validation

[New dependencies and validation results, or "No new technology - validation not required"]

## Challenges & Mitigations

- [Challenge 1]: [Mitigation]
- [Challenge 2]: [Mitigation]

## Status

- [x] Component analysis complete
- [x] Open questions resolved
- [x] Test planning complete (TDD)
- [x] Implementation plan complete
- [x] Technology validation complete
- [ ] Preflight
- [ ] Build
- [ ] QA
~~~

## Step 11: Log Progress

> 🚨 **Printing this notice is NOT the end of this phase.** After printing, continue immediately to the next step - do not stop.

Log the results depending on the build outcome by printing the appropriate block:

### PASS

~~~markdown
# Plan Result

✅ PASS - Level 3: Intermediate Feature

## Summary

- **Components affected**: [list]
- **Open questions**: [count resolved] resolved, [count unresolved] unresolved
- **Behaviors to verify**: [count]
- **Implementation steps**: [count]
- **New dependencies**: [list or "none"]

## Creative Decisions

[List of resolved open questions with one-line decision summaries, or "None - no open questions identified"]

## Challenges

[Brief summary of identified challenges, or "None identified"]

## Next Steps

Proceed to "Preflight" phase to validate the plan.
~~~

### FAIL

~~~markdown
# Plan Result

❌ FAIL

## Reason

[Why planning could not complete]

## Next Steps

- **Prerequisites missing**: Run `/niko` to initialize properly.
- **Re-level required**: Task complexity exceeds Level 3. Discuss with operator before re-planning at Level 4.
- **Open questions unresolved**: Awaiting operator input on [specific question].
~~~

## Step 12: Phase Transition

- If operator input is required: stop and wait for them.
- If operator input is not required: load the appropriate complexity level-specific Niko workflow file, then use its Phase Mappings to execute the next phase.
