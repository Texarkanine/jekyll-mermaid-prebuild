# Intent Clarification

Validate the user's intent before proceeding to complexity analysis. This step bridges raw, unvalidated user input into a shared understanding confirmed by the user.

## Step 1: Ingest Input

Read and absorb the user's input fully:

- If the input contains links to external resources (issues, specs, design docs), fetch and read them.
- If the input references project concepts, code, or files, research them as needed to build understanding.
- Use your judgment on how deep to go — the goal is to understand what the user wants well enough to restate it accurately.

## Step 2: Construct Restatement

Produce a restatement of the user's intent. The restatement must follow these rules:

- **Proportional sizing**: Scale the restatement to the input. Terse input gets a short restatement; verbose input gets a compressed restatement. Do not inflate simple requests into elaborate descriptions.
- **External references preserved**: If the input links to or references an external spec, issue, or document that already contains a complete intent definition, reference it by link — do not lossy-compress it into a self-contained summary. The restatement can be as minimal as "as described in [link]" when the linked resource is already authoritative.
- **Faithful**: Restate what the user said, not what you think they should have said. Do not add scope, features, or constraints the user did not request.

## Step 3: Present Restatement

Present the restatement to the user and ask for confirmation:

```markdown
**Here's my understanding of what you'd like to do:**

[restatement]

Does this capture your intent? If not, let me know what needs adjusting.
```

## Step 4: Evaluate Response

- **Approved** (user confirms, says "yes", "looks good", "proceed", or equivalent) → Done. Proceed to the next step in the `/niko` state machine.
- **Not approved** (user corrects, clarifies, or says "no") → Ask targeted questions about the gaps, do additional research if needed, then return to Step 2 with the refined understanding.

The loop ends only on user approval. Do not self-reject your own restatement — present it and let the user decide.
