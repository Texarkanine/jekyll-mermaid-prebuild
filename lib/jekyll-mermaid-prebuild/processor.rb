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
      return [nil, 0, {}] unless content

      converted_count = 0
      svgs_to_copy = {}

      # Find top-level mermaid blocks respecting fence nesting
      top_level_blocks = find_top_level_mermaid_blocks(content)

      # Process blocks in reverse order to preserve string positions
      processed = content.dup
      top_level_blocks.reverse_each do |block|
        result = convert_block(block)
        next unless result

        result => { svgs:, html: }
        block => { start:, end: block_end }
        converted_count += 1
        svgs_to_copy.merge!(svgs)
        processed[start...block_end] = html
      end

      [processed, converted_count, svgs_to_copy]
    end

    # @param source [String] mermaid passed to mmdc (after optional emoji compensation)
    # @return [String] input to MD5 for cache key
    def digest_string_for_cache(source)
      parts = [source]
      parts << "pcs=#{@config.prefers_color_scheme}"
      parts << "bgL=#{@config.chart_background_light}"
      parts << "bgD=#{@config.chart_background_dark}"
      parts << "tc=#{@config.text_centering}" unless @config.text_centering
      parts << "op=#{@config.overflow_protection}" unless @config.overflow_protection
      pad = @config.edge_label_padding
      parts << "edge_pad=#{pad}" if pad.is_a?(Numeric) && pad.positive?
      parts.join("\0")
    end

    # Convert a single mermaid block to SVG
    #
    # @param block [Hash] block info with :content key
    # @return [Hash, nil] {:svgs, :html} or nil if failed
    def convert_block(block)
      mermaid_source = block[:content]
      diagram_type = EmojiCompensator.detect_diagram_type(mermaid_source)
      source_for_render = if @config.emoji_width_compensation[diagram_type]
                            EmojiCompensator.compensate(mermaid_source, diagram_type)
                          else
                            mermaid_source
                          end
      digest_input = digest_string_for_cache(source_for_render)
      cache_key = DigestCalculator.content_digest(digest_input)
      paths = @generator.generate(source_for_render, cache_key)

      return nil if paths.nil? || paths.empty?

      light_url = @generator.build_svg_url(cache_key)
      html = if @config.prefers_color_scheme == :auto
               dark_url = @generator.build_svg_url("#{cache_key}-dark")
               @generator.build_figure_html(light_url, dark_url: dark_url)
             else
               @generator.build_figure_html(light_url)
             end

      { svgs: paths, html: html }
    end

    # Find all top-level mermaid code blocks (not nested inside other fences)
    #
    # @param content [String] markdown content
    # @return [Array<Hash>] array of {start:, end:, content:} for each top-level mermaid block
    def find_top_level_mermaid_blocks(content)
      blocks = []
      state = { blocks: blocks, fence_stack: [], position: 0 }

      content.lines do |line|
        process_line(line, state)
      end

      blocks
    end

    # Process a single line for fence detection
    def process_line(line, state)
      line_start = state[:position]
      state[:position] += line.length

      match = line.match(FENCE_OPENER)
      if match
        handle_fence_line(line, line_start, match, state)
      elsif (current_mermaid = state[:current_mermaid])
        content_lines = current_mermaid[:content_lines]
        content_lines << line
      end
    end

    # Handle a line that matches a fence pattern
    def handle_fence_line(line, line_start, match, state)
      fence_chars = match[1]
      language = match[2]
      fence_type = fence_chars.include?("~") ? "~" : "`"
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
      blocks = state[:blocks]
      position = state[:position]
      content_lines = cm[:content_lines]
      if fence_type == cm[:fence_type] && fence_length == cm[:fence_length] && line.strip == fence_chars
        blocks << { start: cm[:start], end: position, content: content_lines.join }
        state[:current_mermaid] = nil
      else
        content_lines << line
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
      fence_stack = state[:fence_stack]
      top_fence_length, top_fence_type = fence_stack.last

      if fence_type == top_fence_type && fence_length >= top_fence_length && line.strip.match?(/\A[`~]+\z/)
        fence_stack.pop
      else
        fence_stack.push([fence_length, fence_type])
      end
    end
  end
end
