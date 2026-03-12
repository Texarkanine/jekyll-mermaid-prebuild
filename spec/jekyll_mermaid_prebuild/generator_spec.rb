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
      max_width: nil
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
        allow(JekyllMermaidPrebuild::SvgPostProcessor).to receive(:process).and_return("<svg>processed</svg>")
      end

      it "calls mmdc and returns cache path" do
        result = generator.generate(mermaid_source, cache_key)

        expect(result).to eq(File.join(cache_dir, "#{cache_key}.svg"))
        expect(File.exist?(result)).to be true
      end

      # B13: Post-processing called after successful mmdc render
      it "calls SvgPostProcessor after a successful mmdc render" do
        generator.generate(mermaid_source, cache_key)

        expect(JekyllMermaidPrebuild::SvgPostProcessor).to have_received(:process)
      end

      # B14: Post-processed content written to cache file
      it "writes the post-processed SVG content to the cache file" do
        cache_path = generator.generate(mermaid_source, cache_key)

        expect(File.read(cache_path)).to eq("<svg>processed</svg>")
      end

      # B15: max_width from config passed to SvgPostProcessor
      it "passes max_width from config to SvgPostProcessor" do
        generator.generate(mermaid_source, cache_key)

        expect(JekyllMermaidPrebuild::SvgPostProcessor).to have_received(:process).with(
          "<svg>generated</svg>",
          max_width: nil
        )
      end

      context "when max_width is configured" do
        let(:config) do
          instance_double(
            JekyllMermaidPrebuild::Configuration,
            cache_dir: cache_dir,
            output_dir: "assets/svg",
            max_width: 640
          )
        end

        it "passes the configured max_width to SvgPostProcessor" do
          generator.generate(mermaid_source, cache_key)

          expect(JekyllMermaidPrebuild::SvgPostProcessor).to have_received(:process).with(
            "<svg>generated</svg>",
            max_width: 640
          )
        end
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

      # B16: Failed mmdc render does not invoke post-processing
      it "does not invoke SvgPostProcessor" do
        expect(JekyllMermaidPrebuild::SvgPostProcessor).not_to receive(:process)

        generator.generate(mermaid_source, cache_key)
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
