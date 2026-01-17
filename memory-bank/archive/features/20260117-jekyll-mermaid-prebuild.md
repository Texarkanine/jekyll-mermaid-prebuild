# TASK ARCHIVE: jekyll-mermaid-prebuild

## METADATA
- **Task ID**: jekyll-mermaid-prebuild
- **Complexity**: Level 3 (Feature with multiple phases)
- **Start Date**: 2026-01-16
- **Complete Date**: 2026-01-17
- **Status**: COMPLETE

## SUMMARY

Built a Jekyll plugin gem that renders mermaid diagrams to SVG at build-time using the `mmdc` CLI. Development occurred in two phases: rapid prototyping as a local plugin, then extraction to a proper Ruby gem with TDD.

## REQUIREMENTS

1. Scan markdown for mermaid code blocks (both ``` and ~~~ fences)
2. Convert mermaid definitions to SVG using `mmdc` CLI
3. Replace code blocks with clickable image references
4. Cache generated SVGs for rebuild performance
5. Provide helpful error messages for Puppeteer dependency issues
6. Support configurable output directory
7. Package as publishable Ruby gem with tests and CI/CD

## IMPLEMENTATION

### Phase 1: Local Plugin
- Single file `_plugins/mermaid_prebuild.rb` (~360 lines)
- Rapid iteration with `jekyll build` feedback loop
- Key decisions: pre-render markdown processing, external SVG files, content-based caching

### Phase 2: Gem Extraction
- 6 modules: Configuration, DigestCalculator, MmdcWrapper, Generator, Processor, Hooks
- 42 RSpec tests with 65% coverage
- CI/CD via GitHub Actions + release-please
- RuboCop clean with rubocop-rake + rubocop-rspec

### Gem Structure
```
lib/jekyll-mermaid-prebuild/
├── version.rb
├── configuration.rb
├── digest_calculator.rb
├── mmdc_wrapper.rb
├── generator.rb
├── processor.rb
└── hooks.rb
```

## TESTING

- **Phase 1**: Manual testing with 3 mermaid diagrams in blog post
- **Phase 2**: 42 RSpec examples covering all modules
- **Integration**: devblog successfully builds using gem via local path

## LESSONS LEARNED

### Technical
1. Use `:post_read` hook (not `:after_init`) for persistent `site.data`
2. Pre-render markdown processing is cleaner than post-render HTML
3. Mock `Kernel.system` for CLI wrapper tests
4. Match reference implementation dependency versions exactly

### Process
1. Local plugin prototyping before gem extraction speeds iteration
2. TDD during extraction catches interface issues early
3. Don't overthink tooling config mid-task—pick a baseline and move on

### Patterns Established
1. Jekyll hook registration patterns for plugin gems
2. CLI wrapper pattern with availability checking and error detection
3. Content-based caching with MD5 digests

## REFERENCES

- **Reflection**: `memory-bank/reflection/reflection-mermaid-prebuild.md`
- **Reference Gems**: jekyll-auto-thumbnails, jekyll-highlight-cards
- **Test Blog Post**: `devblog/blog/record/_posts/2026-01-16-all-it-took-was-broken-firmware.md`

## FILES CHANGED

### Created (gem)
- `lib/jekyll-mermaid-prebuild.rb` - entry point
- `lib/jekyll-mermaid-prebuild/*.rb` - 7 module files
- `spec/jekyll_mermaid_prebuild/*_spec.rb` - 6 spec files
- `spec/spec_helper.rb`
- `jekyll-mermaid-prebuild.gemspec`
- `README.md`, `CHANGELOG.md`, `CONTRIBUTING.md`
- `.github/workflows/ci.yaml`, `.github/workflows/release-please.yaml`
- `.rubocop.yml`, `.rspec`, `.ruby-version`, `.gitignore`
- `release-please-config.json`, `.release-please-manifest.json`
- `.github/dependabot.yaml`

### Modified (devblog)
- `Gemfile` - added gem with local path

### Deleted (devblog)
- `_plugins/mermaid_prebuild.rb` - replaced by gem
