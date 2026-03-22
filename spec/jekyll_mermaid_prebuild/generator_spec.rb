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
      block_edge_label_padding: 0
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

    context "when diagram_type is block and block_edge_label_padding is positive" do
      let(:padded_config) do
        instance_double(
          JekyllMermaidPrebuild::Configuration,
          cache_dir: cache_dir,
          output_dir: "assets/svg",
          block_edge_label_padding: 5
        )
      end
      let(:padded_generator) { described_class.new(padded_config) }
      let(:block_svg_from_mmdc) do
        '<svg xmlns="http://www.w3.org/2000/svg" aria-roledescription="block">' \
          '<g class="edgeLabel"><g class="label"><foreignObject width="40" height="10"></foreignObject></g></g></svg>'
      end

      before do
        FileUtils.mkdir_p(cache_dir)
        allow(JekyllMermaidPrebuild::MmdcWrapper).to receive(:render) do |_source, output_path|
          File.write(output_path, block_svg_from_mmdc)
          true
        end
      end

      it "post-processes the file after mmdc" do
        path = padded_generator.generate("block\n  a --> b", "edgepad1", diagram_type: "block")

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

    context "when padding is enabled but diagram_type is not block" do
      let(:padded_config) do
        instance_double(
          JekyllMermaidPrebuild::Configuration,
          cache_dir: cache_dir,
          output_dir: "assets/svg",
          block_edge_label_padding: 5
        )
      end
      let(:padded_generator) { described_class.new(padded_config) }
      let(:flow_svg) do
        '<svg aria-roledescription="flowchart-v2"><g class="edgeLabel"><g class="label">' \
          '<foreignObject width="40" height="10"></foreignObject></g></g></svg>'
      end

      before do
        FileUtils.mkdir_p(cache_dir)
        allow(JekyllMermaidPrebuild::MmdcWrapper).to receive(:render) do |_source, output_path|
          File.write(output_path, flow_svg)
          true
        end
      end

      it "writes mmdc output without widening" do
        path = padded_generator.generate("flowchart LR\n  A --> B", "fc1", diagram_type: "flowchart")

        expect(File.read(path)).to eq(flow_svg)
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
