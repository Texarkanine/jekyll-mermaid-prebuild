# frozen_string_literal: true

require "spec_helper"

RSpec.describe JekyllMermaidPrebuild::Processor do
  let(:config) do
    instance_double(
      JekyllMermaidPrebuild::Configuration,
      prefers_color_scheme: :light,
      chart_background_light: "white",
      chart_background_dark: "black",
      text_centering: true,
      overflow_protection: true,
      edge_label_padding: 0,
      emoji_width_compensation: {}
    )
  end
  let(:generator) do
    instance_double(
      JekyllMermaidPrebuild::Generator,
      generate: { "abc" => "/cache/abc.svg" },
      build_svg_url: "/assets/svg/abc.svg",
      build_figure_html: "<figure/>"
    )
  end
  let(:processor) { described_class.new(config, generator) }

  describe "#digest_string_for_cache" do
    it "includes source and prefers-color-scheme / background tokens" do
      digest = processor.digest_string_for_cache("graph TD", "flowchart")
      expect(digest).to include("graph TD")
      expect(digest).to include("pcs=light")
      expect(digest).to include("bgL=white")
      expect(digest).to include("bgD=black")
      expect(digest).not_to include("tc=")
      expect(digest).not_to include("op=")
      expect(digest).not_to include("edge_pad=")
    end

    it "includes tc/op/edge_pad only when non-default" do
      allow(config).to receive_messages(text_centering: false, overflow_protection: false, edge_label_padding: 3)
      digest = processor.digest_string_for_cache("x", nil)
      expect(digest).to include("tc=false")
      expect(digest).to include("op=false")
      expect(digest).to include("edge_pad=3")
    end
  end

  describe "#convert_block" do
    it "returns nil when generation fails" do
      allow(generator).to receive(:generate).and_return(nil)
      expect(processor.convert_block(content: "graph TD\nA-->B")).to be_nil
    end

    it "returns svgs and html when generation succeeds" do
      result = processor.convert_block(content: "graph TD\nA-->B")
      expect(result[:svgs]).to eq("abc" => "/cache/abc.svg")
      expect(result[:html]).to eq("<figure/>")
    end
  end

  describe "#find_top_level_mermaid_blocks" do
    it "finds a top-level mermaid block" do
      blocks = processor.find_top_level_mermaid_blocks("```mermaid\ngraph TD\n```\n")
      expect(blocks.length).to eq(1)
      expect(blocks.first[:content]).to include("graph TD")
    end

    it "ignores mermaid nested inside another fence" do
      content = "````text\n```mermaid\ngraph TD\n```\n````\n"
      expect(processor.find_top_level_mermaid_blocks(content)).to be_empty
    end
  end
end
