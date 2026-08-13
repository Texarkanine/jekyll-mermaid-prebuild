# Reconcile Persistent Files

> **TL;DR:** Quick scan of persistent memory bank files against the work just completed. Update what this task invalidated or the standing-contract probe flags. For each file that needs no update, print a one-line skip receipt.

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
4. **Standing-contract probe**: did this task introduce or change a standing contract — a convention future contributors would otherwise reinvent incompatibly (error identity, test oracles, path layers, build invariants) — that is absent or no longer accurate in *this* file? If yes, and the contract belongs here per its guidance rule, the file is materially incomplete. A yes here is not a doubt case. The contract is in scope; a catalog of the helpers that implement it is not.
5. **If neither**: leave the file alone and print one line: `[productContext|systemPatterns|techContext]: skip — <reason>`, where the reason covers the probe, not only "not invalidated."
6. **If either**: make a **surgical update** following the guidance rule's conventions, and briefly note what changed and why in your output to the operator.

## Guardrails

- **Selective, not routine.** Most tasks won't change persistent files. This is a quick mental scan, not a ritual rewrite.
- **Surgical, not comprehensive.** Update what this task invalidated or the probe flagged. Do not audit for unrelated staleness. Do not chase completeness.
- **System-level scope.** These files describe the system's shape, not individual tasks. They must never contain content that does not belong.
- **Skip is the norm, not a reflex.** Under-updating is fine for narrative and history; it is not fine for a standing contract the probe caught. When unsure, leave the file alone and give your reason in the receipt.
