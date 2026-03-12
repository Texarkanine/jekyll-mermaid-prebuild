# frozen_string_literal: true

require "spec_helper"

RSpec.describe JekyllMermaidPrebuild::SvgPostProcessor do
  # SVG namespace used in all fixture documents
  let(:svg_ns) { "http://www.w3.org/2000/svg" }
  let(:ns) { { "svg" => svg_ns } }

  # --- Shared SVG fixture helpers ---

  # A minimal flowchart SVG with a root style attribute.
  def flowchart_svg(svg_style: "max-width: 200px;", extra_attrs: "")
    <<~SVG
      <svg xmlns="http://www.w3.org/2000/svg" width="200" height="100" style="#{svg_style}" #{extra_attrs}>
        <g class="nodes">
          <g class="node default" id="flowchart-A-0" transform="translate(100, 50)">
            <rect rx="5" ry="5" x="-46" y="-23.5" width="92" height="47"/>
            <g class="label" transform="translate(-36, -13.5)">
              <foreignObject width="72" height="27">
                <div xmlns="http://www.w3.org/1999/xhtml">A</div>
              </foreignObject>
            </g>
          </g>
        </g>
      </svg>
    SVG
  end

  # Helper: parse result SVG and return root <svg> attributes
  def result_root_svg(svg)
    doc = Nokogiri::XML(svg)
    doc.root
  end

  describe ".process" do
    describe "node content passthrough" do
      # B1: foreignObject width and label transform are left unchanged (mmdc
      # already centers these correctly; modifying them breaks alignment due
      # to display:table-cell shrink-wrapping inside foreignObject).
      context "when SVG contains flowchart nodes with foreignObject" do
        let(:svg) { flowchart_svg }

        it "preserves foreignObject width unchanged" do
          result = described_class.process(svg)
          doc = Nokogiri::XML(result)
          fo = doc.at_xpath("//svg:foreignObject", ns)

          expect(fo["width"]).to eq("72")
        end

        it "preserves label g transform unchanged" do
          result = described_class.process(svg)
          doc = Nokogiri::XML(result)
          label_g = doc.at_xpath("//svg:g[contains(@class, 'label')]", ns)

          expect(label_g["transform"]).to eq("translate(-36, -13.5)")
        end
      end

      # B4: SVG without node groups → returned with no foreignObject changes (no-op)
      context "when SVG has no g.node groups (e.g. sequence diagram)" do
        let(:sequence_svg) do
          <<~SVG
            <svg xmlns="http://www.w3.org/2000/svg" width="200" height="100" style="max-width: 200px;">
              <g class="actors">
                <text>Actor A</text>
                <text>Actor B</text>
              </g>
              <g class="messages">
                <line x1="50" y1="80" x2="150" y2="80"/>
              </g>
            </svg>
          SVG
        end

        it "returns the SVG without error" do
          expect { described_class.process(sequence_svg) }.not_to raise_error
        end

        it "does not add any foreignObject elements" do
          result = described_class.process(sequence_svg)
          doc = Nokogiri::XML(result)

          expect(doc.xpath("//svg:foreignObject", ns)).to be_empty
        end
      end
    end

    describe "root SVG width adjustment" do
      # B5: Root <svg> max-width removed when no max_width configured
      context "when no max_width is configured" do
        let(:svg) { flowchart_svg(svg_style: "max-width: 200px;") }

        it "removes the max-width inline style" do
          result = described_class.process(svg, max_width: nil)
          root = result_root_svg(result)

          expect(root["style"].to_s).not_to include("max-width")
        end
      end

      # B6: Root <svg> max-width set to configured value when max_width provided
      context "when max_width: 640 is configured" do
        let(:svg) { flowchart_svg(svg_style: "max-width: 200px;") }

        it "sets max-width to the configured value" do
          result = described_class.process(svg, max_width: 640)
          root = result_root_svg(result)

          expect(root["style"]).to include("max-width: 640px")
        end
      end

      # B7: Root <svg> without style attribute → no error
      context "when root <svg> has no style attribute" do
        let(:svg) do
          <<~SVG
            <svg xmlns="http://www.w3.org/2000/svg" width="200" height="100">
              <g class="nodes"/>
            </svg>
          SVG
        end

        it "does not raise an error" do
          expect { described_class.process(svg) }.not_to raise_error
        end

        it "does not add an empty style attribute" do
          result = described_class.process(svg)
          root = result_root_svg(result)

          expect(root["style"]).to be_nil
        end
      end

      # B8: Other inline styles on root <svg> preserved (only max-width affected)
      context "when root <svg> has other inline styles alongside max-width" do
        let(:svg) { flowchart_svg(svg_style: "color: red; max-width: 200px; font-size: 12px;") }

        it "preserves non-max-width styles" do
          result = described_class.process(svg, max_width: nil)
          root = result_root_svg(result)

          expect(root["style"]).to include("color: red")
          expect(root["style"]).to include("font-size: 12px")
        end

        it "removes only the max-width style" do
          result = described_class.process(svg, max_width: nil)
          root = result_root_svg(result)

          expect(root["style"]).not_to include("max-width")
        end
      end

      # B9a: Root <svg> always has width="100%" after post-processing (defensive set)
      context "when root <svg> has a fixed pixel width attribute" do
        let(:svg) { flowchart_svg }

        it "sets width attribute to 100%" do
          result = described_class.process(svg)
          root = result_root_svg(result)

          expect(root["width"]).to eq("100%")
        end
      end

      context "when processing with max_width configured alongside max-width style removal" do
        let(:svg) { flowchart_svg(svg_style: "max-width: 200px;") }

        it "replaces the old max-width with the new configured value" do
          result = described_class.process(svg, max_width: 800)
          root = result_root_svg(result)

          expect(root["style"]).to include("max-width: 800px")
          expect(root["style"]).not_to include("max-width: 200px")
        end
      end
    end
  end
end
