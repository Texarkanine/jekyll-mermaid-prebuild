# frozen_string_literal: true

module JekyllMermaidPrebuild
  # Stateless module: compensates for headless Chromium emoji width undermeasurement
  # by appending &nbsp; padding to emoji-containing node labels before mmdc renders.
  module EmojiCompensator
    # Match a single Extended_Pictographic codepoint (emoji).
    EMOJI_RE = /\p{Extended_Pictographic}/

    # Detect diagram type from Mermaid source. Skips frontmatter (---), %% comments,
    # and blank lines. Returns the first token of the first content line; normalizes
    # "graph" to "flowchart". Returns nil if no diagram type line found.
    #
    # @param mermaid_source [String] raw Mermaid diagram source
    # @return [String, nil] diagram type keyword (e.g. "flowchart", "sequenceDiagram") or nil
    def self.detect_diagram_type(mermaid_source)
      return nil unless mermaid_source

      in_frontmatter = false

      mermaid_source.each_line do |line|
        stripped = line.strip
        if stripped == "---"
          in_frontmatter = !in_frontmatter
          next
        end
        next if in_frontmatter
        next if stripped.empty?
        next if stripped.start_with?("%%")

        token = stripped[/\A\S+/]
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
    def self.compensate(mermaid_source, diagram_type)
      return compensate_flowchart_labels(mermaid_source) if diagram_type == "flowchart"

      mermaid_source
    end

    BR_RE = %r{(<br\s*/?>)}i
    NBSP = "&nbsp;"

    # Count Extended_Pictographic codepoints in string.
    #
    # @param text [String]
    # @return [Integer]
    def self.count_emoji(text)
      text.scan(EMOJI_RE).length
    end

    # Visual length for longest-line comparison. Each emoji counts as 2
    # because emoji glyphs render roughly double the width of a regular character.
    #
    # @param text [String]
    # @return [Integer]
    def self.visual_length(text)
      text.length + count_emoji(text)
    end

    # Pad the longest line in a label if it contains emoji.
    # Splits on <br/> variants, finds the visually longest line, and only
    # pads that line (shorter lines center naturally in the wider container).
    # When no padding is applied, returns the same String object (identity),
    # not merely an equal copy.
    #
    # @param content [String] raw label text (may contain <br/> line breaks)
    # @return [String] possibly padded label text
    def self.pad_label_content(content)
      segments = content.split(BR_RE)
      return content if segments.empty?

      lines, = segments.partition.with_index { |_segment, index| index.even? }
      longest_line = lines.max_by { |line| visual_length(line) }
      emoji_count = count_emoji(longest_line)
      return content unless emoji_count.positive?

      padded = "#{longest_line}#{NBSP * (emoji_count * 2)}"
      segments.map { |segment| segment == longest_line ? padded : segment }.join
    end

    def self.compensate_flowchart_labels(source)
      result = source

      [
        [/\["(.+?)"\]/m, '["', '"]'],
        [/\['(.+?)'\]/m, "['", "']"],
        [/\("(.+?)"\)/m, '("', '")'],
        [/\{"(.+?)"\}/m, '{"', '"}']
      ].each do |regex, open_str, close_str|
        result = result.gsub(regex) do
          "#{open_str}#{pad_label_content(Regexp.last_match(1))}#{close_str}"
        end
      end

      result.gsub(%r{\[/"((?:[^"\\]|\\.)+?)"/\]}) do
        "[/\"#{pad_label_content(Regexp.last_match(1))}\"/]"
      end
    end
  end
end
