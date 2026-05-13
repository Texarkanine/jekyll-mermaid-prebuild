# Level 1 Build Phase


## Step 1: Build

1. **Locate** - Find the root cause. Read error messages, trace the call path, identify the affected file(s).
2. **Test** - Write a failing test that reproduces the bug. Run it. Confirm it fails. If it passes, your test doesn't capture the bug - fix the test first.
3. **Fix** - Make the minimum change to pass the test. Resist scope creep.
4. **Verify** - Run the full test suite. No regressions.

## Step 2: Memory Bank Updates

Keep it minimal:

- **tasks.md** - Record the fix: what broke, why, what changed, files affected.
- **activeContext.md** - Update current focus to reflect completion.
- **progress.md** - Briefly record the build phase's key takeaways.

## Step 3: Phase Transition

Load the appropriate complexity level-specific Niko workflow file, then use its Phase Mappings to execute the next phase.
