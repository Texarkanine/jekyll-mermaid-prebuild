# frozen_string_literal: true

require "spec_helper"

RSpec.describe JekyllMermaidPrebuild::Hooks do
  let(:logger) { instance_double(Jekyll::LogAdapter, info: nil, warn: nil, error: nil, debug: nil) }

  before do
    allow(Jekyll).to receive(:logger).and_return(logger)
  end

  describe ".copy_svgs_to_site" do
    let(:cache_dir) { File.join(@temp_dir, "cache") }
    let(:dest_dir) { File.join(@temp_dir, "site") }
    let(:config) do
      instance_double(
        JekyllMermaidPrebuild::Configuration,
        cache_dir: cache_dir,
        output_dir: "assets/svg"
      )
    end
    let(:site) do
      instance_double(Jekyll::Site, dest: dest_dir)
    end

    before do
      FileUtils.mkdir_p(cache_dir)
    end

    context "with SVGs to copy" do
      let(:svgs) do
        {
          "abc12345" => File.join(cache_dir, "abc12345.svg"),
          "def67890" => File.join(cache_dir, "def67890.svg")
        }
      end

      before do
        svgs.each do |key, path|
          File.write(path, "<svg>#{key}</svg>")
        end
      end

      it "copies all SVGs to destination" do
        described_class.copy_svgs_to_site(site, config, svgs)

        svgs.each do |key, cache_path|
          dest_path = File.join(dest_dir, "assets/svg/#{key}.svg")
          expect(File.exist?(dest_path)).to be true
          expect(File.read(dest_path)).to eq(File.read(cache_path))
        end
      end

      it "creates output directory if needed" do
        described_class.copy_svgs_to_site(site, config, svgs)

        expect(Dir.exist?(File.join(dest_dir, "assets/svg"))).to be true
      end

      it "logs the exact copied count and output directory" do
        described_class.copy_svgs_to_site(site, config, svgs)

        expect(logger).to have_received(:info).with("MermaidPrebuild:", "Copied 2 SVG(s) to assets/svg/")
      end

      it "warns and skips missing cache files without counting them" do
        missing_path = File.join(cache_dir, "missing.svg")
        svgs["missing"] = missing_path

        described_class.copy_svgs_to_site(site, config, svgs)

        expect(logger).to have_received(:warn).with(
          "MermaidPrebuild:",
          "Missing cached SVG for missing (expected: #{missing_path})"
        )
        expect(logger).to have_received(:info).with("MermaidPrebuild:", "Copied 2 SVG(s) to assets/svg/")
      end

      it "skips a nil cached_path without raising and continues copying later entries" do
        present = File.join(cache_dir, "present-file.svg")
        File.write(present, "<svg>present</svg>")
        ordered = {
          "nilkey" => nil,
          "present" => present
        }

        expect { described_class.copy_svgs_to_site(site, config, ordered) }.not_to raise_error

        expect(logger).to have_received(:warn).with(
          "MermaidPrebuild:",
          "Missing cached SVG for nilkey (expected: )"
        )
        expect(File.exist?(File.join(dest_dir, "assets/svg/present.svg"))).to be true
        expect(logger).to have_received(:info).with("MermaidPrebuild:", "Copied 1 SVG(s) to assets/svg/")
      end

      it "names destination files from the cache key, not the source basename" do
        weird = File.join(cache_dir, "weird_name.svg")
        File.write(weird, "<svg>weird</svg>")

        described_class.copy_svgs_to_site(site, config, { "keyed1234" => weird })

        expect(File.exist?(File.join(dest_dir, "assets/svg/keyed1234.svg"))).to be true
        expect(File.exist?(File.join(dest_dir, "assets/svg/weird_name.svg"))).to be false
      end
    end

    context "with light and dark stems (auto mode)" do
      let(:svgs) do
        {
          "abc12345" => File.join(cache_dir, "abc12345.svg"),
          "abc12345-dark" => File.join(cache_dir, "abc12345-dark.svg")
        }
      end

      before do
        svgs.each_value { |path| File.write(path, "<svg/>") }
      end

      it "copies both SVGs including the -dark suffix filename" do
        described_class.copy_svgs_to_site(site, config, svgs)

        svgs.each do |key, cache_path|
          dest_path = File.join(dest_dir, "assets/svg/#{key}.svg")
          expect(File.exist?(dest_path)).to be true
          expect(File.read(dest_path)).to eq(File.read(cache_path))
        end
      end
    end

    context "with empty SVGs hash" do
      it "does nothing" do
        described_class.copy_svgs_to_site(site, config, {})

        expect(Dir.exist?(File.join(dest_dir, "assets/svg"))).to be false
        expect(Dir.children(@temp_dir)).not_to include("site")
      end
    end

    context "with nil SVGs" do
      it "does nothing" do
        described_class.copy_svgs_to_site(site, config, nil)

        expect(Dir.exist?(File.join(dest_dir, "assets/svg"))).to be false
        expect(Dir.children(@temp_dir)).not_to include("site")
      end
    end
  end

  describe ".log_puppeteer_error" do
    it "logs the Puppeteer failure topic" do
      described_class.log_puppeteer_error

      expect(logger).to have_received(:error).with(
        "MermaidPrebuild:",
        a_string_matching(/Puppeteer cannot launch headless Chrome/)
      )
    end

    it "logs the troubleshooting guidance topic" do
      described_class.log_puppeteer_error

      expect(logger).to have_received(:error).with(
        "MermaidPrebuild:",
        a_string_matching(%r{pptr\.dev/troubleshooting})
      )
    end
  end

  describe ".initialize_system" do
    let(:site_data) { {} }
    let(:site) do
      instance_double(
        Jekyll::Site,
        config: site_config,
        data: site_data,
        source: @temp_dir,
        dest: File.join(@temp_dir, "_site")
      )
    end

    before do
      JekyllMermaidPrebuild::MmdcWrapper.reset_cache!
    end

    context "when plugin is disabled" do
      let(:site_config) { { "mermaid_prebuild" => { "enabled" => false } } }

      it "marks the site disabled and logs" do
        described_class.initialize_system(site)

        expect(site_data["mermaid_prebuild_enabled"]).to be false
        expect(site_data["mermaid_prebuild_config"]).to be_a(JekyllMermaidPrebuild::Configuration)
        expect(logger).to have_received(:info).with("MermaidPrebuild:", "Disabled in configuration")
      end
    end

    context "when mmdc is available" do
      let(:site_config) { {} }

      before do
        allow(JekyllMermaidPrebuild::MmdcWrapper).to receive_messages(
          check_status: :ok,
          version: "11.0.0"
        )
      end

      it "enables processing and installs generator/processor" do
        described_class.initialize_system(site)

        expect(site_data["mermaid_prebuild_enabled"]).to be true
        generator = site_data["mermaid_prebuild_generator"]
        processor = site_data["mermaid_prebuild_processor"]
        expect(generator).to be_a(JekyllMermaidPrebuild::Generator)
        expect(generator.config).to equal(site_data["mermaid_prebuild_config"])
        expect(processor).to be_a(JekyllMermaidPrebuild::Processor)
        expect(site_data["mermaid_prebuild_svgs"]).to eq({})

        # Prove the installed processor is wired to the installed generator/config.
        allow(generator).to receive_messages(
          generate: { "deadbeef" => File.join(@temp_dir, "deadbeef.svg") },
          build_svg_url: "/assets/svg/deadbeef.svg",
          build_figure_html: "<figure class=\"mermaid-diagram\"/>"
        )
        _result, count, svgs = processor.process_content("```mermaid\nA\n```\n", site)
        expect(count).to eq(1)
        expect(svgs).to eq("deadbeef" => File.join(@temp_dir, "deadbeef.svg"))
        expect(generator).to have_received(:generate)
      end

      it "logs initialization and output directory" do
        described_class.initialize_system(site)

        expect(logger).to have_received(:info).with(
          "MermaidPrebuild:",
          a_string_matching(/Initialized \(mmdc 11\.0\.0\)/)
        )
        expect(logger).to have_received(:info).with(
          "MermaidPrebuild:",
          "Output directory: assets/svg"
        )
      end

      it "uses unknown version when version is nil" do
        allow(JekyllMermaidPrebuild::MmdcWrapper).to receive(:version).and_return(nil)

        described_class.initialize_system(site)

        expect(logger).to have_received(:info).with(
          "MermaidPrebuild:",
          a_string_matching(/unknown version/)
        )
      end
    end

    context "when mmdc is not found" do
      let(:site_config) { {} }

      before do
        allow(JekyllMermaidPrebuild::MmdcWrapper).to receive(:check_status).and_return(:not_found)
      end

      it "disables and warns with install guidance" do
        described_class.initialize_system(site)

        expect(site_data["mermaid_prebuild_enabled"]).to be false
        expect(logger).to have_received(:warn).with(
          "MermaidPrebuild:",
          a_string_matching(/mmdc not found/)
        )
        expect(logger).to have_received(:warn).with(
          "MermaidPrebuild:",
          a_string_matching(%r{npm install -g @mermaid-js/mermaid-cli})
        )
      end
    end

    context "when Puppeteer fails" do
      let(:site_config) { {} }

      before do
        allow(JekyllMermaidPrebuild::MmdcWrapper).to receive(:check_status).and_return(:puppeteer_error)
      end

      it "disables and logs puppeteer error guidance" do
        described_class.initialize_system(site)

        expect(site_data["mermaid_prebuild_enabled"]).to be false
        expect(logger).to have_received(:error).with(
          "MermaidPrebuild:",
          a_string_matching(/Puppeteer cannot launch headless Chrome/)
        )
        expect(logger).to have_received(:error).with(
          "MermaidPrebuild:",
          a_string_matching(%r{pptr\.dev/troubleshooting})
        )
      end
    end

    context "when mmdc status is unknown" do
      let(:site_config) { {} }

      before do
        allow(JekyllMermaidPrebuild::MmdcWrapper).to receive(:check_status).and_return(:unknown_error)
      end

      it "disables and warns about unknown error" do
        described_class.initialize_system(site)

        expect(site_data["mermaid_prebuild_enabled"]).to be false
        expect(logger).to have_received(:warn).with(
          "MermaidPrebuild:",
          a_string_matching(/unknown error/)
        )
      end
    end
  end

  describe ".process_site" do
    let(:site_data) do
      {
        "mermaid_prebuild_enabled" => true,
        "mermaid_prebuild_processor" => processor,
        "mermaid_prebuild_svgs" => {}
      }
    end
    let(:processor) { instance_double(JekyllMermaidPrebuild::Processor) }
    let(:document) do
      instance_double(
        Jekyll::Document,
        content: "```mermaid\ngraph TD\nA-->B\n```",
        relative_path: "_posts/diagram.md"
      )
    end
    let(:page) do
      instance_double(
        Jekyll::Page,
        content: "```mermaid\ngraph TD\nC-->D\n```",
        relative_path: "about.md"
      )
    end
    let(:site) do
      instance_double(
        Jekyll::Site,
        data: site_data,
        documents: [document],
        pages: [page]
      )
    end

    before do
      allow(document).to receive(:content=)
      allow(page).to receive(:content=)
      allow(processor).to receive(:process_content)
    end

    it "skips when plugin is disabled" do
      site_data["mermaid_prebuild_enabled"] = false

      described_class.process_site(site)

      expect(processor).not_to have_received(:process_content)
    end

    it "processes documents and pages, merging svgs" do
      expect(processor).to receive(:process_content)
        .with(document.content, site)
        .and_return(["<figure>doc</figure>", 1, { "aaa11111" => "/cache/a.svg" }])
      expect(processor).to receive(:process_content)
        .with(page.content, site)
        .and_return(["<figure>page</figure>", 1, { "bbb22222" => "/cache/b.svg" }])

      described_class.process_site(site)

      expect(document).to have_received(:content=).with("<figure>doc</figure>")
      expect(page).to have_received(:content=).with("<figure>page</figure>")
      expect(site_data["mermaid_prebuild_svgs"]).to include("aaa11111", "bbb22222")
    end

    it "logs per-file and total conversion counts" do
      allow(processor).to receive(:process_content)
        .with(document.content, site)
        .and_return(["<figure>doc</figure>", 1, { "aaa11111" => "/cache/a.svg" }])
      allow(processor).to receive(:process_content)
        .with(page.content, site)
        .and_return(["<figure>page</figure>", 1, { "bbb22222" => "/cache/b.svg" }])

      described_class.process_site(site)

      expect(logger).to have_received(:info).with(
        "MermaidPrebuild:",
        a_string_matching(%r{Converted 1 diagram\(s\) in _posts/diagram\.md})
      )
      expect(logger).to have_received(:info).with(
        "MermaidPrebuild:",
        a_string_matching(/Converted 1 diagram\(s\) in about\.md/)
      )
      expect(logger).to have_received(:info).with(
        "MermaidPrebuild:",
        "Total: 2 diagram(s) converted"
      )
    end

    it "skips documents and pages without content" do
      empty_doc = instance_double(Jekyll::Document, content: nil, relative_path: "empty.md")
      empty_page = instance_double(Jekyll::Page, content: nil, relative_path: "empty-page.md")
      allow(site).to receive_messages(documents: [empty_doc], pages: [empty_page])

      described_class.process_site(site)

      expect(processor).not_to have_received(:process_content)
    end

    it "does not rewrite content when conversion count is zero" do
      allow(processor).to receive(:process_content).and_return(["same", 0, {}])

      described_class.process_site(site)

      expect(document).not_to have_received(:content=)
      expect(page).not_to have_received(:content=)
      expect(logger).not_to have_received(:info).with("MermaidPrebuild:", a_string_matching(/Total:/))
    end

    it "continues to later documents after skipping a nil-content document" do
      empty_doc = instance_double(Jekyll::Document, content: nil, relative_path: "empty.md")
      allow(site).to receive_messages(documents: [empty_doc, document], pages: [])
      expect(processor).to receive(:process_content).with(document.content, site)
                                                    .and_return(["<figure>doc</figure>", 1,
                                                                 { "aaa11111" => "/cache/a.svg" }])

      described_class.process_site(site)

      expect(document).to have_received(:content=).with("<figure>doc</figure>")
    end

    it "continues to later pages after skipping a nil-content page" do
      empty_page = instance_double(Jekyll::Page, content: nil, relative_path: "empty-page.md")
      allow(site).to receive_messages(documents: [], pages: [empty_page, page])
      expect(processor).to receive(:process_content).with(page.content, site)
                                                    .and_return(["<figure>page</figure>", 1,
                                                                 { "bbb22222" => "/cache/b.svg" }])

      described_class.process_site(site)

      expect(page).to have_received(:content=).with("<figure>page</figure>")
    end

    it "logs document processing errors without raising" do
      error = Class.new(StandardError) do
        def message = "boom"
        def to_s = "not-the-message"
      end.new

      allow(processor).to receive(:process_content).and_raise(error)
      allow(site).to receive_messages(documents: [document], pages: [])

      expect { described_class.process_site(site) }.not_to raise_error
      expect(logger).to have_received(:error).with(
        "MermaidPrebuild:",
        "Error processing _posts/diagram.md: boom"
      )
    end

    it "logs page processing errors without raising" do
      error = Class.new(StandardError) do
        def message = "page-boom"
        def to_s = "not-the-page-message"
      end.new

      allow(processor).to receive(:process_content).and_raise(error)
      allow(site).to receive_messages(documents: [], pages: [page])

      expect { described_class.process_site(site) }.not_to raise_error
      expect(logger).to have_received(:error).with(
        "MermaidPrebuild:",
        "Error processing page: page-boom"
      )
    end

    it "treats a missing enabled flag as disabled without raising" do
      site_data.delete("mermaid_prebuild_enabled")

      expect { described_class.process_site(site) }.not_to raise_error
      expect(processor).not_to have_received(:process_content)
    end

    it "logs NoMethodError when processor key is missing (Hash#[] returns nil)" do
      site_data.delete("mermaid_prebuild_processor")
      allow(site).to receive_messages(documents: [document], pages: [])

      described_class.process_site(site)

      expect(logger).to have_received(:error).with(
        "MermaidPrebuild:",
        a_string_matching(%r{Error processing _posts/diagram\.md:.*nil})
      )
    end

    it "logs NoMethodError when svgs key is missing during document merge (Hash#[] returns nil)" do
      site_data.delete("mermaid_prebuild_svgs")
      allow(site).to receive_messages(documents: [document], pages: [])
      allow(processor).to receive(:process_content)
        .and_return(["<figure>doc</figure>", 1, { "aaa11111" => "/cache/a.svg" }])

      described_class.process_site(site)

      expect(logger).to have_received(:error).with(
        "MermaidPrebuild:",
        a_string_matching(%r{Error processing _posts/diagram\.md:.*nil})
      )
    end

    it "logs NoMethodError when svgs key is missing during page merge (Hash#[] returns nil)" do
      site_data.delete("mermaid_prebuild_svgs")
      allow(site).to receive_messages(documents: [], pages: [page])
      allow(processor).to receive(:process_content)
        .and_return(["<figure>page</figure>", 1, { "bbb22222" => "/cache/b.svg" }])

      described_class.process_site(site)

      expect(logger).to have_received(:error).with(
        "MermaidPrebuild:",
        a_string_matching(/Error processing page:.*nil/)
      )
    end
  end

  describe ".copy_generated_svgs" do
    let(:config) do
      instance_double(JekyllMermaidPrebuild::Configuration, output_dir: "assets/svg", cache_dir: "/cache")
    end
    let(:site_data) do
      {
        "mermaid_prebuild_enabled" => true,
        "mermaid_prebuild_config" => config,
        "mermaid_prebuild_svgs" => { "abc12345" => File.join(@temp_dir, "abc12345.svg") }
      }
    end
    let(:site) do
      instance_double(Jekyll::Site, data: site_data, dest: File.join(@temp_dir, "_site"))
    end

    before do
      File.write(site_data["mermaid_prebuild_svgs"]["abc12345"], "<svg/>")
    end

    it "skips when disabled" do
      site_data["mermaid_prebuild_enabled"] = false

      described_class.copy_generated_svgs(site)

      expect(Dir.exist?(File.join(@temp_dir, "_site"))).to be false
    end

    it "treats a missing enabled flag as disabled without raising" do
      site_data.delete("mermaid_prebuild_enabled")

      expect { described_class.copy_generated_svgs(site) }.not_to raise_error
      expect(Dir.exist?(File.join(@temp_dir, "_site"))).to be false
    end

    it "copies svgs via copy_svgs_to_site when enabled" do
      described_class.copy_generated_svgs(site)

      dest_path = File.join(@temp_dir, "_site/assets/svg/abc12345.svg")
      expect(File.exist?(dest_path)).to be true
      expect(File.read(dest_path)).to eq("<svg/>")
    end

    it "does not raise when config and svgs keys are absent" do
      site_data.delete("mermaid_prebuild_config")
      site_data.delete("mermaid_prebuild_svgs")

      expect { described_class.copy_generated_svgs(site) }.not_to raise_error
    end
  end

  describe "Jekyll hook registration" do
    let(:site_data) { {} }
    let(:site) do
      instance_double(
        Jekyll::Site,
        config: {},
        data: site_data,
        source: @temp_dir,
        dest: File.join(@temp_dir, "_site"),
        documents: [],
        pages: []
      )
    end

    before do
      allow(JekyllMermaidPrebuild::MmdcWrapper).to receive_messages(
        check_status: :ok,
        version: "11.0.0"
      )
    end

    it "runs initialize_system on site post_read" do
      Jekyll::Hooks.trigger :site, :post_read, site

      expect(site_data["mermaid_prebuild_enabled"]).to be true
      expect(site_data["mermaid_prebuild_processor"]).to be_a(JekyllMermaidPrebuild::Processor)
    end

    it "runs process_site on site pre_render" do
      site_data["mermaid_prebuild_enabled"] = true
      processor = instance_double(JekyllMermaidPrebuild::Processor)
      site_data["mermaid_prebuild_processor"] = processor
      site_data["mermaid_prebuild_svgs"] = {}
      allow(processor).to receive(:process_content)

      expect(described_class).to receive(:process_site).and_call_original

      Jekyll::Hooks.trigger :site, :pre_render, site

      expect(processor).not_to have_received(:process_content)
    end

    it "runs copy_generated_svgs on site post_write" do
      cache = File.join(@temp_dir, "c.svg")
      File.write(cache, "<svg/>")
      config = instance_double(JekyllMermaidPrebuild::Configuration, output_dir: "assets/svg")
      site_data["mermaid_prebuild_enabled"] = true
      site_data["mermaid_prebuild_config"] = config
      site_data["mermaid_prebuild_svgs"] = { "c" => cache }

      Jekyll::Hooks.trigger :site, :post_write, site

      expect(File.exist?(File.join(@temp_dir, "_site/assets/svg/c.svg"))).to be true
    end
  end
end
