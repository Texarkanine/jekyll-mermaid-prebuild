# frozen_string_literal: true

require "spec_helper"

RSpec.describe JekyllMermaidPrebuild::Generator do
  subject(:generator) { described_class.new(config) }

  let(:cache_dir) { File.join(@temp_dir, "cache") }
  let(:config) do
    instance_double(JekyllMermaidPrebuild::Configuration, **configuration_generator_attrs(cache_dir))
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

        expect(result).to eq(cache_key => File.join(cache_dir, "#{cache_key}.svg"))
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

      it "creates the cache directory when missing" do
        FileUtils.rm_rf(cache_dir)

        generator.generate(mermaid_source, cache_key)

        expect(Dir.exist?(cache_dir)).to be true
      end

      it "passes mermaid source to mmdc" do
        generator.generate(mermaid_source, cache_key)

        expect(JekyllMermaidPrebuild::MmdcWrapper).to have_received(:render).with(
          mermaid_source,
          File.join(cache_dir, "#{cache_key}.svg"),
          theme: :default
        )
      end

      it "calls mmdc and returns cache path" do
        result = generator.generate(mermaid_source, cache_key)

        path = result[cache_key]
        expect(path).to eq(File.join(cache_dir, "#{cache_key}.svg"))
        expect(File.exist?(path)).to be true
      end

      it "writes the mmdc output to the cache file" do
        paths = generator.generate(mermaid_source, cache_key)
        cache_path = paths[cache_key]

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

    context "when prefers_color_scheme is :light" do
      let(:config) do
        instance_double(
          JekyllMermaidPrebuild::Configuration,
          **configuration_generator_attrs(cache_dir, prefers_color_scheme: :light, chart_background_light: "#fff0aa")
        )
      end

      before do
        FileUtils.mkdir_p(cache_dir)
        allow(JekyllMermaidPrebuild::MmdcWrapper).to receive(:render) do |_source, output_path, **_opts|
          File.write(output_path, '<svg style="background-color: white;"></svg>')
          true
        end
      end

      it "renders with the default theme" do
        generator.generate(mermaid_source, cache_key)

        expect(JekyllMermaidPrebuild::MmdcWrapper).to have_received(:render).with(
          mermaid_source,
          File.join(cache_dir, "#{cache_key}.svg"),
          theme: :default
        )
      end

      it "uses the configured light chart background" do
        paths = generator.generate(mermaid_source, cache_key)
        expect(File.read(paths[cache_key])).to include("background-color: #fff0aa;")
      end
    end

    context "when prefers_color_scheme is :dark" do
      let(:config) do
        instance_double(
          JekyllMermaidPrebuild::Configuration,
          **configuration_generator_attrs(cache_dir, prefers_color_scheme: :dark)
        )
      end

      let(:dark_svg) do
        '<svg id="x" style="max-width: 500px; background-color: white;" viewBox="0 0 500 200">' \
          "<style>#x{fill:#ccc;}</style></svg>"
      end

      before do
        FileUtils.mkdir_p(cache_dir)
        allow(JekyllMermaidPrebuild::MmdcWrapper).to receive(:render) do |_source, output_path, **_opts|
          File.write(output_path, dark_svg)
          true
        end
      end

      it "calls mmdc with dark theme" do
        generator.generate(mermaid_source, cache_key)

        expect(JekyllMermaidPrebuild::MmdcWrapper).to have_received(:render).with(
          mermaid_source,
          File.join(cache_dir, "#{cache_key}.svg"),
          theme: :dark
        )
      end

      it "returns the cached path" do
        paths = generator.generate(mermaid_source, cache_key)
        expect(paths[cache_key]).to eq(File.join(cache_dir, "#{cache_key}.svg"))
      end

      it "applies configured dark chart background (default black)" do
        paths = generator.generate(mermaid_source, cache_key)
        svg = File.read(paths[cache_key])
        expect(svg).to include("background-color: black;")
        expect(svg).not_to include("background-color: white")
      end
    end

    context "when prefers_color_scheme is :auto" do
      let(:config) do
        instance_double(
          JekyllMermaidPrebuild::Configuration,
          **configuration_generator_attrs(
            cache_dir,
            prefers_color_scheme: :auto,
            chart_background_light: "#fff0aa"
          )
        )
      end

      let(:mmdc_svg) do
        '<svg id="x" style="max-width: 500px; background-color: white;" viewBox="0 0 500 200">' \
          "<style>#x{fill:#ccc;}</style></svg>"
      end

      before do
        FileUtils.mkdir_p(cache_dir)
        allow(JekyllMermaidPrebuild::MmdcWrapper).to receive(:render) do |_source, output_path, **_opts|
          File.write(output_path, mmdc_svg)
          true
        end
      end

      it "writes light and dark SVGs and returns both stems" do
        paths = generator.generate(mermaid_source, cache_key)

        expect(paths.keys).to contain_exactly(cache_key, "#{cache_key}-dark")
      end

      it "creates the cache directory when missing" do
        FileUtils.rm_rf(cache_dir)

        generator.generate(mermaid_source, cache_key)

        expect(Dir.exist?(cache_dir)).to be true
      end

      it "applies light and dark chart backgrounds (default white / black)" do
        paths = generator.generate(mermaid_source, cache_key)

        light_svg = File.read(paths[cache_key])
        dark_svg = File.read(paths["#{cache_key}-dark"])

        expect(light_svg).to include("background-color: #fff0aa;")
        expect(dark_svg).to include("background-color: black;")
        expect(dark_svg).not_to include("background-color: white")
      end

      it "renders the light variant with the default theme" do
        generator.generate(mermaid_source, cache_key)

        expect(JekyllMermaidPrebuild::MmdcWrapper).to have_received(:render).with(
          mermaid_source,
          File.join(cache_dir, "#{cache_key}.svg"),
          theme: :default
        )
      end

      it "renders the dark variant with the dark theme" do
        generator.generate(mermaid_source, cache_key)

        expect(JekyllMermaidPrebuild::MmdcWrapper).to have_received(:render).with(
          mermaid_source,
          File.join(cache_dir, "#{cache_key}-dark.svg"),
          theme: :dark
        )
      end

      it "passes mermaid source to both render calls" do
        generator.generate("flowchart LR\nX-->Y", cache_key)

        expect(JekyllMermaidPrebuild::MmdcWrapper).to have_received(:render).with(
          "flowchart LR\nX-->Y",
          anything,
          theme: :default
        )
        expect(JekyllMermaidPrebuild::MmdcWrapper).to have_received(:render).with(
          "flowchart LR\nX-->Y",
          anything,
          theme: :dark
        )
      end

      it "post-processes the light variant" do
        paths = generator.generate(mermaid_source, cache_key)
        expect(File.read(paths[cache_key])).to include("text-align:center")
      end

      context "when light exists but dark does not" do
        before do
          File.write(File.join(cache_dir, "#{cache_key}.svg"), "<svg>cached-light</svg>")
        end

        it "renders only the dark variant" do
          expect(JekyllMermaidPrebuild::MmdcWrapper).to receive(:render).once
          paths = generator.generate(mermaid_source, cache_key)
          expect(paths).to have_key("#{cache_key}-dark")
          expect(File.exist?(paths["#{cache_key}-dark"])).to be true
        end
      end

      context "when both files exist" do
        before do
          File.write(File.join(cache_dir, "#{cache_key}.svg"), "<svg>L</svg>")
          File.write(File.join(cache_dir, "#{cache_key}-dark.svg"), "<svg>D</svg>")
        end

        it "does not call mmdc" do
          expect(JekyllMermaidPrebuild::MmdcWrapper).not_to receive(:render)
          generator.generate(mermaid_source, cache_key)
        end
      end

      context "when dark render fails after light succeeds" do
        before do
          allow(JekyllMermaidPrebuild::MmdcWrapper).to receive(:render) do |_source, output_path, theme: :default|
            if theme == :dark
              false
            else
              File.write(output_path, "<svg>light</svg>")
              true
            end
          end
        end

        it "returns nil" do
          expect(generator.generate(mermaid_source, cache_key)).to be_nil
        end
      end

      context "when light render fails" do
        before do
          allow(JekyllMermaidPrebuild::MmdcWrapper).to receive(:render).and_return(false)
        end

        it "returns nil without attempting dark post-processing" do
          expect(generator.generate(mermaid_source, cache_key)).to be_nil
          expect(File.exist?(File.join(cache_dir, "#{cache_key}-dark.svg"))).to be false
        end
      end
    end

    context "when edge_label_padding is positive" do
      let(:padded_config) do
        instance_double(
          JekyllMermaidPrebuild::Configuration,
          **configuration_generator_attrs(cache_dir, edge_label_padding: 5)
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
        paths = padded_generator.generate("flowchart LR\n  A --> B", "edgepad1")
        path = paths["edgepad1"]
        expected_width = 40 + 5 # fixture foreignObject width + edge_label_padding

        expect(File.read(path)).to include(%(width="#{expected_width}"))
      end
    end

    context "when edge_label_padding is non-numeric" do
      let(:bad_padding_config) do
        instance_double(
          JekyllMermaidPrebuild::Configuration,
          **configuration_generator_attrs(cache_dir, edge_label_padding: "5")
        )
      end
      let(:bad_padding_generator) { described_class.new(bad_padding_config) }
      let(:svg_with_edge_labels) do
        '<svg xmlns="http://www.w3.org/2000/svg">' \
          '<g class="edgeLabel"><g class="label"><foreignObject width="40" height="10"></foreignObject></g></g></svg>'
      end

      before do
        FileUtils.mkdir_p(cache_dir)
        allow(JekyllMermaidPrebuild::MmdcWrapper).to receive(:render) do |_source, output_path|
          File.write(output_path, svg_with_edge_labels)
          true
        end
      end

      it "does not widen edge labels" do
        paths = bad_padding_generator.generate("graph TD\nA-->B", "nopadstr1")
        expect(File.read(paths["nopadstr1"])).to include('width="40"')
      end
    end

    context "when post-processing leaves content unchanged" do
      let(:already_processed) do
        '<svg style="background-color: white;"><style>' \
          "foreignObject > div{display:block !important;text-align:center;}" \
          "foreignObject{overflow:visible;}</style></svg>"
      end

      before do
        FileUtils.mkdir_p(cache_dir)
        allow(JekyllMermaidPrebuild::MmdcWrapper).to receive(:render) do |_source, output_path|
          File.write(output_path, already_processed)
          true
        end
      end

      it "does not rewrite the cache file after the initial mmdc write" do
        cache_path = File.join(cache_dir, "noopcache1.svg")
        allow(File).to receive(:write).and_call_original

        generator.generate(mermaid_source, "noopcache1")

        # One write from the mmdc stub; post_process must not write again.
        expect(File).to have_received(:write).with(cache_path, already_processed).once
      end
    end

    context "when edge_label_padding is zero" do
      let(:svg_with_edge_labels) do
        '<svg xmlns="http://www.w3.org/2000/svg">' \
          '<g class="edgeLabel"><g class="label"><foreignObject width="40" height="10"></foreignObject></g></g></svg>'
      end

      before do
        FileUtils.mkdir_p(cache_dir)
        allow(JekyllMermaidPrebuild::MmdcWrapper).to receive(:render) do |_source, output_path|
          File.write(output_path, svg_with_edge_labels)
          true
        end
      end

      it "does not widen edge labels" do
        paths = generator.generate("graph TD\nA-->B", "zeropad1")
        expect(File.read(paths["zeropad1"])).to include('width="40"')
      end
    end

    context "when SVG is freshly generated" do
      let(:svg_with_style) do
        '<svg id="my-svg" style="max-width: 500px; background-color: white;" viewBox="0 0 500 200">' \
          "<style>#my-svg{font-family:sans-serif;}</style>" \
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
        paths = generator.generate(mermaid_source, cache_key)
        expect(File.read(paths[cache_key])).to include("text-align:center")
      end

      it "injects foreignObject overflow:visible CSS into the SVG" do
        paths = generator.generate(mermaid_source, cache_key)
        expect(File.read(paths[cache_key])).to include("overflow:visible")
      end

      it "always applies the configured light chart background" do
        paths = generator.generate(mermaid_source, cache_key)
        expect(File.read(paths[cache_key])).to include("background-color: white;")
      end

      it "writes the cache file when post-processing changes content" do
        cache_path = File.join(cache_dir, "write1.svg")
        allow(File).to receive(:write).and_call_original

        generator.generate(mermaid_source, "write1")

        # mmdc stub write + post_process rewrite
        expect(File).to have_received(:write).with(cache_path, kind_of(String)).twice
        expect(File.read(cache_path)).to include("text-align:center")
      end
    end

    context "when text_centering is disabled" do
      let(:no_centering_config) do
        instance_double(
          JekyllMermaidPrebuild::Configuration,
          **configuration_generator_attrs(cache_dir, text_centering: false)
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
        paths = no_centering_generator.generate("graph TD\nA-->B", "nocenter1")
        expect(File.read(paths["nocenter1"])).not_to include("text-align:center")
      end
    end

    context "when overflow_protection is disabled" do
      let(:no_overflow_config) do
        instance_double(
          JekyllMermaidPrebuild::Configuration,
          **configuration_generator_attrs(cache_dir, overflow_protection: false)
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
        paths = no_overflow_generator.generate("graph TD\nA-->B", "nooverflow1")
        expect(File.read(paths["nooverflow1"])).not_to include("overflow:visible")
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

      figures = mermaid_figures(html)
      expect(figures.size).to eq(1)
      anchors = figure_anchors(figures.first)
      expect(anchors.size).to eq(1)
      expect(anchors.first.attributes["href"]).to eq("/assets/svg/abc.svg")
      img = anchor_img(anchors.first)
      expect(img.attributes["src"]).to eq("/assets/svg/abc.svg")
      expect(img.attributes["alt"]).to eq("Mermaid Diagram")
    end

    it "omits dual-theme markup when dark_url is omitted" do
      html = generator.build_figure_html("/assets/svg/abc.svg")

      expect(html).not_to include("mermaid-diagram__dark")
      expect(html).not_to include("mermaid-diagram__light")
      expect(html).not_to include("@media")
    end

    it "emits two links and prefers-color-scheme CSS when dark_url is set" do
      html = generator.build_figure_html("/assets/svg/abc.svg", dark_url: "/assets/svg/abc-dark.svg")

      expect(prefers_color_scheme_dark_rule?(html)).to be(true)
      figures = mermaid_figures(html)
      expect(figures.size).to eq(1)
      light = figure_anchors(figures.first, css_class: "mermaid-diagram__light").first
      dark = figure_anchors(figures.first, css_class: "mermaid-diagram__dark").first
      expect(light.attributes["href"]).to eq("/assets/svg/abc.svg")
      expect(dark.attributes["href"]).to eq("/assets/svg/abc-dark.svg")
      expect(anchor_img(light).attributes["src"]).to eq("/assets/svg/abc.svg")
      expect(anchor_img(dark).attributes["src"]).to eq("/assets/svg/abc-dark.svg")
    end
  end
end
