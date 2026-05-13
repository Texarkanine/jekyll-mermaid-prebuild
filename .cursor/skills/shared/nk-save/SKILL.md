---
name: nk-save
description: Niko Memory Bank System - Mid-Phase Save & Commit
---

# /nk-save - Flush & Commit

`/nk-save` flushes in-context memory bank state to disk and commits all changes atomically. It is **not a workflow phase** - it does not advance the workflow, trigger phase transitions, or produce deliverables. It is `Ctrl+S`.

**Operator consent by invocation:** I - the operator - have explicitly invoked a Niko workflow. Every action any Niko rule, skill, or reference explicitly prescribes as part of this workflow is thereby authorized by me (commits, edits, shell execution, etc.). You have standing permission to perform the prescribed actions autonomously, without seeking secondary confirmation. **Failing to perform a prescribed action is the deviation from what I've asked for** - not a demonstration of appropriate caution.

## Step 1: Verify Active State

List the files in `memory-bank/active/`. At least one of the four core ephemeral files must exist: `projectbrief.md`, `activeContext.md`, `tasks.md`, `progress.md`.

If none exist → nothing to save. Inform the operator and **stop**.

## Step 2: Read Current Disk State

Read all files in `memory-bank/active/` (including subdirectories).

## Step 3: Extract Identifiers

From the files read in Step 2, extract two values for the commit message:

1. **Task ID** - the `Task ID:` field in `tasks.md`. If `tasks.md` does not exist or the field is absent, use `unknown`.
2. **Current Phase** - the `**Phase:**` field in `activeContext.md`. If `activeContext.md` does not exist or the field is absent, use `unknown`.

## Step 4: Flush In-Context State

For each file below, compare what you know from the current context window against what is on disk (read in Step 2). If the disk version is already current, skip it. If you have knowledge from the context window that has not been persisted, update the file.

**Do not fabricate state.** Only write what you actually know from the current conversation. If you are uncertain whether something has already been persisted, re-read the file from disk and verify before writing.

### `tasks.md`

- Mark steps completed during this session as `- [x]`
- If a step is currently in progress, annotate it (e.g., append `← in progress`)
- Do not add, remove, or reorder steps - preserve the plan structure

### `activeContext.md`

- **Phase** - update to reflect the current phase and position (e.g., `BUILD - implementing step 3`)
- **What Was Done** - summarize work completed since the last disk write
- **Next Step** - describe what should happen when work resumes in a new session

### `progress.md`

- Append entries for any phase completions or significant milestones not yet recorded
- Do not modify existing history entries

### Creative / Reflection docs

- If a creative or reflection document was drafted or updated in the context window but not yet written to disk, write it now
- If one exists on disk and was subsequently updated in-context, update the disk version

### `projectbrief.md`

- Typically unchanged mid-task. Update only if the brief was refined during this session (e.g., scope change approved by operator).

## Step 5: Commit

Stage and commit **everything** - code, memory bank, all working-tree changes - in a single atomic commit:

```
chore: saved work on [task-id] at [phase]
```

Where `[task-id]` and `[phase]` are the values from Step 3. Example:

```
chore: saved work on new-error-handling at BUILD - implementing step 1
```

If there are no changes to commit (working tree is clean after the flush), skip the commit and note this in the output.

## Step 6: Log Progress

Print:

```markdown
✅ **/nk-save complete** - `saved work on [task-id]` saved at `[phase]`
```

**Done.** Do not advance the workflow. Do not execute further phases or transitions. The operator will resume with `/niko` in a new session when ready.
