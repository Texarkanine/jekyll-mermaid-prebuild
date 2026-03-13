# frozen_string_literal: true

require "spec_helper"

RSpec.describe JekyllMermaidPrebuild::EmojiCompensator do
  let(:nbsp) { "&nbsp;" }

  describe ".detect_diagram_type" do
    # D1: Bare flowchart LR on first line → flowchart
    it "detects flowchart from first line" do
      source = "flowchart LR\n  A --> B"
      expect(described_class.detect_diagram_type(source)).to eq("flowchart")
    end

    # D2: graph TD → flowchart (alias)
    it "detects graph as flowchart alias" do
      source = "graph TD\n  A --> B"
      expect(described_class.detect_diagram_type(source)).to eq("flowchart")
    end

    # D3: YAML frontmatter before diagram type
    it "detects type after YAML frontmatter" do
      source = <<~MERMAID
        ---
        title: My Chart
        ---
        flowchart LR
          A --> B
      MERMAID
      expect(described_class.detect_diagram_type(source)).to eq("flowchart")
    end

    # D4: %% comment lines before diagram type
    it "detects type after comment lines" do
      source = <<~MERMAID
        %% This is a comment
        %% Another comment
        flowchart LR
          A --> B
      MERMAID
      expect(described_class.detect_diagram_type(source)).to eq("flowchart")
    end

    # D5: Frontmatter + comments + blank before diagram type
    it "detects type after frontmatter, comments, and blank lines" do
      source = <<~MERMAID
        ---
        title: X
        ---

        %% comment

        flowchart LR
          A --> B
      MERMAID
      expect(described_class.detect_diagram_type(source)).to eq("flowchart")
    end

    # D6: sequenceDiagram → not flowchart
    it "detects sequenceDiagram as different type" do
      source = "sequenceDiagram\n  A->>B: msg"
      expect(described_class.detect_diagram_type(source)).not_to eq("flowchart")
    end

    # D7: Empty/whitespace-only → nil
    it "returns nil for empty or whitespace-only source" do
      expect(described_class.detect_diagram_type("")).to be_nil
      expect(described_class.detect_diagram_type("   \n  ")).to be_nil
    end
  end

  describe ".compensate" do
    # E1: Single emoji in label → 2 nbsp at end of label
    it "appends two nbsp per emoji in flowchart label" do
      source = "flowchart LR\n  A[\"🔧 Code\"] --> B"
      result = described_class.compensate(source, "flowchart")
      expect(result).to include("[\"🔧 Code#{nbsp}#{nbsp}\"]")
    end

    # E2: Multiple emoji → 2 nbsp per emoji
    it "appends two nbsp per emoji when label has multiple emoji" do
      source = "flowchart LR\n  A[\"🔧 🛠\"] --> B"
      result = described_class.compensate(source, "flowchart")
      expect(result).to include("[\"🔧 🛠#{nbsp * 4}\"]")
    end

    # E3: No emoji → unchanged
    it "returns source unchanged when label has no emoji" do
      source = "flowchart LR\n  A[Code] --> B"
      result = described_class.compensate(source, "flowchart")
      expect(result).to eq(source)
    end

    # E4: Existing &nbsp; entities → adds compensation on top
    it "adds compensation on top of existing nbsp in label" do
      source = "flowchart LR\n  A[\"🔧 Code#{nbsp}#{nbsp}\"] --> B"
      result = described_class.compensate(source, "flowchart")
      expect(result).to include("[\"🔧 Code#{nbsp}#{nbsp}#{nbsp}#{nbsp}\"]")
    end

    # E5: Multi-line label where emoji line is longest → padding on that line only
    it "pads the emoji line when it is the longest line in a multi-line label" do
      source = "flowchart LR\n  A[\"🔧 Line1<br/>Line2\"] --> B"
      result = described_class.compensate(source, "flowchart")
      expect(result).to include("[\"🔧 Line1#{nbsp}#{nbsp}<br/>Line2\"]")
    end

    # E11: Multi-line label where non-emoji line is longest → no padding at all
    it "skips padding when the longest line has no emoji" do
      source = "flowchart LR\n  A[\"🔧 Hi<br/>This is a much longer line\"] --> B"
      result = described_class.compensate(source, "flowchart")
      expect(result).to eq(source)
    end

    # E12: Emoji line is longest by visual length (emoji counts as 2) but not by char count
    it "uses visual length (emoji counts as 2) to determine longest line" do
      source = "flowchart LR\n  A[\"🔧🔧 A<br/>ABCDE\"] --> B"
      result = described_class.compensate(source, "flowchart")
      expect(result).to include("[\"🔧🔧 A#{nbsp * 4}<br/>ABCDE\"]")
    end

    # E6: Multiple nodes, some with emoji, some without
    it "pads only nodes whose labels contain emoji" do
      source = <<~MERMAID
        flowchart LR
          A["🔧"] --> B[No emoji]
          B --> C["✅ Done"]
      MERMAID
      result = described_class.compensate(source, "flowchart")
      expect(result).to include("[\"🔧#{nbsp}#{nbsp}\"]")
      expect(result).to include("[No emoji]")
      expect(result).to include("[\"✅ Done#{nbsp}#{nbsp}\"]")
    end

    # E7: Not a compensated diagram type → unchanged
    it "returns source unchanged when diagram type is not flowchart" do
      source = "sequenceDiagram\n  participant A[\"🔧\"]"
      result = described_class.compensate(source, "sequenceDiagram")
      expect(result).to eq(source)
    end

    # E8: HTML entities in label preserved
    it "preserves HTML entities in labels" do
      source = "flowchart LR\n  A[\"🔧 &amp; code\"] --> B"
      result = described_class.compensate(source, "flowchart")
      expect(result).to include("&amp;")
      expect(result).to include("[\"🔧 &amp; code#{nbsp}#{nbsp}\"]")
    end

    # E9: Various flowchart node shapes
    it "compensates all common flowchart node shapes" do
      base = "flowchart LR\n"
      shapes = [
        'A["🔧"]',
        'B("🔧")',
        'C{"🔧"}',
        'D(("🔧"))'
      ]
      shapes.each do |shape|
        source = base + "  #{shape} --> X\n"
        result = described_class.compensate(source, "flowchart")
        expect(result).to include(nbsp), "Expected nbsp padding for shape #{shape.inspect}"
      end
    end

    # E10: graph LR keyword works (alias)
    it "compensates when diagram uses graph keyword" do
      source = "graph LR\n  A[\"🔧\"] --> B"
      result = described_class.compensate(source, "flowchart")
      expect(result).to include("[\"🔧#{nbsp}#{nbsp}\"]")
    end
  end
end
