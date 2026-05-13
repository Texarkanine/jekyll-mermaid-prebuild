# Reconcile Persistent Files

> **TL;DR:** Quick scan of persistent memory bank files against the work just completed. Update only what this task invalidated. Skip silently if nothing changed.

## Persistent Files to Check

| File | Guidance Rule |
|------|---------------|
| `memory-bank/productContext.md` | `.cursor/rules/shared/niko/memory-bank/productContext.mdc` |
| `memory-bank/systemPatterns.md` | `.cursor/rules/shared/niko/memory-bank/systemPatterns.mdc` |
| `memory-bank/techContext.md` | `.cursor/rules/shared/niko/memory-bank/techContext.mdc` |

## Procedure

For each persistent file listed above:

1. **Load** its guidance rule - this defines what belongs in the file and how to write it.
2. **Read** the file's current contents.
3. **Compare** against the work just completed: with the guidance rule's definition in mind, does the file contain anything that is now **factually wrong** or **materially incomplete** because of the changes made in this task?
4. **If no**: move on - do not touch the file.
5. **If yes**: make a **surgical update** following the guidance rule's conventions - fix only the specific content invalidated by this task.

If any file was updated, briefly note what changed and why in your output to the operator.

## Guardrails

- **Selective, not routine.** Most tasks won't change persistent files. This step should be a quick mental scan, not a ritual rewrite. If nothing is obviously wrong or missing, move on immediately.
- **Surgical, not comprehensive.** Update what this task invalidated. Do not audit for unrelated staleness. Do not rewrite sections that aren't directly affected.
- **System-level scope.** These files describe the system's shape, not individual tasks.
- **Skip confidently.** When in doubt, leave the file alone. Under-updating is safe (future tasks can fix it). Over-updating introduces noise and potential inaccuracy.
