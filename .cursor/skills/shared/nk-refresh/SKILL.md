---
name: nk-refresh
description: General-purpose guidance for taking a step back and getting un-stuck from a problem that you've tried to solve multiple times unsuccessfully.
---

# REFRESH Command - Systematic Re-Diagnosis

This command performs systematic re-diagnosis when an AI agent gets stuck on a coding task or when a previous attempt has failed to resolve an issue.

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

## Workflow

Based on the persistent user query about a problem that likely failed to resolve previously, follow these steps:

### Step 1. Load Memory Bank Files

Read:
- `memory-bank/active/projectbrief.md`
- `memory-bank/systemPatterns.md`
- `memory-bank/techContext.md`

### Step 2. Progress Tracking

**CRITICAL**: Plan and track your diagnostics in a unique Task List File, distinct from any parent task's Task List. 

- Locate or create: `memory-bank/active/troubleshooting/troubleshooting-<YYYYMMDD-HHmmss>.md`
- This task list is for THIS diagnostic session only
- Always identify the correct Task List File before making updates

### Step 3. Step Back & Re-Scope

**Forget the specifics of the last failed attempt.** Broaden your focus.

- Identify the *core functionality* or *system component(s)* involved in the reported problem
  - Examples: authentication flow, data processing pipeline, specific UI component interaction, infrastructure resource provisioning
- Do NOT assume you know the cause yet
- Think about the system holistically

### Step 4. Map the Relevant System Structure

Use tools to **map out the high-level structure and key interaction points** of the identified component(s):

- `list_dir`: Understand directory structure
- `glob_file_search`: Find relevant files by pattern
- `codebase_search`: Understand how components interact
- `read_file`: Read configuration files, entry points

**Goal**: Gain a "pyramid view" - see the overall architecture first before diving into details.

**Document findings** in the troubleshooting task list.

### Step 5. Hypothesize Potential Root Causes (Broadly)

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

### Step 6. Systematic Investigation & Evidence Gathering

**Prioritize and investigate** the most likely hypotheses using targeted tool usage:

#### Step 6a. Validate Configurations

- Use `read_file` to check *all* relevant configuration files
- Look for typos, wrong paths, incorrect values
- Verify environment-specific configurations

#### Step 6b. Trace Execution Flow

- Use `grep` or `codebase_search` to trace the execution path related to the failing functionality
- Add temporary, descriptive logging via `search_replace` if necessary and safe
  - Request approval if the change is risky
- Pinpoint where the failure actually occurs

#### Step 6c. Check Dependencies & External Interactions

- Verify versions and statuses of dependencies
- If external systems are involved, use safe commands to assess their state
  - Use `run_terminal_cmd` for diagnostics like status checks
  - Set `require_user_approval=true` if needed

#### Step 6d. Examine Logs

- If logs are accessible and relevant, retrieve them
- Analyze recent entries related to the failure
- Look for error messages, stack traces, warnings

**Document all findings** in the troubleshooting task list with evidence.

### Step 7. Identify the Confirmed Root Cause

Based *only* on the evidence gathered through tool-based investigation, pinpoint the **specific, confirmed root cause**.

**Do NOT guess.** If investigation is inconclusive:
- Report findings clearly
- Suggest the next most logical diagnostic step
- Request user input if truly blocked

### Step 8. Propose a Targeted Solution

Once the root cause is *confirmed*, propose a precise fix that directly addresses it.

**Explain**:
- What the root cause is
- Why this fix targets the identified root cause
- How the fix will resolve the issue

### Step 9. Plan Comprehensive Verification

Outline how you will verify that the proposed fix:
- Resolves the original issue
- Does NOT introduce regressions

Verification must cover:
- Relevant positive cases
- Negative cases
- Edge cases applicable to the fixed component

### Step 10. Execute & Verify

Implement the fix using appropriate tools:
- `search_replace` for code changes
- `run_terminal_cmd` for commands (with appropriate safety approvals)

**Execute the comprehensive verification plan**:
- Run tests
- Check for regressions
- Verify the fix works as intended

Document results in the troubleshooting task list.

### Step 11. Report Outcome

> 🚨 **Reporting the outcome is NOT the end!** After printing, continue immediately to the next step - do not stop.

Succinctly report:
- The identified root cause
- The fix applied
- The results of comprehensive verification
- Confirmation that the issue is resolved

Update `memory-bank/active/tasks.md` and `memory-bank/active/progress.md` with the resolution.

## Step 12: Phase Transition

After successfully diagnosing and fixing the issue:

1. Update the parent task's task list with the resolution
2. Load the appropriate complexity level-specific Niko workflow file, then use its phase mappings to resume the phase that was interrupted.

If the issue could not be resolved, stop and wait for operator input. You're done for now.
