# frozen_string_literal: true

require "digest"

module JekyllMermaidPrebuild
  # Computes content-based digests for caching
  module DigestCalculator
    module_function

    # Generate a short digest for mermaid content
    #
    # @param content [String] mermaid diagram source
    # @return [String] 8-character hex digest
    def content_digest(content)
      Digest::MD5.hexdigest(content)[0, 8]
    end
  end
end
