# frozen_string_literal: true

module JekyllMermaidPrebuild
  # Configuration wrapper for site config
  class Configuration
    DEFAULT_OUTPUT_DIR = "assets/svg"
    CACHE_DIR = ".jekyll-cache/jekyll-mermaid-prebuild"
    DEFAULT_CHART_BG_LIGHT = "white"
    DEFAULT_CHART_BG_DARK = "black"
    MAX_CHART_BACKGROUND_LENGTH = 256
    INVALID_CHART_BACKGROUND = /[\x00-\x1f"'<>;`\\]/

    # YAML keys under mermaid_prebuild — hyphenated to align with CSS (@media (prefers-color-scheme), background-color).
    PREFERS_COLOR_SCHEME_YAML_KEY = "prefers-color-scheme"
    BACKGROUND_COLOR_YAML_KEY = "background-color"

    attr_reader :output_dir, :text_centering, :overflow_protection, :edge_label_padding, :emoji_width_compensation,
                :prefers_color_scheme, :chart_background_light, :chart_background_dark

    # Initialize configuration from Jekyll site
    #
    # @param site [Jekyll::Site] the Jekyll site
    def initialize(site)
      config = site.config["mermaid_prebuild"] || {}
      @output_dir = parse_output_dir(config["output_dir"])
      @enabled = config.fetch("enabled", true)
      pcs_raw = config[PREFERS_COLOR_SCHEME_YAML_KEY]
      parse_prefers_color_scheme(pcs_raw)

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

    # Parse the prefers-color-scheme block (see PREFERS_COLOR_SCHEME_YAML_KEY) from a Hash only
    # (mode + optional background-color map). Non-Hash values fall back to :light and default
    # backgrounds with a warning.
    #
    # @param value [Object] raw site config value
    # @return [void]
    def parse_prefers_color_scheme(value)
      unless value.is_a?(Hash)
        @prefers_color_scheme = :light
        @chart_background_light = finalize_background(DEFAULT_CHART_BG_LIGHT)
        @chart_background_dark = finalize_background(DEFAULT_CHART_BG_DARK)
        unless value.nil?
          Jekyll.logger.warn(
            "MermaidPrebuild:",
            "Invalid #{PREFERS_COLOR_SCHEME_YAML_KEY} (expected a Hash); " \
            "using light mode and default backgrounds"
          )
        end
        return
      end

      mode_raw = config_hash_fetch(value, "mode")
      @prefers_color_scheme = normalize_prefers_mode(mode_raw)

      bg_container = config_hash_fetch(value, BACKGROUND_COLOR_YAML_KEY)
      if bg_container.is_a?(Hash)
        light_raw = config_hash_fetch(bg_container, "light")
        dark_raw = config_hash_fetch(bg_container, "dark")
        @chart_background_light = coerce_chart_background(light_raw, DEFAULT_CHART_BG_LIGHT, "light")
        @chart_background_dark = coerce_chart_background(dark_raw, DEFAULT_CHART_BG_DARK, "dark")
      else
        @chart_background_light = finalize_background(DEFAULT_CHART_BG_LIGHT)
        @chart_background_dark = finalize_background(DEFAULT_CHART_BG_DARK)
      end
    end

    # @param raw [Object]
    # @return [Symbol] :light, :dark, or :auto
    def normalize_prefers_mode(raw)
      return :light if raw.nil?

      s = raw.to_s.strip.downcase
      return :light if s.empty?

      case s
      when "light" then :light
      when "dark" then :dark
      when "auto" then :auto
      else
        Jekyll.logger.warn(
          "MermaidPrebuild:",
          "Invalid #{PREFERS_COLOR_SCHEME_YAML_KEY} mode #{raw.inspect}; using light"
        )
        :light
      end
    end

    # Read a config key from a Hash (string key as in YAML, or matching Symbol).
    #
    # @param hash [Hash]
    # @param key [String] exact key (e.g. "mode", "background-color", "light")
    # @return [Object, nil]
    def config_hash_fetch(hash, key)
      return nil unless hash.is_a?(Hash)

      hash[key] || hash[key.to_sym]
    end

    # @param value [Object] raw color string or nil (use default)
    # @param default [String] fallback literal
    # @param label [String] "light" or "dark" for logging
    # @return [String] frozen sanitized CSS fragment
    def coerce_chart_background(value, default, label)
      return finalize_background(default) if value.nil?

      str = value.to_s.strip
      if str.empty?
        Jekyll.logger.warn "MermaidPrebuild:",
                           "Invalid chart background (#{label}): empty string; using #{default.inspect}"
        return finalize_background(default)
      end

      if str.length > MAX_CHART_BACKGROUND_LENGTH
        Jekyll.logger.warn "MermaidPrebuild:",
                           "Invalid chart background (#{label}): value too long; using #{default.inspect}"
        return finalize_background(default)
      end

      if chart_background_invalid?(str)
        Jekyll.logger.warn "MermaidPrebuild:",
                           "Invalid chart background (#{label}): disallowed characters; using #{default.inspect}"
        return finalize_background(default)
      end

      str.freeze
    end

    def chart_background_invalid?(value)
      INVALID_CHART_BACKGROUND.match?(value)
    end

    # @param value [String]
    # @return [String] frozen copy
    def finalize_background(value)
      value.to_s.freeze
    end

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
