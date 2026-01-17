# Contributing to jekyll-mermaid-prebuild

## Development Setup

### Prerequisites

- Ruby 3.1 or higher
- Bundler
- Node.js and npm (for mermaid-cli)
- mermaid-cli (`npm install -g @mermaid-js/mermaid-cli`)

### Clone and Setup

```bash
git clone https://github.com/Texarkanine/jekyll-mermaid-prebuild.git
cd jekyll-mermaid-prebuild
bundle install
```

### Running Tests

Run the full test suite:

```bash
bundle exec rspec
```

Run specific test file:

```bash
bundle exec rspec spec/processor_spec.rb
```

Run with coverage report:

```bash
bundle exec rspec
open coverage/index.html
```

### Code Quality

Check code style:

```bash
bundle exec rubocop
```

Auto-fix style issues:

```bash
bundle exec rubocop --autocorrect
```

## Development Workflow

### TDD Approach

This project follows Test-Driven Development:

1. **Write tests first** - Define expected behavior in specs
2. **Run tests** - Watch them fail (red)
3. **Write code** - Implement to make tests pass (green)
4. **Refactor** - Improve code while keeping tests green
5. **Verify** - Run full suite and Rubocop

### Adding Features

1. Create feature branch: `git checkout -b feature/my-feature`
2. Write tests in `spec/`
3. Implement feature in `lib/`
4. Run tests: `bundle exec rspec`
5. Check style: `bundle exec rubocop`
6. Commit with conventional commit format
7. Push and create pull request

### Commit Messages

Use conventional commit format:

- `feat: Add new feature`
- `fix: Fix bug in XYZ`

## Testing Guidelines

### Test Coverage

- Cover happy paths and edge cases
- Test error handling
- Mock external dependencies (mmdc, file I/O)

### Test Structure

```ruby
RSpec.describe MyModule do
  describe ".method_name" do
    context "with valid input" do
      it "returns expected result" do
        # test code
      end
    end
    
    context "with invalid input" do
      it "raises appropriate error" do
        # test code
      end
    end
  end
end
```

## Project Structure

```
jekyll-mermaid-prebuild/
├── lib/
│   ├── jekyll-mermaid-prebuild.rb      # Main entry point
│   └── jekyll-mermaid-prebuild/
│       ├── version.rb                   # Version constant
│       ├── configuration.rb             # Config parsing
│       ├── digest_calculator.rb         # MD5 computation
│       ├── mmdc_wrapper.rb              # mermaid-cli wrapper
│       ├── generator.rb                 # SVG generation
│       ├── processor.rb                 # Content processing
│       └── hooks.rb                     # Jekyll integration
├── spec/                                # Test files
│   ├── spec_helper.rb
│   └── *_spec.rb                        # Tests for each module
└── jekyll-mermaid-prebuild.gemspec      # Gem specification
```

## Building and Installing

### Build the Gem

```bash
gem build jekyll-mermaid-prebuild.gemspec
```

### Install Locally

```bash
gem install ./jekyll-mermaid-prebuild-*.gem
```

Or in a test Jekyll site's Gemfile:

```ruby
gem 'jekyll-mermaid-prebuild', path: '/path/to/jekyll-mermaid-prebuild'
```

## Questions?

Open an issue on GitHub for questions, bug reports, or feature requests.
