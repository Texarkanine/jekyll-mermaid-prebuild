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
      enabled?: true,
      max_width: nil
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

    context "cache key uniqueness with max_width" do
      let(:mermaid_source) { "graph TD\nA-->B\n" }
      let(:diagram_content) { "```mermaid\n#{mermaid_source}```\n" }

      def capture_cache_key(processor)
        captured = nil
        allow(generator).to receive(:generate) do |_src, key|
          captured = key
          File.join(cache_dir, "#{key}.svg")
        end
        processor.process_content(diagram_content)
        captured
      end

      # B17: Same diagram source + different max_width → different cache keys
      it "produces different cache keys for different max_width values" do
        config_fixed = instance_double(
          JekyllMermaidPrebuild::Configuration,
          cache_dir: cache_dir, output_dir: "assets/svg",
          enabled?: true, max_width: 640
        )

        key_no_width = capture_cache_key(described_class.new(config, generator))
        key_with_width = capture_cache_key(described_class.new(config_fixed, generator))

        expect(key_no_width).not_to eq(key_with_width)
      end

      # B18: max_width=nil → cache key differs from legacy format (auto-migration)
      # The new key format is digest("source\x00max_width=nil"), which differs from
      # digest("source"), ensuring cached SVGs from before the upgrade are regenerated.
      it "produces a different cache key than the raw-source digest (legacy format)" do
        new_key = capture_cache_key(described_class.new(config, generator))
        legacy_key = JekyllMermaidPrebuild::DigestCalculator.content_digest(mermaid_source)

        expect(new_key).not_to eq(legacy_key)
      end
    end

    context "with mermaid block nested inside another fence" do
      let(:content_with_nested_mermaid) do
        <<~MARKDOWN
          # Documentation Example

          Here's how to write a mermaid diagram:

          ````markdown
          ```mermaid
          graph TD
          A-->B
          ```
          ````

          And here's a real diagram:

          ```mermaid
          flowchart LR
          X-->Y
          ```
        MARKDOWN
      end

      it "only converts top-level mermaid blocks, not nested examples" do
        result, count, _svgs = processor.process_content(content_with_nested_mermaid, site)

        # Should only convert the real diagram (1), not the nested example
        expect(count).to eq(1)

        # The nested example should remain as literal code
        expect(result).to include("````markdown")
        expect(result).to include("```mermaid\ngraph TD")

        # The real diagram should be converted
        expect(result).to include("<figure class=\"mermaid-diagram\">")
        expect(result).not_to include("flowchart LR")
      end

      it "preserves nested mermaid blocks inside tilde fences" do
        content = <<~MARKDOWN
          ~~~~markdown
          ~~~mermaid
          graph TD
          A-->B
          ~~~
          ~~~~
        MARKDOWN

        result, count, _svgs = processor.process_content(content, site)

        expect(count).to eq(0)
        expect(result).to include("~~~mermaid")
        expect(result).to include("graph TD")
      end

      it "handles deeply nested fences correctly" do
        content = <<~MARKDOWN
          `````
          ````markdown
          ```mermaid
          graph TD
          A-->B
          ```
          ````
          `````
        MARKDOWN

        result, count, _svgs = processor.process_content(content, site)

        expect(count).to eq(0)
        expect(result).to include("```mermaid")
      end
    end
  end
end
