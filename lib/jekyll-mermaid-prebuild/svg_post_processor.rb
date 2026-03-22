# frozen_string_literal: true

module JekyllMermaidPrebuild
  # Widens block-diagram edge-label <foreignObject> widths after mmdc so stroked text is not clipped.
  # Scoped to SVG roots with aria-roledescription="block" and <g class="edgeLabel">…<foreignObject width="…">.
  module SvgPostProcessor
    module_function

    # Opening sequence produced by mmdc for block edge labels (deterministic minified output).
    EDGE_LABEL_FOREIGN_OBJECT_RE = /
      (<g\sclass="edgeLabel"[^>]*><g\sclass="label"[^>]*><foreignObject)
      (\s[^>]+)
      (>)
    /x

    BLOCK_ROOT_MARKER = 'aria-roledescription="block"'

    # @param svg_string [String] full SVG document from mmdc
    # @param padding [Numeric] user units to add to each matching foreignObject width (must be positive)
    # @return [String] possibly widened SVG, or the original string on no-op / error
    def apply(svg_string, padding:)
      return svg_string unless svg_string.is_a?(String)
      return svg_string unless padding.is_a?(Numeric) && padding.positive?
      return svg_string unless svg_string.include?(BLOCK_ROOT_MARKER)

      apply_edge_label_padding(svg_string, padding)
    rescue StandardError
      svg_string
    end

    def apply_edge_label_padding(svg_string, padding)
      svg_string.gsub(EDGE_LABEL_FOREIGN_OBJECT_RE) do
        prefix = Regexp.last_match(1)
        attrs = Regexp.last_match(2)
        suffix = Regexp.last_match(3)
        new_attrs = attrs.sub(/\swidth="(\d+(?:\.\d+)?)"/) do
          new_w = Regexp.last_match(1).to_f + padding
          %( width="#{format("%g", new_w)}")
        end
        prefix + new_attrs + suffix
      end
    end
    private_class_method :apply_edge_label_padding
  end
end
