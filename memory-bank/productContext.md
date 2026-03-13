# Product Context

## Target Audience

Jekyll site maintainers who use Mermaid diagrams in their markdown content and want faster, lighter pages without client-side JavaScript rendering.

## Use Cases

- **Documentation sites** — Architecture diagrams, flowcharts, and sequence diagrams embedded in markdown, rendered as static SVGs at build time.
- **Blogs** — Technical posts with inline diagrams that don't require the ~2 MB mermaid.js client library.
- **Mermaid syntax documentation** — Posts or pages that *discuss* mermaid syntax can include literal mermaid code blocks inside nested fences without them being converted.

## Key Benefits

- **Eliminates client-side mermaid.js** — Diagrams are pre-rendered to SVG during `jekyll build`, removing a large JavaScript dependency from the browser.
- **Content-based caching** — Unchanged diagrams are not re-rendered on subsequent builds, keeping incremental builds fast.
- **Zero syntax changes** — Standard mermaid fenced code blocks work as-is; no custom Liquid tags or shortcodes needed.
- **Clickable SVGs** — Generated images link to the full-size SVG for detail inspection.

## Success Criteria

- All top-level mermaid code blocks in markdown are replaced with static SVG images at build time.
- Nested mermaid blocks (e.g., inside documentation examples) are left untouched as literal code.
- Cache prevents redundant regeneration of unchanged diagrams.
- Clear, actionable error messages surface when `mmdc` or Puppeteer dependencies are missing or misconfigured.

## Key Constraints

- Requires `mmdc` (mermaid-cli) installed and on `PATH`; this in turn requires Node.js and Puppeteer with a compatible Chromium binary.
- Linux/WSL environments may need additional system libraries for headless Chromium.
- Processing happens at `:pre_render`, so diagrams must be valid mermaid before markdown rendering occurs.
