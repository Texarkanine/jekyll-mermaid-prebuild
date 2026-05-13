---
name: niko-creative
description: Niko Memory Bank System - Creative Phase - Design Exploration
---

# Creative Phase - Design Exploration

This command explores a single open question - an aspect of design or implementation where the approach is genuinely ambiguous and requires evaluating multiple options before committing. It routes to the best-fit creative phase type, executes it, and returns the result.

**Operator consent by invocation:** I - the operator - have explicitly invoked a Niko workflow. Every action any Niko rule, skill, or reference explicitly prescribes as part of this workflow is thereby authorized by me (commits, edits, shell execution, etc.). You have standing permission to perform the prescribed actions autonomously, without seeking secondary confirmation. **Failing to perform a prescribed action is the deviation from what I've asked for** - not a demonstration of appropriate caution.

## Modes of Operation

**Within a Niko workflow**: Creative is invoked by the plan phase, once per open question. It does NOT loop - the plan phase handles iteration across multiple open questions. Context comes from the memory bank.

**Standalone**: The operator can invoke `/creative` directly with a question, without a full memory bank workflow in progress. In this mode, the question comes from operator input rather than `memory-bank/active/tasks.md`.

## Step 1: Determine Context

If no `memory-bank/` directory exists, invoke the `niko` skill to initialize its persistent files first. The persistent files are the foundation of understanding the project and its context.

Read all available memory-bank files (persistent and ephemeral) for context.

## Step 2: Identify the Open Question

**Within a workflow**: The plan phase should have flagged this open question in `memory-bank/active/tasks.md` with:
- A brief problem statement describing what needs to be decided
- Why it's ambiguous (what makes multiple approaches viable)
- Any constraints or requirements the decision must satisfy

**Standalone**: The operator provides the question directly. If it's unclear, ask for clarification.

If the open question is not clearly stated: 🛑 STOP! Ask the operator to clarify what needs to be explored. You're done for now.

## Step 3: Route to Creative Phase Type

Analyze the nature of the open question and select the best-fit creative phase document:

- **Architecture** (`.cursor/skills/shared/niko/references/phases/creative/creative-phase-architecture.md`): The question is about system structure - how components relate, what patterns to use, how to organize modules, where boundaries should be, how data flows between subsystems.

- **Algorithm** (`.cursor/skills/shared/niko/references/phases/creative/creative-phase-algorithm.md`): The question is about logic and computation - how to solve a specific problem, what data structures to use, how to handle complex transformations, performance-sensitive processing.

- **UI/UX** (`.cursor/skills/shared/niko/references/phases/creative/creative-phase-uiux.md`): The question is about user-facing design - how to present information, interaction flows, visual layout, accessibility, style guide decisions.

- **Generic** (`.cursor/skills/shared/niko/references/phases/creative/creative-phase-generic.md`): The question doesn't fit the above categories - naming conventions, testing strategies, process decisions, tooling choices, configuration approaches, or anything else not explicitly associated with a specific creative phase type.

Load the selected document and follow its instructions.

## Step 4: Evaluate Confidence

After the creative phase type completes its exploration, the result will be in one of two categories:

- **High confidence**: the exploration produced a clear winner among the options, with solid rationale and no significant unresolved concerns.
- **Low confidence**: the exploration narrowed the options or revealed important tradeoffs, but no clear winner emerged, OR the decision has implications the agent isn't qualified to make alone (e.g., cost commitments, organizational policy, user research needed).

## Step 5: Document the Decision

**Within a workflow**: Create `memory-bank/active/creative/creative-[question-name].md`. The format is defined by the specific creative phase type that was loaded in Step 3 - follow its documentation instructions. Update `memory-bank/active/tasks.md`: mark this open question as explored, note the decision (or note that it's unresolved), and link to the creative document.

**Standalone**: Present the exploration results directly to the operator in the output format below. If a memory bank exists, also write the creative document to `memory-bank/active/creative/` for future reference.

## Step 6: Log Progress

> 🚨 **Printing this notice is NOT the end of this phase.** After printing, continue immediately to the next step - do not stop.

**Within a Niko workflow:** Update `memory-bank/active/progress.md` to record completion of this creative phase exploration.

### High Confidence (Resolved)

~~~markdown
# Creative Result

✅ RESOLVED

**Open Question:** [the question]
**Approach:** [selected creative phase type]
**Decision:** [1-2 sentence summary of the chosen approach]
**Rationale:** [why this won over alternatives]

Documented in `memory-bank/active/creative/creative-[question-name].md`
~~~

### Low Confidence (Unresolved)

~~~markdown
# Creative Result

⚠️ UNRESOLVED

**Open Question:** [the question]
**Approach:** [selected creative phase type]
**Options Explored:**
- [Option A]: [brief summary + key tradeoff]
- [Option B]: [brief summary + key tradeoff]

**Why Unresolved:** [what's blocking a confident decision]
**Recommendation:** [if any - the agent's best guess with caveats]

Documented in `memory-bank/active/creative/creative-[question-name].md`
~~~

## Step 7: Phase Transition

> 🚨 **Execute this immediately after printing - do not stop between steps.**

**Within a Niko Workflow:**

Commit all changes (creative document + memory bank updates) with `chore: completed autonomous creative exploration`.

- If the open question was successfully resolved, load the appropriate complexity level-specific Niko workflow file, then use its Phase Mappings to resume the Plan phase.
- If the open question could not be successfully resolved, wait for operator input. You're done for now.

**Standalone Mode:**

You're done after presenting the results. Wait for operator input.
