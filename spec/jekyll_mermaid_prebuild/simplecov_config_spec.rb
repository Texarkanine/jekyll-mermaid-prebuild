# frozen_string_literal: true

require "spec_helper"

# rubocop:disable RSpec/DescribeClass -- contract over spec_helper config, not a class
RSpec.describe "SimpleCov configuration in spec_helper" do
  # Ensures SimpleCov 1.0 uses skip (not deprecated add_filter) so suite runs emit no DEPRECATION warnings.
  describe "filter API" do
    subject(:helper_source) { File.read(File.expand_path("../spec_helper.rb", __dir__)) }

    it "uses skip instead of deprecated add_filter for spec and vendor paths" do
      expect(helper_source).not_to match(/\badd_filter\b/)
      expect(helper_source).to match(%r{\bskip\s+["'](?:/)?spec/})
      expect(helper_source).to match(%r{\bskip\s+["'](?:/)?vendor/})
    end
  end
end
# rubocop:enable RSpec/DescribeClass
