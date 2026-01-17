# frozen_string_literal: true

require "spec_helper"

RSpec.describe JekyllMermaidPrebuild::Hooks do
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

        expect(File.exist?(File.join(dest_dir, "assets/svg/abc12345.svg"))).to be true
        expect(File.exist?(File.join(dest_dir, "assets/svg/def67890.svg"))).to be true
      end

      it "creates output directory if needed" do
        described_class.copy_svgs_to_site(site, config, svgs)

        expect(Dir.exist?(File.join(dest_dir, "assets/svg"))).to be true
      end
    end

    context "with empty SVGs hash" do
      it "does nothing" do
        expect { described_class.copy_svgs_to_site(site, config, {}) }.not_to raise_error
      end
    end

    context "with nil SVGs" do
      it "does nothing" do
        expect { described_class.copy_svgs_to_site(site, config, nil) }.not_to raise_error
      end
    end
  end

  describe ".log_puppeteer_error" do
    it "logs error messages without raising" do
      expect(Jekyll.logger).to receive(:error).at_least(:once)

      expect { described_class.log_puppeteer_error }.not_to raise_error
    end
  end
end
