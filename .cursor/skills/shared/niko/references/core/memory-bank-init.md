# Memory Bank Initialization & Verification

```mermaid
graph TD
    A((Start)) --> B{All Files Exist?<br>1. memory-bank/active/projectbrief.md<br>2. memory-bank/active/activeContext.md<br>3. memory-bank/active/tasks.md<br>4. memory-bank/active/progress.md}
    B --"Yes"--> C("Memory Bank is already fully initialized<br>work is in-progress")
    B --"No"--> D{All Files Exist?<br>1. memory-bank/productContext.md<br>2. memory-bank/systemPatterns.md<br>3. memory-bank/techContext.md}
    D --"Yes"--> E("Memory Bank is partially initialized:<br>ready for new work")
    D --"No"--> F("Memory bank is uninitialized:<br>initialize it now")
```

## Uninitialized

If the memory bank is completely uninitialized, the following persistent files must be created:

1. `memory-bank/productContext.md`
    * The "Product Context File" is the business context of this collection of files: target users, use cases, success criteria, constraints. If this information is not obvious from traditional documentation sources, prompt the user for more information.
    * Load: `.cursor/rules/shared/niko/memory-bank/productContext.mdc` and create the file by following the instructions in the rule.
2. `memory-bank/systemPatterns.md`
    * The "System Patterns File" is the architectural patterns of this collection of files: code organization, naming conventions, design patterns in use. Scan the codebase for significant patterns (nonstandard or high-criticality) and document them.
    * Load: `.cursor/rules/shared/niko/memory-bank/systemPatterns.mdc` and create the file by following the instructions in the rule.
3. `memory-bank/techContext.md`
    * The "Tech Context File" summarizes how to work with the technology stack(s) in use in the project. Identify the tools, commands, frameworks, and design system references that should be top-of-mind while working on the project. Do NOT include session-specific info (current branch, current task, local environment, etc).
    * Load: `.cursor/rules/shared/niko/memory-bank/techContext.mdc` and create the file by following the instructions in the rule.

**🚨 CRITICAL:** If initializing the memory bank in preparation for a user-initiated task, do *not* take the user's task into account when creating the persistent files. The persistent files should be able to stand on their own, in a vacuum, regardless of the user's task. Including knowledge of the user's task in the persistent files will pollute them with stale, temporary information!

**🚨 CRITICAL:** Before writing persistent files, scan for existing AI-facing documentation (`.cursor/rules/`, `.claude/`, `AGENTS.md`, `CLAUDE.md`, or equivalent). Persistent files must not duplicate information already present in these files - they serve different purposes. Persistent files capture *project knowledge* (business context, non-obvious architecture, tech stack orientation). Rule files capture *working instructions* (how to test, how to format output, coding conventions). If a fact is already in a rule file, omit it from the persistent file or reference the rule file instead.

Once the above files have been created, the memory bank is partially initialized, and ready for new work.

### Output to User:

```markdown
✅ **Memory Bank Initialized** - Ready for new work.
```

## Partially Initialized - Ready for New Work

Once the memory bank has been partially initialized with the persistent files and is ready for new work, the following ephemeral files must be created or updated for that work. These files will normally be created during complexity analysis and/or planning phases. In case you need to create or update one these files out-of-band, here's how:

1. `memory-bank/active/projectbrief.md`
    * The "Project Brief File" is the current session deliverable: user story & requirements.
    * Load: `.cursor/rules/shared/niko/memory-bank/active/projectbrief.mdc` and create the file by following the instructions in the rule.
2. `memory-bank/active/activeContext.md`
    * The "Active Context File" is the current session focus: what's being worked on now, recent decisions, immediate next steps.
    * Load: `.cursor/rules/shared/niko/memory-bank/active/activeContext.mdc` and create the file by following the instructions in the rule.
3. `memory-bank/active/tasks.md`
    * The "Tasks File" is the active task tracking: current task details, checklists, component lists.
    * Load: `.cursor/rules/shared/niko/memory-bank/active/tasks.mdc` and create the file by following the instructions in the rule.
4. `memory-bank/active/progress.md`
    * The "Progress File" is the implementation progress: history of completed work and phase transitions.
    * Load: `.cursor/rules/shared/niko/memory-bank/active/progress.mdc` and create the file by following the instructions in the rule.

**Note:** The ephemeral files will always contain information about a user-provided task. This is normal and expected; it is their purpose!