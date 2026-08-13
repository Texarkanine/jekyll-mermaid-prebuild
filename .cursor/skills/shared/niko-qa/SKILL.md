---
name: niko-qa
description: Niko Memory Bank System - QA Phase - Post-Implementation Semantic Review
---

# QA Phase - Post-Implementation Semantic Review

This command performs a structured semantic review of the code just implemented against the original plan. It catches over-engineering, incomplete implementations, pattern violations, and implementation debris that mechanical checks (lint/build/test) cannot detect.

## Step 1: Load Memory Bank Files

Read:
- `memory-bank/active/tasks.md`
- `memory-bank/active/projectbrief.md`
- `memory-bank/systemPatterns.md`
- `memory-bank/active/activeContext.md`
- `memory-bank/active/progress.md`
- `memory-bank/active/creative/`

## Step 2: QA Workflow

1. **Verify Prerequisites**
    - Check `memory-bank/active/tasks.md` for build phase completion
    - Read the original implementation plan to establish the review baseline
    - For Level 3-4: Read creative phase documents for design intent

2. **Review the code just implemented against the original plan.** Judge only — do not edit the implementation under review. Flag violations of:

    - **KISS**: Over-engineered logic, unnecessary abstractions, or indirection that a simpler construct would replace.
    - **DRY**: Duplicate code, boilerplate, or reinvented utilities the codebase already provides.
    - **YAGNI**: Speculative code, unused parameters, or features not required by the plan.
    - **Completeness**: Requirements stubbed, TODO'd, commented-as-pseudocode, or otherwise not actually implemented.
    - **Regression**: Broken naming, structure, error-handling, or other established patterns across affected projects; code that accretes rather than extends the architecture.
    - **Integrity**: Hardcoded shortcuts, magic numbers, placeholder strings, or debug artifacts left from scaffolding.
    - **Documentation**: Project docs that should have been updated with the code changes and were not.

3. **Judge, Do Not Fix**
     - Surface and judge. Never modify the work under review.
     - Allowed writes only: `memory-bank/active/.qa-validation-status`, QA findings in `tasks.md` / `progress.md`, and (at Step 4) the `**Phase:**` field in `activeContext.md`.
     - Record every issue as a finding. FAIL when something must change before acceptance; PASS only when the implementation is acceptable as-is (advisories allowed).

4. **Generate QA Report**
    - Summarize findings
    - Write validation status to `memory-bank/active/.qa-validation-status`
    - Update `memory-bank/active/tasks.md` with QA results

5. **Handle Results**
    - **On PASS**: Good job!
    - **On FAIL (issues requiring build changes)**: Record that Build must rerun to fix the issues.
    - **On FAIL (fundamental plan issue discovered)**: Record that Plan must rerun to revise the plan.

## Step 3: Log Progress

> 🚨 **Printing this notice is NOT the end of this phase.** After printing, continue immediately to the next step - do not stop.

Update `memory-bank/active/progress.md` to record completion of the QA phase.

When QA review is complete, print:

### PASS

~~~markdown
# QA Result

✅ PASS

1. **Findings** - bulleted list of each semantic finding and why it does or does not block

~~~

### FAIL

~~~markdown
# QA Result

❌ FAIL

1. **Findings** - bulleted list of each semantic finding and why it blocks

## Next Steps

(the next command, if any, based on the current complexity-level's workflow & QA result)
~~~

## Step 4: End of Verification

Update `memory-bank/active/activeContext.md` so `**Phase:**` records this phase complete with PASS or FAIL (e.g. `**Phase:** PREFLIGHT - COMPLETE (PASS)` / `**Phase:** QA - COMPLETE (FAIL)`). Do not load a level workflow or begin another phase. Stop.
