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
    # @param diagram_type [String, nil] from EmojiCompensator.detect_diagram_type (e.g. "block")
    # @return [Hash{String => String}, nil] stem (cache filename without .svg) => absolute cache path, or nil on failure
    def generate(mermaid_source, cache_key, diagram_type: nil)
      case @config.prefers_color_scheme
      when :light
        generate_one(mermaid_source, cache_key, diagram_type: diagram_type, theme: :default)
      when :dark
        generate_one(mermaid_source, cache_key, diagram_type: diagram_type, theme: :dark)
      when :auto
        generate_auto(mermaid_source, cache_key, diagram_type: diagram_type)
      end
    end

    # Build SVG URL from cache key (stem, e.g. digest or digest-dark)
    #
    # @param cache_key [String] the cache stem
    # @return [String] URL path to SVG
    def build_svg_url(cache_key)
      "/#{@config.output_dir}/#{cache_key}.svg"
    end

    # Build figure HTML for a diagram
    #
    # @param svg_url [String] URL to the light (or only) SVG file
    # @param dark_url [String, nil] when set (auto mode), second link + CSS toggle for prefers-color-scheme
    # @return [String] HTML figure element
    def build_figure_html(svg_url, dark_url: nil)
      if dark_url
        return <<~HTML
          <figure class="mermaid-diagram">
          <style>
          .mermaid-diagram__light { display: inline; }
          .mermaid-diagram__dark { display: none; }
          @media (prefers-color-scheme: dark) {
            .mermaid-diagram__light { display: none; }
            .mermaid-diagram__dark { display: inline; }
          }
          </style>
          <a class="mermaid-diagram__light" href="#{svg_url}"><img src="#{svg_url}" alt="Mermaid Diagram"></a>
          <a class="mermaid-diagram__dark" href="#{dark_url}"><img src="#{dark_url}" alt="Mermaid Diagram"></a>
          </figure>
        HTML
      end

      <<~HTML
        <figure class="mermaid-diagram">
        <a href="#{svg_url}"><img src="#{svg_url}" alt="Mermaid Diagram"></a>
        </figure>
      HTML
    end

    private

    # @return [Hash{String => String}, nil]
    def generate_one(mermaid_source, stem, diagram_type:, theme:)
      cache_path = File.join(@config.cache_dir, "#{stem}.svg")
      return { stem => cache_path } if File.exist?(cache_path)

      FileUtils.mkdir_p(@config.cache_dir)
      return nil unless MmdcWrapper.render(mermaid_source, cache_path, theme: theme)

      post_process_svg(cache_path, diagram_type, dark: theme == :dark)
      { stem => cache_path }
    end

    # @return [Hash{String => String}, nil]
    def generate_auto(mermaid_source, cache_key, diagram_type:)
      light_stem = cache_key
      dark_stem = "#{cache_key}-dark"
      light_path = File.join(@config.cache_dir, "#{light_stem}.svg")
      dark_path = File.join(@config.cache_dir, "#{dark_stem}.svg")

      FileUtils.mkdir_p(@config.cache_dir)

      unless File.exist?(light_path)
        return nil unless MmdcWrapper.render(mermaid_source, light_path, theme: :default)

        post_process_svg(light_path, diagram_type)
      end

      unless File.exist?(dark_path)
        return nil unless MmdcWrapper.render(mermaid_source, dark_path, theme: :dark)

        post_process_svg(dark_path, diagram_type, dark: true)
      end

      { light_stem => light_path, dark_stem => dark_path }
    end

    def post_process_svg(cache_path, _diagram_type, dark: false)
      raw = File.read(cache_path)
      svg = raw

      svg = SvgPostProcessor.ensure_text_centering(svg) if @config.text_centering
      svg = SvgPostProcessor.ensure_foreignobject_overflow(svg) if @config.overflow_protection
      svg = SvgPostProcessor.ensure_transparent_background(svg) if dark

      pad = @config.edge_label_padding
      svg = SvgPostProcessor.apply(svg, padding: pad) if pad.is_a?(Numeric) && pad.positive?

      File.write(cache_path, svg) if svg != raw
    end
  end
end
