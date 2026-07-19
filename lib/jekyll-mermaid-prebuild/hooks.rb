# frozen_string_literal: true

require "fileutils"

module JekyllMermaidPrebuild
  # Jekyll hook integration
  module Hooks
    # Copy generated SVGs to _site directory
    #
    # @param site [Jekyll::Site] the Jekyll site
    # @param config [Configuration] plugin configuration
    # @param svgs [Hash] cache_key => cached_path mapping
    def self.copy_svgs_to_site(site, config, svgs)
      return if svgs.nil? || svgs.empty?

      dest_dir = File.join(site.dest, config.output_dir)
      FileUtils.mkdir_p(dest_dir)

      copied_count = 0
      svgs.each do |cache_key, cached_path|
        unless cached_path && File.exist?(cached_path)
          Jekyll.logger.warn "MermaidPrebuild:", "Missing cached SVG for #{cache_key} (expected: #{cached_path})"
          next
        end

        dest_path = File.join(dest_dir, "#{cache_key}.svg")
        FileUtils.cp(cached_path, dest_path)
        copied_count += 1
      end

      Jekyll.logger.info "MermaidPrebuild:", "Copied #{copied_count} SVG(s) to #{config.output_dir}/"
    end

    # Log helpful error message for Puppeteer issues
    def self.log_puppeteer_error
      Jekyll.logger.error "MermaidPrebuild:", "mmdc failed: Puppeteer cannot launch headless Chrome"
      Jekyll.logger.error "MermaidPrebuild:", "Install system libraries (see https://pptr.dev/troubleshooting)"
    end

    # Initialize plugin state after site data is loaded (:post_read)
    #
    # @param site [Jekyll::Site] the Jekyll site
    def self.initialize_system(site)
      config = Configuration.new(site)
      site.data["mermaid_prebuild_config"] = config

      unless config.enabled?
        Jekyll.logger.info "MermaidPrebuild:", "Disabled in configuration"
        site.data["mermaid_prebuild_enabled"] = false
        return
      end

      status = MmdcWrapper.check_status

      case status
      when :ok
        Jekyll.logger.info "MermaidPrebuild:", "Initialized (mmdc #{MmdcWrapper.version || "unknown version"})"
        Jekyll.logger.info "MermaidPrebuild:", "Output directory: #{config.output_dir}"
        site.data["mermaid_prebuild_enabled"] = true
        generator = Generator.new(config)
        site.data["mermaid_prebuild_generator"] = generator
        site.data["mermaid_prebuild_processor"] = Processor.new(config, generator)
        site.data["mermaid_prebuild_svgs"] = {}
      when :not_found
        Jekyll.logger.warn "MermaidPrebuild:", "mmdc not found - mermaid diagrams will not be converted"
        Jekyll.logger.warn "MermaidPrebuild:", "Install with: npm install -g @mermaid-js/mermaid-cli"
        site.data["mermaid_prebuild_enabled"] = false
      when :puppeteer_error
        log_puppeteer_error
        site.data["mermaid_prebuild_enabled"] = false
      else
        Jekyll.logger.warn "MermaidPrebuild:", "mmdc check failed with unknown error"
        site.data["mermaid_prebuild_enabled"] = false
      end
    end

    # Process documents/pages before rendering (:pre_render)
    #
    # @param site [Jekyll::Site] the Jekyll site
    def self.process_site(site)
      return unless site.data["mermaid_prebuild_enabled"]

      processor = site.data["mermaid_prebuild_processor"]
      total_count = 0

      site.documents.each do |document|
        next unless document.content

        processed, count, svgs = processor.process_content(document.content, site)
        if count.positive?
          document.content = processed
          site.data["mermaid_prebuild_svgs"].merge!(svgs)
          Jekyll.logger.info "MermaidPrebuild:", "Converted #{count} diagram(s) in #{document.relative_path}"
          total_count += count
        end
      rescue StandardError => e
        Jekyll.logger.error "MermaidPrebuild:", "Error processing #{document.relative_path}: #{e.message}"
      end

      site.pages.each do |page|
        next unless page.content

        processed, count, svgs = processor.process_content(page.content, site)
        if count.positive?
          page.content = processed
          site.data["mermaid_prebuild_svgs"].merge!(svgs)
          Jekyll.logger.info "MermaidPrebuild:", "Converted #{count} diagram(s) in #{page.relative_path}"
          total_count += count
        end
      rescue StandardError => e
        Jekyll.logger.error "MermaidPrebuild:", "Error processing page: #{e.message}"
      end

      Jekyll.logger.info "MermaidPrebuild:", "Total: #{total_count} diagram(s) converted" if total_count.positive?
    end

    # Copy SVGs into _site after write (:post_write)
    #
    # @param site [Jekyll::Site] the Jekyll site
    def self.copy_generated_svgs(site)
      return unless site.data["mermaid_prebuild_enabled"]

      config = site.data["mermaid_prebuild_config"]
      svgs = site.data["mermaid_prebuild_svgs"]
      copy_svgs_to_site(site, config, svgs)
    end
  end
end

# Register Jekyll hooks when loaded
Jekyll::Hooks.register :site, :post_read do |site|
  JekyllMermaidPrebuild::Hooks.initialize_system(site)
end

Jekyll::Hooks.register :site, :pre_render do |site|
  JekyllMermaidPrebuild::Hooks.process_site(site)
end

Jekyll::Hooks.register :site, :post_write do |site|
  JekyllMermaidPrebuild::Hooks.copy_generated_svgs(site)
end
