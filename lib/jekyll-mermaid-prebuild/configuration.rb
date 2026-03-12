# frozen_string_literal: true

module JekyllMermaidPrebuild
  # Configuration wrapper for site config
  class Configuration
    DEFAULT_OUTPUT_DIR = "assets/svg"
    CACHE_DIR = ".jekyll-cache/jekyll-mermaid-prebuild"

    attr_reader :output_dir, :max_width

    # Initialize configuration from Jekyll site
    #
    # @param site [Jekyll::Site] the Jekyll site
    def initialize(site)
      config = site.config["mermaid_prebuild"] || {}
      @output_dir = parse_output_dir(config["output_dir"])
      @enabled = config.fetch("enabled", true)
      @max_width = parse_max_width(config["max_width"])
    end

    # Check if the plugin is enabled
    #
    # @return [Boolean] true if enabled
    def enabled?
      @enabled
    end

    # Get the cache directory path
    #
    # @return [String] cache directory path
    def cache_dir
      CACHE_DIR
    end

    private

    # Validate and return a positive integer max_width, or nil if invalid/absent.
    # Accepts only Integer values greater than zero; rejects floats, strings, booleans, nil.
    #
    # @param value [Object] raw config value
    # @return [Integer, nil] validated pixel width or nil
    def parse_max_width(value)
      return nil unless value.is_a?(Integer)
      return nil unless value.positive?

      value
    end

    def parse_output_dir(dir)
      return DEFAULT_OUTPUT_DIR unless dir.is_a?(String)

      dir = dir.strip
      return DEFAULT_OUTPUT_DIR if dir.empty?

      # Strip leading/trailing slashes for consistency
      dir.gsub(%r{^/+|/+$}, "")
    end
  end
end
