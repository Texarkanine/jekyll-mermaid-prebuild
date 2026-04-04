---
name: niko-archive
description: Niko Memory Bank System - Archive Phase - Task Archiving & Cleanup
---

# Archive Phase - Task Archiving & Cleanup

This command creates a self-contained archive document for the completed task, inlines all ephemeral content, clears task-specific files from the memory bank, and commits everything. Archive depth scales with complexity level - this file routes to the appropriate level-specific archive document.

## Step 1: Load Memory Bank Files

Read:
- `memory-bank/active/tasks.md`
- `memory-bank/active/activeContext.md`
- `memory-bank/active/progress.md`

## Step 2: Determine Complexity Level

If no complexity level is set, or `memory-bank/active/progress.md` does not exist: 🛑 STOP! It doesn't make sense to archive before a task has been completed.

Ask the operator for clarification, and wait for their instructions. You're done for now.

## Step 3: Route to Level-Specific Archive

Load the appropriate complexity level-specific Niko workflow file, then use its Phase Mappings to execute the Archive phase.
