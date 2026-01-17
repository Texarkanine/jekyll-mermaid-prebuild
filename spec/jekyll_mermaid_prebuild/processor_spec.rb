# frozen_string_literal: true

require "spec_helper"

RSpec.describe JekyllMermaidPrebuild::Processor do
  subject(:processor) { described_class.new(config, generator) }

  let(:cache_dir) { File.join(@temp_dir, "cache") }
  let(:config) do
    instance_double(
      JekyllMermaidPrebuild::Configuration,
      cache_dir: cache_dir,
      output_dir: "assets/svg",
      enabled?: true
    )
  end
  let(:generator) { instance_double(JekyllMermaidPrebuild::Generator) }
  let(:site_data) { {} }
  let(:site) do
    instance_double(Jekyll::Site, data: site_data, dest: @temp_dir)
  end

  describe "#process_content" do
    let(:content_with_mermaid) do
      <<~MARKDOWN
        # Test Document

        Some text before.

        ```mermaid
        graph TD
        A-->B
        ```

        Some text after.
      MARKDOWN
    end

    let(:content_without_mermaid) do
      <<~MARKDOWN
        # Test Document

        Just regular content.

        ```ruby
        puts 'hello'
        ```
      MARKDOWN
    end

    before do
      FileUtils.mkdir_p(cache_dir)
      figure_html = <<~HTML
        <figure class="mermaid-diagram">
        <a href="/assets/svg/abc12345.svg"><img src="/assets/svg/abc12345.svg" alt="Mermaid Diagram"></a>
        </figure>
      HTML
      allow(generator).to receive_messages(generate: File.join(cache_dir, "abc12345.svg"),
                                           build_svg_url: "/assets/svg/abc12345.svg", build_figure_html: figure_html)
      File.write(File.join(cache_dir, "abc12345.svg"), "<svg>test</svg>")
    end

    context "with mermaid code block" do
      it "replaces mermaid block with figure HTML" do
        result, count, = processor.process_content(content_with_mermaid, site)

        expect(count).to eq(1)
        expect(result).to include("<figure class=\"mermaid-diagram\">")
        expect(result).not_to include("```mermaid")
      end

      it "tracks SVGs for copying" do
        _result, _count, svgs = processor.process_content(content_with_mermaid, site)

        expect(svgs).not_to be_empty
      end
    end

    context "without mermaid code block" do
      it "returns content unchanged" do
        result, count, svgs = processor.process_content(content_without_mermaid, site)

        expect(count).to eq(0)
        expect(result).to eq(content_without_mermaid)
        expect(svgs).to be_empty
      end
    end

    context "with multiple mermaid blocks" do
      let(:content_with_multiple) do
        <<~MARKDOWN
          ```mermaid
          graph TD
          A-->B
          ```

          Some text.

          ~~~mermaid
          flowchart LR
          X-->Y
          ~~~
        MARKDOWN
      end

      it "converts all blocks" do
        result, count, _svgs = processor.process_content(content_with_multiple, site)

        expect(count).to eq(2)
        expect(result.scan("<figure class=\"mermaid-diagram\">").length).to eq(2)
      end
    end

    context "when generation fails" do
      before do
        allow(generator).to receive(:generate).and_return(nil)
      end

      it "keeps original code block" do
        result, count, _svgs = processor.process_content(content_with_mermaid, site)

        expect(count).to eq(0)
        expect(result).to include("```mermaid")
      end
    end
  end
end
