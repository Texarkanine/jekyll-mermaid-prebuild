# frozen_string_literal: true

require "spec_helper"

RSpec.describe JekyllMermaidPrebuild::MmdcWrapper do
  before do
    # Reset all cached values before each test
    described_class.reset_cache!
  end

  describe ".available?" do
    context "when mmdc is in PATH" do
      before do
        allow(described_class).to receive(:command_exists?).with("mmdc").and_return(true)
      end

      it "returns true" do
        expect(described_class.available?).to be true
      end
    end

    context "when mmdc is not in PATH" do
      before do
        allow(described_class).to receive(:command_exists?).with("mmdc").and_return(false)
      end

      it "returns false" do
        expect(described_class.available?).to be false
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
    context "when mmdc is not available" do
      before do
        allow(described_class).to receive(:command_exists?).with("mmdc").and_return(false)
      end

      it "returns :not_found" do
        expect(described_class.check_status).to eq(:not_found)
      end
    end

    context "when mmdc is available but Puppeteer fails" do
      before do
        allow(described_class).to receive(:command_exists?).with("mmdc").and_return(true)
        allow(described_class).to receive(:test_render).and_return(:puppeteer_error)
      end

      it "returns :puppeteer_error" do
        expect(described_class.check_status).to eq(:puppeteer_error)
      end
    end

    context "when mmdc works correctly" do
      before do
        allow(described_class).to receive(:command_exists?).with("mmdc").and_return(true)
        allow(described_class).to receive(:test_render).and_return(:ok)
      end

      it "returns :ok" do
        expect(described_class.check_status).to eq(:ok)
      end
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
