# frozen_string_literal: true

require "spec_helper"

RSpec.describe JekyllMermaidPrebuild::SvgPostProcessor do
  # SVG namespace used in all fixture documents
  let(:svg_ns) { "http://www.w3.org/2000/svg" }
  let(:ns) { { "svg" => svg_ns } }

  # --- Shared SVG fixture helpers ---

  # A minimal flowchart SVG with one node whose foreignObject is narrower
  # than its parent rect (the typical mmdc output bug scenario).
  #
  # rect_width:       width of the containing rect element
  # fo_width:         width of the foreignObject (< rect_width - 8 → needs fix)
  # label_translate:  translate(x, y) string on the label <g>
  # svg_style:        inline style on the root <svg> element
  def flowchart_svg(rect_width: 92, fo_width: 72, label_translate: "translate(-36, -13.5)",
                    svg_style: "max-width: 200px;", extra_attrs: "")
    <<~SVG
      <svg xmlns="http://www.w3.org/2000/svg" width="200" height="100" style="#{svg_style}" #{extra_attrs}>
        <g class="nodes">
          <g class="node default" id="flowchart-A-0" transform="translate(100, 50)">
            <rect rx="5" ry="5" x="-46" y="-23.5" width="#{rect_width}" height="47"/>
            <g class="label" transform="#{label_translate}">
              <foreignObject width="#{fo_width}" height="27">
                <div xmlns="http://www.w3.org/1999/xhtml">A</div>
              </foreignObject>
            </g>
          </g>
        </g>
      </svg>
    SVG
  end

  # Helper: parse result SVG and extract the foreignObject width as a Float
  def result_fo_width(svg)
    doc = Nokogiri::XML(svg)
    doc.at_xpath("//svg:foreignObject", ns)["width"].to_f
  end

  # Helper: parse result SVG and extract the label <g> translate x as a Float
  def result_label_translate_x(svg)
    doc = Nokogiri::XML(svg)
    t = doc.at_xpath("//svg:g[contains(@class, 'label')]", ns)["transform"]
    t.match(/translate\(([-\d.]+)/)[1].to_f
  end

  # Helper: parse result SVG and extract the label <g> translate y as a Float
  def result_label_translate_y(svg)
    doc = Nokogiri::XML(svg)
    t = doc.at_xpath("//svg:g[contains(@class, 'label')]", ns)["transform"]
    t.match(/translate\([^,]+,\s*([-\d.]+)/)[1].to_f
  end

  # Helper: parse result SVG and return root <svg> attributes
  def result_root_svg(svg)
    doc = Nokogiri::XML(svg)
    doc.root
  end

  describe ".process" do
    describe "foreignObject width correction" do
      # B1: foreignObject narrower than parent rect → width corrected to rect_width - 8
      context "when foreignObject width is narrower than parent rect" do
        let(:svg) { flowchart_svg(rect_width: 92, fo_width: 72) }

        it "corrects foreignObject width to rect_width minus margin" do
          result = described_class.process(svg)

          expect(result_fo_width(result)).to eq(84.0)
        end
      end

      # B2: Label <g> transform is preserved unchanged when foreignObject is widened.
      # Puppeteer sets translate_x = -content_width/2 to center the text; only the
      # foreignObject clip boundary (fo_width) is buggy — the translate itself is correct.
      # Changing translate_x would shift content left and introduce left-alignment.
      context "when foreignObject is widened" do
        let(:svg) { flowchart_svg(rect_width: 92, fo_width: 72, label_translate: "translate(-36, -13.5)") }

        it "preserves the label g translate x unchanged" do
          result = described_class.process(svg)

          expect(result_label_translate_x(result)).to eq(-36.0)
        end

        it "preserves the label g translate y unchanged" do
          result = described_class.process(svg)

          expect(result_label_translate_y(result)).to eq(-13.5)
        end
      end

      # B3: foreignObject already matches rect width → no change to fo_width; translate always preserved
      context "when foreignObject already matches rect_width minus margin" do
        let(:svg) { flowchart_svg(rect_width: 92, fo_width: 84, label_translate: "translate(-36.0, -13.5)") }

        it "keeps foreignObject width at the correct value" do
          result = described_class.process(svg)

          expect(result_fo_width(result)).to eq(84.0)
        end

        it "keeps the label g translate x unchanged" do
          result = described_class.process(svg)

          expect(result_label_translate_x(result)).to eq(-36.0)
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

          # style is nil when removed entirely (only max-width was present) — both cases are correct
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
