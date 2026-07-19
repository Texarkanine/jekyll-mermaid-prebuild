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

    it "opens mermaid metadata from a fence opener line" do
      state = empty_state

      processor.process_line("```mermaid\n", state)

      expect(state[:current_mermaid]).to include(fence_type: "`", fence_length: 3, start: 0)
    end

    it "closes mermaid block on matching fence via process_line" do
      state = {
        blocks: [],
        fence_stack: [],
        current_mermaid: { start: 0, fence_type: "`", fence_length: 3, content_lines: ["A\n"] },
        position: 3
      }

      processor.process_line("```\n", state)

      expect(state[:blocks].length).to eq(1)
      expect(state[:blocks].first[:content]).to eq("A\n")
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
      expect(state[:position]).to eq("plain text\n".length)
      expect(state[:blocks]).to be_empty
      expect(state[:fence_stack]).to be_empty
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

    it "closes an open mermaid block on a matching fence" do
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

    it "pops nested fence stack on matching close via handle_fence_line" do
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
      expect(state[:fence_stack]).to eq([[3, "`"]])
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
