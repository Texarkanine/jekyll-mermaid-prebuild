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
        expect(svgs.keys).to all(match(/\A[a-f0-9]{8}\z/))
        expect(svgs.values).to all(start_with(cache_dir).and(end_with(".svg")))
      end

      it "merges svg paths into a cumulative hash" do
        _result, _count, svgs = processor.process_content(content_with_mermaid, site)

        expect(svgs).to be_a(Hash)
        expect(svgs.values.first).to eq(File.join(cache_dir, "#{svgs.keys.first}.svg"))
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

      it "replaces every block when earlier replacements change string length" do
        content = <<~MARKDOWN
          ```mermaid
          first-diagram
          ```

          filler paragraph between blocks

          ```mermaid
          second-diagram
          ```
        MARKDOWN

        result, count, _svgs = processor.process_content(content, site)

        expect(count).to eq(2)
        expect(result).not_to include("first-diagram")
        expect(result).not_to include("second-diagram")
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

    context "when content is nil" do
      it "returns early without processing" do
        expect(processor.process_content(nil)).to eq([nil, 0, {}])
      end
    end

    it "does not mutate the original content string" do
      content = "```mermaid\nA-->B\n```\n"
      original = content.dup

      processor.process_content(content, site)

      expect(content).to eq(original)
    end

    it "preserves characters immediately after the replaced block" do
      content = "```mermaid\nA\n```\nTAIL"

      result, count, = processor.process_content(content, site)

      expect(count).to eq(1)
      expect(result).to end_with("TAIL")
    end

    context "when generation fails for the first block only" do
      let(:content_with_two_blocks) do
        <<~MARKDOWN
          ```mermaid
          first
          ```

          ```mermaid
          second
          ```
        MARKDOWN
      end

      it "continues converting later blocks" do
        calls = 0
        allow(generator).to receive(:generate) do |_source, key, **_kwargs|
          calls += 1
          next nil if calls == 1

          path = File.join(cache_dir, "#{key}.svg")
          File.write(path, "<svg/>")
          { key => path }
        end

        _result, count, _svgs = processor.process_content(content_with_two_blocks, site)

        expect(count).to eq(1)
      end
    end

    context "when convert_block returns empty paths" do
      before do
        allow(generator).to receive(:generate).and_return({})
      end

      it "skips conversion and leaves the block in place" do
        result, count, svgs = processor.process_content(content_with_mermaid, site)

        expect(count).to eq(0)
        expect(svgs).to be_empty
        expect(result).to include("```mermaid")
      end
    end
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

        expect(JekyllMermaidPrebuild::EmojiCompensator).not_to receive(:compensate)
        allow(generator).to receive(:generate).and_return(nil)

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
        flowchart_block = { content: "flowchart LR\n  A --> B\n" }

        expect(JekyllMermaidPrebuild::EmojiCompensator).not_to receive(:compensate)
        allow(generator).to receive(:generate).and_return(nil)

        processor_disabled.convert_block(flowchart_block)
      end
    end
  end

  describe "#find_top_level_mermaid_blocks" do
    it "returns an empty array when no mermaid blocks exist" do
      content = "# Title\n\nNo diagrams here.\n"

      expect(processor.find_top_level_mermaid_blocks(content)).to eq([])
    end

    it "records start position zero for a leading mermaid block" do
      content = "```mermaid\nA-->B\n```\n"

      blocks = processor.find_top_level_mermaid_blocks(content)

      expect(blocks.length).to eq(1)
      expect(blocks[0][:start]).to eq(0)
      expect(blocks[0][:end]).to eq(content.length)
      expect(blocks[0][:content]).to eq("A-->B\n")
    end

    it "finds multiple top-level mermaid blocks" do
      content = <<~MARKDOWN
        ```mermaid
        graph TD
        A-->B
        ```

        ```mermaid
        flowchart LR
        X-->Y
        ```
      MARKDOWN

      blocks = processor.find_top_level_mermaid_blocks(content)

      expect(blocks.length).to eq(2)
      expect(blocks.map { |b| b[:content].strip }).to contain_exactly(
        "graph TD\nA-->B",
        "flowchart LR\nX-->Y"
      )
    end

    it "ignores mermaid blocks nested inside another fence" do
      content = <<~MARKDOWN
        ````markdown
        ```mermaid
        nested
        ```
        ````

        ```mermaid
        top-level
        ```
      MARKDOWN

      blocks = processor.find_top_level_mermaid_blocks(content)

      expect(blocks.length).to eq(1)
      expect(blocks[0][:content]).to eq("top-level\n")
    end

    it "finds mermaid blocks opened with tilde fences" do
      content = "~~~mermaid\nflowchart LR\nX-->Y\n~~~\n"

      blocks = processor.find_top_level_mermaid_blocks(content)

      expect(blocks.length).to eq(1)
      expect(blocks[0][:content]).to eq("flowchart LR\nX-->Y\n")
    end
  end

  describe "#process_line" do
    def empty_state
      { blocks: [], fence_stack: [], current_mermaid: nil, position: 0 }
    end

    it "advances position by the line length" do
      state = empty_state

      processor.process_line("hello\n", state)

      expect(state[:position]).to eq(6)
    end

    it "delegates fence openers to handle_fence_line" do
      state = empty_state

      processor.process_line("```mermaid\n", state)

      expect(state[:current_mermaid]).to include(fence_type: "`", fence_length: 3, start: 0)
    end

    it "passes the original line when closing a mermaid fence" do
      state = {
        blocks: [],
        fence_stack: [],
        current_mermaid: { start: 0, fence_type: "`", fence_length: 3, content_lines: ["A\n"] },
        position: 3
      }

      processor.process_line("```\n", state)

      expect(state[:blocks].length).to eq(1)
      expect(state[:current_mermaid]).to be_nil
    end

    it "passes the current position as the line start offset" do
      state = empty_state.merge(position: 5)

      processor.process_line("```mermaid\n", state)

      expect(state[:current_mermaid][:start]).to eq(5)
    end

    it "appends non-fence lines to the active mermaid block" do
      state = {
        blocks: [],
        fence_stack: [],
        current_mermaid: { start: 0, fence_type: "`", fence_length: 3, content_lines: [] },
        position: 12
      }

      processor.process_line("  A-->B\n", state)

      expect(state[:current_mermaid][:content_lines]).to eq(["  A-->B\n"])
      expect(state[:position]).to eq(20)
    end

    it "ignores non-fence lines when current_mermaid is not set on state" do
      state = { blocks: [], fence_stack: [], position: 0 }

      processor.process_line("plain text\n", state)

      expect(state[:current_mermaid]).to be_nil
    end

    it "requires content_lines to be initialized before appending diagram lines" do
      state = {
        blocks: [],
        fence_stack: [],
        current_mermaid: { start: 0, fence_type: "`", fence_length: 3 },
        position: 0
      }

      expect do
        processor.process_line("A\n", state)
      end.to raise_error(NoMethodError)
    end

    it "requires position to be initialized before processing" do
      expect do
        processor.process_line("hello\n", { blocks: [], fence_stack: [], current_mermaid: nil })
      end.to raise_error(NoMethodError)
    end
  end

  describe "#handle_fence_line" do
    def empty_state
      { blocks: [], fence_stack: [], current_mermaid: nil, position: 0 }
    end

    def fence_match(line)
      line.match(described_class::FENCE_OPENER)
    end

    it "starts a mermaid block at top level" do
      state = empty_state
      line = "```mermaid\n"

      processor.handle_fence_line(line, 0, fence_match(line), state)

      expect(state[:current_mermaid]).to include(fence_type: "`", fence_length: 3, start: 0)
    end

    it "opens mermaid blocks when current_mermaid is not yet set on state" do
      state = { blocks: [], fence_stack: [], position: 0 }
      line = "```mermaid\n"

      processor.handle_fence_line(line, 0, fence_match(line), state)

      expect(state[:current_mermaid]).to include(fence_type: "`", fence_length: 3)
    end

    it "requires fence_stack to be initialized before routing at top level" do
      state = { blocks: [], position: 0 }
      line = "```mermaid\n"

      expect do
        processor.handle_fence_line(line, 0, fence_match(line), state)
      end.to raise_error(NoMethodError)
    end

    it "uses the first fence character as fence type for tilde fences" do
      state = empty_state
      line = "~~~mermaid\n"

      processor.handle_fence_line(line, 0, fence_match(line), state)

      expect(state[:current_mermaid][:fence_type]).to eq("~")
    end

    it "pushes non-mermaid fences onto the stack at top level" do
      state = empty_state
      line = "```ruby\n"

      processor.handle_fence_line(line, 0, fence_match(line), state)

      expect(state[:fence_stack]).to eq([[3, "`"]])
    end

    it "routes to handle_line_in_mermaid when already inside a mermaid block" do
      state = {
        blocks: [],
        fence_stack: [],
        current_mermaid: { start: 0, fence_type: "`", fence_length: 3, content_lines: ["A\n"] },
        position: 5
      }
      line = "```\n"

      processor.handle_fence_line(line, 5, fence_match(line), state)

      expect(state[:blocks].length).to eq(1)
      expect(state[:current_mermaid]).to be_nil
    end

    it "routes to handle_line_in_nested_fence when inside a non-mermaid fence" do
      state = { blocks: [], fence_stack: [[3, "`"]], current_mermaid: nil, position: 10 }
      line = "```\n"

      processor.handle_fence_line(line, 10, fence_match(line), state)

      expect(state[:fence_stack]).to be_empty
    end
  end

  describe "#handle_line_at_top_level" do
    def empty_state
      { blocks: [], fence_stack: [], current_mermaid: nil, position: 0 }
    end

    it "opens a mermaid block when language is mermaid" do
      state = empty_state

      processor.handle_line_at_top_level(4, "mermaid", "`", 3, state)

      expect(state[:current_mermaid]).to eq(
        start: 4,
        fence_type: "`",
        fence_length: 3,
        content_lines: []
      )
    end

    it "pushes other languages onto the fence stack" do
      state = empty_state

      processor.handle_line_at_top_level(0, "ruby", "`", 3, state)
      processor.handle_line_at_top_level(10, "python", "~", 4, state)

      expect(state[:fence_stack]).to eq([[3, "`"], [4, "~"]])
    end

    it "does not open a mermaid block for other languages" do
      state = empty_state

      processor.handle_line_at_top_level(0, "ruby", "`", 3, state)

      expect(state[:current_mermaid]).to be_nil
    end

    it "requires fence_stack to be initialized before pushing" do
      expect do
        processor.handle_line_at_top_level(0, "ruby", "`", 3, { blocks: [], position: 0 })
      end.to raise_error(NoMethodError)
    end
  end

  describe "#handle_line_in_mermaid" do
    def mermaid_state(content_lines: ["A\n"])
      {
        blocks: [],
        fence_stack: [],
        current_mermaid: { start: 0, fence_type: "`", fence_length: 3, content_lines: content_lines.dup },
        position: content_lines.join.length
      }
    end

    it "closes the block when fence type, length, and stripped line match" do
      state = mermaid_state
      state[:position] = 5

      processor.handle_line_in_mermaid("```\n", "```", "`", 3, state)

      expect(state[:blocks]).to eq([{ start: 0, end: 5, content: "A\n" }])
      expect(state[:current_mermaid]).to be_nil
    end

    it "joins accumulated content lines when closing" do
      state = mermaid_state(content_lines: %W[A\n B\n])
      state[:position] = 10

      processor.handle_line_in_mermaid("```\n", "```", "`", 3, state)

      expect(state[:blocks][0][:content]).to eq("A\nB\n")
      expect(state[:blocks][0][:end]).to eq(10)
    end

    it "does not close when fence type differs" do
      state = mermaid_state
      state[:position] = 5

      processor.handle_line_in_mermaid("~~~\n", "~~~", "~", 3, state)

      expect(state[:blocks]).to be_empty
      expect(state[:current_mermaid][:content_lines]).to eq(["A\n", "~~~\n"])
    end

    it "does not close when fence length differs" do
      state = mermaid_state
      state[:position] = 5

      processor.handle_line_in_mermaid("````\n", "````", "`", 4, state)

      expect(state[:blocks]).to be_empty
      expect(state[:current_mermaid][:content_lines]).to eq(["A\n", "````\n"])
    end

    it "does not close when stripped line differs from fence chars" do
      state = mermaid_state
      state[:position] = 5

      processor.handle_line_in_mermaid("```ruby\n", "```", "`", 3, state)

      expect(state[:blocks]).to be_empty
      expect(state[:current_mermaid][:content_lines]).to eq(["A\n", "```ruby\n"])
    end

    it "closes even when the closing fence has leading whitespace" do
      state = mermaid_state
      state[:position] = 8

      processor.handle_line_in_mermaid("   ```\n", "```", "`", 3, state)

      expect(state[:blocks].length).to eq(1)
      expect(state[:current_mermaid]).to be_nil
    end

    it "records nil end when position is not set on state" do
      state = {
        blocks: [],
        fence_stack: [],
        current_mermaid: { start: 0, fence_type: "`", fence_length: 3, content_lines: ["A\n"] }
      }

      processor.handle_line_in_mermaid("```\n", "```", "`", 3, state)

      expect(state[:blocks][0][:end]).to be_nil
    end

    it "records nil start when fence metadata omits start" do
      state = {
        blocks: [],
        fence_stack: [],
        current_mermaid: { fence_type: "`", fence_length: 3, content_lines: ["A\n"] },
        position: 5
      }

      processor.handle_line_in_mermaid("```\n", "```", "`", 3, state)

      expect(state[:blocks][0][:start]).to be_nil
    end

    it "requires blocks to be initialized before recording a closed fence" do
      state = {
        fence_stack: [],
        current_mermaid: { start: 0, fence_type: "`", fence_length: 3, content_lines: ["A\n"] },
        position: 5
      }

      expect do
        processor.handle_line_in_mermaid("```\n", "```", "`", 3, state)
      end.to raise_error(NoMethodError)
    end

    it "requires current_mermaid to be initialized before handling" do
      expect do
        processor.handle_line_in_mermaid("```\n", "```", "`", 3, { blocks: [], fence_stack: [], position: 0 })
      end.to raise_error(NoMethodError)
    end

    it "does not close when fence metadata omits fence_type" do
      state = {
        blocks: [],
        fence_stack: [],
        current_mermaid: { start: 0, fence_length: 3, content_lines: ["A\n"] },
        position: 5
      }

      processor.handle_line_in_mermaid("```\n", "```", "`", 3, state)

      expect(state[:blocks]).to be_empty
      expect(state[:current_mermaid][:content_lines]).to eq(["A\n", "```\n"])
    end

    it "does not close when fence metadata omits fence_length" do
      state = {
        blocks: [],
        fence_stack: [],
        current_mermaid: { start: 0, fence_type: "`", content_lines: ["A\n"] },
        position: 5
      }

      processor.handle_line_in_mermaid("```\n", "```", "`", 3, state)

      expect(state[:blocks]).to be_empty
      expect(state[:current_mermaid][:content_lines]).to eq(["A\n", "```\n"])
    end

    it "raises when closing without initialized content_lines" do
      state = {
        blocks: [],
        fence_stack: [],
        current_mermaid: { start: 0, fence_type: "`", fence_length: 3 },
        position: 5
      }

      expect do
        processor.handle_line_in_mermaid("```\n", "```", "`", 3, state)
      end.to raise_error(NoMethodError)
    end
  end

  describe "#handle_line_in_nested_fence" do
    def nested_state(stack)
      { blocks: [], fence_stack: stack.dup, current_mermaid: nil, position: 0 }
    end

    it "pops the stack when a matching closing fence is found" do
      state = nested_state([[3, "`"]])

      processor.handle_line_in_nested_fence("```\n", "`", 3, state)

      expect(state[:fence_stack]).to be_empty
    end

    it "requires matching fence type to pop" do
      state = nested_state([[3, "`"]])

      processor.handle_line_in_nested_fence("~~~\n", "~", 3, state)

      expect(state[:fence_stack]).to eq([[3, "`"], [3, "~"]])
    end

    it "requires closing fence length to be at least the opener length" do
      state = nested_state([[4, "`"]])

      processor.handle_line_in_nested_fence("```\n", "`", 3, state)

      expect(state[:fence_stack]).to eq([[4, "`"], [3, "`"]])
    end

    it "pops when the closing fence is longer than the opener" do
      state = nested_state([[3, "`"]])

      processor.handle_line_in_nested_fence("````\n", "`", 4, state)

      expect(state[:fence_stack]).to be_empty
    end

    it "pops only the innermost fence from the stack" do
      state = nested_state([[3, "`"], [4, "`"]])

      processor.handle_line_in_nested_fence("````\n", "`", 4, state)

      expect(state[:fence_stack]).to eq([[3, "`"]])
    end

    it "pops closing fences that include trailing whitespace after strip" do
      state = nested_state([[3, "`"]])

      processor.handle_line_in_nested_fence("```   \n", "`", 3, state)

      expect(state[:fence_stack]).to be_empty
    end

    it "pushes when encountering an inner opening fence" do
      state = nested_state([[3, "`"]])

      processor.handle_line_in_nested_fence("````ruby\n", "`", 4, state)

      expect(state[:fence_stack]).to eq([[3, "`"], [4, "`"]])
    end

    it "does not pop when the closing line is not only fence characters" do
      state = nested_state([[3, "`"]])

      processor.handle_line_in_nested_fence("```ruby\n", "`", 3, state)

      expect(state[:fence_stack]).to eq([[3, "`"], [3, "`"]])
    end

    it "pops even when the closing fence has leading whitespace" do
      state = nested_state([[3, "`"]])

      processor.handle_line_in_nested_fence("   ```\n", "`", 3, state)

      expect(state[:fence_stack]).to be_empty
    end

    it "requires fence_stack to be initialized before inspecting nested fences" do
      expect do
        processor.handle_line_in_nested_fence("```\n", "`", 3, { blocks: [], position: 0 })
      end.to raise_error(NoMethodError)
    end
  end
end
