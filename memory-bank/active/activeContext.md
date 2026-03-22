# Active Context

## Current Task: ci-foreignobject-clip-fix
**Phase:** PLAN - COMPLETE (amended)

## What Was Done
- Original overflow fix built and QA passed (7 new tests, 110 total)
- User requested: (1) all postprocessing features togglable via config booleans, (2) `postprocessing:` config group, (3) `emoji_width_compensation` moves under it, (4) `block_edge_label_padding` renamed to `edge_label_padding` and block restriction dropped
- Re-planned with 5 implementation steps across Configuration, SvgPostProcessor, Generator, Processor, docs

## Key Decisions
- Breaking config change (pre-1.0, clean break, no shimming)
- `text_centering` and `overflow_protection` default to `true` (safe defaults)
- `edge_label_padding` default `0` (opt-in, as before)
- Padding applies to ALL diagram types, not just block
- Overflow:visible fixes NODE labels (background is node shape); padding fixes EDGE labels (background is foreignObject container)

## Next Step
- Preflight → Build
