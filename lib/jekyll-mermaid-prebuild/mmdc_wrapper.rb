# frozen_string_literal: true

require "open3"
require "tempfile"

module JekyllMermaidPrebuild
  # Wrapper for mmdc (mermaid CLI) commands
  module MmdcWrapper
    # Check if mmdc is available in PATH
    #
    # @return [Boolean] true if mmdc is available
    MMDC_COMMAND = "mmdc"

    def self.available?
      return @available if instance_variable_defined?(:@available)

      @available = command_exists?(MMDC_COMMAND)
    end

    # Check if a command exists in PATH (cross-platform)
    #
    # @param cmd [String] command name
    # @return [Boolean] true if command found
    def self.command_exists?(cmd)
      return false if cmd.nil? || cmd.empty?

      cmd_name = Gem.win_platform? ? "#{cmd}.exe" : cmd
      path_dirs = ENV.fetch("PATH", "").split(File::PATH_SEPARATOR)

      path_dirs.any? do |dir|
        executable = File.join(dir, cmd_name)
        File.file?(executable) && File.executable?(executable)
      end
    end

    # Get mmdc version
    #
    # @return [String, nil] version string or nil
    def self.version
      return @version if instance_variable_defined?(:@version)

      output, status = Open3.capture2e(MMDC_COMMAND, "--version")
      @version = output.strip if status.success?
    rescue StandardError
      @version = nil
    end

    # Check mmdc status (availability and Puppeteer)
    #
    # @return [Symbol] :ok, :not_found, :puppeteer_error, or :unknown_error
    def self.check_status
      return @check_status if instance_variable_defined?(:@check_status)

      unless available?
        @check_status = :not_found
        return @check_status
      end

      @check_status = test_render
    end

    # Reset cached status (useful for testing)
    def self.reset_cache!
      remove_instance_variable(:@available) if instance_variable_defined?(:@available)
      remove_instance_variable(:@version) if instance_variable_defined?(:@version)
      remove_instance_variable(:@check_status) if instance_variable_defined?(:@check_status)
    end

    # Test mmdc with a minimal diagram to verify Puppeteer works
    #
    # @return [Symbol] :ok, :puppeteer_error, or :unknown_error
    def self.test_render
      input = Tempfile.new(["", ".mmd"])
      output = Tempfile.new(["", ".svg"])
      input.write("graph TD\nA-->B")
      input.close
      output.close # Close before mmdc writes (Windows file locking)

      _stdout, stderr, status = Open3.capture3(
        MMDC_COMMAND, "-i", input.path, "-o", output.path, "-e", "svg"
      )

      if status.success?
        :ok
      elsif stderr.include?("libgbm") || stderr.include?("browser process")
        :puppeteer_error
      else
        :unknown_error
      end
    end

    # Render mermaid source to SVG file
    #
    # @param mermaid_source [String] mermaid diagram definition
    # @param output_path [String] path to write SVG file
    ALLOWED_RENDER_THEMES = %i[default dark].freeze

    # @param theme [Symbol] :default (mermaid default theme) or :dark (mmdc -t dark)
    # @return [Boolean] true if successful
    # @raise [ArgumentError] if theme is not supported
    def self.render(mermaid_source, output_path, theme: :default)
      raise ArgumentError, "unsupported mmdc theme #{theme.inspect}" unless ALLOWED_RENDER_THEMES.include?(theme)

      input_file = Tempfile.new(["mermaid", ".mmd"])

      begin
        input_file.write(mermaid_source)
        input_file.close

        cmd = [MMDC_COMMAND, "-i", input_file.path, "-o", output_path, "-e", "svg"]
        cmd += ["-t", "dark"] if theme == :dark
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
    def self.mermaid_fence_pattern
      /
        ^(`{3,}|~{3,})mermaid\s*\n  # Opening fence: 3+ backticks or tildes, then 'mermaid'
        (.*?)                        # Content (captured, non-greedy)
        ^\1\s*$                      # Closing fence: must match opening fence type and length
      /mx
    end
  end
end
