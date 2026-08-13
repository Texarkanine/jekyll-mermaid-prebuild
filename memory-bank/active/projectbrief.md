# Project Brief

## User Story

As a site author watching a Jekyll build, I want MermaidPrebuild completion logs to include elapsed time so I can see how much of the build conversion and SVG copy consumed.

## Use-Case(s)

### Use-Case 1

A CI build prints `MermaidPrebuild: Total: 58 diagram(s) converted in 12s` and `MermaidPrebuild: Copied 58 SVG(s) to assets/svg/ in 1s`.

### Use-Case 2

A long conversion step prints `Total: 58 diagram(s) converted in 7 m 2 s` when elapsed time is a minute or more.

## Requirements

1. Append elapsed time to the `Total: N diagram(s) converted` line from `Hooks.process_site` when that line is emitted.
2. Append elapsed time to the `Copied N SVG(s) to …` completion line from `Hooks.copy_svgs_to_site`.
3. Format under one minute as `in Xs` (integer seconds). Format one minute or more as `in X m Y s`.
4. Do not add elapsed time to per-document `Converted N diagram(s) in path` lines.

## Constraints

1. No new runtime dependencies.
2. Preserve existing hook behavior, cache semantics, and conversion contracts.
3. Public interface is the Jekyll hook log output; exact log-string specs must be updated.

## Acceptance Criteria

1. `Total: N diagram(s) converted` includes a trailing elapsed-time suffix when the line is emitted.
2. `Copied N SVG(s) to …` includes a trailing elapsed-time suffix.
3. Sub-minute times use `in Xs`; times of 60 seconds or more use `in X m Y s`.
4. Existing MermaidPrebuild behavior is unchanged aside from those log suffixes.
