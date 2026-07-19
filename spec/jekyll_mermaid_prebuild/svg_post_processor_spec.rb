# frozen_string_literal: true

require "spec_helper"

RSpec.describe JekyllMermaidPrebuild::SvgPostProcessor do
  describe ".apply" do
    # mmdc emits minified SVG; drop line breaks only so attributes keep their spaces.
    def compact_svg(str)
      str.delete("\n")
    end

    let(:block_root) { '<svg xmlns="http://www.w3.org/2000/svg" aria-roledescription="block"' }

    it "adds padding to each edgeLabel foreignObject width on block diagrams" do
      svg = compact_svg(<<~SVG)
        #{block_root}><g class="edgeLabel" x="1"><g class="label" y="2">
        <foreignObject width="100" height="24">
        <div xmlns="http://www.w3.org/1999/xhtml">e</div></foreignObject></g></g></svg>
      SVG
      out = described_class.apply(svg, padding: 6)
      expect(out).to include('width="106"')
      expect(out).not_to include('width="100"')
    end

    it "preserves float width arithmetic" do
      svg = compact_svg(<<~SVG)
        #{block_root}><g class="edgeLabel"><g class="label">
        <foreignObject width="12.5" height="10"></foreignObject></g></g></svg>
      SVG
      out = described_class.apply(svg, padding: 4)
      expect(out).to include('width="16.5"')
    end

    it "widens edge labels in non-block diagram types too" do
      svg = compact_svg(<<~SVG)
        <svg xmlns="http://www.w3.org/2000/svg" aria-roledescription="flowchart-v2">
        <g class="edgeLabel"><g class="label">
        <foreignObject width="100" height="24"></foreignObject></g></g></svg>
      SVG
      out = described_class.apply(svg, padding: 8)
      expect(out).to include('width="108"')
    end

    it "returns input unchanged when padding is zero" do
      svg = compact_svg(<<~SVG)
        #{block_root}><g class="edgeLabel"><g class="label">
        <foreignObject width="100" height="24"></foreignObject></g></g></svg>
      SVG
      expect(described_class.apply(svg, padding: 0)).to eq(svg)
    end

    it "returns input unchanged when padding is not numeric" do
      svg = compact_svg(<<~SVG)
        #{block_root}><g class="edgeLabel"><g class="label">
        <foreignObject width="100" height="24"></foreignObject></g></g></svg>
      SVG
      expect(described_class.apply(svg, padding: "5")).to eq(svg)
    end

    it "returns input unchanged when padding is negative" do
      svg = compact_svg(<<~SVG)
        #{block_root}><g class="edgeLabel"><g class="label">
        <foreignObject width="100" height="24"></foreignObject></g></g></svg>
      SVG
      expect(described_class.apply(svg, padding: -1)).to eq(svg)
    end

    it "widens every edgeLabel foreignObject and leaves node labels alone" do
      svg = compact_svg(<<~SVG)
        #{block_root}>
        <g class="edgeLabel"><g class="label"><foreignObject width="10" height="1"></foreignObject></g></g>
        <g class="edgeLabel"><g class="label"><foreignObject width="20" height="1"></foreignObject></g></g>
        <g class="node"><g class="label"><foreignObject width="99" height="1"></foreignObject></g></g></svg>
      SVG
      out = described_class.apply(svg, padding: 5)
      expect(out).to include('width="15"')
      expect(out).to include('width="25"')
      expect(out).to include('width="99"')
    end

    it "does not mangle foreignObject inner markup" do
      inner = '<div xmlns="http://www.w3.org/1999/xhtml" style="display: inline-block;">' \
              '<span class="edgeLabel">Hi</span></div>'
      svg = "#{block_root}><g class=\"edgeLabel\"><g class=\"label\"><foreignObject width=\"30\" height=\"20\">" \
            "#{inner}</foreignObject></g></g></svg>"
      out = described_class.apply(svg, padding: 2)
      expect(out).to include(inner)
      expect(out).to include('width="32"')
    end

    it "leaves foreignObject unchanged when width attribute is absent" do
      svg = compact_svg(<<~SVG)
        #{block_root}><g class="edgeLabel"><g class="label">
        <foreignObject height="20"></foreignObject></g></g></svg>
      SVG
      out = described_class.apply(svg, padding: 4)
      expect(out).not_to include("width=")
    end

    it "leaves non-numeric width values unchanged" do
      svg = compact_svg(<<~SVG)
        #{block_root}><g class="edgeLabel"><g class="label">
        <foreignObject width="auto" height="20"></foreignObject></g></g></svg>
      SVG
      out = described_class.apply(svg, padding: 4)
      expect(out).to include('width="auto"')
    end

    it "adds padding when width is zero" do
      svg = compact_svg(<<~SVG)
        #{block_root}><g class="edgeLabel"><g class="label">
        <foreignObject width="0" height="10"></foreignObject></g></g></svg>
      SVG
      out = described_class.apply(svg, padding: 3)
      expect(out).to include('width="3"')
    end

    it "preserves other foreignObject attributes while widening width" do
      svg = compact_svg(<<~SVG)
        #{block_root}><g class="edgeLabel"><g class="label">
        <foreignObject x="7" width="10" height="20"></foreignObject></g></g></svg>
      SVG
      out = described_class.apply(svg, padding: 2)
      expect(out).to include('x="7"')
      expect(out).to include('width="12"')
    end

    it "does not duplicate edgeLabel markup" do
      svg = compact_svg(<<~SVG)
        #{block_root}><g class="edgeLabel"><g class="label">
        <foreignObject width="10" height="20"></foreignObject></g></g></svg>
      SVG
      out = described_class.apply(svg, padding: 2)
      expect(out.scan('class="edgeLabel"').size).to eq(1)
    end

    it "formats whole-number widths without a decimal suffix" do
      svg = compact_svg(<<~SVG)
        #{block_root}><g class="edgeLabel"><g class="label">
        <foreignObject width="10.0" height="20"></foreignObject></g></g></svg>
      SVG
      out = described_class.apply(svg, padding: 4)
      expect(out).to include('width="14"')
      expect(out).not_to include('width="14.0"')
    end

    it "preserves multi-digit fractional widths" do
      svg = compact_svg(<<~SVG)
        #{block_root}><g class="edgeLabel"><g class="label">
        <foreignObject width="12.34" height="20"></foreignObject></g></g></svg>
      SVG
      out = described_class.apply(svg, padding: 4)
      expect(out).to include('width="16.34"')
    end

    it "keeps the foreignObject tag properly closed after padding" do
      svg = compact_svg(<<~SVG)
        #{block_root}><g class="edgeLabel"><g class="label">
        <foreignObject width="10" height="20"></foreignObject></g></g></svg>
      SVG
      out = described_class.apply(svg, padding: 2)
      expect(out).to include('<foreignObject width="12" height="20">')
    end

    it "returns non-string input unchanged" do
      expect(described_class.apply(nil, padding: 4)).to be_nil
    end

    it "returns original string when gsub raises" do
      svg = compact_svg(<<~SVG)
        #{block_root}><g class="edgeLabel"><g class="label">
        <foreignObject width="1" height="1"></foreignObject></g></g></svg>
      SVG
      allow(svg).to receive(:gsub).and_raise(StandardError, "forced")
      expect(described_class.apply(svg, padding: 2)).to eq(svg)
    end
  end

  describe ".ensure_foreignobject_overflow" do
    let(:svg_with_style) do
      '<svg id="my-svg"><style>#my-svg{font-family:sans-serif;}</style>' \
        '<foreignObject width="100" height="24">' \
        '<div style="display: table-cell;">text</div></foreignObject></svg>'
    end

    it "injects an overflow:visible rule into the style block" do
      out = described_class.ensure_foreignobject_overflow(svg_with_style)
      expect(out).to include("overflow:visible")
    end

    it "keeps the rule inside the existing <style> element" do
      out = described_class.ensure_foreignobject_overflow(svg_with_style)
      style_content = out[%r{<style>(.*?)</style>}m, 1]
      expect(style_content).to include("overflow:visible")
    end

    it "is idempotent — does not duplicate the rule on repeated calls" do
      once = described_class.ensure_foreignobject_overflow(svg_with_style)
      twice = described_class.ensure_foreignobject_overflow(once)
      expect(twice).to eq(once)
    end

    it "returns the original string when there is no <style> tag" do
      no_style = '<svg><foreignObject width="10" height="10"></foreignObject></svg>'
      expect(described_class.ensure_foreignobject_overflow(no_style)).to eq(no_style)
    end

    it "returns non-string input unchanged" do
      expect(described_class.ensure_foreignobject_overflow(nil)).to be_nil
    end

    it "returns the original string on error" do
      svg = svg_with_style.dup
      allow(svg).to receive(:include?).and_raise(StandardError, "boom")
      expect(described_class.ensure_foreignobject_overflow(svg)).to eq(svg)
    end
  end

  describe ".ensure_text_centering" do
    let(:svg_with_style) do
      '<svg id="my-svg"><style>#my-svg{font-family:sans-serif;}</style>' \
        '<foreignObject width="100" height="24">' \
        '<div style="display: table-cell;">text</div></foreignObject></svg>'
    end

    it "injects a text-align:center rule into the style block" do
      out = described_class.ensure_text_centering(svg_with_style)
      expect(out).to include("text-align:center")
    end

    it "keeps the rule inside the existing <style> element" do
      out = described_class.ensure_text_centering(svg_with_style)
      style_content = out[%r{<style>(.*?)</style>}m, 1]
      expect(style_content).to include("text-align:center")
    end

    it "is idempotent — does not duplicate the rule on repeated calls" do
      once = described_class.ensure_text_centering(svg_with_style)
      twice = described_class.ensure_text_centering(once)
      expect(twice).to eq(once)
    end

    it "returns the original string when there is no <style> tag" do
      no_style = '<svg><foreignObject width="10" height="10"></foreignObject></svg>'
      expect(described_class.ensure_text_centering(no_style)).to eq(no_style)
    end

    it "returns non-string input unchanged" do
      expect(described_class.ensure_text_centering(nil)).to be_nil
    end

    it "returns the original string on error" do
      svg = svg_with_style.dup
      allow(svg).to receive(:include?).and_raise(StandardError, "boom")
      expect(described_class.ensure_text_centering(svg)).to eq(svg)
    end
  end

  describe ".apply_root_svg_background" do
    let(:mmdc_svg) do
      '<svg id="my-svg" width="100%" xmlns="http://www.w3.org/2000/svg" ' \
        'style="max-width: 500px; background-color: white;" viewBox="0 0 500 200">' \
        "<style>#my-svg{fill:#ccc;}</style></svg>"
    end

    it "replaces background-color:white with the given CSS value" do
      out = described_class.apply_root_svg_background(mmdc_svg, "black")
      expect(out).to include("background-color: black;")
      expect(out).not_to include("background-color: white")
    end

    it "supports hex colors" do
      out = described_class.apply_root_svg_background(mmdc_svg, "#fff0aa")
      expect(out).to include("background-color: #fff0aa;")
    end

    it "is idempotent when applied twice with the same target color" do
      once = described_class.apply_root_svg_background(mmdc_svg, "black")
      twice = described_class.apply_root_svg_background(once, "black")
      expect(twice).to eq(once)
    end

    it "leaves SVGs without background-color:white unchanged" do
      no_bg = '<svg style="max-width: 500px;" viewBox="0 0 500 200"></svg>'
      expect(described_class.apply_root_svg_background(no_bg, "black")).to eq(no_bg)
    end

    it "returns non-string svg unchanged" do
      expect(described_class.apply_root_svg_background(nil, "black")).to be_nil
    end

    it "returns original when css_background is blank" do
      expect(described_class.apply_root_svg_background(mmdc_svg, "")).to eq(mmdc_svg)
    end

    it "returns original when css_background is nil" do
      expect(described_class.apply_root_svg_background(mmdc_svg, nil)).to eq(mmdc_svg)
    end

    it "returns original when css_background is not a string" do
      expect(described_class.apply_root_svg_background(mmdc_svg, :black)).to eq(mmdc_svg)
    end

    it "accepts String subclasses as background colors" do
      background = Class.new(String).new("black")
      out = described_class.apply_root_svg_background(mmdc_svg, background)
      expect(out).to include("background-color: black;")
    end

    it "updates root svg when style follows other attributes" do
      spaced = '<svg id="my-svg" width="100%" style="background-color: white;" viewBox="0 0 1 1"></svg>'
      out = described_class.apply_root_svg_background(spaced, "black")
      expect(out).to include("background-color: black;")
    end

    it "updates root svg when style is the first attribute" do
      minimal = '<svg style="background-color: white;" viewBox="0 0 1 1"></svg>'
      out = described_class.apply_root_svg_background(minimal, "black")
      expect(out).to include("background-color: black;")
    end

    it "replaces background-color white without a trailing semicolon" do
      no_semi = '<svg style="max-width: 500px; background-color: white" viewBox="0 0 500 200"></svg>'
      out = described_class.apply_root_svg_background(no_semi, "black")
      expect(out).to include("background-color: black;")
      expect(out).not_to include("background-color: white")
    end

    it "preserves other root style properties" do
      out = described_class.apply_root_svg_background(mmdc_svg, "black")
      expect(out).to include("max-width: 500px")
    end

    it "does not change nested elements that merely contain background-color white" do
      nested = '<svg><g style="background-color: white;"></g></svg>'
      expect(described_class.apply_root_svg_background(nested, "black")).to eq(nested)
    end

    it "matches background-color:white without whitespace after the colon" do
      compact = '<svg style="background-color:white;" viewBox="0 0 1 1"></svg>'
      out = described_class.apply_root_svg_background(compact, "black")
      expect(out).to include("background-color: black;")
    end

    it "requires the style attribute on the root svg element" do
      no_root_style = '<svg viewBox="0 0 1 1"><style>svg{background-color: white;}</style></svg>'
      expect(described_class.apply_root_svg_background(no_root_style, "black")).to eq(no_root_style)
    end

    it "returns the original string on error" do
      svg = mmdc_svg.dup
      allow(svg).to receive(:sub).and_raise(StandardError, "boom")
      expect(described_class.apply_root_svg_background(svg, "black")).to eq(svg)
    end
  end
end
