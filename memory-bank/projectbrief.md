# Project Brief: jekyll-mermaid-prebuild

## Overview
A Jekyll plugin (Ruby gem) that renders mermaid diagrams to SVG at build-time using the `mmdc` CLI tool.

## Motivation
- Client-side mermaid.js is ~2MB minified
- Build-time SVG generation is more performant and accessible
- Static SVGs are cacheable by browsers/CDN

## Goals
1. Scan markdown for mermaid code blocks (before rendering)
2. Convert mermaid definitions to SVG using `mmdc` CLI
3. Replace code blocks with clickable image references
4. Cache generated SVGs for rebuild performance

## Dependencies
- `mmdc` (mermaid CLI) - must be installed on system
- Puppeteer system libraries (for headless Chrome)

## Reference Implementations
- `jekyll-auto-thumbnails`: Pattern for wrapping external CLI tools
- `jekyll-highlight-cards`: Pattern for Jekyll plugin gems with TDD

## Development Phases
1. **Phase 1** (Complete): Built as local plugin in `devblog/_plugins/`
2. **Phase 2** (Complete): Extracted to standalone gem with TDD, ready for RubyGems
