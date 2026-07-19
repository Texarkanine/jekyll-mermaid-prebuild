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

    it "returns nil for nil source" do
      expect(described_class.detect_diagram_type(nil)).to be_nil
    end

    it "returns nil when source has only comments" do
      source = <<~MERMAID
        %% setup
        %% teardown
      MERMAID
      expect(described_class.detect_diagram_type(source)).to be_nil
    end

    it "returns nil when source has only frontmatter" do
      source = <<~MERMAID
        ---
        title: Orphan
        ---
      MERMAID
      expect(described_class.detect_diagram_type(source)).to be_nil
    end

    it "detects diagram type on a line with leading whitespace" do
      source = "  flowchart LR\n  A --> B"
      expect(described_class.detect_diagram_type(source)).to eq("flowchart")
    end

    it "detects diagram type after leading whitespace on the whole source" do
      source = "  \nflowchart LR\n  A --> B"
      expect(described_class.detect_diagram_type(source)).to eq("flowchart")
    end

    it "detects other mermaid diagram keywords verbatim" do
      expect(described_class.detect_diagram_type("classDiagram\n  Animal <|-- Duck")).to eq("classDiagram")
      expect(described_class.detect_diagram_type("gantt\n  title A Gantt Chart")).to eq("gantt")
    end

    it "uses only the first whitespace-delimited token on the diagram line" do
      source = "flowchart   LR   extra\n  A --> B"
      expect(described_class.detect_diagram_type(source)).to eq("flowchart")
    end

    it "detects graph without a direction suffix" do
      expect(described_class.detect_diagram_type("graph\n  A --> B")).to eq("flowchart")
    end
  end

  describe ".pad_label_content" do
    it "returns content unchanged when there is no emoji" do
      expect(described_class.pad_label_content("plain text")).to eq("plain text")
    end

    it "returns empty content unchanged" do
      expect(described_class.pad_label_content("")).to eq("")
    end

    it "appends two nbsp per emoji on a single line" do
      expect(described_class.pad_label_content("🔧")).to eq("🔧#{nbsp}#{nbsp}")
    end

    it "appends four nbsp when the longest line contains two emoji" do
      expect(described_class.pad_label_content("🔧🛠")).to eq("🔧🛠#{nbsp * 4}")
    end

    it "uses visual length rather than character count when choosing the longest line" do
      long_ascii = "Z" * 50
      input = "🔧🔧🔧🔧🔧<br/>#{long_ascii}"
      expect(described_class.pad_label_content(input)).to eq(input)
    end

    it "pads only the emoji line after a br tag, not the br tag segment" do
      expect(described_class.pad_label_content("a<br/>🔧")).to eq("a<br/>🔧#{nbsp}#{nbsp}")
    end

    it "recognizes br tags case-insensitively" do
      expect(described_class.pad_label_content("🔧 extra<BR/>line")).to eq("🔧 extra#{nbsp}#{nbsp}<BR/>line")
    end

    it "recognizes br without a closing slash" do
      expect(described_class.pad_label_content("🔧 extra<br>line")).to eq("🔧 extra#{nbsp}#{nbsp}<br>line")
    end

    it "returns the original string object when no padding is applied" do
      content = "plain"
      expect(described_class.pad_label_content(content)).to equal(content)
    end

    it "returns a new padded string rather than nil when emoji padding applies" do
      padded = described_class.pad_label_content("🔧")
      expect(padded).to be_a(String)
      expect(padded).not_to be_nil
    end
  end

  describe ".compensate_flowchart_labels" do
    it "does not mutate the original source string" do
      source = "flowchart LR\n  A[\"🔧\"] --> B"
      result = described_class.compensate_flowchart_labels(source)
      expect(result).to include("[\"🔧#{nbsp}#{nbsp}\"]")
      expect(source).not_to include(nbsp)
    end

    it "compensates double-quoted node labels" do
      source = "flowchart LR\n  A[\"🔧\"] --> B"
      expect(described_class.compensate_flowchart_labels(source)).to include("[\"🔧#{nbsp}#{nbsp}\"]")
    end

    it "compensates single-quoted node labels" do
      source = "flowchart LR\n  A['🔧'] --> B"
      expect(described_class.compensate_flowchart_labels(source)).to include("['🔧#{nbsp}#{nbsp}']")
    end

    it "compensates parenthesized node labels" do
      source = "flowchart LR\n  A(\"🔧\") --> B"
      expect(described_class.compensate_flowchart_labels(source)).to include("(\"🔧#{nbsp}#{nbsp}\")")
    end

    it "compensates brace-wrapped node labels" do
      source = "flowchart LR\n  A{\"🔧\"} --> B"
      expect(described_class.compensate_flowchart_labels(source)).to include("{\"🔧#{nbsp}#{nbsp}\"}")
    end

    it "compensates trapezoid node labels" do
      source = "flowchart LR\n  A[/\"🔧\"/] --> B"
      expect(described_class.compensate_flowchart_labels(source)).to include("[/\"🔧#{nbsp}#{nbsp}\"/]")
    end

    it "compensates multiline quoted labels" do
      source = "flowchart LR\n  A[\"line1\nline2 🔧\"] --> B"
      expect(described_class.compensate_flowchart_labels(source)).to include("line2 🔧#{nbsp}#{nbsp}")
    end

    it "compensates empty quoted labels without error" do
      source = "flowchart LR\n  A[\"\"] --> B"
      expect(described_class.compensate_flowchart_labels(source)).to eq(source)
    end

    it "preserves escaped quotes in trapezoid labels" do
      source = "flowchart LR\n  A[/\"say \\\"hi\\\" 🔧\"/] --> B"
      result = described_class.compensate_flowchart_labels(source)
      expect(result).to include('say \"hi\" 🔧')
      expect(result).to include(nbsp)
    end

    it "compensates every matching quoted label in the source" do
      source = "flowchart LR\n  A[\"🔧\"] --> B[\"🔧\"]"
      result = described_class.compensate_flowchart_labels(source)
      expect(result.scan("[\"🔧#{nbsp}#{nbsp}\"]").length).to eq(2)
    end

    it "compensates multiline single-quoted labels" do
      source = "flowchart LR\n  A['line1\nline2 🔧'] --> B"
      expect(described_class.compensate_flowchart_labels(source)).to include("line2 🔧#{nbsp}#{nbsp}")
    end

    it "compensates single-quoted labels longer than one character" do
      source = "flowchart LR\n  A['text🔧'] --> B"
      expect(described_class.compensate_flowchart_labels(source)).to include("['text🔧#{nbsp}#{nbsp}']")
    end

    it "compensates parenthesized labels longer than one character" do
      source = "flowchart LR\n  A(\"text🔧\") --> B"
      expect(described_class.compensate_flowchart_labels(source)).to include("(\"text🔧#{nbsp}#{nbsp}\")")
    end

    it "compensates multiline parenthesized labels" do
      source = "flowchart LR\n  A(\"line1\nline2 🔧\") --> B"
      expect(described_class.compensate_flowchart_labels(source)).to include("line2 🔧#{nbsp}#{nbsp}")
    end

    it "compensates brace labels longer than one character" do
      source = "flowchart LR\n  A{\"text🔧\"} --> B"
      expect(described_class.compensate_flowchart_labels(source)).to include("{\"text🔧#{nbsp}#{nbsp}\"}")
    end

    it "compensates multiline brace labels" do
      source = "flowchart LR\n  A{\"line1\nline2 🔧\"} --> B"
      expect(described_class.compensate_flowchart_labels(source)).to include("line2 🔧#{nbsp}#{nbsp}")
    end

    it "compensates trapezoid labels that contain only whitespace" do
      source = "flowchart LR\n  A[/\"  \"/] --> B"
      expect(described_class.compensate_flowchart_labels(source)).to eq(source)
    end

    it "compensates multiline trapezoid labels" do
      source = "flowchart LR\n  A[/\"line1\nline2 🔧\"/] --> B"
      expect(described_class.compensate_flowchart_labels(source)).to include("line2 🔧#{nbsp}#{nbsp}")
    end

    it "compensates every trapezoid label in the source" do
      source = "flowchart LR\n  A[/\"🔧\"/] --> B[/\"🔧\"/]"
      result = described_class.compensate_flowchart_labels(source)
      expect(result.scan("[/\"🔧#{nbsp}#{nbsp}\"/]").length).to eq(2)
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

    it "compensates when diagram_type is a distinct String object with the same value" do
      source = "flowchart LR\n  A[\"🔧\"] --> B"
      result = described_class.compensate(source, +"flowchart")
      expect(result).to include("[\"🔧#{nbsp}#{nbsp}\"]")
    end
  end
end
