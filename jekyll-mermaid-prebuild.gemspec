# frozen_string_literal: true

require_relative "lib/jekyll-mermaid-prebuild/version"

Gem::Specification.new do |spec|
  spec.name = "jekyll-mermaid-prebuild"
  spec.version = JekyllMermaidPrebuild::VERSION
  spec.authors = ["Texarkanine"]
  spec.email = ["texarkanine@protonmail.com"]

  spec.summary = "Pre-render mermaid diagrams to SVG at Jekyll build time"
  spec.description = "Jekyll plugin that converts mermaid diagram code blocks to SVG files " \
                     "at build time using the mmdc CLI. Eliminates the need for client-side " \
                     "mermaid.js (~2MB) by generating static SVG files with intelligent caching."
  spec.homepage = "https://github.com/Texarkanine/jekyll-mermaid-prebuild"
  spec.license = "AGPL-3.0-or-later"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/Texarkanine/jekyll-mermaid-prebuild"
  spec.metadata["changelog_uri"] = "https://github.com/Texarkanine/jekyll-mermaid-prebuild/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir[
    "*.gemspec",
    "lib/**/*.rb",
    "LICENSE",
    "README.md",
    "CHANGELOG.md"
  ]
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "jekyll", ">= 4.0", "< 5.0"

  # Development dependencies
  spec.add_development_dependency "rake", "~> 13.3"
  spec.add_development_dependency "rspec", "~> 3.13"
  spec.add_development_dependency "rubocop", "~> 1.81"
  spec.add_development_dependency "rubocop-rake", "~> 0.7"
  spec.add_development_dependency "rubocop-rspec", "~> 3.8"
  spec.add_development_dependency "simplecov", "~> 0.22"
  spec.add_development_dependency "simplecov-cobertura", "~> 3.1"
end
