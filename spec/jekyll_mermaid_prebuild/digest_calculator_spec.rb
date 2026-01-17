# frozen_string_literal: true

require "spec_helper"

RSpec.describe JekyllMermaidPrebuild::DigestCalculator do
  describe ".content_digest" do
    context "with mermaid content" do
      it "computes 8-character MD5 digest" do
        content = "graph TD\nA-->B"
        digest = described_class.content_digest(content)

        expect(digest).to be_a(String)
        expect(digest.length).to eq(8)
        expect(digest).to match(/^[0-9a-f]{8}$/)
      end
    end

    context "with same content" do
      it "returns consistent digest" do
        content = "flowchart LR\nX-->Y"
        digest1 = described_class.content_digest(content)
        digest2 = described_class.content_digest(content)

        expect(digest1).to eq(digest2)
      end
    end

    context "with different content" do
      it "produces different digests" do
        digest1 = described_class.content_digest("graph TD\nA-->B")
        digest2 = described_class.content_digest("graph TD\nC-->D")

        expect(digest1).not_to eq(digest2)
      end
    end

    context "with empty string" do
      it "returns a valid digest" do
        digest = described_class.content_digest("")

        expect(digest).to be_a(String)
        expect(digest.length).to eq(8)
      end
    end

    context "with whitespace variations" do
      it "produces different digests for different whitespace" do
        digest1 = described_class.content_digest("graph TD\nA-->B")
        digest2 = described_class.content_digest("graph TD\n  A-->B")

        expect(digest1).not_to eq(digest2)
      end
    end
  end
end
