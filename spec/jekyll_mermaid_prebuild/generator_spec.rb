# frozen_string_literal: true

require "spec_helper"

RSpec.describe JekyllMermaidPrebuild::Generator do
  subject(:generator) { described_class.new(config) }

  let(:cache_dir) { File.join(@temp_dir, "cache") }
  let(:config) do
    instance_double(
      JekyllMermaidPrebuild::Configuration,
      cache_dir: cache_dir,
      output_dir: "assets/svg",
      text_centering: true,
      overflow_protection: true,
      edge_label_padding: 0
    )
  end

  describe "#initialize" do
    it "stores configuration" do
      expect(generator.config).to eq(config)
    end
  end

  describe "#generate" do
    let(:mermaid_source) { "graph TD\nA-->B" }
    let(:cache_key) { "abc12345" }

    context "when SVG is already cached" do
      before do
        FileUtils.mkdir_p(cache_dir)
        File.write(File.join(cache_dir, "#{cache_key}.svg"), "<svg>cached</svg>")
      end

      it "returns cached path without calling mmdc" do
        expect(JekyllMermaidPrebuild::MmdcWrapper).not_to receive(:render)

        result = generator.generate(mermaid_source, cache_key)

        expect(result).to eq(File.join(cache_dir, "#{cache_key}.svg"))
      end
    end

    context "when SVG needs to be generated" do
      before do
        FileUtils.mkdir_p(cache_dir)
        allow(JekyllMermaidPrebuild::MmdcWrapper).to receive(:render) do |_source, output_path|
          File.write(output_path, "<svg>generated</svg>")
          true
        end
      end

      it "calls mmdc and returns cache path" do
        result = generator.generate(mermaid_source, cache_key)

        expect(result).to eq(File.join(cache_dir, "#{cache_key}.svg"))
        expect(File.exist?(result)).to be true
      end

      it "writes the mmdc output to the cache file" do
        cache_path = generator.generate(mermaid_source, cache_key)

        expect(File.read(cache_path)).to eq("<svg>generated</svg>")
      end
    end

    context "when mmdc fails" do
      before do
        allow(JekyllMermaidPrebuild::MmdcWrapper).to receive(:render).and_return(false)
      end

      it "returns nil" do
        result = generator.generate(mermaid_source, cache_key)

        expect(result).to be_nil
      end
    end

    context "when edge_label_padding is positive" do
      let(:padded_config) do
        instance_double(
          JekyllMermaidPrebuild::Configuration,
          cache_dir: cache_dir,
          output_dir: "assets/svg",
          text_centering: true,
          overflow_protection: true,
          edge_label_padding: 5
        )
      end
      let(:padded_generator) { described_class.new(padded_config) }
      let(:svg_with_edge_labels) do
        '<svg xmlns="http://www.w3.org/2000/svg" aria-roledescription="flowchart-v2">' \
          '<g class="edgeLabel"><g class="label"><foreignObject width="40" height="10"></foreignObject></g></g></svg>'
      end

      before do
        FileUtils.mkdir_p(cache_dir)
        allow(JekyllMermaidPrebuild::MmdcWrapper).to receive(:render) do |_source, output_path|
          File.write(output_path, svg_with_edge_labels)
          true
        end
      end

      it "widens edge label foreignObjects regardless of diagram type" do
        path = padded_generator.generate("flowchart LR\n  A --> B", "edgepad1", diagram_type: "flowchart")

        expect(File.read(path)).to include('width="45"')
      end
    end

    context "when SVG is freshly generated" do
      let(:svg_with_style) do
        '<svg id="my-svg"><style>#my-svg{font-family:sans-serif;}</style>' \
          '<foreignObject width="100" height="24"><div>text</div></foreignObject></svg>'
      end

      before do
        FileUtils.mkdir_p(cache_dir)
        allow(JekyllMermaidPrebuild::MmdcWrapper).to receive(:render) do |_source, output_path|
          File.write(output_path, svg_with_style)
          true
        end
      end

      it "injects text-centering CSS into the SVG" do
        path = generator.generate(mermaid_source, cache_key)
        expect(File.read(path)).to include("text-align:center")
      end

      it "injects foreignObject overflow:visible CSS into the SVG" do
        path = generator.generate(mermaid_source, cache_key)
        expect(File.read(path)).to include("overflow:visible")
      end
    end

    context "when text_centering is disabled" do
      let(:no_centering_config) do
        instance_double(
          JekyllMermaidPrebuild::Configuration,
          cache_dir: cache_dir,
          output_dir: "assets/svg",
          text_centering: false,
          overflow_protection: true,
          edge_label_padding: 0
        )
      end
      let(:no_centering_generator) { described_class.new(no_centering_config) }
      let(:svg_with_style) do
        '<svg id="my-svg"><style>#my-svg{font-family:sans-serif;}</style>' \
          '<foreignObject width="100" height="24"><div>text</div></foreignObject></svg>'
      end

      before do
        FileUtils.mkdir_p(cache_dir)
        allow(JekyllMermaidPrebuild::MmdcWrapper).to receive(:render) do |_source, output_path|
          File.write(output_path, svg_with_style)
          true
        end
      end

      it "does not inject centering CSS" do
        path = no_centering_generator.generate("graph TD\nA-->B", "nocenter1")
        expect(File.read(path)).not_to include("text-align:center")
      end
    end

    context "when overflow_protection is disabled" do
      let(:no_overflow_config) do
        instance_double(
          JekyllMermaidPrebuild::Configuration,
          cache_dir: cache_dir,
          output_dir: "assets/svg",
          text_centering: true,
          overflow_protection: false,
          edge_label_padding: 0
        )
      end
      let(:no_overflow_generator) { described_class.new(no_overflow_config) }
      let(:svg_with_style) do
        '<svg id="my-svg"><style>#my-svg{font-family:sans-serif;}</style>' \
          '<foreignObject width="100" height="24"><div>text</div></foreignObject></svg>'
      end

      before do
        FileUtils.mkdir_p(cache_dir)
        allow(JekyllMermaidPrebuild::MmdcWrapper).to receive(:render) do |_source, output_path|
          File.write(output_path, svg_with_style)
          true
        end
      end

      it "does not inject overflow CSS" do
        path = no_overflow_generator.generate("graph TD\nA-->B", "nooverflow1")
        expect(File.read(path)).not_to include("overflow:visible")
      end
    end
  end

  describe "#build_svg_url" do
    it "builds URL with output_dir and cache_key" do
      url = generator.build_svg_url("abc12345")

      expect(url).to eq("/assets/svg/abc12345.svg")
    end
  end

  describe "#build_figure_html" do
    it "generates figure with linked image" do
      html = generator.build_figure_html("/assets/svg/abc.svg")

      expect(html).to include('<figure class="mermaid-diagram">')
      expect(html).to include('<a href="/assets/svg/abc.svg">')
      expect(html).to include('<img src="/assets/svg/abc.svg" alt="Mermaid Diagram">')
      expect(html).to include("</a>")
      expect(html).to include("</figure>")
    end
  end
end
