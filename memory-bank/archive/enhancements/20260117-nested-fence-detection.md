# TASK ARCHIVE: Nested Fence Detection

## METADATA

| Field | Value |
|-------|-------|
| Task ID | nested-fence-detection |
| Date | 2026-01-17 |
| Complexity | Level 2 (Enhancement) |
| Branch | allow-literals |
| Status | COMPLETE |

## SUMMARY

Added support for preserving mermaid code blocks that appear inside other code fences. This allows users to write documentation about mermaid syntax without the examples being converted to SVGs.

Before this change, a mermaid block inside a `````markdown` fence would be converted to an SVG, making it impossible to show mermaid syntax examples in blog posts or documentation.

## REQUIREMENTS

1. Mermaid blocks nested inside other code fences should be preserved as literal code
2. Top-level mermaid blocks should continue to be converted to SVG
3. Must handle both backtick and tilde fence styles
4. Must handle arbitrary nesting depth
5. No changes to user-facing syntax required (preserve default behavior)

## IMPLEMENTATION

### Approach: State Machine for Fence Tracking

Replaced simple regex-based `gsub` with a state machine that:
1. Parses document line-by-line
2. Tracks fence nesting depth with a stack
3. Only processes mermaid blocks at depth 0 (top level)

### Key Files Changed

- `lib/jekyll-mermaid-prebuild/processor.rb` - Complete rewrite of `process_content` method
  - Added `find_top_level_mermaid_blocks` method
  - Extracted helper methods: `process_line`, `handle_fence_line`, `handle_line_in_mermaid`, `handle_line_at_top_level`, `handle_line_in_nested_fence`

### Tests Added

3 new test cases in `spec/jekyll_mermaid_prebuild/processor_spec.rb`:
- `only converts top-level mermaid blocks, not nested examples`
- `preserves nested mermaid blocks inside tilde fences`
- `handles deeply nested fences correctly`

## TESTING

### TDD Process
1. Wrote failing tests first that demonstrated the bug
2. Tests showed: expected 1 conversion, got 2 (nested example incorrectly processed)
3. Implemented fix until tests passed
4. Refactored for rubocop compliance

### Final Test Results
- 47 tests, all passing
- No rubocop offenses
- Verified in devblog with real content

## LESSONS LEARNED

1. **Default behavior matters** - Users shouldn't have to change syntax to maintain existing behavior. The nested fence approach works because it follows existing markdown conventions.

2. **Condition order in state machines** - Check most specific state first (`current_mermaid`), then progressively more general (`fence_stack.empty?`).

3. **Discuss design before implementing** - Initial suggestion (`mermaid-syntax` identifier) was rejected, leading to a better solution.

4. **Regex can't track nesting** - Some problems require state machines, not pattern matching.

## REFERENCES

- Reflection: `memory-bank/reflection/reflection-nested-fence-detection.md`
- PR: https://github.com/Texarkanine/jekyll-mermaid-prebuild/pull/new/allow-literals
- Related blog post: `devblog/blog/diary/_posts/2026-01-17-2mb-lighter.md`
