# frozen_string_literal: true

require "simplecov"
require "simplecov-cobertura"

# Configure coverage formatter for CI environments (Codecov)
SimpleCov.start do
  formatter SimpleCov::Formatter::CoberturaFormatter if ENV["CI"]

  add_filter "/spec/"
  add_filter "/vendor/"
end

require "tmpdir"
require "jekyll"
require "jekyll-mermaid-prebuild"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Create a temporary directory for testing
  config.around do |example|
    Dir.mktmpdir do |dir|
      @temp_dir = dir
      example.run
    end
  end
end
