# Tech Context

Ruby gem (Jekyll plugin) that shells out to `mmdc` (mermaid-cli) for SVG generation. Packaged as a RubyGem, consumed by Jekyll sites via Bundler.

## Environment Setup

- Ruby version pinned in `.ruby-version`
- `mmdc` must be installed globally (`npm install -g @mermaid-js/mermaid-cli`) and on `PATH`
- On Linux/WSL, Puppeteer's Chromium may require additional system libraries (see mermaid-cli docs)

## Build Tools

- **Bundler** — Dependency management via `Gemfile` (which defers to the gemspec for runtime + dev deps). Run `bundle install` to set up.
- **Gem build** — `gem build jekyll-mermaid-prebuild.gemspec` produces the `.gem` artifact.
- **Release** — Automated via Release Please (config in `release-please-config.json` and `.release-please-manifest.json`); CI publishes to RubyGems.

## Testing Process

- **RSpec** — Test framework, configured in `.rspec`. Specs live in `spec/jekyll_mermaid_prebuild/`, one file per module.
- **Run**: `bundle exec rspec`
- **Coverage**: SimpleCov with Cobertura output for CI (Codecov integration).
- **Linting**: RuboCop with `rubocop-rake` and `rubocop-rspec` plugins, configured in `.rubocop.yml`. Run: `bundle exec rubocop`.
- **CI**: GitHub Actions workflow in `.github/workflows/ci.yaml` runs both RSpec and RuboCop on PRs.
