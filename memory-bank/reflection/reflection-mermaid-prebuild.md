# Reflection: jekyll-mermaid-prebuild

**Task**: Build a Jekyll plugin that renders mermaid diagrams to SVG at build-time
**Complexity**: Level 2 (local plugin) → Level 3 (gem extraction)
**Status**: Complete (Phase 1 + Phase 2)

## Summary

Successfully built a Jekyll plugin (`_plugins/mermaid_prebuild.rb`) that converts mermaid code blocks to SVG files at build time using the `mmdc` CLI. The plugin processes markdown before rendering, generates cached SVG files, and outputs clickable image references.

## What Went Well

### 1. Reference Implementation Strategy
Following the `jekyll-auto-thumbnails` patterns proved highly effective:
- Hook registration patterns translated directly
- CLI wrapper approach (checking availability, capturing errors) was reusable
- Caching strategy (content-based MD5 hash) worked well

### 2. Iterative Development
Starting as a local plugin in `_plugins/` allowed rapid iteration:
- Quick feedback loop with `jekyll build`
- Easy debugging with Jekyll's logger
- No gem packaging overhead during development

### 3. Error Messaging
The Puppeteer dependency error detection and helpful messaging worked well:
- Proactive check on initialization (test render)
- Specific error detection (libgbm, browser process)
- Actionable remediation instructions

## Challenges Encountered

### 1. Jekyll Hook Timing (`site.data` persistence)
**Problem**: Initial implementation used `:site, :after_init` to set `site.data['mermaid_prebuild_enabled']`, but the value was nil in `:site, :pre_render`.

**Root Cause**: `site.data` is reset between `:after_init` and `:pre_render`.

**Solution**: Use `:site, :post_read` instead - data persists after this hook.

**Lesson**: Jekyll hook timing matters. The hook sequence is: `after_init` → `after_reset` → `post_read` → `pre_render` → `post_render` → `post_write`. Data set in early hooks may not persist.

### 2. Markdown vs HTML Processing
**Initial Approach**: Process rendered HTML to find `<pre><code class="language-mermaid">` blocks.

**Problem**: More complex regex, HTML entity decoding needed, harder to replace cleanly.

**Revised Approach**: Process markdown BEFORE rendering using `:site, :pre_render` hook.

**Benefits**:
- Simpler regex for code fences
- Generated SVGs become proper static assets
- Works with Jekyll's natural flow
- Images are cacheable by browsers/CDN

