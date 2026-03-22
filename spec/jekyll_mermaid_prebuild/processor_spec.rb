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
      allow(generator).to receive_messages(
        generate: { "abc12345" => File.join(cache_dir, "abc12345.svg") },
        build_svg_url: "/assets/svg/abc12345.svg",
        build_figure_html: figure_html
      )
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

    context "emoji width compensation integration" do
      # P1: Flowchart with emoji + compensation enabled → EmojiCompensator called
      it "calls EmojiCompensator when flowchart has emoji and compensation enabled" do
        config_with_comp = instance_double(
          JekyllMermaidPrebuild::Configuration,
          **configuration_processor_attrs(
            cache_dir,
            emoji_width_compensation: { "flowchart" => true }
          )
        )
        proc_with_comp = described_class.new(config_with_comp, generator)
        content = <<~MARKDOWN
          ```mermaid
          flowchart LR
            A["🔧"] --> B
          ```
        MARKDOWN
        allow(generator).to receive(:generate) do |source, key, **_kwargs|
          expect(source).to include("&nbsp;&nbsp;")
          { key => File.join(cache_dir, "#{key}.svg") }
        end

        proc_with_comp.process_content(content, site)

        expect(generator).to have_received(:generate)
      end

      # P2: Flowchart with emoji + compensation NOT enabled → EmojiCompensator NOT applied
      it "does not compensate when emoji_width_compensation is not enabled for flowchart" do
        content = <<~MARKDOWN
          ```mermaid
          flowchart LR
            A["🔧"] --> B
          ```
        MARKDOWN
        allow(generator).to receive(:generate) do |source, key, **_kwargs|
          expect(source).not_to include("&nbsp;&nbsp;")
          { key => File.join(cache_dir, "#{key}.svg") }
        end

        processor.process_content(content, site)

        expect(generator).to have_received(:generate)
      end

      # P3: Sequence diagram + compensation enabled for flowchart only → no compensation
      it "does not compensate sequence diagrams when only flowchart is enabled" do
        config_flowchart_only = instance_double(
          JekyllMermaidPrebuild::Configuration,
          **configuration_processor_attrs(
            cache_dir,
            emoji_width_compensation: { "flowchart" => true }
          )
        )
        proc_flowchart_only = described_class.new(config_flowchart_only, generator)
        content = <<~MARKDOWN
          ```mermaid
          sequenceDiagram
            A->>B: 🔧
          ```
        MARKDOWN
        allow(generator).to receive(:generate) do |source, key, **_kwargs|
          expect(source).not_to include("&nbsp;&nbsp;")
          { key => File.join(cache_dir, "#{key}.svg") }
        end

        proc_flowchart_only.process_content(content, site)

        expect(generator).to have_received(:generate)
      end

      # P4: Cache key includes compensated source (different from uncompensated)
      it "uses different cache key for compensated vs uncompensated same diagram" do
        config_with_comp = instance_double(
          JekyllMermaidPrebuild::Configuration,
          **configuration_processor_attrs(
            cache_dir,
            emoji_width_compensation: { "flowchart" => true }
          )
        )
        keys = []
        allow(generator).to receive(:generate) do |_source, key, **_kwargs|
          keys << key
          { key => File.join(cache_dir, "#{key}.svg") }
        end
        content = "```mermaid\nflowchart LR\n  A[\"🔧\"] --> B\n```\n"
        processor.process_content(content, site)
        described_class.new(config_with_comp, generator).process_content(content, site)
        expect(keys.uniq.size).to eq(2)
      end
    end

    context "postprocessing config cache digest" do
      let(:stub_generator) do
        instance_double(
          JekyllMermaidPrebuild::Generator,
          build_svg_url: "/assets/svg/x.svg",
          build_figure_html: "<figure/>"
        )
      end
      let(:captured_keys) { [] }

      before do
        allow(stub_generator).to receive(:generate) do |_source, key, **_kwargs|
          captured_keys << key
          path = File.join(cache_dir, "#{key}.svg")
          File.write(path, "<svg/>")
          { key => path }
        end
      end

      it "uses different cache keys for the same source when padding differs" do
        content = "```mermaid\nflowchart LR\n  A --> B\n```\n"
        cfg4 = instance_double(
          JekyllMermaidPrebuild::Configuration,
          **configuration_processor_attrs(cache_dir, edge_label_padding: 4)
        )
        cfg8 = instance_double(
          JekyllMermaidPrebuild::Configuration,
          **configuration_processor_attrs(cache_dir, edge_label_padding: 8)
        )
        described_class.new(cfg4, stub_generator).process_content(content, site)
        described_class.new(cfg8, stub_generator).process_content(content, site)
        expect(captured_keys.uniq.size).to eq(2)
      end

      it "does not vary digest when padding is zero and booleans match" do
        content = "```mermaid\nflowchart LR\n  A --> B\n```\n"
        cfg = instance_double(
          JekyllMermaidPrebuild::Configuration,
          **configuration_processor_attrs(cache_dir)
        )
        2.times { described_class.new(cfg, stub_generator).process_content(content, site) }
        expect(captured_keys.uniq.size).to eq(1)
      end

      it "uses different cache keys when text_centering changes" do
        content = "```mermaid\nflowchart LR\n  A --> B\n```\n"
        cfg_on = instance_double(
          JekyllMermaidPrebuild::Configuration,
          **configuration_processor_attrs(cache_dir)
        )
        cfg_off = instance_double(
          JekyllMermaidPrebuild::Configuration,
          **configuration_processor_attrs(cache_dir, text_centering: false)
        )
        described_class.new(cfg_on, stub_generator).process_content(content, site)
        described_class.new(cfg_off, stub_generator).process_content(content, site)
        expect(captured_keys.uniq.size).to eq(2)
      end

      it "uses different cache keys when overflow_protection changes" do
        content = "```mermaid\nflowchart LR\n  A --> B\n```\n"
        cfg_on = instance_double(
          JekyllMermaidPrebuild::Configuration,
          **configuration_processor_attrs(cache_dir)
        )
        cfg_off = instance_double(
          JekyllMermaidPrebuild::Configuration,
          **configuration_processor_attrs(cache_dir, overflow_protection: false)
        )
        described_class.new(cfg_on, stub_generator).process_content(content, site)
        described_class.new(cfg_off, stub_generator).process_content(content, site)
        expect(captured_keys.uniq.size).to eq(2)
      end

      it "uses different cache keys when prefers_color_scheme changes" do
        content = "```mermaid\nflowchart LR\n  A --> B\n```\n"
        cfg_light = instance_double(
          JekyllMermaidPrebuild::Configuration,
          **configuration_processor_attrs(cache_dir)
        )
        cfg_dark = instance_double(
          JekyllMermaidPrebuild::Configuration,
          **configuration_processor_attrs(cache_dir, prefers_color_scheme: :dark)
        )
        described_class.new(cfg_light, stub_generator).process_content(content, site)
        described_class.new(cfg_dark, stub_generator).process_content(content, site)
        expect(captured_keys.uniq.size).to eq(2)
      end

      it "uses different cache keys when chart_background_light changes" do
        content = "```mermaid\nflowchart LR\n  A --> B\n```\n"
        cfg_a = instance_double(
          JekyllMermaidPrebuild::Configuration,
          **configuration_processor_attrs(cache_dir, chart_background_light: "white")
        )
        cfg_b = instance_double(
          JekyllMermaidPrebuild::Configuration,
          **configuration_processor_attrs(cache_dir, chart_background_light: "#fff0aa")
        )
        described_class.new(cfg_a, stub_generator).process_content(content, site)
        described_class.new(cfg_b, stub_generator).process_content(content, site)
        expect(captured_keys.uniq.size).to eq(2)
      end

      it "uses different cache keys when chart_background_dark changes" do
        content = "```mermaid\nflowchart LR\n  A --> B\n```\n"
        cfg_a = instance_double(
          JekyllMermaidPrebuild::Configuration,
          **configuration_processor_attrs(cache_dir, chart_background_dark: "black")
        )
        cfg_b = instance_double(
          JekyllMermaidPrebuild::Configuration,
          **configuration_processor_attrs(cache_dir, chart_background_dark: "navy")
        )
        described_class.new(cfg_a, stub_generator).process_content(content, site)
        described_class.new(cfg_b, stub_generator).process_content(content, site)
        expect(captured_keys.uniq.size).to eq(2)
      end
    end

    context "when prefers_color_scheme is :auto" do
      let(:config_auto) do
        instance_double(
          JekyllMermaidPrebuild::Configuration,
          **configuration_processor_attrs(cache_dir, prefers_color_scheme: :auto)
        )
      end
      let(:processor_auto) { described_class.new(config_auto, generator) }
      let(:content_with_mermaid) do
        <<~MARKDOWN
          ```mermaid
          graph TD
          A-->B
          ```
        MARKDOWN
      end

      it "merges light and dark SVG entries into svgs_to_copy" do
        allow(generator).to receive(:generate) do |_source, key, **_kwargs|
          {
            key => File.join(cache_dir, "#{key}.svg"),
            "#{key}-dark" => File.join(cache_dir, "#{key}-dark.svg")
          }
        end
        allow(generator).to receive(:build_svg_url) { |stem| "/assets/svg/#{stem}.svg" }
        allow(generator).to receive(:build_figure_html).and_return("<figure>auto</figure>")

        _result, _count, svgs = processor_auto.process_content(content_with_mermaid, site)

        expect(svgs.size).to eq(2)
        expect(svgs.keys).to include(match(/\A[a-f0-9]{8}\z/), match(/\A[a-f0-9]{8}-dark\z/))
      end

      it "builds figure HTML with dark_url" do
        allow(generator).to receive(:generate) do |_source, key, **_kwargs|
          {
            key => File.join(cache_dir, "#{key}.svg"),
            "#{key}-dark" => File.join(cache_dir, "#{key}-dark.svg")
          }
        end
        allow(generator).to receive(:build_svg_url) { |stem| "/assets/svg/#{stem}.svg" }
        expect(generator).to receive(:build_figure_html).with(
          a_string_matching(%r{\A/assets/svg/[a-f0-9]{8}\.svg\z}),
          hash_including(dark_url: a_string_matching(%r{\A/assets/svg/[a-f0-9]{8}-dark\.svg\z}))
        ).and_return("<figure/>")

        processor_auto.process_content(content_with_mermaid, site)
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
