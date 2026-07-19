# frozen_string_literal: true

require "rexml/document"
require "rexml/xpath"

# Structural HTML assertions for figure/link contracts without pinning attribute order.
module HtmlFragmentHelpers
  VOID_TAGS = %w[img br hr meta link input].freeze

  # Parse an HTML fragment into a REXML document rooted at <root>.
  #
  # @param html [String]
  # @return [REXML::Document]
  def parse_html_fragment(html)
    REXML::Document.new("<root>#{normalize_void_tags(html)}</root>")
  end

  # @param html [String]
  # @return [Array<REXML::Element>]
  def mermaid_figures(html)
    REXML::XPath.match(parse_html_fragment(html), "//figure[@class='mermaid-diagram']")
  end

  # @param figure [REXML::Element]
  # @param css_class [String, nil]
  # @return [Array<REXML::Element>]
  def figure_anchors(figure, css_class: nil)
    if css_class
      REXML::XPath.match(figure, "./a[@class='#{css_class}']")
    else
      REXML::XPath.match(figure, "./a")
    end
  end

  # @param anchor [REXML::Element]
  # @return [REXML::Element, nil]
  def anchor_img(anchor)
    REXML::XPath.first(anchor, "./img")
  end

  # @param html [String]
  # @return [Boolean]
  def prefers_color_scheme_dark_rule?(html)
    style = REXML::XPath.first(parse_html_fragment(html), "//style")
    return false unless style

    style.text.to_s.include?("prefers-color-scheme: dark")
  end

  private

  def normalize_void_tags(html)
    html.gsub(/<(#{VOID_TAGS.join("|")})([^>]*)>/i) do
      tag = Regexp.last_match(1)
      attrs = Regexp.last_match(2)
      attrs.end_with?("/") ? "<#{tag}#{attrs}>" : "<#{tag}#{attrs} />"
    end
  end
end

RSpec.configure do |config|
  config.include HtmlFragmentHelpers
end
