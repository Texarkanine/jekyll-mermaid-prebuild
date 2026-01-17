# frozen_string_literal: true

require "fileutils"

module JekyllMermaidPrebuild
  # Jekyll hook integration
  module Hooks
    module_function

    # Copy generated SVGs to _site directory
    #
    # @param site [Jekyll::Site] the Jekyll site
    # @param config [Configuration] plugin configuration
    # @param svgs [Hash] cache_key => cached_path mapping
    def copy_svgs_to_site(site, config, svgs)
      return unless svgs && !svgs.empty?

      dest_dir = File.join(site.dest, config.output_dir)
      FileUtils.mkdir_p(dest_dir)

      svgs.each do |cache_key, cached_path|
        dest_path = File.join(dest_dir, "#{cache_key}.svg")
        FileUtils.cp(cached_path, dest_path)
      end

      Jekyll.logger.info "MermaidPrebuild:", "Copied #{svgs.size} SVG(s) to #{config.output_dir}/"
    end

    # Log helpful error message for Puppeteer issues
    def log_puppeteer_error
      Jekyll.logger.error "MermaidPrebuild:", "=" * 60
      Jekyll.logger.error "MermaidPrebuild:", "mmdc failed: Puppeteer cannot launch headless Chrome"
      Jekyll.logger.error "MermaidPrebuild:", ""
      Jekyll.logger.error "MermaidPrebuild:", "This usually means missing system libraries."
      Jekyll.logger.error "MermaidPrebuild:", "On Debian/Ubuntu/WSL, install with:"
      Jekyll.logger.error "MermaidPrebuild:", ""
      Jekyll.logger.error "MermaidPrebuild:", "  sudo apt-get update"
      Jekyll.logger.error "MermaidPrebuild:", "  sudo apt-get install -y libgbm1 libasound2 libatk1.0-0 \\"
      Jekyll.logger.error "MermaidPrebuild:", "    libatk-bridge2.0-0 libcups2 libdrm2 libxcomposite1 \\"
      Jekyll.logger.error "MermaidPrebuild:", "    libxdamage1 libxfixes3 libxrandr2 libxkbcommon0 \\"
      Jekyll.logger.error "MermaidPrebuild:", "    libpango-1.0-0 libcairo2 libnss3 libnspr4"
      Jekyll.logger.error "MermaidPrebuild:", ""
      Jekyll.logger.error "MermaidPrebuild:", "See: https://pptr.dev/troubleshooting"
      Jekyll.logger.error "MermaidPrebuild:", "=" * 60
    end

    # Register Jekyll hooks
    def register
      # Initialize and check mmdc after site data is loaded
      Jekyll::Hooks.register :site, :post_read do |site|
        config = Configuration.new(site)
        site.data["mermaid_prebuild_config"] = config

        unless config.enabled?
          Jekyll.logger.info "MermaidPrebuild:", "Disabled in configuration"
          site.data["mermaid_prebuild_enabled"] = false
          next
        end

        status = MmdcWrapper.check_status

        case status
        when :ok
          Jekyll.logger.info "MermaidPrebuild:", "Initialized (mmdc #{MmdcWrapper.version || "unknown version"})"
          Jekyll.logger.info "MermaidPrebuild:", "Output directory: #{config.output_dir}"
          site.data["mermaid_prebuild_enabled"] = true
          site.data["mermaid_prebuild_generator"] = Generator.new(config)
          site.data["mermaid_prebuild_processor"] = Processor.new(config, site.data["mermaid_prebuild_generator"])
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

      # Process all documents/pages BEFORE rendering
      Jekyll::Hooks.register :site, :pre_render do |site|
        next unless site.data["mermaid_prebuild_enabled"]

        processor = site.data["mermaid_prebuild_processor"]
        total_count = 0

        # Process all documents
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

        # Process all pages
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

      # Copy SVGs to _site after write
      Jekyll::Hooks.register :site, :post_write do |site|
        next unless site.data["mermaid_prebuild_enabled"]

        config = site.data["mermaid_prebuild_config"]
        svgs = site.data["mermaid_prebuild_svgs"]
        copy_svgs_to_site(site, config, svgs)
      end
    end
  end
end

# Register hooks when loaded
JekyllMermaidPrebuild::Hooks.register
