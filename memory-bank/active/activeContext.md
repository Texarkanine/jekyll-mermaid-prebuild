# Active Context

## Current Task: ci-foreignobject-clip-fix
**Phase:** PLAN - COMPLETE

## What Was Done
- Complexity analysis: L2, bug fix with cross-environment investigation
- Compared actual SVGs: CI foreignObject widths 7–22% narrower than local (non-uniform delta)
- User confirmed font SIZES also differ, not just metrics
- Designed fix: inject `foreignObject{overflow:visible;}` CSS — same pattern as existing `ensure_text_centering`
- Plan written to tasks.md: 2 TDD cycles + docs update

## Key Decisions
- `overflow:visible` chosen over padding because the width delta is non-uniform (7–22%) and per-label — no fixed/percentage pad can reliably cover it
- New method `ensure_foreignobject_overflow` follows existing `ensure_text_centering` pattern (idempotent, always-on, CSS injection)
- No config changes needed — fix is unconditional
- Existing `block_edge_label_padding` feature left as-is (optional belt-and-suspenders)

## Next Step
- Preflight → Build
