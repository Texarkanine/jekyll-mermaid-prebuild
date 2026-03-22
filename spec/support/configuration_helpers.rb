# frozen_string_literal: true

# Default attributes for instance_double(JekyllMermaidPrebuild::Configuration, ...) across specs.
module ConfigurationHelpers
  def configuration_generator_attrs(cache_dir, overrides = {})
    {
      cache_dir: cache_dir,
      output_dir: "assets/svg",
      text_centering: true,
      overflow_protection: true,
      edge_label_padding: 0,
      prefers_color_scheme: :light,
      chart_background_light: "white",
      chart_background_dark: "black"
    }.merge(overrides)
  end

  def configuration_processor_attrs(cache_dir, overrides = {})
    {
      cache_dir: cache_dir,
      output_dir: "assets/svg",
      enabled?: true,
      emoji_width_compensation: {},
      edge_label_padding: 0,
      text_centering: true,
      overflow_protection: true,
      prefers_color_scheme: :light,
      chart_background_light: "white",
      chart_background_dark: "black"
    }.merge(overrides)
  end
end

RSpec.configure do |config|
  config.include ConfigurationHelpers
end
