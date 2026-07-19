# frozen_string_literal: true

require "spec_helper"

RSpec.describe JekyllMermaidPrebuild::Configuration do
  let(:site_config) { {} }
  let(:site) do
    instance_double(Jekyll::Site, config: site_config)
  end

  describe "#initialize" do
    context "with no configuration" do
      it "uses default output_dir" do
        config = described_class.new(site)

        expect(config.output_dir).to eq("assets/svg")
      end

      it "defaults enabled to true" do
        config = described_class.new(site)

        expect(config.enabled?).to be true
      end

      it "defaults postprocessing flags when postprocessing is omitted" do
        config = described_class.new(site)

        expect(config.text_centering).to be true
        expect(config.overflow_protection).to be true
        expect(config.edge_label_padding).to eq(0)
        expect(config.emoji_width_compensation).to eq({})
      end

      it "defaults prefers-color-scheme mode and chart backgrounds" do
        config = described_class.new(site)

        expect(config.prefers_color_scheme).to eq(:light)
        expect(config.chart_background_light).to eq("white")
        expect(config.chart_background_dark).to eq("black")
        expect(config.chart_background_light).to be_frozen
        expect(config.chart_background_dark).to be_frozen
      end
    end

    context "with custom output_dir" do
      let(:site_config) do
        { "mermaid_prebuild" => { "output_dir" => "images/diagrams" } }
      end

      it "uses configured output_dir" do
        config = described_class.new(site)

        expect(config.output_dir).to eq("images/diagrams")
      end
    end

    context "with leading slash in output_dir" do
      let(:site_config) do
        { "mermaid_prebuild" => { "output_dir" => "/assets/svg/" } }
      end

      it "strips leading and trailing slashes" do
        config = described_class.new(site)

        expect(config.output_dir).to eq("assets/svg")
      end
    end

    context "with empty output_dir" do
      let(:site_config) do
        { "mermaid_prebuild" => { "output_dir" => "" } }
      end

      it "uses default output_dir" do
        config = described_class.new(site)

        expect(config.output_dir).to eq("assets/svg")
      end
    end

    context "with enabled: false" do
      let(:site_config) do
        { "mermaid_prebuild" => { "enabled" => false } }
      end

      it "stores enabled false" do
        config = described_class.new(site)

        expect(config.enabled?).to be false
      end
    end

    context "with postprocessing overrides" do
      let(:site_config) do
        {
          "mermaid_prebuild" => {
            "postprocessing" => {
              "text_centering" => false,
              "overflow_protection" => false,
              "edge_label_padding" => 4,
              "emoji_width_compensation" => { "flowchart" => true }
            }
          }
        }
      end

      it "applies configured postprocessing overrides" do
        config = described_class.new(site)

        expect(config.text_centering).to be false
        expect(config.overflow_protection).to be false
        expect(config.edge_label_padding).to eq(4)
        expect(config.emoji_width_compensation).to eq("flowchart" => true)
        expect(config.emoji_width_compensation).to be_frozen
      end
    end

    it "reads prefers-color-scheme from the hyphenated YAML key only" do
      site_config = {
        "mermaid_prebuild" => {
          "prefers_color_scheme" => { "mode" => "dark" },
          "prefers-color-scheme" => { "mode" => "auto" }
        }
      }
      config = described_class.new(instance_double(Jekyll::Site, config: site_config))
      expect(config.prefers_color_scheme).to eq(:auto)
    end
  end

  describe "#enabled?" do
    context "with no configuration" do
      it "returns true by default" do
        config = described_class.new(site)

        expect(config.enabled?).to be true
      end
    end

    context "with enabled: false" do
      let(:site_config) do
        { "mermaid_prebuild" => { "enabled" => false } }
      end

      it "returns false" do
        config = described_class.new(site)

        expect(config.enabled?).to be false
      end
    end

    context "with enabled: true" do
      let(:site_config) do
        { "mermaid_prebuild" => { "enabled" => true } }
      end

      it "returns true" do
        config = described_class.new(site)

        expect(config.enabled?).to be true
      end
    end
  end

  describe "#cache_dir" do
    it "returns the cache directory path" do
      config = described_class.new(site)

      expect(config.cache_dir).to eq(".jekyll-cache/jekyll-mermaid-prebuild")
    end
  end

  describe "#text_centering" do
    context "when not configured" do
      it "defaults to true" do
        expect(described_class.new(site).text_centering).to be true
      end
    end

    context "when set to false" do
      let(:site_config) { { "mermaid_prebuild" => { "postprocessing" => { "text_centering" => false } } } }

      it "returns false" do
        expect(described_class.new(site).text_centering).to be false
      end
    end

    context "when set to true explicitly" do
      let(:site_config) { { "mermaid_prebuild" => { "postprocessing" => { "text_centering" => true } } } }

      it "returns true" do
        expect(described_class.new(site).text_centering).to be true
      end
    end
  end

  describe "#overflow_protection" do
    context "when not configured" do
      it "defaults to true" do
        expect(described_class.new(site).overflow_protection).to be true
      end
    end

    context "when set to false" do
      let(:site_config) { { "mermaid_prebuild" => { "postprocessing" => { "overflow_protection" => false } } } }

      it "returns false" do
        expect(described_class.new(site).overflow_protection).to be false
      end
    end

    context "when set to true explicitly" do
      let(:site_config) { { "mermaid_prebuild" => { "postprocessing" => { "overflow_protection" => true } } } }

      it "returns true" do
        expect(described_class.new(site).overflow_protection).to be true
      end
    end
  end

  describe "#edge_label_padding" do
    context "when not configured" do
      it "returns 0" do
        expect(described_class.new(site).edge_label_padding).to eq(0)
      end
    end

    context "when set to an integer" do
      let(:site_config) { { "mermaid_prebuild" => { "postprocessing" => { "edge_label_padding" => 6 } } } }

      it "returns that value" do
        expect(described_class.new(site).edge_label_padding).to eq(6)
      end
    end

    context "when set to a float" do
      let(:site_config) { { "mermaid_prebuild" => { "postprocessing" => { "edge_label_padding" => 4.5 } } } }

      it "returns that value" do
        expect(described_class.new(site).edge_label_padding).to eq(4.5)
      end
    end

    context "when set to false" do
      let(:site_config) { { "mermaid_prebuild" => { "postprocessing" => { "edge_label_padding" => false } } } }

      it "returns 0" do
        expect(described_class.new(site).edge_label_padding).to eq(0)
      end
    end

    context "when set to a negative number" do
      let(:site_config) { { "mermaid_prebuild" => { "postprocessing" => { "edge_label_padding" => -3 } } } }

      it "returns 0" do
        expect(described_class.new(site).edge_label_padding).to eq(0)
      end
    end

    context "when set to a non-numeric value" do
      let(:site_config) { { "mermaid_prebuild" => { "postprocessing" => { "edge_label_padding" => "wide" } } } }

      it "returns 0" do
        expect(described_class.new(site).edge_label_padding).to eq(0)
      end
    end
  end

  describe "#emoji_width_compensation" do
    context "with no emoji_width_compensation configured" do
      it "returns empty hash" do
        config = described_class.new(site)

        expect(config.emoji_width_compensation).to eq({})
      end
    end

    context "with emoji_width_compensation: { flowchart: true }" do
      let(:site_config) do
        { "mermaid_prebuild" => { "postprocessing" => { "emoji_width_compensation" => { "flowchart" => true } } } }
      end

      it "returns hash with flowchart => true" do
        config = described_class.new(site)

        expect(config.emoji_width_compensation).to eq("flowchart" => true)
      end
    end

    context "with emoji_width_compensation: { flowchart: false }" do
      let(:site_config) do
        { "mermaid_prebuild" => { "postprocessing" => { "emoji_width_compensation" => { "flowchart" => false } } } }
      end

      it "returns hash with flowchart => false" do
        config = described_class.new(site)

        expect(config.emoji_width_compensation).to eq("flowchart" => false)
      end
    end

    context "with emoji_width_compensation set to a non-hash value" do
      let(:site_config) do
        { "mermaid_prebuild" => { "postprocessing" => { "emoji_width_compensation" => true } } }
      end

      it "returns empty hash" do
        config = described_class.new(site)

        expect(config.emoji_width_compensation).to eq({})
      end
    end
  end

  describe "#prefers_color_scheme" do
    context "when not configured" do
      it "defaults to :light" do
        expect(described_class.new(site).prefers_color_scheme).to eq(:light)
      end
    end

    context "with nested hash (mode only)" do
      let(:site_config) do
        { "mermaid_prebuild" => { "prefers-color-scheme" => { "mode" => "auto" } } }
      end

      it "parses mode" do
        expect(described_class.new(site).prefers_color_scheme).to eq(:auto)
      end

      it "uses default chart backgrounds" do
        c = described_class.new(site)
        expect(c.chart_background_light).to eq("white")
        expect(c.chart_background_dark).to eq("black")
      end
    end

    context "with nested background-color (string and symbol keys for slots)" do
      let(:site_config) do
        {
          "mermaid_prebuild" => {
            "prefers-color-scheme" => {
              "mode" => "dark",
              "background-color" => { "light" => "#fff0aa", "dark" => "black" }
            }
          }
        }
      end

      it "parses mode and backgrounds" do
        c = described_class.new(site)
        expect(c.prefers_color_scheme).to eq(:dark)
        expect(c.chart_background_light).to eq("#fff0aa")
        expect(c.chart_background_dark).to eq("black")
      end
    end

    context "with background-color using symbol keys for mode and slots" do
      let(:site_config) do
        {
          "mermaid_prebuild" => {
            "prefers-color-scheme" => {
              mode: "auto",
              "background-color" => { light: "rgb(1, 2, 3)", dark: "hsl(0 0% 0%)" }
            }
          }
        }
      end

      it "parses symbol and string keys in nested hash" do
        c = described_class.new(site)
        expect(c.prefers_color_scheme).to eq(:auto)
        expect(c.chart_background_light).to eq("rgb(1, 2, 3)")
        expect(c.chart_background_dark).to eq("hsl(0 0% 0%)")
      end
    end

    context "with non-Hash prefers-color-scheme" do
      let(:site_config) { { "mermaid_prebuild" => { "prefers-color-scheme" => "auto" } } }

      it "falls back to :light" do
        expect(described_class.new(site).prefers_color_scheme).to eq(:light)
      end

      it "logs a warning" do
        expect(Jekyll.logger).to receive(:warn).with("MermaidPrebuild:", /expected a Hash/)

        described_class.new(site)
      end
    end

    context "with invalid mode in hash" do
      let(:site_config) do
        { "mermaid_prebuild" => { "prefers-color-scheme" => { "mode" => "banana" } } }
      end

      it "falls back to :light" do
        expect(described_class.new(site).prefers_color_scheme).to eq(:light)
      end

      it "logs a warning" do
        expect(Jekyll.logger).to receive(:warn).with("MermaidPrebuild:", /Invalid prefers-color-scheme mode/)

        described_class.new(site)
      end
    end

    context "with empty mode string" do
      let(:site_config) do
        { "mermaid_prebuild" => { "prefers-color-scheme" => { "mode" => "   " } } }
      end

      it "treats as :light" do
        expect(described_class.new(site).prefers_color_scheme).to eq(:light)
      end
    end
  end

  describe "chart background sanitization" do
    context "with breakout characters in color" do
      let(:site_config) do
        {
          "mermaid_prebuild" => {
            "prefers-color-scheme" => {
              "mode" => "light",
              "background-color" => { "light" => 'white";', "dark" => "black" }
            }
          }
        }
      end

      it "rejects and falls back to defaults" do
        expect(Jekyll.logger).to receive(:warn).with("MermaidPrebuild:", /disallowed characters/).at_least(:once)
        c = described_class.new(site)
        expect(c.chart_background_light).to eq("white")
      end
    end

    context "with empty string color" do
      let(:site_config) do
        {
          "mermaid_prebuild" => {
            "prefers-color-scheme" => {
              "mode" => "light",
              "background-color" => { "light" => "", "dark" => "black" }
            }
          }
        }
      end

      it "falls back to default light background" do
        expect(Jekyll.logger).to receive(:warn).with("MermaidPrebuild:", /empty string/)
        c = described_class.new(site)
        expect(c.chart_background_light).to eq("white")
      end
    end

    context "with overly long color string" do
      let(:long) { "a" * 300 }
      let(:site_config) do
        {
          "mermaid_prebuild" => {
            "prefers-color-scheme" => {
              "mode" => "light",
              "background-color" => { "light" => long, "dark" => "black" }
            }
          }
        }
      end

      it "falls back to default" do
        expect(Jekyll.logger).to receive(:warn).with("MermaidPrebuild:", /too long/)
        c = described_class.new(site)
        expect(c.chart_background_light).to eq("white")
      end
    end
  end

  describe "#finalize_background" do
    let(:config) { described_class.new(instance_double(Jekyll::Site, config: {})) }

    it "returns a frozen duplicate string from String()" do
      result = config.finalize_background("papayawhip")
      expect(result).to eq("papayawhip")
      expect(result).to be_frozen
      expect(result).not_to equal("papayawhip")
    end

    it "uses String() (to_s) rather than to_str" do
      value = Object.new
      def value.to_s = "from-to_s"
      def value.to_str = "from-to_str"

      expect(config.finalize_background(value)).to eq("from-to_s")
    end
  end

  describe "#coerce_chart_background" do
    let(:config) { described_class.new(instance_double(Jekyll::Site, config: {})) }
    let(:default) { +"white" }

    before { allow(Jekyll.logger).to receive(:warn) }

    it "returns a frozen duplicate of the default when value is nil without warning" do
      result = config.coerce_chart_background(nil, default, "light")
      expect(result).to eq("white")
      expect(result).to be_frozen
      expect(result).not_to equal(default)
      expect(Jekyll.logger).not_to have_received(:warn)
    end

    it "warns with exact label/default and falls back for empty string" do
      result = config.coerce_chart_background("  ", default, "light")
      expect(result).to eq("white")
      expect(result).not_to equal(default)
      expect(Jekyll.logger).to have_received(:warn).with(
        "MermaidPrebuild:",
        'Invalid chart background (light): empty string; using "white"'
      )
    end

    it "warns with exact label/default and falls back for overly long values" do
      result = config.coerce_chart_background("a" * 300, default, "dark")
      expect(result).to eq("white")
      expect(result).to be_frozen
      expect(result).not_to equal(default)
      expect(Jekyll.logger).to have_received(:warn).with(
        "MermaidPrebuild:",
        'Invalid chart background (dark): value too long; using "white"'
      )
    end

    it "warns with exact label/default and falls back for disallowed characters" do
      result = config.coerce_chart_background("red;alert(1)", default, "light")
      expect(result).to eq("white")
      expect(result).to be_frozen
      expect(result).not_to equal(default)
      expect(Jekyll.logger).to have_received(:warn).with(
        "MermaidPrebuild:",
        'Invalid chart background (light): disallowed characters; using "white"'
      )
    end

    it "strips both leading and trailing whitespace before accepting a color" do
      expect(config.coerce_chart_background("  #abc  ", default, "light")).to eq("#abc")
      expect(config.coerce_chart_background("  #abc", default, "light")).to eq("#abc")
      expect(config.coerce_chart_background("#abc  ", default, "light")).to eq("#abc")
    end

    it "stringifies via to_s before stripping" do
      value = Object.new
      def value.to_s = "  #def  "
      def value.to_str = "  #bad  "
      expect(config.coerce_chart_background(value, default, "light")).to eq("#def")
    end

    it "returns a frozen sanitized color" do
      result = config.coerce_chart_background("#abc", default, "light")
      expect(result).to eq("#abc")
      expect(result).to be_frozen
    end
  end

  describe "#config_hash_fetch" do
    let(:config) { described_class.new(instance_double(Jekyll::Site, config: {})) }

    it "returns nil for non-hash input" do
      expect(config.config_hash_fetch("x", "mode")).to be_nil
    end

    it "reads string keys" do
      expect(config.config_hash_fetch({ "mode" => "dark" }, "mode")).to eq("dark")
    end

    it "reads symbol keys when string key is absent" do
      expect(config.config_hash_fetch({ mode: "auto" }, "mode")).to eq("auto")
    end

    it "prefers string keys over symbol keys" do
      expect(config.config_hash_fetch({ "mode" => "light", mode: "dark" }, "mode")).to eq("light")
    end

    it "accepts Hash subclasses via is_a?" do
      value = Class.new(Hash).new
      value[:mode] = "dark"

      expect(config.config_hash_fetch(value, "mode")).to eq("dark")
    end

    it "returns nil when neither string nor symbol key is present" do
      expect(config.config_hash_fetch({ "other" => "x" }, "mode")).to be_nil
    end

    it "returns nil for present string keys with nil values without falling back to symbol keys" do
      expect(config.config_hash_fetch({ "mode" => nil, mode: "dark" }, "mode")).to be_nil
    end
  end

  describe "#normalize_prefers_mode" do
    let(:config) { described_class.new(instance_double(Jekyll::Site, config: {})) }

    before { allow(Jekyll.logger).to receive(:warn) }

    it "returns the default for nil without warning" do
      expect(config.normalize_prefers_mode(nil)).to eq(:light)
      expect(Jekyll.logger).not_to have_received(:warn)
    end

    it "returns the default for blank strings without warning" do
      expect(config.normalize_prefers_mode("  ")).to eq(:light)
      expect(Jekyll.logger).not_to have_received(:warn)
    end

    it "symbolizes known modes case-insensitively after to_s strip" do
      expect(config.normalize_prefers_mode(" DARK ")).to eq(:dark)
      expect(config.normalize_prefers_mode("Auto")).to eq(:auto)
      expect(config.normalize_prefers_mode("light")).to eq(:light)
      value = Object.new
      def value.to_s = " dark "
      def value.to_str = " auto "
      expect(config.normalize_prefers_mode(value)).to eq(:dark)
    end

    it "does not warn for known light mode" do
      config.normalize_prefers_mode("light")
      expect(Jekyll.logger).not_to have_received(:warn)
    end

    it "warns with raw.inspect and defaults for unknown modes" do
      expect(config.normalize_prefers_mode("banana")).to eq(:light)
      expect(Jekyll.logger).to have_received(:warn).with(
        "MermaidPrebuild:",
        'Invalid prefers-color-scheme mode "banana"; using light'
      )
    end
  end

  describe "#parse_edge_label_padding" do
    let(:config) { described_class.new(instance_double(Jekyll::Site, config: {})) }

    it "returns 0 for nil, false, negative, and non-numeric" do
      expect(config.parse_edge_label_padding(nil)).to eq(0)
      expect(config.parse_edge_label_padding(false)).to eq(0)
      expect(config.parse_edge_label_padding(-1)).to eq(0)
      expect(config.parse_edge_label_padding("x")).to eq(0)
    end

    it "returns numeric padding values including zero" do
      expect(config.parse_edge_label_padding(0)).to eq(0)
      expect(config.parse_edge_label_padding(3)).to eq(3)
      expect(config.parse_edge_label_padding(2.5)).to eq(2.5)
    end
  end

  describe "#parse_emoji_width_compensation" do
    let(:config) { described_class.new(instance_double(Jekyll::Site, config: {})) }

    it "returns a frozen empty hash for non-hash values" do
      result = config.parse_emoji_width_compensation("nope")
      expect(result).to eq({})
      expect(result).to be_frozen
    end

    it "stringifies keys, coerces values, and freezes" do
      result = config.parse_emoji_width_compensation({ flowchart: true, other: "x" })
      expect(result).to eq("flowchart" => true, "other" => false)
      expect(result).to be_frozen
    end

    it "preserves explicit false values" do
      result = config.parse_emoji_width_compensation({ "flowchart" => false })
      expect(result).to eq("flowchart" => false)
      expect(result).to be_frozen
    end

    it "accepts Hash subclasses via is_a?" do
      value = Class.new(Hash).new
      value[:flowchart] = true

      result = config.parse_emoji_width_compensation(value)
      expect(result).to eq("flowchart" => true)
      expect(result).to be_frozen
    end
  end

  describe "#parse_output_dir" do
    let(:config) { described_class.new(instance_double(Jekyll::Site, config: {})) }

    it "returns the default for non-strings and blanks" do
      expect(config.parse_output_dir(123)).to eq("assets/svg")
      expect(config.parse_output_dir("")).to eq("assets/svg")
      expect(config.parse_output_dir("   ")).to eq("assets/svg")
    end

    it "accepts String subclasses via is_a?" do
      subclass = Class.new(String)
      expect(config.parse_output_dir(subclass.new("/x/"))).to eq("x")
    end

    it "strips both leading and trailing whitespace before slash cleanup" do
      expect(config.parse_output_dir("  /a/b/  ")).to eq("a/b")
    end

    it "strips multiple leading and trailing slashes" do
      expect(config.parse_output_dir("//a/b//")).to eq("a/b")
    end

    it "collapses repeated internal slashes" do
      expect(config.parse_output_dir("a//b")).to eq("a/b")
    end
  end

  describe "#parse_prefers_color_scheme" do
    let(:config) { described_class.new(instance_double(Jekyll::Site, config: {})) }

    before { allow(Jekyll.logger).to receive(:warn) }

    it "sets frozen defaults for nil without warning" do
      config.parse_prefers_color_scheme(nil)
      expect(config.prefers_color_scheme).to eq(:light)
      expect(config.chart_background_light).to eq("white")
      expect(config.chart_background_dark).to eq("black")
      expect(config.chart_background_light).to be_frozen
      expect(config.chart_background_dark).to be_frozen
      expect(config.chart_background_light).not_to equal(described_class::DEFAULT_CHART_BG_LIGHT)
      expect(config.chart_background_dark).not_to equal(described_class::DEFAULT_CHART_BG_DARK)
      expect(Jekyll.logger).not_to have_received(:warn)
    end

    it "warns and defaults for non-hash values" do
      config.parse_prefers_color_scheme("dark")
      expect(config.prefers_color_scheme).to eq(:light)
      expect(config.chart_background_light).to be_frozen
      expect(config.chart_background_dark).to eq("black")
      expect(config.chart_background_dark).to be_frozen
      expect(config.chart_background_dark).not_to equal(described_class::DEFAULT_CHART_BG_DARK)
      expect(Jekyll.logger).to have_received(:warn).with("MermaidPrebuild:", /expected a Hash/)
    end

    it "accepts Hash subclasses via is_a?" do
      value = Class.new(Hash).new
      value["mode"] = "dark"
      config.parse_prefers_color_scheme(value)
      expect(config.prefers_color_scheme).to eq(:dark)
      expect(Jekyll.logger).not_to have_received(:warn)
    end

    it "does not warn for valid hash config" do
      config.parse_prefers_color_scheme("mode" => "auto")
      expect(config.prefers_color_scheme).to eq(:auto)
      expect(Jekyll.logger).not_to have_received(:warn)
    end

    it "parses mode and background-color map with labels" do
      config.parse_prefers_color_scheme(
        "mode" => "auto",
        "background-color" => { "light" => "#eee", "dark" => "#111" }
      )
      expect(config.prefers_color_scheme).to eq(:auto)
      expect(config.chart_background_light).to eq("#eee")
      expect(config.chart_background_dark).to eq("#111")
    end

    it "uses default frozen backgrounds when background-color is not a Hash" do
      config.parse_prefers_color_scheme("mode" => "light", "background-color" => "white")
      expect(config.chart_background_light).to eq("white")
      expect(config.chart_background_dark).to eq("black")
      expect(config.chart_background_light).to be_frozen
      expect(config.chart_background_dark).to be_frozen
      expect(config.chart_background_light).not_to equal(described_class::DEFAULT_CHART_BG_LIGHT)
      expect(config.chart_background_dark).not_to equal(described_class::DEFAULT_CHART_BG_DARK)
    end

    it "reads background-color from Hash subclasses via is_a?" do
      bg = Class.new(Hash).new
      bg["light"] = "#eee"
      bg["dark"] = "#111"
      config.parse_prefers_color_scheme("mode" => "auto", "background-color" => bg)
      expect(config.chart_background_light).to eq("#eee")
      expect(config.chart_background_dark).to eq("#111")
    end

    it "passes light/dark labels into coercion warnings" do
      config.parse_prefers_color_scheme(
        "mode" => "light",
        "background-color" => { "light" => "bad;color", "dark" => "also;bad" }
      )
      expect(Jekyll.logger).to have_received(:warn).with(
        "MermaidPrebuild:",
        a_string_matching(/Invalid chart background \(light\):/)
      )
      expect(Jekyll.logger).to have_received(:warn).with(
        "MermaidPrebuild:",
        a_string_matching(/Invalid chart background \(dark\):/)
      )
    end
  end
end