### 3. Code Fence Pattern Complexity
**Initial Regex**: Only matched backtick fences (`` ``` ``)

**Requirement**: Support both backticks and tildes (`~~~`), with 3+ characters

**Solution**: Use backreference in regex to ensure closing fence matches opening:
```ruby
%r{^(`{3,}|~{3,})mermaid\s*\n(.*?)^\1\s*$}mx
```

**Note**: Backticks in Ruby regex literals are just literal characters (not shell execution).

### 4. Puppeteer Dependencies in WSL
**Problem**: `mmdc` uses Puppeteer (headless Chrome), which needs system libraries not present in WSL by default.

**Solution**: Document required packages and add detection with helpful error messages.

## Lessons Learned

1. **Hook Selection Matters**: Choose Jekyll hooks based on what data you need and when. `:post_read` is the safe choice for storing site-wide state.

2. **Pre-render is Powerful**: Processing content before markdown rendering gives more control and simpler code than post-processing HTML.

3. **Test External Dependencies Early**: The mmdc/Puppeteer dependency issue was only discovered at runtime. The proactive test render on initialization catches this immediately.

4. **Configuration Should Be Optional**: Providing sensible defaults (`assets/svg`) while allowing override keeps the plugin usable out-of-the-box.

5. **Let Other Plugins Do Their Job**: By outputting simple `<a><img></a>` markup, other plugins (like `href_decorator`) can add their own attributes without interference.

## Technical Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Processing stage | Pre-render (markdown) | Cleaner output, proper static assets |
| SVG storage | External files | Cacheable, clickable, inspectable |
| Caching | MD5 content hash | Deterministic, content-addressed |
| Default output dir | `assets/svg` | Consistent with Jekyll conventions |
| Error handling | Keep original on failure | Graceful degradation |

## Metrics

- **Lines of Code**: ~360
- **Build Time Impact**: +5s initial (mmdc rendering), ~0s cached
- **Test Coverage**: Manual testing with 3 diagrams
- **Diagrams Converted**: 3 in test blog post

## Future Improvements

1. **Configuration Options**:
   - Custom alt text (extract from mermaid title/description)
   - Figure caption support
   - CSS class customization

2. **Performance**:
   - Parallel mmdc execution for multiple diagrams
   - Incremental builds (only process changed files)

3. **CI/CD**:
   - Document Puppeteer dependencies for GitHub Actions
   - Add Docker support for consistent builds

---

# Phase 2: Gem Extraction

**Complexity**: Level 3
**Status**: Complete

## Summary

Extracted the local plugin into a standalone Ruby gem with TDD, CI/CD, and documentation. The gem follows patterns from `jekyll-auto-thumbnails` and `jekyll-highlight-cards`.

## What Went Well

### 1. Module Decomposition
The monolithic 360-line plugin split cleanly into 6 focused modules:
- `Configuration` - config parsing
- `DigestCalculator` - content hashing
- `MmdcWrapper` - CLI interaction
- `Generator` - SVG generation + HTML building
- `Processor` - content scanning + replacement
- `Hooks` - Jekyll lifecycle integration

Each module has a single responsibility and is independently testable.

### 2. TDD Approach
Writing tests first for each module caught design issues early:
- Forced clear interfaces between modules
- Made mocking strategies explicit (e.g., `Kernel.system` for CLI calls)
- 42 tests, all passing

### 3. Reference Gem Patterns
Having `jekyll-auto-thumbnails` and `jekyll-highlight-cards` as templates made setup fast:
- Gemspec structure
- CI/CD workflows (GitHub Actions, release-please)
- RuboCop configuration baseline

## Challenges Encountered

### 1. SimpleCov/Cobertura Version Mismatch
**Problem**: `simplecov-cobertura ~> 2.1` caused XML parsing errors.

**Solution**: Updated to `~> 3.1` to match `jekyll-auto-thumbnails`.

**Lesson**: When following a reference implementation, match dependency versions exactly.

### 2. RuboCop Configuration Drift
**Problem**: Spent too much time tweaking RuboCop config reactively—disabling cops one by one as they complained.

**Root Cause**: Didn't start with a clear baseline. The three Jekyll plugin gems have inconsistent rubocop configs.

**Solution**: Settled on using `rubocop-rspec` (like `jekyll-highlight-cards`) with sensible relaxations. Documented recommendation to standardize across all three gems later.

**Lesson**: Establish tooling standards before building multiple related projects.

### 3. Mocking Kernel Methods
**Problem**: `allow(described_class).to receive(:system)` didn't work for mocking CLI calls.

**Solution**: Use `allow(Kernel).to receive(:system)` because `system` is a Kernel method.

### 4. Spec Directory Structure Decision
**Problem**: Flat vs nested spec directories. RuboCop's `RSpec/SpecFilePathFormat` cop expects nested.

**Decision**: Use nested (`spec/jekyll_mermaid_prebuild/*.rb`) for:
- RuboCop compliance
- Clearer organization as gem grows
- Consistency with `jekyll-highlight-cards`

## Lessons Learned

1. **Match Reference Implementations Closely**: When following a pattern, copy dependency versions and configurations exactly before customizing.

2. **Don't Overthink Tooling**: Spent too long on rubocop config. Should have picked a working baseline and moved on.

3. **Hooks Modules Are Inherently Complex**: Jekyll hook registration involves callbacks with closures. Metrics cops will complain. Just exclude the file.

4. **TDD Pays Off for Extraction**: Writing tests first made the extraction smooth—each module's interface was validated before integration.

## Metrics

| Metric | Phase 1 (Plugin) | Phase 2 (Gem) |
|--------|------------------|---------------|
| Files | 1 | 8 lib + 6 spec |
| Lines | ~360 | ~500 lib, ~600 spec |
| Tests | Manual | 42 RSpec |
| Coverage | N/A | 65% |
| RuboCop | N/A | 0 offenses |

## Technical Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Spec structure | Nested dirs | RuboCop compliance, scalability |
| RuboCop plugins | rake + rspec | Full linting coverage |
| CI | GitHub Actions | Matches other gems |
| Releases | release-please | Automated changelog + versioning |
| Local testing | path in Gemfile | Fast iteration before publish |
