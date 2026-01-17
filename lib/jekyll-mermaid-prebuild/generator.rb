# frozen_string_literal: true

require "fileutils"

module JekyllMermaidPrebuild
  # SVG generation and caching
  class Generator
    attr_reader :config

    # Initialize generator with configuration
    #
    # @param config [Configuration] plugin configuration
    def initialize(config)
      @config = config
    end

    # Generate SVG from mermaid source (with caching)
    #
    # @param mermaid_source [String] mermaid diagram definition
    # @param cache_key [String] digest for caching
    # @return [String, nil] path to cached SVG file or nil on failure
    def generate(mermaid_source, cache_key)
      cache_path = File.join(@config.cache_dir, "#{cache_key}.svg")

      # Return cached file if it exists
      return cache_path if File.exist?(cache_path)

      # Ensure cache directory exists
      FileUtils.mkdir_p(@config.cache_dir)

      # Generate SVG using mmdc
      success = MmdcWrapper.render(mermaid_source, cache_path)

      success ? cache_path : nil
    end

    # Build SVG URL from cache key
    #
    # @param cache_key [String] the cache key
    # @return [String] URL path to SVG
    def build_svg_url(cache_key)
      "/#{@config.output_dir}/#{cache_key}.svg"
    end

    # Build figure HTML for a diagram
    #
    # @param svg_url [String] URL to the SVG file
    # @return [String] HTML figure element
    def build_figure_html(svg_url)
      <<~HTML
        <figure class="mermaid-diagram">
        <a href="#{svg_url}"><img src="#{svg_url}" alt="Mermaid Diagram"></a>
        </figure>
      HTML
    end
  end
end
