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

    it "does not modify flowchart-v2 SVGs" do
      svg = compact_svg(<<~SVG)
        <svg xmlns="http://www.w3.org/2000/svg" aria-roledescription="flowchart-v2">
        <g class="edgeLabel"><g class="label">
        <foreignObject width="100" height="24"></foreignObject></g></g></svg>
      SVG
      out = described_class.apply(svg, padding: 8)
      expect(out).to eq(svg)
    end

    it "returns input unchanged when padding is zero" do
      svg = compact_svg(<<~SVG)
        #{block_root}><g class="edgeLabel"><g class="label">
        <foreignObject width="100" height="24"></foreignObject></g></g></svg>
      SVG
      expect(described_class.apply(svg, padding: 0)).to eq(svg)
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
end
