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

  describe "#max_width" do
    # B9: max_width defaults to nil when not configured
    context "with no max_width configured" do
      it "returns nil" do
        config = described_class.new(site)

        expect(config.max_width).to be_nil
      end
    end

    # B10: max_width parses positive integer from config
    context "with max_width: 640" do
      let(:site_config) { { "mermaid_prebuild" => { "max_width" => 640 } } }

      it "returns the configured integer" do
        config = described_class.new(site)

        expect(config.max_width).to eq(640)
      end
    end

    # B11: max_width rejects zero and negative values → nil
    context "with max_width: 0" do
      let(:site_config) { { "mermaid_prebuild" => { "max_width" => 0 } } }

      it "returns nil for zero" do
        config = described_class.new(site)

        expect(config.max_width).to be_nil
      end
    end

    context "with max_width: -100" do
      let(:site_config) { { "mermaid_prebuild" => { "max_width" => -100 } } }

      it "returns nil for negative value" do
        config = described_class.new(site)

        expect(config.max_width).to be_nil
      end
    end

    # B12: max_width rejects non-integer values (string, float, boolean) → nil
    context "with max_width: 'large'" do
      let(:site_config) { { "mermaid_prebuild" => { "max_width" => "large" } } }

      it "returns nil for string value" do
        config = described_class.new(site)

        expect(config.max_width).to be_nil
      end
    end

    context "with max_width: 3.14" do
      let(:site_config) { { "mermaid_prebuild" => { "max_width" => 3.14 } } }

      it "returns nil for float value" do
        config = described_class.new(site)

        expect(config.max_width).to be_nil
      end
    end

    context "with max_width: true" do
      let(:site_config) { { "mermaid_prebuild" => { "max_width" => true } } }

      it "returns nil for boolean value" do
        config = described_class.new(site)

        expect(config.max_width).to be_nil
      end
    end
  end
end
