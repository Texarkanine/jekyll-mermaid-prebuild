---
name: niko-build
description: Niko Memory Bank System - Build Phase - Code Implementation
---

# Build Phase - Code Implementation

This command implements the planned changes following the validated implementation plan. Implementation depth scales with complexity level - this file routes to the appropriate level-specific build document.

## Step 1: Load Memory Bank Files

Read:
- `memory-bank/active/tasks.md`
- `memory-bank/active/activeContext.md`

## Step 2: Determine Complexity Level

Read the complexity level from `memory-bank/active/activeContext.md`.

If no complexity level is set, or `memory-bank/active/activeContext.md` does not exist: STOP BUILDING! Invoke the `niko` skill to initialize the memory bank and perform complexity analysis.

## Step 3: Route to Level-Specific Build

Load the appropriate complexity level-specific Niko workflow file, then use its Phase Mappings to execute the Build phase.
