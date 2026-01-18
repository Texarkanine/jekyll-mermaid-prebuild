# frozen_string_literal: true

module JekyllMermaidPrebuild
  # Processes document/page content, replacing mermaid blocks with SVG references
  class Processor
    # Pattern to detect any fence opener (captures fence chars and optional language)
    FENCE_OPENER = /^(`{3,}|~{3,})(\w*)/

    # Initialize processor
    #
    # @param config [Configuration] plugin configuration
    # @param generator [Generator] SVG generator
    def initialize(config, generator)
      @config = config
      @generator = generator
    end

    # Process content, replacing mermaid code blocks with figure HTML
    # Only processes top-level mermaid blocks (not nested inside other fences)
    #
    # @param content [String] markdown content
    # @param _site [Jekyll::Site] the Jekyll site (unused, kept for API compatibility)
    # @return [Array<String, Integer, Hash>] [processed_content, count, svgs_to_copy]
    def process_content(content, _site = nil)
      return [content, 0, {}] unless content

      converted_count = 0
      svgs_to_copy = {}

      # Find top-level mermaid blocks respecting fence nesting
      top_level_blocks = find_top_level_mermaid_blocks(content)

      # Process blocks in reverse order to preserve string positions
      processed = content.dup
      top_level_blocks.reverse_each do |block|
        result = convert_block(block)
        next unless result

        converted_count += 1
        svgs_to_copy[result[:cache_key]] = result[:cached_path]
        processed[block[:start]...block[:end]] = result[:html]
      end

      [processed, converted_count, svgs_to_copy]
    end

    private

    # Convert a single mermaid block to SVG
    #
    # @param block [Hash] block info with :content key
    # @return [Hash, nil] {cache_key:, cached_path:, html:} or nil if failed
    def convert_block(block)
      mermaid_source = block[:content]
      cache_key = DigestCalculator.content_digest(mermaid_source)
      cached_path = @generator.generate(mermaid_source, cache_key)

      return nil unless cached_path

      svg_url = @generator.build_svg_url(cache_key)
      { cache_key: cache_key, cached_path: cached_path, html: @generator.build_figure_html(svg_url) }
    end

    # Find all top-level mermaid code blocks (not nested inside other fences)
    #
    # @param content [String] markdown content
    # @return [Array<Hash>] array of {start:, end:, content:} for each top-level mermaid block
    def find_top_level_mermaid_blocks(content)
      state = { blocks: [], fence_stack: [], current_mermaid: nil, position: 0 }

      content.lines.each do |line|
        process_line(line, state)
      end

      state[:blocks]
    end

    # Process a single line for fence detection
    def process_line(line, state)
      line_start = state[:position]
      state[:position] += line.length

      match = line.match(FENCE_OPENER)
      if match
        handle_fence_line(line, line_start, match, state)
      elsif state[:current_mermaid]
        state[:current_mermaid][:content_lines] << line
      end
    end

    # Handle a line that matches a fence pattern
    def handle_fence_line(line, line_start, match, state)
      fence_chars = match[1]
      language = match[2]
      fence_type = fence_chars[0]
      fence_length = fence_chars.length

      if state[:current_mermaid]
        handle_line_in_mermaid(line, fence_chars, fence_type, fence_length, state)
      elsif state[:fence_stack].empty?
        handle_line_at_top_level(line_start, language, fence_type, fence_length, state)
      else
        handle_line_in_nested_fence(line, fence_type, fence_length, state)
      end
    end

    # Handle fence line while inside a mermaid block
    def handle_line_in_mermaid(line, fence_chars, fence_type, fence_length, state)
      cm = state[:current_mermaid]
      if fence_type == cm[:fence_type] && fence_length == cm[:fence_length] && line.strip == fence_chars
        state[:blocks] << { start: cm[:start], end: state[:position], content: cm[:content_lines].join }
        state[:current_mermaid] = nil
      else
        cm[:content_lines] << line
      end
    end

    # Handle fence line at top level (not inside any fence)
    def handle_line_at_top_level(line_start, language, fence_type, fence_length, state)
      if language == "mermaid"
        state[:current_mermaid] = { start: line_start, fence_type: fence_type,
                                    fence_length: fence_length, content_lines: [] }
      else
        state[:fence_stack].push([fence_length, fence_type])
      end
    end

    # Handle fence line while inside a non-mermaid fence
    def handle_line_in_nested_fence(line, fence_type, fence_length, state)
      top_fence_length, top_fence_type = state[:fence_stack].last

      if fence_type == top_fence_type && fence_length >= top_fence_length && line.strip.match?(/^[`~]+$/)
        state[:fence_stack].pop
      else
        state[:fence_stack].push([fence_length, fence_type])
      end
    end
  end
end
