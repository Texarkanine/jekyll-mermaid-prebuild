# ARCHIVE Command - Task Archiving

This command creates comprehensive archive documentation and updates the Memory Bank for future reference.

## Memory Bank Integration

Reads from:
- `memory-bank/tasks.md` - Complete task details and checklists
- `memory-bank/reflection/reflection-<task-id>.md` - Reflection document
- `memory-bank/progress.md` - Implementation status
- `memory-bank/creative/creative-*.md` - Creative phase documents (Level 3-4)

Creates:
- `memory-bank/archive/<kind>/<YYYYMMDD>-<task-id>.md` - Archive document

**Archive Kind Categories:**
- `bug-fixes/` - Bug fixes and quick fixes (Level 1-2)
- `enhancements/` - Simple enhancements and improvements (Level 2)
- `features/` - New features and functionality (Level 3)
- `systems/` - Complex system changes and architecture (Level 4)
- `documentation/` - Documentation updates and improvements

Updates:
- `memory-bank/tasks.md` - Mark task as COMPLETE
- `memory-bank/progress.md` - Add archive reference
- `memory-bank/activeContext.md` - Reset for next task

## Progressive Rule Loading

### Step 1: Load Core Rules
```
Load: .cursor/rules/shared/niko/main.mdc
Load: .cursor/rules/shared/niko/Core/memory-bank-paths.mdc
```

### Step 2: Load ARCHIVE Mode Map
```
Load: .cursor/rules/shared/niko/visual-maps/archive-mode-map.mdc
```

### Step 3: Load Complexity-Specific Archive Rules
Based on complexity level from `memory-bank/tasks.md`:

**Level 1:**
```
Load: .cursor/rules/shared/niko/Level1/quick-documentation.mdc
```

**Level 2:**
```
Load: .cursor/rules/shared/niko/Level2/archive-basic.mdc
```

**Level 3:**
```
Load: .cursor/rules/shared/niko/Level3/archive-intermediate.mdc
```

**Level 4:**
```
Load: .cursor/rules/shared/niko/Level4/archive-comprehensive.mdc
```

## Workflow

1. **Verify Reflection Complete**
   - Check that `memory-bank/reflection/reflection-<task-id>.md` exists
   - Verify reflection is complete
   - If not complete, return to `/niko/reflect` command

2. **Create Archive Document**

   **Level 1:**
   - Create quick summary
   - Update `memory-bank/tasks.md` marking task complete

   **Level 2:**
   - Create basic archive document
   - Document changes made
   - Update `memory-bank/tasks.md` and `memory-bank/progress.md`

   **Level 3-4:**
   - Create comprehensive archive document
   - Include: Metadata, Summary, Requirements, Implementation details, Testing, Lessons Learned, References
   - Archive creative phase documents
   - Document code changes
   - Document testing approach
   - Summarize lessons learned
   - Update all Memory Bank files

3. **Archive Document Structure**
   ```
   # TASK ARCHIVE: [Task Name]
   
   ## METADATA
   - Task ID, dates, complexity level
   
   ## SUMMARY
   Brief overview of the task
   
   ## REQUIREMENTS
   What the task needed to accomplish
   
   ## IMPLEMENTATION
   How the task was implemented
   
   ## TESTING
   How the solution was verified
   
   ## LESSONS LEARNED
   Key takeaways from the task
   
   ## REFERENCES
   Links to related documents (reflection, creative phases, etc.)
   ```

4. **Update Memory Bank**
   - Create `memory-bank/archive/<kind>/<YYYYMMDD>-<task-id>.md` (where `<kind>` is one of: bug-fixes, enhancements, features, systems, documentation)
   - Mark task as COMPLETE in `memory-bank/tasks.md`
   - Update `memory-bank/progress.md` with archive reference
   - Reset `memory-bank/activeContext.md` for next task
   - Clear completed task details from `memory-bank/tasks.md` (keep structure)

## Usage

Type `/niko/archive` to archive the completed task after reflection is done.

## `/archive clear` - Clean Memory Bank

The `/archive clear` command removes all local-machine and task-specific files from the memory bank, leaving only repository-specific information and past task archives.

### What Gets Cleared

**Directories:**
- `memory-bank/creative/` - All creative phase documents (task-specific)
- `memory-bank/reflection/` - All reflection documents (task-specific)

**Files:**
- `memory-bank/tasks.md` - Task tracking (ephemeral, task-specific)
- `memory-bank/progress.md` - Implementation status (task-specific)
- `memory-bank/activeContext.md` - Current focus (task-specific)
- `memory-bank/.qa_validation_status` - QA validation status (task-specific)

### What Gets Preserved

**Repository-Specific Files (Kept):**
- `memory-bank/projectbrief.md` - Project foundation
- `memory-bank/productContext.md` - Product context
- `memory-bank/systemPatterns.md` - System patterns
- `memory-bank/techContext.md` - Tech context
- `memory-bank/style-guide.md` - Style guide
- `memory-bank/archive/` - All archive documents (past tasks)

### Workflow

1. **Verify All Tasks Archived**
   - Ensure all completed tasks have been archived
   - Check that `memory-bank/archive/` contains all expected archive documents

2. **Clear Task-Specific Files**
   - Remove all files in `memory-bank/creative/` directory
   - Remove all files in `memory-bank/reflection/` directory
   - Clear content from `memory-bank/tasks.md` (reset to initial state)
   - Clear content from `memory-bank/progress.md` (reset to initial state)
   - Clear content from `memory-bank/activeContext.md` (reset to initial state)
   - Remove `memory-bank/.qa_validation_status` if it exists

3. **Preserve Repository Knowledge**
   - Keep all repository-specific context files
   - Keep all archive documents
   - Ensure Memory Bank structure remains intact

4. **Git Commit**
   - Stage all cleared files
   - Commit changes with message: `chore: clear task-specific memory bank files`
   - This makes the operation revertable via `git revert HEAD`

5. **Verification**
   - Verify only task-specific files were removed
   - Verify repository-specific files remain
   - Verify archive documents remain
   - Verify Memory Bank structure is intact
   - Verify git commit was successful

### When to Use

Use `/archive clear` when:
- Preparing the repository for sharing or handoff
- Starting fresh after completing multiple tasks
- Removing local-machine specific information
- Ensuring only repository knowledge remains in Memory Bank

**Note:** All changes are automatically committed to git, making this operation revertable if needed.

## Next Steps

After archiving complete, use `/niko` command to start the next task.

After clearing, the Memory Bank will be ready for new tasks with only repository-specific knowledge preserved.

