# frozen_string_literal: true

require "spec_helper"

RSpec.describe JekyllMermaidPrebuild::MmdcWrapper do
  before do
    # Reset all cached values before each test
    described_class.reset_cache!
  end

  describe ".available?" do
    around do |example|
      original_path = ENV.fetch("PATH", nil)
      example.run
      ENV["PATH"] = original_path
    end

    context "when mmdc is in PATH" do
      it "returns true" do
        Dir.mktmpdir do |dir|
          ENV["PATH"] = dir
          filename = Gem.win_platform? ? "mmdc.exe" : "mmdc"
          executable = File.join(dir, filename)
          File.write(executable, Gem.win_platform? ? "" : "#!/bin/sh\nexit 0")
          File.chmod(0o755, executable) unless Gem.win_platform?

          expect(described_class.available?).to be true
        end
      end

      it "caches the positive result across PATH changes until reset" do
        Dir.mktmpdir do |dir|
          ENV["PATH"] = dir
          filename = Gem.win_platform? ? "mmdc.exe" : "mmdc"
          executable = File.join(dir, filename)
          File.write(executable, Gem.win_platform? ? "" : "#!/bin/sh\nexit 0")
          File.chmod(0o755, executable) unless Gem.win_platform?

          expect(described_class.available?).to be true
          ENV["PATH"] = "/nonexistent"
          expect(described_class.available?).to be true
          described_class.reset_cache!
          expect(described_class.available?).to be false
        end
      end
    end

    context "when mmdc is not in PATH" do
      it "returns false" do
        ENV["PATH"] = "/nonexistent"
        expect(described_class.available?).to be false
      end

      it "caches the negative result" do
        ENV["PATH"] = "/nonexistent"
        expect(described_class.available?).to be false
        Dir.mktmpdir do |dir|
          ENV["PATH"] = dir
          filename = Gem.win_platform? ? "mmdc.exe" : "mmdc"
          executable = File.join(dir, filename)
          File.write(executable, Gem.win_platform? ? "" : "#!/bin/sh\nexit 0")
          File.chmod(0o755, executable) unless Gem.win_platform?

          expect(described_class.available?).to be false
        end
      end
    end
  end

  describe ".command_exists?" do
    around do |example|
      original_path = ENV.fetch("PATH", nil)
      example.run
      ENV["PATH"] = original_path
    end

    it "returns true when executable exists in PATH" do
      Dir.mktmpdir do |dir|
        ENV["PATH"] = dir
        filename = Gem.win_platform? ? "testcmd.exe" : "testcmd"
        executable = File.join(dir, filename)
        File.write(executable, Gem.win_platform? ? "" : "#!/bin/sh\nexit 0")
        File.chmod(0o755, executable) unless Gem.win_platform?

        expect(described_class.command_exists?("testcmd")).to be true
      end
    end

    it "returns false when executable does not exist" do
      ENV["PATH"] = "/nonexistent"
      expect(described_class.command_exists?("nonexistent_cmd")).to be false
    end

    it "returns false for blank command names" do
      expect(described_class.command_exists?("")).to be false
      expect(described_class.command_exists?(nil)).to be false
    end

    it "requires a regular file, not only an executable directory entry" do
      Dir.mktmpdir do |dir|
        ENV["PATH"] = dir
        expect(described_class.command_exists?("")).to be false
      end
    end
  end

  describe ".version" do
    context "when mmdc returns version" do
      before do
        allow(Open3).to receive(:capture2e)
          .with("mmdc", "--version")
          .and_return(["11.12.0\n", instance_double(Process::Status, success?: true)])
      end

      it "returns trimmed version string" do
        expect(described_class.version).to eq("11.12.0")
      end
    end

    context "when mmdc fails" do
      before do
        allow(Open3).to receive(:capture2e)
          .with("mmdc", "--version")
          .and_return(["", instance_double(Process::Status, success?: false)])
      end

      it "returns nil" do
        expect(described_class.version).to be_nil
      end
    end
  end

  describe ".check_status" do
    around do |example|
      original_path = ENV.fetch("PATH", nil)
      example.run
      ENV["PATH"] = original_path
    end

    context "when mmdc is not available" do
      it "returns :not_found" do
        ENV["PATH"] = "/nonexistent"
        expect(described_class.check_status).to eq(:not_found)
      end
    end

    context "when mmdc is available but Puppeteer fails" do
      it "returns :puppeteer_error" do
        Dir.mktmpdir do |dir|
          ENV["PATH"] = dir
          filename = Gem.win_platform? ? "mmdc.exe" : "mmdc"
          executable = File.join(dir, filename)
          File.write(executable, Gem.win_platform? ? "" : "#!/bin/sh\nexit 0")
          File.chmod(0o755, executable) unless Gem.win_platform?

          bad = instance_double(Process::Status, success?: false)
          allow(Open3).to receive(:capture3).and_return(["", "Failed to launch the browser process", bad])

          expect(described_class.check_status).to eq(:puppeteer_error)
        end
      end
    end

    context "when mmdc works correctly" do
      it "returns :ok" do
        Dir.mktmpdir do |dir|
          ENV["PATH"] = dir
          filename = Gem.win_platform? ? "mmdc.exe" : "mmdc"
          executable = File.join(dir, filename)
          File.write(executable, Gem.win_platform? ? "" : "#!/bin/sh\nexit 0")
          File.chmod(0o755, executable) unless Gem.win_platform?

          ok = instance_double(Process::Status, success?: true)
          allow(Open3).to receive(:capture3).and_return(["", "", ok])

          expect(described_class.check_status).to eq(:ok)
        end
      end
    end
  end

  describe ".test_render" do
    let(:status_ok) { instance_double(Process::Status, success?: true) }
    let(:status_bad) { instance_double(Process::Status, success?: false) }

    it "invokes mmdc with tempfile paths ending in .mmd and .svg" do
      expect(Open3).to receive(:capture3).with(
        "mmdc",
        "-i", a_string_matching(/\.mmd\z/),
        "-o", a_string_matching(/\.svg\z/),
        "-e", "svg"
      ).and_return(["", "", status_ok])

      expect(described_class.test_render).to eq(:ok)
    end

    it "writes the probe diagram into the input tempfile" do
      written = nil
      allow(Open3).to receive(:capture3) do |*args|
        input_path = args[args.index("-i") + 1]
        written = File.read(input_path)
        ["", "", status_ok]
      end

      described_class.test_render
      expect(written).to eq("graph TD\nA-->B")
    end

    it "returns :puppeteer_error when stderr mentions libgbm" do
      allow(Open3).to receive(:capture3).and_return(["", "missing libgbm", status_bad])
      expect(described_class.test_render).to eq(:puppeteer_error)
    end

    it "returns :puppeteer_error when stderr mentions browser process" do
      allow(Open3).to receive(:capture3).and_return(["", "Failed to launch the browser process", status_bad])
      expect(described_class.test_render).to eq(:puppeteer_error)
    end

    it "returns :unknown_error for other failures" do
      allow(Open3).to receive(:capture3).and_return(["", "other failure", status_bad])
      expect(described_class.test_render).to eq(:unknown_error)
    end
  end

  describe ".render" do
    let(:status_ok) { instance_double(Process::Status, success?: true) }

    it "invokes mmdc without -t for default theme" do
      expect(Open3).to receive(:capture3).with(
        "mmdc", "-i", a_string_matching(/\.mmd\z/), "-o", "/tmp/out.svg", "-e", "svg"
      ).and_return(["", "", status_ok])

      described_class.render("graph TD\nA-->B", "/tmp/out.svg", theme: :default)
    end

    it "appends -t dark when theme is :dark" do
      expect(Open3).to receive(:capture3).with(
        "mmdc", "-i", a_string_matching(/\.mmd\z/), "-o", "/tmp/out.svg", "-e", "svg", "-t", "dark"
      ).and_return(["", "", status_ok])

      described_class.render("graph TD\nA-->B", "/tmp/out.svg", theme: :dark)
    end

    it "returns false when mmdc fails" do
      bad = instance_double(Process::Status, success?: false)
      allow(Open3).to receive(:capture3).and_return(["", "err", bad])

      expect(described_class.render("x", "/tmp/nope.svg")).to be false
    end

    it "raises ArgumentError for an unsupported theme" do
      expect do
        described_class.render("graph TD\nA-->B", "/tmp/out.svg", theme: :forest)
      end.to raise_error(ArgumentError, /unsupported mmdc theme/)
    end
  end

  describe ".mermaid_fence_pattern" do
    let(:pattern) { described_class.mermaid_fence_pattern }

    it "matches backtick fenced mermaid blocks" do
      content = "```mermaid\ngraph TD\nA-->B\n```"
      match = content.match(pattern)

      expect(match).not_to be_nil
      expect(match[2]).to eq("graph TD\nA-->B\n")
    end

    it "matches tilde fenced mermaid blocks" do
      content = "~~~mermaid\nflowchart LR\nX-->Y\n~~~"
      match = content.match(pattern)

      expect(match).not_to be_nil
      expect(match[2]).to eq("flowchart LR\nX-->Y\n")
    end

    it "matches 4+ fence characters" do
      content = "````mermaid\ngraph TD\nC-->D\n````"
      match = content.match(pattern)

      expect(match).not_to be_nil
      expect(match[2]).to eq("graph TD\nC-->D\n")
    end

    it "does not match mismatched fence types" do
      content = "```mermaid\ngraph TD\nA-->B\n~~~"
      match = content.match(pattern)

      expect(match).to be_nil
    end

    it "does not match non-mermaid code blocks" do
      content = "```ruby\nputs 'hello'\n```"
      match = content.match(pattern)

      expect(match).to be_nil
    end

    it "captures the fence characters" do
      content = "```mermaid\ngraph TD\n```"
      match = content.match(pattern)

      expect(match[1]).to eq("```")
    end
  end
end
