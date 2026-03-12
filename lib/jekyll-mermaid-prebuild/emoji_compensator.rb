# frozen_string_literal: true

module JekyllMermaidPrebuild
  # Stateless module: compensates for headless Chromium emoji width undermeasurement
  # by appending &nbsp; padding to emoji-containing node labels before mmdc renders.
  module EmojiCompensator
    module_function

    # Match a single Extended_Pictographic codepoint (emoji).
    EMOJI_RE = /\p{Extended_Pictographic}/

    # Detect diagram type from Mermaid source. Skips frontmatter (---), %% comments,
    # and blank lines. Returns the first token of the first content line; normalizes
    # "graph" to "flowchart". Returns nil if no diagram type line found.
    #
    # @param mermaid_source [String] raw Mermaid diagram source
    # @return [String, nil] diagram type keyword (e.g. "flowchart", "sequenceDiagram") or nil
    def detect_diagram_type(mermaid_source)
      return nil if !mermaid_source || mermaid_source.strip.empty?

      in_frontmatter = false
      frontmatter_delim_count = 0

      mermaid_source.each_line do |line|
        stripped = line.strip
        # Track YAML frontmatter
        if stripped == "---"
          frontmatter_delim_count += 1
          in_frontmatter = frontmatter_delim_count.odd?
          next
        end
        next if in_frontmatter
        next if stripped.empty?
        next if stripped.start_with?("%%")

        # First token of first non-skipped line
        token = stripped.split(/\s+/, 2).first
        return nil if token.nil? || token.empty?

        return token == "graph" ? "flowchart" : token
      end

      nil
    end

    # If diagram_type is enabled for compensation, pad emoji-containing labels with
    # non-breaking spaces (2 per emoji). Otherwise return source unchanged.
    #
    # @param mermaid_source [String] Mermaid diagram source
    # @param diagram_type [String] result of detect_diagram_type
    # @return [String] possibly modified source
    def compensate(mermaid_source, diagram_type)
      return mermaid_source if diagram_type != "flowchart"

      compensate_flowchart_labels(mermaid_source)
    end

    BR_RE = %r{(<br\s*/?>)}i
    NBSP = "&nbsp;"

    # Count Extended_Pictographic codepoints in string.
    #
    # @param text [String]
    # @return [Integer]
    def count_emoji(text)
      text.scan(EMOJI_RE).length
    end

    # Visual length for longest-line comparison. Each emoji counts as 2
    # because emoji glyphs render roughly double the width of a regular character.
    #
    # @param text [String]
    # @return [Integer]
    def visual_length(text)
      text.length + count_emoji(text)
    end

    # Pad the longest line in a label if it contains emoji.
    # Splits on <br/> variants, finds the visually longest line, and only
    # pads that line (shorter lines center naturally in the wider container).
    # Returns content unchanged if the longest line has no emoji.
    #
    # @param content [String] raw label text (may contain <br/> line breaks)
    # @return [String] possibly padded label text
    def pad_label_content(content)
      parts = content.split(BR_RE)
      line_indices = (0...parts.length).step(2).to_a
      return content if line_indices.empty?

      longest_part_idx = line_indices.max_by { |i| visual_length(parts[i]) }
      longest_line = parts[longest_part_idx]
      n = count_emoji(longest_line)
      return content unless n.positive?

      parts[longest_part_idx] = "#{longest_line}#{NBSP * (n * 2)}"
      parts.join
    end

    def compensate_flowchart_labels(source)
      result = source.dup

      [
        [/\["(.*?)"\]/m, '["', '"]'],
        [/\['(.*?)'\]/m, "['", "']"],
        [/\("(.*?)"\)/m, '("', '")'],
        [/\{"(.*?)"\}/m, '{"', '"}']
      ].each do |regex, open_str, close_str|
        result = result.gsub(regex) do
          "#{open_str}#{pad_label_content(Regexp.last_match(1))}#{close_str}"
        end
      end

      result.gsub(%r{\[/"((?:[^"\\]|\\.)*)"/\]}m) do
        "[/\"#{pad_label_content(Regexp.last_match(1))}\"/]"
      end
    end
  end
end
