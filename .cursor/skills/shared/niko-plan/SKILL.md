---
name: niko-plan
description: Niko Memory Bank System - Plan Phase - Implementation Planning
---

# Plan Phase - Implementation Planning

This command creates a detailed implementation plan for the current task. Planning depth scales with complexity level - this file routes to the appropriate level-specific planning document.

## Step 1: Load Memory Bank Files

Read:
- `memory-bank/active/tasks.md`
- `memory-bank/active/activeContext.md`

## Step 2: Determine Complexity Level

Read the complexity level from `memory-bank/active/activeContext.md`

If no complexity level is set, or `memory-bank/active/activeContext.md` does not exist: STOP PLANNING! Invoke the `niko` skill to initialize the memory bank and perform complexity analysis, then proceed as instructed there.

## Step 3: Route to Level-Specific Planning

Load the appropriate complexity level-specific Niko workflow file, then use its Phase Mappings to execute the Plan phase.
