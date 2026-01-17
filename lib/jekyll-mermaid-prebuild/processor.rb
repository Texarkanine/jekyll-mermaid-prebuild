# frozen_string_literal: true

module JekyllMermaidPrebuild
  # Processes document/page content, replacing mermaid blocks with SVG references
  class Processor
    # Initialize processor
    #
    # @param config [Configuration] plugin configuration
    # @param generator [Generator] SVG generator
    def initialize(config, generator)
      @config = config
      @generator = generator
    end

    # Process content, replacing mermaid code blocks with figure HTML
    #
    # @param content [String] markdown content
    # @param _site [Jekyll::Site] the Jekyll site (unused, kept for API compatibility)
    # @return [Array<String, Integer, Hash>] [processed_content, count, svgs_to_copy]
    def process_content(content, _site = nil)
      return [content, 0, {}] unless content

      pattern = MmdcWrapper.mermaid_fence_pattern
      converted_count = 0
      svgs_to_copy = {}

      processed = content.gsub(pattern) do |original_match|
        mermaid_source = Regexp.last_match(2)

        # Generate cache key from content
        cache_key = DigestCalculator.content_digest(mermaid_source)

        # Generate SVG
        cached_path = @generator.generate(mermaid_source, cache_key)

        if cached_path
          converted_count += 1

          # Track SVG for copying to _site later
          svgs_to_copy[cache_key] = cached_path

          # Return replacement HTML
          svg_url = @generator.build_svg_url(cache_key)
          @generator.build_figure_html(svg_url)
        else
          # Keep original on failure
          original_match
        end
      end

      [processed, converted_count, svgs_to_copy]
    end
  end
end
