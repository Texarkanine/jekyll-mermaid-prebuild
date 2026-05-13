---
name: nk-chat
description: Load Niko's memory bank and begin a conversation
disable-model-invocation: true
---

## Step 1: Load Context

Read everything available, in this order. Do not skip files.

1. **Persistent files** (always required if memory bank exists):
   - `memory-bank/productContext.md`
   - `memory-bank/systemPatterns.md`
   - `memory-bank/techContext.md`

2. **Ephemeral files** (read if `memory-bank/active/` exists; do not create or modify):
   - `memory-bank/active/projectbrief.md`
   - `memory-bank/active/activeContext.md`
   - `memory-bank/active/tasks.md`
   - `memory-bank/active/progress.md`
   - any files under `memory-bank/active/creative/`
   - any files under `memory-bank/active/reflection/`

3. **Recent archive entries** (skim, do not exhaustively read): list `memory-bank/archive/` to know what past work exists. Read individual archive files only when a question makes one relevant.

### Graceful Degradation

- **No `memory-bank/` directory at all**: Stop loading. Inform the operator that no memory bank exists and offer to initialize one via `/niko`. Do not fabricate context. Do not continue to Step 2. You are done.
- **Persistent files missing or partial**: Inform the operator which files are missing. Offer to initialize via `/niko`. Proceed with whatever context is available, but be explicit about gaps when answering questions.
- **No `memory-bank/active/` directory**: Note "no task currently in flight" and proceed with persistent-context-only Q&A. This is normal and expected.
- **Partial ephemeral state** (e.g., `progress.md` exists but no `tasks.md`): Note the inconsistency factually ("looks like a task may be paused or in an unusual state"). Do not attempt to repair it.

## Step 2: Greet & Orient

Print a structured "Context Loaded" summary so the operator knows exactly what you are grounded in. Use this exact shape:

~~~markdown
# Context Loaded

**Persistent context:** [numbered list of persistent files read, or "none — no memory bank found"]

**In-flight task:** [one-line summary from `activeContext.md` and `progress.md`, or "none — no active ephemeral state"]

**Phase:** [current phase from `activeContext.md`, if any]

**Recent archives:** [numbered list of most-recent 1–3 by name, or "none"]
~~~

Then handle the operator's input:

- **No question provided alongside `/nk-chat`**: append `What would you like to discuss?` and wait for input.
- **Question provided alongside `/nk-chat`**: proceed directly to Step 3.

## Step 3: Conversational Q&A Loop

Answer questions using the loaded context as ground truth. Apply these guidelines:

- **Cite sources.** When an answer comes from a specific memory-bank file, archive entry, or codebase file, name it. The operator should be able to verify your grounding.
- **Acknowledge gaps honestly.** If the loaded context doesn't answer a question, say so. You may use read-only codebase exploration tools to fill the gap, but cite what you read.
- **Ask clarifying questions when needed.** Don't guess at intent on ambiguous questions.
- **Stay grounded.** Do not speculate about future work, suggested designs, or "what we should do" beyond what is supported by the loaded context. If the operator asks for an opinion, give one — but mark it clearly as opinion, not as project fact.

The conversation continues for as many turns as the operator wants. Each turn: read the question, answer using context, cite sources, repeat.

## Step 4: Handoff Triggers

If the conversation reveals real work to be done, **do not do the work**. Hand off explicitly:

- Operator asks you to make a change → "That's real work — you'll want to invoke `/niko` so the work goes through the proper workflow."
- Conversation surfaces an open design question worth exploring with a documented outcome → "Sounds like a `/niko-creative` candidate. Want me to summarize the question for you to take into that?"
- Operator says "yeah just do it" or otherwise tries to skip the handoff → restate the contract once: "Chat is read-only by design — even with your go-ahead I shouldn't modify state from here. Drop into `/niko` and I'll do it properly there." Do not capitulate.

You may help the operator *prepare* for a handoff (e.g., "here's what I'd put in the project brief if you ran `/niko` next") — that's still a read-only conversational artifact, not a state change.
