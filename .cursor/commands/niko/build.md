# BUILD Command - Code Implementation

This command implements the planned changes following the implementation plan and creative phase decisions. 

**CRITICAL**: This command enforces **Test-Driven Development (TDD)**. ALL code changes MUST follow the TDD process: **TESTS GET WRITTEN FIRST!**

## Memory Bank Integration

Reads from:
- `memory-bank/tasks.md` - Implementation plan and checklists
- `memory-bank/creative/creative-*.md` - Design decisions (Level 3-4)
- `memory-bank/activeContext.md` - Current project context
- `memory-bank/progress.md` - Implementation status (if exists)
- `memory-bank/projectbrief.md` - Project foundation (if exists)

Updates:
- `memory-bank/tasks.md` - Implementation progress, test results, and status
- `memory-bank/progress.md` - Build status, test outcomes, and observations

## Progressive Rule Loading

### Step 1: Load TDD Methodology
```
Load: .cursor/rules/shared/always-tdd.mdc
```

**TDD Process Overview:**
1. **Determine Scope**: Identify code changes and behaviors to test
2. **Preparation (Stubbing)**: Create empty test implementations and stub interfaces
3. **Write Tests**: Implement tests (they should fail initially)
4. **Write Code**: Implement code to make tests pass

### Step 2: Load Core Rules
```
Load: .cursor/rules/shared/niko/main.mdc
Load: .cursor/rules/shared/niko/Core/memory-bank-paths.mdc
Load: .cursor/rules/shared/niko/Core/command-execution.mdc
```

### Step 3: Load BUILD Mode Map
```
Load: .cursor/rules/shared/niko/visual-maps/implement-mode-map.mdc
```

### Step 4: Load Complexity-Specific Implementation Rules
Based on complexity level from `memory-bank/tasks.md`:

**Level 1:**
```
Load: .cursor/rules/shared/niko/Level1/workflow-level1.mdc
Load: .cursor/rules/shared/niko/Level1/optimized-workflow-level1.mdc
```

**Level 2:**
```
Load: .cursor/rules/shared/niko/Level2/workflow-level2.mdc
```

**Level 3-4:**
```
Load: .cursor/rules/shared/niko/Level3/implementation-intermediate.mdc
Load: .cursor/rules/shared/niko/Level4/phased-implementation.mdc
```

## Workflow

1. **Verify Prerequisites**
   - Check `memory-bank/.qa_validation_status` for QA validation (must be PASS)
   - Check `memory-bank/tasks.md` for planning completion
   - For Level 3-4: Verify creative phase documents exist
   - Review implementation plan
   
   **Note**: BUILD mode is blocked until QA validation passes. If QA validation has not been completed, the system will prompt you to run `/niko/qa` first.

2. **Determine Complexity Level**
   - Read complexity level from `memory-bank/tasks.md`
   - Load appropriate workflow rules

3. **Execute Implementation (Following TDD)**

   **IMPORTANT**: For ALL levels, follow the TDD process (see Step 1 above):
   1. Determine scope and behaviors to test
   2. Stub tests and interfaces (empty implementations)
   3. Implement tests (they should fail)
   4. Implement code to make tests pass

   **Level 1 (Quick Bug Fix):**
   - Review bug report and examine relevant code
   - **TDD Step 1-2**: Determine what to test, stub test cases
   - **TDD Step 3**: Write test(s) that will validate the fix (tests should fail)
   - **TDD Step 4**: Implement targeted fix to make tests pass
   - Run tests and ensure they pass
   - Update `memory-bank/tasks.md`

   **Level 2 (Simple Enhancement):**
   - Review build plan and examine relevant code areas
   - **TDD Step 1-2**: Identify behaviors to test, stub test cases and interfaces
   - **TDD Step 3**: Write tests for each success criterion (tests should fail)
   - **TDD Step 4**: Implement changes sequentially to make tests pass
   - Run all tests and ensure they pass
   - Update `memory-bank/tasks.md`

   **Level 3-4 (Feature/System):**
   - Review plan and creative decisions
   - Create directory structure
   - Build in planned phases
   - **For each phase:**
     - **TDD Step 1-2**: Determine scope, stub tests and interfaces for phase
     - **TDD Step 3**: Write tests for all phase success criteria (tests should fail)
     - **TDD Step 4**: Implement phase to make tests pass
     - Run tests and ensure they pass
     - Do NOT proceed to next phase until all tests pass
   - Integration testing (following TDD)
   - Document implementation
   - Update `memory-bank/tasks.md` and `memory-bank/progress.md`

4. **Test-Driven Phase Completion**
   - Extract success criteria from current phase in `memory-bank/tasks.md`
   - Following TDD methodology, write test cases BEFORE implementation
   - Execute all tests (they should fail initially)
   - Implement code to make tests pass
   - **Gate:** All tests MUST pass before phase completion
   - Document test results in `memory-bank/tasks.md`
   - If tests fail: fix implementation, re-run tests, repeat until all pass

5. **Command Execution**
   - Document all commands executed
   - Document results and observations
   - Follow platform-specific command guidelines

6. **Verification**
   - Verify all build steps completed
   - Verify all success criteria tests pass
   - Verify changes meet requirements
   - Update `memory-bank/tasks.md` with completion status

## Usage

Type `/niko/build` to start implementation based on the plan in `memory-bank/tasks.md`.

## Next Steps

After implementation complete, proceed to `/niko/reflect` command for task review.

