# frozen_string_literal: true

require "nokogiri"

module JekyllMermaidPrebuild
  # Stateless post-processing module for mmdc-generated SVGs.
  #
  # Fixes a display-width issue with mmdc's Puppeteer rendering output:
  #
  # mmdc emits a hardcoded `max-width` inline style on the root <svg> tied to
  # the Puppeteer viewport width. When the page's content column is narrower
  # than this value the SVG scales down proportionally — but HTML text inside
  # <foreignObject> elements does NOT scale (it renders at full CSS pixel
  # size), so node labels overflow and get clipped.
  #
  # The fix removes the hardcoded max-width (or replaces it with the user's
  # configured value) and sets `width="100%"` so the SVG fills its container
  # without over-shrinking.
  module SvgPostProcessor
    module_function

    # Post-process an mmdc-generated SVG string.
    # Removes the hardcoded max-width style (or sets it to max_width if
    # provided). Defensively sets width="100%" on the root <svg> element.
    # Node content (foreignObject widths, label transforms) is left
    # untouched — mmdc already centers these correctly.
    #
    # @param svg_content [String] raw SVG string from mmdc
    # @param max_width [Integer, nil] optional pixel width constraint
    # @return [String] post-processed SVG string
    def process(svg_content, max_width: nil)
      doc = Nokogiri::XML(svg_content)
      adjust_root_svg_width(doc, max_width)
      result = doc.to_xml
      result.sub!(/\A<\?xml[^?]*\?>\n/, "") unless svg_content.lstrip.start_with?("<?xml")
      result
    end

    # Set width="100%" on the root <svg>, then remove the existing max-width
    # inline style and (optionally) replace it with the configured value.
    #
    # @param doc [Nokogiri::XML::Document] parsed SVG document (mutated in place)
    # @param max_width [Integer, nil] optional pixel width constraint
    # @return [void]
    def adjust_root_svg_width(doc, max_width)
      root = doc.root
      return unless root&.name == "svg"

      root["width"] = "100%"

      style = root["style"] || ""
      style = style.gsub(/\s*max-width\s*:[^;]*;?/, "").gsub(/;\s*$/, "").strip

      if max_width
        style = style.empty? ? "max-width: #{max_width}px" : "#{style}; max-width: #{max_width}px"
      end

      if style.empty?
        root.delete("style")
      else
        root["style"] = style
      end
    end
  end
end
