# Reflection: Nested Fence Detection

**Date:** 2026-01-17
**Branch:** allow-literals
**Status:** Completed

## Summary

Implemented support for preserving mermaid code blocks that appear inside other code fences. This allows users to write documentation about mermaid syntax without the examples being converted to SVGs.

## What Went Well

### TDD Process
- Started with failing tests that clearly demonstrated the bug
- Tests exposed the issue: expected 1 conversion, got 2 (nested example was incorrectly processed)
- Having the failing tests made it clear when the fix was correct

### Design Discussion Before Implementation
- Explored multiple approaches before coding:
  - Alternative language identifier (`mermaid-syntax`) - rejected as backwards (changes default behavior)
  - Config exclusion patterns - too coarse-grained
  - HTML comment directives - hacky
  - Nested fence detection - chosen as most "markdown-native"
- The discussion prevented implementing a solution users would dislike

### Clean Refactoring
- Initial implementation worked but had rubocop violations (method too long, block too long)
- Extracted helper methods: `process_line`, `handle_fence_line`, `handle_line_in_mermaid`, etc.
- Final code is more readable and maintainable
- All 47 tests pass with no rubocop offenses

## Challenges

### Logic Flow Bug
- First implementation had a subtle bug: after starting a mermaid block, the closing fence check was never reached
- The condition order `if fence_stack.empty? ... elsif current_mermaid` was wrong
- Fixed by checking `current_mermaid` first, before `fence_stack.empty?`

### Regex vs State Machine Trade-off
- Original implementation used simple regex with `gsub` - elegant but can't understand nesting
- New implementation is a proper state machine tracking fence boundaries
- More code, but correctly handles the edge case that regex cannot

## Lessons Learned

### Default Behavior Matters
- User pushed back on `mermaid-syntax` because it required changing behavior to maintain old expectations
- Better principle: new features should enhance, not require migration for existing use cases
- The nested fence approach works because users already use nested fences for documentation

### Condition Order in State Machines
- When tracking multiple states (in_mermaid, in_nested_fence, at_top_level), the check order matters
- Check the most specific state first (current_mermaid), then progressively more general

### Extracting Methods Helps Reasoning
- The 50-line method was hard to verify correct
- Breaking into `handle_line_in_mermaid`, `handle_line_at_top_level`, `handle_line_in_nested_fence` made each case obvious

## Technical Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Processing approach | State machine | Regex can't track nesting depth |
| State representation | Hash with `:fence_stack`, `:current_mermaid` | Mutable state passed through helper methods |
| Fence closing detection | Same type, >= length, only fence chars | Matches CommonMark spec |

## Process Improvements

- **Discuss design before implementing** - the user rejected my first suggestion, leading to a better solution
- **Write regression tests first** - clearly showed the bug and when it was fixed
- **Refactor after green** - got tests passing first, then cleaned up for rubocop

## Next Steps

- PR review and merge to main
- Release new version (v0.3.0) with this feature
- Update documentation/README to mention the behavior
