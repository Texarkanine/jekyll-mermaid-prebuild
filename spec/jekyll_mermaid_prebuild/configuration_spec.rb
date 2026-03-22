# frozen_string_literal: true

require "spec_helper"

RSpec.describe JekyllMermaidPrebuild::Configuration do
  let(:site_config) { {} }
  let(:site) do
    instance_double(Jekyll::Site, config: site_config)
  end

  describe "#initialize" do
    context "with no configuration" do
      it "uses default output_dir" do
        config = described_class.new(site)

        expect(config.output_dir).to eq("assets/svg")
      end
    end

    context "with custom output_dir" do
      let(:site_config) do
        { "mermaid_prebuild" => { "output_dir" => "images/diagrams" } }
      end

      it "uses configured output_dir" do
        config = described_class.new(site)

        expect(config.output_dir).to eq("images/diagrams")
      end
    end

    context "with leading slash in output_dir" do
      let(:site_config) do
        { "mermaid_prebuild" => { "output_dir" => "/assets/svg/" } }
      end

      it "strips leading and trailing slashes" do
        config = described_class.new(site)

        expect(config.output_dir).to eq("assets/svg")
      end
    end

    context "with empty output_dir" do
      let(:site_config) do
        { "mermaid_prebuild" => { "output_dir" => "" } }
      end

      it "uses default output_dir" do
        config = described_class.new(site)

        expect(config.output_dir).to eq("assets/svg")
      end
    end
  end

  describe "#enabled?" do
    context "with no configuration" do
      it "returns true by default" do
        config = described_class.new(site)

        expect(config.enabled?).to be true
      end
    end

    context "with enabled: false" do
      let(:site_config) do
        { "mermaid_prebuild" => { "enabled" => false } }
      end

      it "returns false" do
        config = described_class.new(site)

        expect(config.enabled?).to be false
      end
    end

    context "with enabled: true" do
      let(:site_config) do
        { "mermaid_prebuild" => { "enabled" => true } }
      end

      it "returns true" do
        config = described_class.new(site)

        expect(config.enabled?).to be true
      end
    end
  end

  describe "#cache_dir" do
    it "returns the cache directory path" do
      config = described_class.new(site)

      expect(config.cache_dir).to eq(".jekyll-cache/jekyll-mermaid-prebuild")
    end
  end

  describe "#emoji_width_compensation" do
    # C1: not configured → empty hash
    context "with no emoji_width_compensation configured" do
      it "returns empty hash" do
        config = described_class.new(site)

        expect(config.emoji_width_compensation).to eq({})
      end
    end

    # C2: flowchart: true → { "flowchart" => true }
    context "with emoji_width_compensation: { flowchart: true }" do
      let(:site_config) do
        { "mermaid_prebuild" => { "emoji_width_compensation" => { "flowchart" => true } } }
      end

      it "returns hash with flowchart => true" do
        config = described_class.new(site)

        expect(config.emoji_width_compensation).to eq("flowchart" => true)
      end
    end

    # C3: flowchart: false → { "flowchart" => false }
    context "with emoji_width_compensation: { flowchart: false }" do
      let(:site_config) do
        { "mermaid_prebuild" => { "emoji_width_compensation" => { "flowchart" => false } } }
      end

      it "returns hash with flowchart => false" do
        config = described_class.new(site)

        expect(config.emoji_width_compensation).to eq("flowchart" => false)
      end
    end

    # C4: non-hash value → empty hash (rejected)
    context "with emoji_width_compensation set to a non-hash value" do
      let(:site_config) do
        { "mermaid_prebuild" => { "emoji_width_compensation" => true } }
      end

      it "returns empty hash" do
        config = described_class.new(site)

        expect(config.emoji_width_compensation).to eq({})
      end
    end
  end

  describe "#block_edge_label_padding" do
    context "when not configured" do
      it "returns 0" do
        expect(described_class.new(site).block_edge_label_padding).to eq(0)
      end
    end

    context "when set to an integer" do
      let(:site_config) { { "mermaid_prebuild" => { "block_edge_label_padding" => 6 } } }

      it "returns that value" do
        expect(described_class.new(site).block_edge_label_padding).to eq(6)
      end
    end

    context "when set to a float" do
      let(:site_config) { { "mermaid_prebuild" => { "block_edge_label_padding" => 4.5 } } }

      it "returns that value" do
        expect(described_class.new(site).block_edge_label_padding).to eq(4.5)
      end
    end

    context "when set to false" do
      let(:site_config) { { "mermaid_prebuild" => { "block_edge_label_padding" => false } } }

      it "returns 0" do
        expect(described_class.new(site).block_edge_label_padding).to eq(0)
      end
    end

    context "when set to a negative number" do
      let(:site_config) { { "mermaid_prebuild" => { "block_edge_label_padding" => -3 } } }

      it "returns 0" do
        expect(described_class.new(site).block_edge_label_padding).to eq(0)
      end
    end

    context "when set to a non-numeric value" do
      let(:site_config) { { "mermaid_prebuild" => { "block_edge_label_padding" => "wide" } } }

      it "returns 0" do
        expect(described_class.new(site).block_edge_label_padding).to eq(0)
      end
    end
  end
end
