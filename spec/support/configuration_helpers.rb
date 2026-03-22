# frozen_string_literal: true

# Default attributes for instance_double(JekyllMermaidPrebuild::Configuration, ...) across specs.
module ConfigurationHelpers
  PLUGIN_CONFIGURATION = JekyllMermaidPrebuild::Configuration

  def configuration_generator_attrs(cache_dir, overrides = {})
    c = PLUGIN_CONFIGURATION
    {
      cache_dir: cache_dir,
      output_dir: c::DEFAULT_OUTPUT_DIR,
      text_centering: true,
      overflow_protection: true,
      edge_label_padding: 0,
      prefers_color_scheme: c::DEFAULT_PREFERS_COLOR_SCHEME_MODE,
      chart_background_light: c::DEFAULT_CHART_BG_LIGHT,
      chart_background_dark: c::DEFAULT_CHART_BG_DARK
    }.merge(overrides)
  end

  def configuration_processor_attrs(cache_dir, overrides = {})
    c = PLUGIN_CONFIGURATION
    {
      cache_dir: cache_dir,
      output_dir: c::DEFAULT_OUTPUT_DIR,
      enabled?: true,
      emoji_width_compensation: {},
      edge_label_padding: 0,
      text_centering: true,
      overflow_protection: true,
      prefers_color_scheme: c::DEFAULT_PREFERS_COLOR_SCHEME_MODE,
      chart_background_light: c::DEFAULT_CHART_BG_LIGHT,
      chart_background_dark: c::DEFAULT_CHART_BG_DARK
    }.merge(overrides)
  end
end

RSpec.configure do |config|
  config.include ConfigurationHelpers
end
