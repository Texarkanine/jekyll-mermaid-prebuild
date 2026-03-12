# Active Context

## Current Task: svg-post-processing
**Phase:** PLAN REVISION — incorporating emoji width compensation discovery

## What Changed Since Build Completion

After the initial build (foreignObject widening + max_width handling), user testing revealed:

1. **foreignObject width manipulation breaks centering.** The inner `<div>` uses `display: table-cell` which shrink-wraps to content width. Widening the foreignObject creates empty space that the div doesn't fill, causing text to appear left- or right-aligned depending on transform adjustments. This was the wrong fix — removed entirely.

2. **The real clipping root cause is emoji width mismatch.** Puppeteer's headless Chrome undermeasures emoji glyphs when sizing foreignObject elements. Example: Puppeteer measures "🔧 Code" at 55.66px; the same string in desktop browsers needs ~63-65px due to wider emoji rendering. The foreignObject is sized to Puppeteer's measurement and clips in the viewing browser.

3. **User discovered the fix:** Adding `&nbsp;` (non-breaking space) characters to Mermaid source labels compensates for emoji undermeasurement. Each emoji needs ~2 `&nbsp;` characters. The `&nbsp;` is "sacrificial" width — Puppeteer allocates space for it, and in the viewing browser the emoji's true wider rendering consumes that padding. Trailing whitespace is invisible or overflow-clipped.

4. **max_width handling is correct and stays.** Removing/replacing the hardcoded `max-width` inline style on the root `<svg>` is the right approach for responsive sizing.

## Current State of Code

- `SvgPostProcessor.process` now only handles root SVG `adjust_root_svg_width` (max-width + width="100%")
- foreignObject width manipulation, recenter_label_transform, FOREIGN_OBJECT_MARGIN, TRANSLATE_RE — all removed
- 73/73 tests pass, RuboCop clean
- Devblog builds correctly with centered, unmodified node content

## New Approach: Mermaid Source Preprocessing

Instead of post-processing the SVG output, preprocess the Mermaid source BEFORE passing it to mmdc:

1. Parse node labels in the Mermaid source (text within `["..."]`, `("...")`, etc.)
2. Count emoji characters per label (Ruby: `\p{Extended_Pictographic}` or codepoint ranges)
3. For each emoji, append 2 `&nbsp;` to the label text
4. Pass the padded source to mmdc — Puppeteer now measures correct widths natively
5. Centering, layout, foreignObject sizing all handled correctly by Puppeteer

This is opt-in via config: `emoji_width_compensation: true` (or similar).

## Next Step
- Update the task plan for the new preprocessing approach
- Proceed to build the Mermaid source preprocessor
