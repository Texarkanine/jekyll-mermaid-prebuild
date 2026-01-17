# frozen_string_literal: true

require "open3"
require "tempfile"

module JekyllMermaidPrebuild
  # Wrapper for mmdc (mermaid CLI) commands
  module MmdcWrapper
    module_function

    # Check if mmdc is available in PATH
    #
    # @return [Boolean] true if mmdc is available
    def available?
      return @available if defined?(@available)

      @available = command_exists?("mmdc")
    end

    # Check if a command exists in PATH (cross-platform)
    #
    # @param cmd [String] command name
    # @return [Boolean] true if command found
    def command_exists?(cmd)
      cmd_name = Gem.win_platform? ? "#{cmd}.exe" : cmd
      path_dirs = ENV.fetch("PATH", "").split(File::PATH_SEPARATOR)

      path_dirs.any? do |dir|
        executable = File.join(dir, cmd_name)
        File.executable?(executable)
      end
    end

    # Get mmdc version
    #
    # @return [String, nil] version string or nil
    def version
      return @version if defined?(@version)

      output, status = Open3.capture2e("mmdc", "--version")
      @version = status.success? ? output.strip : nil
    rescue StandardError
      @version = nil
    end

    # Check mmdc status (availability and Puppeteer)
    #
    # @return [Symbol] :ok, :not_found, :puppeteer_error, or :unknown_error
    def check_status
      return @check_status if defined?(@check_status)

      unless available?
        @check_status = :not_found
        return @check_status
      end

      @check_status = test_render
    end

    # Reset cached status (useful for testing)
    def reset_cache!
      remove_instance_variable(:@available) if defined?(@available)
      remove_instance_variable(:@version) if defined?(@version)
      remove_instance_variable(:@check_status) if defined?(@check_status)
    end

    # Test mmdc with a minimal diagram to verify Puppeteer works
    #
    # @return [Symbol] :ok, :puppeteer_error, or :unknown_error
    def test_render
      input = Tempfile.new(["test", ".mmd"])
      output = Tempfile.new(["test", ".svg"])

      begin
        input.write("graph TD\nA-->B")
        input.close
        output.close # Close before mmdc writes (Windows file locking)

        _stdout, stderr, status = Open3.capture3("mmdc", "-i", input.path, "-o", output.path, "-e", "svg")

        if status.success?
          :ok
        elsif stderr.include?("libgbm") || stderr.include?("browser process")
          :puppeteer_error
        else
          :unknown_error
        end
      ensure
        input.close! rescue nil # rubocop:disable Style/RescueModifier
        output.close! rescue nil # rubocop:disable Style/RescueModifier
      end
    end

    # Render mermaid source to SVG file
    #
    # @param mermaid_source [String] mermaid diagram definition
    # @param output_path [String] path to write SVG file
    # @return [Boolean] true if successful
    def render(mermaid_source, output_path)
      input_file = Tempfile.new(["mermaid", ".mmd"])

      begin
        input_file.write(mermaid_source)
        input_file.close

        cmd = ["mmdc", "-i", input_file.path, "-o", output_path, "-e", "svg"]
        _stdout, _stderr, status = Open3.capture3(*cmd)

        status.success?
      ensure
        input_file.unlink
      end
    end

    # Build regex pattern for mermaid fenced code blocks
    # Supports both backtick (```) and tilde (~~~) fences with 3+ characters
    #
    # @return [Regexp] pattern matching mermaid code blocks
    def mermaid_fence_pattern
      /
        ^(`{3,}|~{3,})mermaid\s*\n  # Opening fence: 3+ backticks or tildes, then 'mermaid'
        (.*?)                        # Content (captured, non-greedy)
        ^\1\s*$                      # Closing fence: must match opening fence type and length
      /mx
    end
  end
end
