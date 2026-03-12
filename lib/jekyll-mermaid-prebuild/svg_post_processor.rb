# frozen_string_literal: true

require "nokogiri"

module JekyllMermaidPrebuild
  # Stateless post-processing module for mmdc-generated SVGs.
  #
  # Corrects two issues with mmdc's Puppeteer rendering output:
  #
  # 1. foreignObject width mismatch — mmdc renders <foreignObject> elements
  #    narrower than their parent <rect>, which clips node label text. The fix
  #    widens each <foreignObject> to rect_width - FOREIGN_OBJECT_MARGIN.
  #    The label <g> transform is intentionally left unchanged: Puppeteer sets
  #    translate_x = -content_width/2 to center the text, so the transform is
  #    already correct — only the clip boundary (fo_width) is buggy.
  #
  # 2. Hardcoded max-width inline style — mmdc emits a `max-width` inline style
  #    on the root <svg> fixed to the Puppeteer viewport width. This prevents
  #    responsive scaling. The fix removes that style (or replaces it with the
  #    user-configured value) and ensures `width="100%"` is set on the root element.
  module SvgPostProcessor
    module_function

    NS = { "svg" => "http://www.w3.org/2000/svg" }.freeze

    # Pixel margin subtracted from rect width when sizing each foreignObject.
    FOREIGN_OBJECT_MARGIN = 8

    # Post-process an mmdc-generated SVG string.
    # Always fixes foreignObject width mismatches. Removes the hardcoded
    # max-width style (or sets it to max_width if provided). Defensively
    # sets width="100%" on the root <svg> element.
    #
    # @param svg_content [String] raw SVG string from mmdc
    # @param max_width [Integer, nil] optional pixel width constraint
    # @return [String] post-processed SVG string
    def process(svg_content, max_width: nil)
      doc = Nokogiri::XML(svg_content)
      fix_foreign_object_widths(doc)
      adjust_root_svg_width(doc, max_width)
      # Strip the XML declaration that Nokogiri adds if the original lacked one
      result = doc.to_xml
      result.sub!(/\A<\?xml[^?]*\?>\n/, "") unless svg_content.lstrip.start_with?("<?xml")
      result
    end

    # Widen each <foreignObject> inside a g.node group to match its sibling
    # <rect> width (minus FOREIGN_OBJECT_MARGIN), preventing text clipping.
    # The label <g> transform is left unchanged because Puppeteer already set
    # translate_x = -content_width/2 to center the label text correctly.
    #
    # @param doc [Nokogiri::XML::Document] parsed SVG document (mutated in place)
    # @return [void]
    def fix_foreign_object_widths(doc)
      doc.xpath("//svg:g[contains(@class, 'node')]", NS).each do |node_g|
        rect = node_g.at_xpath(".//svg:rect[@width]", NS)
        fo = node_g.at_xpath(".//svg:foreignObject", NS)
        next unless rect && fo

        fo["width"] = (rect["width"].to_f - FOREIGN_OBJECT_MARGIN).to_s
      end
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
      # Remove any existing max-width declaration (handles trailing semicolons)
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
