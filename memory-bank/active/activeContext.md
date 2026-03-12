# Active Context

## Current Task: svg-post-processing
**Phase:** PLAN — revised scope, ready for build

## Scope Change: max_width / SvgPostProcessor removed

User confirmed via Chrome DevTools testing on the live site that SVGs scale correctly without any `max-width` manipulation. The original clipping symptom was entirely caused by emoji width undermeasurement, not container compression. The `SvgPostProcessor`, `max_width` config, Nokogiri dependency, and all related tests/integration are being removed.

## Current Scope: Emoji Width Compensation Only

Single focused feature: preprocess Mermaid source before mmdc to pad emoji-containing node labels with `&nbsp;`. This compensates for headless Chromium's emoji width undermeasurement on non-Mac platforms.

Key constraint: the padding belongs in the plugin, NOT in the source files, because `&nbsp;` renders incorrectly in GitHub preview, IDE preview, mermaid.live, and client-side mermaid.js. The blog content is bound to multiple rendering pipelines.

## Current State of Code

- `SvgPostProcessor` exists but is slated for deletion (Step 0)
- `max_width` config exists but is slated for removal (Step 0)
- Nokogiri dependency exists but is slated for removal (Step 0)
- Generator has `post_process_svg` integration — slated for removal (Step 0)
- 73/73 tests currently pass, RuboCop clean

## Implementation Plan

0. **Remove max_width / SvgPostProcessor** — delete dead code, remove Nokogiri, update tests
1. **Configuration** — add `emoji_width_compensation` (Hash of diagram types to booleans)
2. **EmojiCompensator** — new module: detect diagram type, find emoji in labels, append `&nbsp;`
3. **Processor** — integrate: detect type → check config → compensate → cache key
4. **Documentation** — README with clear when/why/how guidance

## Next Step

Proceed to build (Step 0 first: cleanup removal)
