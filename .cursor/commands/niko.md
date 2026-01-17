# Niko Command - Initialization & Entry Point

This command initializes the Memory Bank system, performs platform detection, determines task complexity, and routes to appropriate workflows.

**Note:** Memory Bank is a one-time project setup. Once initialized, it persists across all `/niko` commands. The verification step below is a quick check that only creates the structure if it doesn't already exist.

## Memory Bank Integration

**CRITICAL:** All Memory Bank files are located in `memory-bank/` directory:
- `memory-bank/tasks.md` - Source of truth for task tracking
- `memory-bank/activeContext.md` - Current focus
- `memory-bank/progress.md` - Implementation status
- `memory-bank/projectbrief.md` - Project foundation

## Progressive Rule Loading

This command loads rules progressively to optimize context usage:

### Step 1: Load Core Rules (Always Required)
```
Load: .cursor/rules/shared/niko/main.mdc
Load: .cursor/rules/shared/niko/Core/memory-bank-paths.mdc
Load: .cursor/rules/shared/niko/Core/platform-awareness.mdc
Load: .cursor/rules/shared/niko/Core/file-verification.mdc
```

### Step 2: Load NIKO Mode Map
```
Load: .cursor/rules/shared/niko/visual-maps/van_mode_split/van-mode-map.mdc
```

### Step 3: Load Complexity-Specific Rules (Based on Task Analysis)
After determining complexity level, load:
- **Level 1:** `.cursor/rules/shared/niko/Level1/workflow-level1.mdc`
- **Level 2-4:** Load plan mode rules (transition to PLAN command)

## Workflow

1. **Platform Detection**
   - Detect operating system
   - Adapt commands for platform
   - Set path separators

2. **Memory Bank Verification (Quick Check)**
   - **Execute:** Check if `memory-bank/` directory exists: `test -d memory-bank` (Mac/Linux) or `Test-Path memory-bank` (Windows)
   - **If missing:** Create Memory Bank structure using the platform-specific commands from the loaded `file-verification.mdc` rule (see "Platform-Specific Commands" section in that rule)

3. **Task Analysis**
   - Read `memory-bank/tasks.md` if exists
   - Analyze task requirements (from user prompt if provided, otherwise from `tasks.md`)
   - Determine complexity level (1-4)

4. **Route Based on Complexity**
   - **Level 1:** Continue in Niko mode, proceed to implementation
   - **Level 2-4:** Transition to `/niko/plan` command

5. **Update Memory Bank**
   - Update `memory-bank/tasks.md` with complexity determination
   - Update `memory-bank/activeContext.md` with current focus

## Usage

Type `/niko` followed by your task description or initialization request.

Examples:
```
/niko
/niko Initialize project for adding user authentication feature
/niko Fix the login bug
```

## Next Steps

- **Level 1 tasks:** Proceed directly to `/niko/build` command
- **Level 2-4 tasks:** Use `/niko/plan` command for detailed planning

