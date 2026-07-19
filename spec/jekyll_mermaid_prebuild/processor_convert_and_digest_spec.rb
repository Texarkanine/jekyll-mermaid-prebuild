# frozen_string_literal: true

require "spec_helper"

RSpec.describe JekyllMermaidPrebuild::Processor do
  subject(:processor) { described_class.new(config, generator) }

  let(:cache_dir) { File.join(@temp_dir, "cache") }
  let(:config) do
    instance_double(JekyllMermaidPrebuild::Configuration, **configuration_processor_attrs(cache_dir))
  end
  let(:generator) { instance_double(JekyllMermaidPrebuild::Generator) }
  let(:site_data) { {} }
  let(:site) do
    instance_double(Jekyll::Site, data: site_data, dest: @temp_dir)
  end

  describe "#digest_string_for_cache" do
    def digest_for(**config_overrides)
      cfg = instance_double(
        JekyllMermaidPrebuild::Configuration,
        **configuration_processor_attrs(cache_dir, config_overrides)
      )
      described_class.new(cfg, generator).digest_string_for_cache("diagram-source")
    end

    it "always includes source and color-scheme background parts" do
      digest = digest_for

      expect(digest).to start_with("diagram-source\0")
      expect(digest).to include("pcs=light")
      expect(digest).to include("bgL=white")
      expect(digest).to include("bgD=black")
    end

    it "omits text_centering when enabled" do
      expect(digest_for(text_centering: true)).not_to include("tc=")
    end

    it "includes text_centering when disabled" do
      expect(digest_for(text_centering: false)).to include("tc=false")
    end

    it "omits overflow_protection when enabled" do
      expect(digest_for(overflow_protection: true)).not_to include("op=")
    end

    it "includes overflow_protection when disabled" do
      expect(digest_for(overflow_protection: false)).to include("op=false")
    end

    it "includes positive numeric edge_label_padding" do
      expect(digest_for(edge_label_padding: 6)).to include("edge_pad=6")
    end

    it "omits edge_label_padding when zero" do
      expect(digest_for(edge_label_padding: 0)).not_to include("edge_pad=")
    end

    it "omits edge_label_padding when not numeric" do
      expect(digest_for(edge_label_padding: "wide")).not_to include("edge_pad=")
    end
  end

  describe "#convert_block" do
    let(:block) { { content: "graph TD\nA-->B\n" } }
    let(:figure_html) { "<figure class=\"mermaid-diagram\">rendered</figure>" }

    before do
      FileUtils.mkdir_p(cache_dir)
      allow(generator).to receive(:generate) do |_source, key, **_kwargs|
        path = File.join(cache_dir, "#{key}.svg")
        File.write(path, "<svg/>")
        { key => path }
      end
      allow(generator).to receive(:build_svg_url) { |stem| "/assets/svg/#{stem}.svg" }
      allow(generator).to receive(:build_figure_html).and_return(figure_html)
    end

    it "returns nil when generation returns nil" do
      allow(generator).to receive(:generate).and_return(nil)

      expect(processor.convert_block(block)).to be_nil
    end

    it "returns nil when generation returns an empty hash" do
      allow(generator).to receive(:generate).and_return({})

      expect(processor.convert_block(block)).to be_nil
    end

    it "returns nil when the block omits content" do
      allow(generator).to receive(:generate).and_return(nil)

      expect(processor.convert_block({})).to be_nil
    end

    it "uses the uncompensated source when compensation is not configured for the diagram type" do
      expect(generator).to receive(:generate).with(
        "flowchart LR\nA-->B\n",
        anything
      ).and_return(nil)

      processor.convert_block({ content: "flowchart LR\nA-->B\n" })
    end

    it "returns svgs and html on success" do
      result = processor.convert_block(block)

      expect(result[:html]).to eq(figure_html)
      expect(result[:svgs]).not_to be_empty
      expect(result[:svgs].keys.first).to match(/\A[a-f0-9]{8}\z/)
    end

    it "uses a distinct cache digest for different diagram sources" do
      keys = []
      allow(generator).to receive(:generate) do |_source, key, **_kwargs|
        keys << key
        path = File.join(cache_dir, "#{key}.svg")
        File.write(path, "<svg/>")
        { key => path }
      end

      processor.convert_block({ content: "graph TD\nA-->B\n" })
      processor.convert_block({ content: "graph TD\nC-->D\n" })

      expect(keys.uniq.size).to eq(2)
    end

    it "builds figure HTML without dark_url when prefers_color_scheme is not :auto" do
      expect(generator).to receive(:build_figure_html).with(
        a_string_matching(%r{\A/assets/svg/[a-f0-9]{8}\.svg\z})
      ).and_return(figure_html)

      processor.convert_block(block)
    end

    context "when prefers_color_scheme is :auto" do
      let(:config_auto) do
        instance_double(
          JekyllMermaidPrebuild::Configuration,
          **configuration_processor_attrs(cache_dir, prefers_color_scheme: :auto)
        )
      end
      let(:processor_auto) { described_class.new(config_auto, generator) }

      before do
        allow(generator).to receive(:generate) do |_source, key, **_kwargs|
          {
            key => File.join(cache_dir, "#{key}.svg"),
            "#{key}-dark" => File.join(cache_dir, "#{key}-dark.svg")
          }
        end
      end

      it "builds figure HTML with dark_url" do
        expect(generator).to receive(:build_figure_html).with(
          a_string_matching(%r{\A/assets/svg/[a-f0-9]{8}\.svg\z}),
          hash_including(dark_url: a_string_matching(%r{\A/assets/svg/[a-f0-9]{8}-dark\.svg\z}))
        ).and_return(figure_html)

        processor_auto.convert_block(block)
      end
    end

    context "with emoji width compensation enabled" do
      let(:config_with_comp) do
        instance_double(
          JekyllMermaidPrebuild::Configuration,
          **configuration_processor_attrs(
            cache_dir,
            emoji_width_compensation: { "flowchart" => true }
          )
        )
      end
      let(:processor_with_comp) { described_class.new(config_with_comp, generator) }
      let(:emoji_block) { { content: "flowchart LR\n  A[\"🔧\"] --> B\n" } }

      it "passes compensated source to the generator" do
        allow(generator).to receive(:generate) do |source, key, **_kwargs|
          expect(source).to include("&nbsp;&nbsp;")
          { key => File.join(cache_dir, "#{key}.svg") }
        end

        processor_with_comp.convert_block(emoji_block)
      end

      it "does not compensate when diagram type is not configured for compensation" do
        sequence_block = { content: "sequenceDiagram\n  A->>B: hi\n" }

        allow(generator).to receive(:generate) do |source, key, **_kwargs|
          expect(source).to eq(sequence_block[:content])
          expect(source).not_to include("&nbsp;&nbsp;")
          { key => File.join(cache_dir, "#{key}.svg") }
        end

        processor_with_comp.convert_block(sequence_block)
      end

      it "does not compensate when compensation is explicitly disabled for the diagram type" do
        config_disabled = instance_double(
          JekyllMermaidPrebuild::Configuration,
          **configuration_processor_attrs(
            cache_dir,
            emoji_width_compensation: { "flowchart" => false }
          )
        )
        processor_disabled = described_class.new(config_disabled, generator)
        # Include emoji so a wrongly-unconditional compensate path would inject nbsp.
        flowchart_block = { content: "flowchart LR\n  A[\"🔧\"] --> B\n" }

        allow(generator).to receive(:generate) do |source, key, **_kwargs|
          expect(source).to eq(flowchart_block[:content])
          expect(source).not_to include("&nbsp;&nbsp;")
          { key => File.join(cache_dir, "#{key}.svg") }
        end

        processor_disabled.convert_block(flowchart_block)
      end
    end
  end
end
