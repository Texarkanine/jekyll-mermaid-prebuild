# frozen_string_literal: true

module JekyllMermaidPrebuild
  # Post-processes mmdc-generated SVGs to fix rendering issues.
  #
  # Four independent fixes:
  # 1. Text centering: Mermaid's CSS `text-align: center` targets SVG `<g>` elements where it
  #    has no effect on HTML inside `<foreignObject>`. We inject a CSS rule so that foreignObject
  #    content centers correctly regardless of text measurement differences between the generating
  #    and viewing browsers. Always applied, idempotent.
  # 2. Overflow protection: foreignObject defaults to overflow:hidden, which silently clips labels
  #    when the viewing browser renders text wider than the generating Chromium measured. We inject
  #    a CSS rule setting overflow:visible on all foreignObjects. Always applied, idempotent.
  # 3. Edge label padding: Widens edge-label `<foreignObject>` widths in any diagram type to
  #    prevent clipping when the viewing browser renders text wider than headless Chromium measured.
  #    Opt-in via `postprocessing.edge_label_padding` config.
  # 4. Root SVG background: mmdc always emits `background-color: white` on the root `<svg>` regardless
  #    of theme. The plugin replaces that token with configurable CSS color values for light and
  #    dark variants (defaults white / black) so charts match page background in both modes.
  module SvgPostProcessor
    module_function

    # Opening sequence produced by mmdc for block edge labels (deterministic minified output).
    EDGE_LABEL_FOREIGN_OBJECT_RE = /
      (<g\sclass="edgeLabel"[^>]*><g\sclass="label"[^>]*><foreignObject)
      (\s[^>]+)
      (>)
    /x

    # @param svg_string [String] full SVG document from mmdc
    # @param padding [Numeric] user units to add to each matching foreignObject width (must be positive)
    # @return [String] possibly widened SVG, or the original string on no-op / error
    def apply(svg_string, padding:)
      return svg_string unless svg_string.is_a?(String)
      return svg_string unless padding.is_a?(Numeric) && padding.positive?

      apply_edge_label_padding(svg_string, padding)
    rescue StandardError
      svg_string
    end

    OVERFLOW_RULE = "foreignObject{overflow:visible;}"

    # Injects a CSS rule into the SVG <style> block that sets overflow:visible on foreignObject
    # elements. By default foreignObject clips content (overflow:hidden); when the generating
    # browser measures text narrower than the viewing browser renders it, labels are silently
    # truncated. This rule prevents that regardless of the magnitude of measurement mismatch.
    # Always applied, idempotent.
    #
    # @param svg_string [String] full SVG document from mmdc
    # @return [String] SVG with overflow rule injected, or original on no-op / error
    def ensure_foreignobject_overflow(svg_string)
      return svg_string unless svg_string.is_a?(String)
      return svg_string if svg_string.include?(OVERFLOW_RULE)
      return svg_string unless svg_string.include?("</style>")

      svg_string.sub("</style>", "#{OVERFLOW_RULE}</style>")
    rescue StandardError
      svg_string
    end

    CENTERING_RULE = "foreignObject > div{display:block !important;text-align:center;}"

    # Injects a CSS rule into the SVG <style> block that centers text inside foreignObject divs.
    # Mermaid's own `.node .label { text-align: center }` targets SVG <g> elements where
    # text-align has no effect; this rule targets the HTML div directly.
    # Idempotent: no visual effect when foreignObject width matches text width.
    #
    # @param svg_string [String] full SVG document from mmdc
    # @return [String] SVG with centering rule injected, or original on no-op / error
    def ensure_text_centering(svg_string)
      return svg_string unless svg_string.is_a?(String)
      return svg_string if svg_string.include?(CENTERING_RULE)
      return svg_string unless svg_string.include?("</style>")

      svg_string.sub("</style>", "#{CENTERING_RULE}</style>")
    rescue StandardError
      svg_string
    end

    # Replace `background-color: white` on the root <svg> style attribute with a caller-supplied
    # CSS color (already sanitized by Configuration). Idempotent when mmdc output no longer contains
    # the white token or the value already matches.
    #
    # @param svg_string [String] full SVG document from mmdc
    # @param css_background [String] literal after `background-color:` (e.g. "black", "#fff0aa")
    # @return [String] SVG with updated root background, or original on no-op / error
    def apply_root_svg_background(svg_string, css_background)
      return svg_string unless svg_string.is_a?(String)
      return svg_string unless css_background.is_a?(String) && !css_background.empty?

      svg_string.sub(
        /(<svg\b[^>]*\bstyle="[^"]*?)background-color:\s*white;?/,
        "\\1background-color: #{css_background};"
      )
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
