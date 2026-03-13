# System Patterns

## How This System Works

This is a Jekyll plugin gem that hooks into three points of the Jekyll build lifecycle:

1. **`:post_read`** — Loads configuration, checks `mmdc` availability, and creates shared `Generator` and `Processor` instances stored in `site.data`. This hook (not `:after_init`) is used because `site.data` is not reliably persistent before `:post_read`.
2. **`:pre_render`** — Processes each document's and page's raw markdown *before* Jekyll's markdown engine runs. Mermaid code blocks are identified and replaced with image references pointing to pre-generated SVGs.
3. **`:post_write`** — Copies the generated SVG files into the `_site` output directory.

Content is processed **before** markdown rendering. This is a deliberate design choice: operating on raw markdown (fence-level parsing) is significantly simpler and more reliable than parsing rendered HTML.

### Fence Parsing: State Machine, Not Regex

The processor uses a line-by-line state machine with a fence stack to track nesting depth. Only mermaid blocks at depth 0 (top level) are converted; blocks nested inside other code fences are preserved as literal code. The closing fence must match the opening fence's type (backtick vs. tilde); for mermaid blocks, the length must match exactly, while nested non-mermaid fences follow CommonMark's "at least as long" rule.

### Shared State via `site.data`

`Configuration`, `Generator`, and `Processor` instances are created once in `:post_read` and stored in `site.data["mermaid_prebuild"]`. All subsequent hooks read from this shared location. This is the plugin's dependency injection mechanism — there is no global state or class-level singletons.

## CLI Wrapper with Availability Gating

`MmdcWrapper` wraps the external `mmdc` binary. It performs an availability check (`which mmdc`) once and caches the result. All downstream code checks availability before attempting generation, so a missing `mmdc` produces a clear warning rather than a crash. The wrapper shells out via `Kernel.system` and inspects exit status and stderr for error detection.

## Content-Based Caching

`DigestCalculator` produces an 8-character MD5 hex digest of diagram source content. `Generator` uses this as a cache key under `.jekyll-cache/jekyll-mermaid-prebuild/`. If the cached SVG exists, generation is skipped entirely. This means unchanged diagrams survive full rebuilds without re-invoking Puppeteer/Chrome.

## Module Organization

All modules live under the `JekyllMermaidPrebuild` namespace. Stateless utility modules (`DigestCalculator`, `MmdcWrapper`, `Hooks`) use `module_function` — they have no instance state and are called directly on the module. Stateful components (`Configuration`, `Generator`, `Processor`) are classes instantiated per-build.
