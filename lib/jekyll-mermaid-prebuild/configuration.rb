# frozen_string_literal: true

module JekyllMermaidPrebuild
  # Configuration wrapper for site config
  class Configuration
    DEFAULT_OUTPUT_DIR = "assets/svg"
    CACHE_DIR = ".jekyll-cache/jekyll-mermaid-prebuild"

    attr_reader :output_dir, :text_centering, :overflow_protection, :edge_label_padding, :emoji_width_compensation

    # Initialize configuration from Jekyll site
    #
    # @param site [Jekyll::Site] the Jekyll site
    def initialize(site)
      config = site.config["mermaid_prebuild"] || {}
      @output_dir = parse_output_dir(config["output_dir"])
      @enabled = config.fetch("enabled", true)

      pp = config["postprocessing"] || {}
      @text_centering = pp.fetch("text_centering", true)
      @overflow_protection = pp.fetch("overflow_protection", true)
      @edge_label_padding = parse_edge_label_padding(pp["edge_label_padding"])
      @emoji_width_compensation = parse_emoji_width_compensation(pp["emoji_width_compensation"])
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

    # Returns a frozen Hash of diagram type (string) => boolean. Non-hash values are rejected → {}.
    #
    # @param value [Object] raw config value
    # @return [Hash<String, Boolean>] frozen hash, empty if invalid/absent
    def parse_emoji_width_compensation(value)
      return {}.freeze unless value.is_a?(Hash)

      result = value.transform_keys(&:to_s).transform_values { |v| [true, false].include?(v) ? v : false }
      result.freeze
    end

    def parse_output_dir(dir)
      return DEFAULT_OUTPUT_DIR unless dir.is_a?(String)

      dir = dir.strip
      return DEFAULT_OUTPUT_DIR if dir.empty?

      dir.gsub(%r{^/+|/+$}, "")
    end

    # @param value [Object] raw config (numeric or off)
    # @return [Numeric] non-negative padding in SVG user units; 0 means disabled
    def parse_edge_label_padding(value)
      return 0 if value.nil? || value == false

      num = value.is_a?(Numeric) ? value : nil
      return 0 unless num

      num.negative? ? 0 : num
    end
  end
end
