# REFRESH Command - Systematic Re-Diagnosis

This command performs systematic re-diagnosis when an AI agent gets stuck on a coding task or when a previous attempt has failed to resolve an issue.

## Purpose

When stuck or after a failed attempt, this command provides a structured troubleshooting process that:
- Discards previous assumptions
- Re-scopes the problem broadly
- Maps the system structure comprehensively
- Investigates systematically with evidence
- Proposes targeted solutions based on confirmed root causes

## Memory Bank Integration

Reads from:
- `memory-bank/tasks.md` - Current task details and previous attempts
- `memory-bank/progress.md` - Implementation status and issues
- `memory-bank/activeContext.md` - Current focus

Creates:
- `memory-bank/troubleshooting/troubleshooting-<timestamp>.md` - Diagnostic session log

Updates:
- `memory-bank/tasks.md` - Updated with diagnostic findings and fixes
- `memory-bank/progress.md` - Diagnostic outcomes

## Workflow

Based on the persistent user query about a problem that likely failed to resolve previously, follow these steps adhering strictly to niko-core principles:

### 1. Progress Tracking
**CRITICAL**: Plan and track your diagnostics in a unique Task List File, distinct from any parent task's Task List. 

- Locate or create: `memory-bank/troubleshooting/troubleshooting-<timestamp>.md`
- This task list is for THIS diagnostic session only
- Always identify the correct Task List File before making updates

### 2. Step Back & Re-Scope
**Forget the specifics of the last failed attempt.** Broaden your focus.

- Identify the *core functionality* or *system component(s)* involved in the reported problem
  - Examples: authentication flow, data processing pipeline, specific UI component interaction, infrastructure resource provisioning
- Do NOT assume you know the cause yet
- Think about the system holistically

### 3. Map the Relevant System Structure
Use tools to **map out the high-level structure and key interaction points** of the identified component(s):

- `list_dir`: Understand directory structure
- `glob_file_search`: Find relevant files by pattern
- `codebase_search`: Understand how components interact
- `read_file`: Read configuration files, entry points

**Goal**: Gain a "pyramid view" - see the overall architecture first before diving into details.

**Document findings** in the troubleshooting task list.

### 4. Hypothesize Potential Root Causes (Broadly)
Based on the system map and the problem description, generate a *broad* list of potential areas where the root cause might lie:

Examples:
- Configuration error
- Incorrect API call
- Upstream data issue
- Logic flaw in module X
- Dependency conflict
- Infrastructure misconfiguration
- Incorrect permissions
- Path resolution issues
- Environment-specific problems

**Do NOT pick one yet.** List them all.

### 5. Systematic Investigation & Evidence Gathering
**Prioritize and investigate** the most likely hypotheses using targeted tool usage:

#### Validate Configurations
- Use `read_file` to check *all* relevant configuration files
- Look for typos, wrong paths, incorrect values
- Verify environment-specific configurations

#### Trace Execution Flow
- Use `grep` or `codebase_search` to trace the execution path related to the failing functionality
- Add temporary, descriptive logging via `search_replace` if necessary and safe
  - Request approval if the change is risky
- Pinpoint where the failure actually occurs

#### Check Dependencies & External Interactions
- Verify versions and statuses of dependencies
- If external systems are involved, use safe commands to assess their state
  - Use `run_terminal_cmd` for diagnostics like status checks
  - Set `require_user_approval=true` if needed

#### Examine Logs
- If logs are accessible and relevant, retrieve them
- Analyze recent entries related to the failure
- Look for error messages, stack traces, warnings

**Document all findings** in the troubleshooting task list with evidence.

### 6. Identify the Confirmed Root Cause
Based *only* on the evidence gathered through tool-based investigation, pinpoint the **specific, confirmed root cause**.

**Do NOT guess.** If investigation is inconclusive:
- Report findings clearly
- Suggest the next most logical diagnostic step
- Request user input if truly blocked

### 7. Propose a Targeted Solution
Once the root cause is *confirmed*, propose a precise fix that directly addresses it.

**Explain**:
- What the root cause is
- Why this fix targets the identified root cause
- How the fix will resolve the issue

### 8. Plan Comprehensive Verification
Outline how you will verify that the proposed fix:
- Resolves the original issue
- Does NOT introduce regressions

Verification must cover:
- Relevant positive cases
- Negative cases
- Edge cases applicable to the fixed component

### 9. Execute & Verify
Implement the fix using appropriate tools:
- `search_replace` for code changes
- `run_terminal_cmd` for commands (with appropriate safety approvals)

**Execute the comprehensive verification plan**:
- Run tests
- Check for regressions
- Verify the fix works as intended

Document results in the troubleshooting task list.

### 10. Report Outcome
Succinctly report:
- The identified root cause
- The fix applied
- The results of comprehensive verification
- Confirmation that the issue is resolved

Update `memory-bank/tasks.md` and `memory-bank/progress.md` with the resolution.

## Usage

Type `/niko/refresh` when stuck or after a failed attempt to resolve an issue, followed by a description of the problem:

Example:
```
/niko/refresh The build is failing with "Module not found" error, but the module is installed
```

## Progressive Rule Loading

This command loads rules to support diagnostic work:

### Step 1: Load Core Principles & Rules
```
Load: .cursor/rules/shared/niko/main.mdc
Load: .cursor/rules/shared/niko/Core/memory-bank-paths.mdc
Load: .cursor/rules/shared/niko/Core/file-verification.mdc
```

## Key Principles

### Do NOT Jump to Solutions
- No fixing until the root cause is CONFIRMED through investigation
- Evidence-based diagnosis only
- Systematic exploration, not trial-and-error

### Broaden Before Narrowing
- Start with a wide view of the system
- Map the architecture
- Then narrow down based on evidence

### Document Everything
- All hypotheses
- All investigation steps
- All evidence found
- All conclusions drawn

### Transparent Communication
- Explain what you're investigating and why
- Share findings as you go
- Be clear about confidence level

## Next Steps

After successfully diagnosing and fixing the issue:
- Update the parent task's task list with the resolution
- Return to the appropriate mode for the task:
  - If in BUILD phase: Continue with `/niko/build`
  - If in PLAN phase: Return to `/niko/plan`
  - If testing issues: Verify with appropriate test commands
- Archive the troubleshooting session document for future reference

## Integration with Niko Core

This command embodies the niko-core principles (loaded in Step 1):
- **Diagnose Holistically**: Analyze system context, dependencies, and components
- **Avoid Quick Fixes**: Ensure solutions address root causes
- **Attempt Autonomous Correction**: Implement reasoned corrections based on comprehensive diagnosis
- **Validate Fixes**: Verify corrections don't impact other system parts
- **Report & Propose**: If blocked, explain the problem, diagnosis, attempts, and propose solutions

See niko-core Error Handling section for complete principles.

