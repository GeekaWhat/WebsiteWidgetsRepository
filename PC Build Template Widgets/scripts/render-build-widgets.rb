#!/usr/bin/env ruby
# frozen_string_literal: true

require "yaml"
require "pathname"

def escape_html(text)
  text
    .to_s
    .gsub("&", "&amp;")
    .gsub("<", "&lt;")
    .gsub(">", "&gt;")
    .gsub('"', "&quot;")
end

def html_value(text)
  escaped = escape_html(text)
  escaped
    .gsub("&lt;br&gt;", "<br>")
    .gsub("&lt;br /&gt;", "<br>")
    .gsub("&lt;br/&gt;", "<br>")
end

def blankish?(value)
  s = value.to_s.strip
  s.empty? || s == "..." || s == "__AUTO_FROM_SOURCE__"
end

PART_LABELS = {
  "cpu" => "CPU",
  "cpu_cooler" => "CPU Cooler",
  "motherboard" => "Motherboard",
  "ram" => "RAM",
  "ssd" => "SSD",
  "gpu" => "GPU",
  "case" => "Case",
  "psu" => "PSU"
}.freeze

PANEL_IDS = {
  "cpu" => "gw-part-cpu",
  "cpu_cooler" => "gw-part-cooler",
  "motherboard" => "gw-part-mobo",
  "ram" => "gw-part-ram",
  "ssd" => "gw-part-ssd",
  "gpu" => "gw-part-gpu",
  "case" => "gw-part-case",
  "psu" => "gw-part-psu"
}.freeze

def default_anchor_for(part_key)
  return "CPU" if part_key == "cpu"
  return "GPU" if part_key == "gpu"

  part_key.tr("_", "-")
end

def build_menu_button(part_key, name, active:)
  label = PART_LABELS.fetch(part_key, part_key)
  panel_id = PANEL_IDS.fetch(part_key, "gw-part-#{part_key.tr('_', '-')}")
  classes = ["gw-build-tab"]
  classes << "is-active" if active
  aria_selected = active ? "true" : "false"
  <<~HTML.chomp
          <button class="#{classes.join(' ')}" type="button" role="tab" aria-selected="#{aria_selected}" data-target="#{panel_id}"><strong>#{escape_html(label)}:</strong> #{escape_html(name)}</button>
  HTML
end

def build_specs(specs)
  return "" if specs.nil? || !specs.is_a?(Array) || specs.empty?

  specs.map do |row|
    label = row.is_a?(Hash) ? row["label"] : nil
    value = row.is_a?(Hash) ? row["value"] : nil
    next if blankish?(label) && blankish?(value)

    <<~HTML.chomp
              <div class="gw-build-spec-row"><div class="gw-build-label">#{escape_html(label)}</div><div class="gw-build-value">#{escape_html(value)}</div></div>
    HTML
  end.compact.join("\n")
end

def build_panel(part_key, part, active:, component_headings:)
  panel_id = PANEL_IDS.fetch(part_key, "gw-part-#{part_key.tr('_', '-')}")
  classes = ["gw-build-panel"]
  classes << "is-active" if active

  name = part.is_a?(Hash) ? part["name"] : nil
  name = component_headings[part_key] if blankish?(name) && component_headings.is_a?(Hash)
  name = PART_LABELS.fetch(part_key, part_key) if blankish?(name)

  anchor = part.is_a?(Hash) ? part["section_anchor"] : nil
  anchor = default_anchor_for(part_key) if blankish?(anchor) || anchor == "__AUTO_FROM_PART_KEY__"

  img_url = part.is_a?(Hash) ? part["image_url"] : nil
  img_alt = part.is_a?(Hash) ? part["image_alt"] : nil
  summary = part.is_a?(Hash) ? part["summary"] : nil
  buy_shortcode = part.is_a?(Hash) ? part["buy_shortcode"] : nil
  specs_html = build_specs(part.is_a?(Hash) ? part["specs"] : nil)

  media_html =
    if blankish?(img_url)
      ""
    else
      alt = blankish?(img_alt) ? name : img_alt
      %(<div class="gw-build-media"><img src="#{escape_html(img_url)}" alt="#{escape_html(alt)}"></div>)
    end

  summary_html =
    if blankish?(summary)
      ""
    else
      %(<p class="gw-build-summary">#{escape_html(summary)}</p>)
    end

  specs_block =
    if specs_html.empty?
      ""
    else
      <<~HTML.chomp
        <div class="gw-build-specs">
#{specs_html}
        </div>
      HTML
    end

  buy_html =
    if blankish?(buy_shortcode)
      ""
    else
      %(<p class="gw-buy-placeholder">#{buy_shortcode}</p>)
    end

  <<~HTML.chomp
        <article id="#{panel_id}" class="#{classes.join(' ')}" role="tabpanel">
          <div class="gw-build-head-row"><h3 class="gw-build-title">#{escape_html(name)}</h3><a class="gw-build-skip" href="##{escape_html(anchor)}">Skip to Section</a></div>
          #{media_html}
          #{summary_html}
          #{specs_block}
          #{buy_html}
        </article>
  HTML
end

def render_parts_list_html(build_data)
  component_headings = build_data["component_headings"] || {}
  parts_list = build_data["parts_list"]
  return nil unless parts_list.is_a?(Array) && !parts_list.empty?

  menu_buttons = []
  panels = []

  parts_list.each_with_index do |part, idx|
    part_key = part.is_a?(Hash) ? part["part_key"].to_s : ""
    next if part_key.empty?

    name = part["name"]
    name = component_headings[part_key] if blankish?(name) && component_headings.is_a?(Hash)
    name = PART_LABELS.fetch(part_key, part_key) if blankish?(name)

    menu_buttons << build_menu_button(part_key, name, active: idx.zero?)
    panels << build_panel(part_key, part, active: idx.zero?, component_headings: component_headings)
  end

  menu_html = <<~HTML.chomp
      <div class="gw-build-menu" role="tablist" aria-label="Build Components">
#{menu_buttons.join("\n")}
      </div>
  HTML

  content_html = <<~HTML.chomp
      <div class="gw-build-content">
#{panels.join("\n\n")}
      </div>
  HTML

  [menu_html, content_html]
end

def apply_component_headings!(path, component_headings)
  return unless File.exist?(path)
  return unless component_headings.is_a?(Hash)

  content = File.read(path)
  replacements = {
    "CPU" => component_headings["cpu"],
    "cpu-cooler" => component_headings["cpu_cooler"],
    "motherboard" => component_headings["motherboard"],
    "ram" => component_headings["ram"],
    "ssd" => component_headings["ssd"],
    "GPU" => component_headings["gpu"],
    "case" => component_headings["case"],
    "psu" => component_headings["psu"]
  }

  replacements.each do |id, value|
    next if blankish?(value)

    content.gsub!(%r{(<h2 class="gw-part-title" id="#{Regexp.escape(id)}">)(.*?)(</h2>)}m) do
      "#{Regexp.last_match(1)}#{escape_html(value)}#{Regexp.last_match(3)}"
    end
  end

  File.write(path, content)
end

def apply_parts_list!(path, build_data)
  return unless File.exist?(path)

  rendered = render_parts_list_html(build_data)
  return if rendered.nil?

  menu_html, content_html = rendered
  content = File.read(path)

  unless content.sub!(%r{<div class="gw-build-menu"[^>]*>.*?</div>}m, menu_html)
    warn "Could not find parts-list menu block in: #{path}"
  end

  block_re = %r{<div class="gw-build-content">\s*.*?\s*</div>\s*</div>\s*</section>}m
  replacement = "#{content_html}\n  </div>\n</section>"
  unless content.sub!(block_re, replacement)
    warn "Could not find parts-list content block in: #{path}"
  end

  File.write(path, content)
end

def write_shortcodes!(path, build_data)
  headings = build_data["component_headings"]
  return unless headings.is_a?(Hash)

  lines = []
  %w[cpu cpu_cooler motherboard ram ssd gpu case psu].each do |key|
    next if blankish?(headings[key])

    label = PART_LABELS.fetch(key, key).gsub("_", " ")
    lines << "#{label}: #{headings[key]}"
  end
  File.write(path, lines.join("\n") + "\n") unless lines.empty?
end

def render_motherboard_specs_html(specs)
  items = [
    ["Model", specs["model"]],
    ["Chipset / Socket", specs["chipset_socket"]],
    ["Form Factor", specs["form_factor"]],
    ["CPU Support", specs["cpu_support"]],
    ["Memory Support", specs["memory_support_html"]],
    ["VRM Design", specs["vrm_design"]],
    ["Graphics Card Compatibility (1 Slot)", specs["graphics_card_compatibility_1_slot"]],
    ["Expansion Card Compatibility", specs["expansion_card_compatibility_html"]],
    ["M.2 Compatibility (3 Slots)", specs["m2_compatibility_3_slots_html"]],
    ["SATA Storage", specs["sata_storage"]],
    ["Networking", specs["networking_html"]],
    ["Rear I/O", specs["rear_io_html"]],
    ["Front I/O Headers", specs["front_io_headers_html"]],
    ["Audio", specs["audio"]]
  ]

  rows = items.map do |label, value|
    <<~HTML.chomp
        <li class="gw-mobo-spec-item">
          <p class="gw-mobo-spec-label">#{escape_html(label)}</p>
          <p class="gw-mobo-spec-value">#{html_value(value)}</p>
        </li>
    HTML
  end.join("\n")

  <<~HTML.chomp
    <ul class="gw-mobo-spec-grid">
#{rows}
    </ul>
  HTML
end

def apply_motherboard_specs!(path, build_data)
  return unless path && File.exist?(path)

  specs = build_data["motherboard_specs"]
  return unless specs.is_a?(Hash) && specs["enabled"] == true

  content = File.read(path)
  list_html = render_motherboard_specs_html(specs)
  unless content.sub!(%r{<ul class="gw-mobo-spec-grid">.*?</ul>}m, list_html)
    warn "Could not find motherboard spec list in: #{path}"
  end
  File.write(path, content)
end

def render_case_spec_value(value)
  if value.is_a?(Array)
    inner = value.map { |entry| "<div>#{html_value(entry)}</div>" }.join
    %(<div class="gw-case-spec-value gw-case-spec-list">#{inner}</div>)
  else
    %(<p class="gw-case-spec-value">#{html_value(value)}</p>)
  end
end

def render_case_specs_html(specs)
  items = [
    ["Model", specs["model"]],
    ["Form Factor", specs["form_factor"]],
    ["Motherboard Support", specs["motherboard_support"]],
    ["Case Dimensions (L x W x H)", specs["dimensions_l_w_h"]],
    ["Front IO", specs["front_io"]],
    ["PCI-E Slots", specs["pcie_slots"]],
    ["Colour", specs["colour"]],
    ["Max Clearance", specs["max_clearance"]],
    ["Drive Support", specs["drive_support"]],
    ["Fan Support", specs["fan_support"]],
    ["Radiator Support", specs["radiator_support"]],
    ["Pre-Installed Fans", specs["pre_installed_fans"]]
  ]

  rows = items.map do |label, value|
    <<~HTML.chomp
        <li class="gw-case-spec-item">
          <p class="gw-case-spec-label">#{escape_html(label)}</p>
          #{render_case_spec_value(value)}
        </li>
    HTML
  end.join("\n")

  <<~HTML.chomp
    <ul class="gw-case-spec-grid">
#{rows}
    </ul>
  HTML
end

def apply_case_specs!(path, build_data)
  return unless path && File.exist?(path)

  specs = build_data["case_specs"]
  return unless specs.is_a?(Hash) && specs["enabled"] == true

  content = File.read(path)
  list_html = render_case_specs_html(specs)
  unless content.sub!(%r{<ul class="gw-case-spec-grid">.*?</ul>}m, list_html)
    warn "Could not find case spec list in: #{path}"
  end
  File.write(path, content)
end

def format_mb_s(value)
  value.to_i.to_s.reverse.scan(/\d{1,3}/).join(",").reverse
end

def escape_js_string(value)
  value.to_s.gsub("\\", "\\\\\\").gsub('"', "\\\"")
end

def apply_cooler_temps_graph!(path, build_data)
  return unless path && File.exist?(path)

  cooler = build_data["cooler_temps_graph"]
  return unless cooler.is_a?(Hash) && cooler["enabled"] == true

  title = cooler["title"]
  benchmark_badge = cooler["benchmark_badge"]
  highlight_names = Array(cooler["highlight_names"]).map(&:to_s).map(&:strip).reject(&:empty?)
  highlight_name = cooler["highlight_name"].to_s
  highlight_value = if highlight_names.any?
    "[#{highlight_names.map { |name| %("#{escape_js_string(name)}") }.join(", ")}]"
  else
    %("#{escape_js_string(highlight_name)}")
  end

  content = File.read(path)
  content.sub!(%r{(<section class="gw-testing-widget" id="gw-cooler-testing-widget-v2" aria-label=")(.*?)(">)}m) do
    "#{Regexp.last_match(1)}#{escape_html(title)} testing carousel#{Regexp.last_match(3)}"
  end
  content.sub!(%r{(<h3 class="gw-testing-title">)(.*?)(</h3>)}m) do
    "#{Regexp.last_match(1)}#{escape_html(title)}#{Regexp.last_match(3)}"
  end
  content.sub!(%r{(<p class="gw-testing-bench-badge">\s*<span class="gw-testing-bench-icon"></span>\s*)(.*?)(\s*</p>)}m) do
    "#{Regexp.last_match(1)}#{escape_html(benchmark_badge)}#{Regexp.last_match(3)}"
  end
  content.sub!(/var highlightName = ".*?";/, %(var highlightName = #{highlight_value};))
  content.sub!(%r{function colorByHighlight\(labels, focus, base, hi\) \{\s*return labels\.map\(function \(n\) \{ return n === focus \? hi : base; \}\);\s*\}\s*}m) do
    <<~JS.chomp
      function colorByHighlight(labels, focus, base, hi) {
        var focusList = Array.isArray(focus) ? focus : [focus];
        var normalizedFocus = focusList.map(function (entry) {
          return String(entry || "").trim().toLowerCase();
        });
        return labels.map(function (n) {
          return normalizedFocus.indexOf(String(n || "").trim().toLowerCase()) !== -1 ? hi : base;
        });
      }
    JS
  end

  File.write(path, content)
end

def apply_ssd_widget!(path, build_data)
  return unless path && File.exist?(path)

  ssd = build_data["ssd_widget"]
  return unless ssd.is_a?(Hash) && ssd["enabled"] == true

  read_value = format_mb_s(ssd["sequential_read_mb_s"])
  write_value = format_mb_s(ssd["sequential_write_mb_s"])
  read_percent = ssd["read_marker_percent"].to_s.strip
  write_percent = ssd["write_marker_percent"].to_s.strip

  content = File.read(path)
  content.sub!(%r{(<p class="gw-ssd-sub">)(.*?)(</p>)}m) do
    "#{Regexp.last_match(1)}#{escape_html(ssd["subtext"])}#{Regexp.last_match(3)}"
  end
  content.sub!(%r{(<p class="gw-ssd-metric-label">Sequential Read</p>\s*<p class="gw-ssd-metric-value">)(.*?)(</p>)}m) do
    "#{Regexp.last_match(1)}#{read_value} MB/s#{Regexp.last_match(3)}"
  end
  content.sub!(%r{(<p class="gw-ssd-metric-label">Sequential Write</p>\s*<p class="gw-ssd-metric-value">)(.*?)(</p>)}m) do
    "#{Regexp.last_match(1)}#{write_value} MB/s#{Regexp.last_match(3)}"
  end
  content.sub!(%r{<span class="gw-ssd-marker read" style="--at:\s*[^;]+;"><span class="gw-ssd-dot-label">.*?</span></span>}m) do
    %(<span class="gw-ssd-marker read" style="--at: #{escape_html(read_percent)}%;"><span class="gw-ssd-dot-label">Read #{read_value} MB/s</span></span>)
  end
  content.sub!(%r{<span class="gw-ssd-marker write" style="--at:\s*[^;]+;"><span class="gw-ssd-dot-label">.*?</span></span>}m) do
    %(<span class="gw-ssd-marker write" style="--at: #{escape_html(write_percent)}%;"><span class="gw-ssd-dot-label">Write #{write_value} MB/s</span></span>)
  end
  content.sub!(%r{(<p class="gw-ssd-foot">)(.*?)(</p>)}m) do
    "#{Regexp.last_match(1)}#{escape_html(ssd["footnote"])}#{Regexp.last_match(3)}"
  end

  File.write(path, content)
end

def render_psu_spec_rows(row_map)
  row_map.map do |label, key, data|
    next if blankish?(data[key])

    %(<div class="gw-psu-spec-row"><div class="gw-psu-label">#{escape_html(label)}</div><div class="gw-psu-value">#{html_value(data[key])}</div></div>)
  end.compact.join("\n          ")
end

def render_psu_widget(psu)
  connectors = psu["connectors"] || {}
  defs = [
    ["pcie_6_2", "gw-psu-pcie62", "PCIe (6+2 pin)", [["Connector Type", "connector_type"], ["Build Usage", "build_usage"], ["Recommended Setup", "recommended_setup"], ["Notes", "notes"]]],
    ["pcie_12v_2x6", "gw-psu-12v2x6", "12V-2x6", [["Connector Type", "connector_type"], ["Typical Output", "typical_output"], ["Build Usage", "build_usage"], ["Notes", "notes"]]],
    ["atx_24pin", "gw-psu-atx24", "ATX 24-pin", [["Connector Type", "connector_type"], ["Quantity Included", "quantity_included"], ["Primary Use", "primary_use"], ["Notes", "notes"]]],
    ["cpu_eps_4_4", "gw-psu-atx12v", "CPU EPS (4+4)", [["Connector Type", "connector_type"], ["Quantity Included", "quantity_included"], ["Primary Use", "primary_use"], ["Notes", "notes"]]],
    ["sata_15pin", "gw-psu-sata", "SATA (15-pin)", [["Connector Type", "connector_type"], ["Primary Use", "primary_use"], ["Build Usage", "build_usage"]]],
    ["molex_4pin", "gw-psu-molex", "Peripheral (Molex 4-pin)", [["Connector Type", "connector_type"], ["Primary Use", "primary_use"], ["Build Usage", "build_usage"]]]
  ]

  tabs = defs.each_with_index.map do |(_, target, title, _), idx|
    active = idx.zero? ? " is-active" : ""
    selected = idx.zero? ? "true" : "false"
    %(<button class="gw-psu-tab#{active}" type="button" role="tab" aria-selected="#{selected}" data-target="#{target}">#{escape_html(title)}</button>)
  end.join("\n      ")

  panels = defs.each_with_index.map do |row, idx|
    key, target, title, row_map = row
    data = connectors[key] || {}
    active = idx.zero? ? " is-active" : ""
    rows = render_psu_spec_rows(row_map.map { |label, map_key| [label, map_key, data] })
    <<~HTML.chomp
          <article id="#{target}" class="gw-psu-panel#{active}" role="tabpanel">
            <h3 class="gw-psu-title">#{escape_html(title)}</h3>
            <div class="gw-psu-specs">
              #{rows}
            </div>
          </article>
    HTML
  end.join("\n\n")

  [tabs, panels]
end

def apply_psu_specs!(path, build_data)
  return unless path && File.exist?(path)

  psu = build_data["psu_connectors"]
  return unless psu.is_a?(Hash) && psu["enabled"] == true

  tabs_html, panels_html = render_psu_widget(psu)
  content = File.read(path)

  content.gsub!(%r{(<h3 class="gw-psu-widget-title">)(.*?)(</h3>)}m) do
    "#{Regexp.last_match(1)}#{escape_html(psu["widget_title"])}#{Regexp.last_match(3)}"
  end
  content.sub!(%r{<div class="gw-psu-menu"[^>]*>.*?</div>}m, "<div class=\"gw-psu-menu\" role=\"tablist\" aria-label=\"PSU Connectors\">\n      #{tabs_html}\n    </div>")
  content.sub!(%r{<div class="gw-psu-content">.*?</div>\s*</div>\s*</section>}m, "<div class=\"gw-psu-content\">\n#{panels_html}\n    </div>\n  </div>\n</section>")

  File.write(path, content)
end

def slugify_game_name(name)
  key = name.downcase.gsub(/[^a-z0-9]+/, "")
  key.empty? ? "game" : key
end

def parse_performance_results(raw_results)
  return [] unless raw_results.is_a?(Array)

  raw_results.map do |line|
    next unless line.is_a?(String)

    match = line.strip.match(/\A(.+?)\s*-\s*([0-9]+(?:\.[0-9]+)?)\s*FPS\s*\(@\s*([^)]+)\)\s*\z/i)
    next unless match

    game = match[1].strip
    fps = match[2].to_f
    resolution = match[3].strip
    key = slugify_game_name(game)

    data = { "HD1080p" => nil, "UltraHD1440p" => nil, "UHD4K" => nil, "resolution" => resolution }
    down = resolution.downcase
    if down.include?("4k") || down.include?("2160")
      data["UHD4K"] = fps
    elsif down.include?("1440")
      data["UltraHD1440p"] = fps
    elsif down.include?("1080")
      data["HD1080p"] = fps
    else
      data["UHD4K"] = fps
    end

    [key, game, data]
  end.compact
end

def to_js_object(hash)
  lines = hash.map do |k, v|
    value =
      case v
      when String
        '"' + v.gsub("\\", "\\\\\\").gsub('"', "\\\"") + '"'
      when Numeric
        v.to_s
      when NilClass
        "null"
      else
        "null"
      end
    "      #{k}: #{value}"
  end
  "{\n#{lines.join(",\n")}\n    }"
end

def parse_perf_setting_pair(entry)
  case entry
  when Hash
    label = entry["label"] || entry[:label]
    value = entry["value"] || entry[:value]
    return nil if blankish?(label) || blankish?(value)
    [label.to_s, value.to_s]
  when Array
    return nil if entry.length < 2
    label = entry[0]
    value = entry[1]
    return nil if blankish?(label) || blankish?(value)
    [label.to_s, value.to_s]
  when String
    return nil unless entry.include?(":")
    label, value = entry.split(":", 2).map(&:strip)
    return nil if blankish?(label) || blankish?(value)
    [label, value]
  else
    nil
  end
end

def performance_settings_pairs(perf, key, resolution)
  preserve_defaults = perf.dig("settings_policy", "preserve_default_settings") != false
  locked = perf["default_settings_locked"]
  raw_pairs = locked.is_a?(Hash) ? locked[key] : nil
  pairs = Array(raw_pairs).map { |entry| parse_perf_setting_pair(entry) }.compact
  return pairs unless pairs.empty? && preserve_defaults

  [
    ["Resolution", resolution.to_s],
    ["Preset", "As configured in benchmark run"]
  ]
end

def performance_driver_class_and_logo(driver_type)
  case driver_type.to_s.strip.downcase
  when "amd"
    ["amd", "A"]
  when "nvidia"
    ["nvidia", "N"]
  else
    ["gpu", "?"]
  end
end

def apply_performance_widget!(path, build_data)
  return unless path && File.exist?(path)

  perf = build_data["performance_widget"]
  return unless perf.is_a?(Hash) && perf["enabled"] == true

  parsed = parse_performance_results(perf["raw_results"])
  return if parsed.empty?

  order = parsed.map { |row| row[0] }
  labels = parsed.to_h { |key, label, _| [key, label] }
  data_map = parsed.to_h { |key, _, data| [key, data] }

  game_order_js = "var GAME_ORDER = [\n      " + order.map { |k| "\"#{k}\"" }.join(",\n      ") + "\n    ];"
  game_labels_js = "var GAME_LABELS = {\n" + order.map { |k| "      #{k}: \"#{escape_js_string(labels[k])}\"" }.join(",\n") + "\n    };"
  game_data_js = "var GAME_DATA = {\n" + order.map { |k| "      #{k}: #{to_js_object(data_map[k])}" }.join(",\n") + "\n    };"
  settings_js = "var SETTINGS = {\n" + order.map { |k|
    pairs = performance_settings_pairs(perf, k, data_map[k]["resolution"])
    js_pairs = pairs.map { |label, value| "[\"#{escape_js_string(label)}\", \"#{escape_js_string(value)}\"]" }.join(", ")
    "      #{k}: [#{js_pairs}]"
  }.join(",\n") + "\n    };"
  metrics_helper_js = <<~JS.chomp
    function buildMetricsHTML(gameData) {
      var metrics = [
        { label: "1080p", value: gameData.HD1080p },
        { label: "1440p", value: gameData.UltraHD1440p },
        { label: "4K", value: gameData.UHD4K }
      ].filter(function (metric) {
        return typeof metric.value === "number" && !isNaN(metric.value);
      });

      if (!metrics.length) {
        return '<article class="gw-perf-metric-pill"><p class="gw-perf-metric-label">FPS</p><p class="gw-perf-metric-value">--<span class="gw-perf-metric-unit">FPS</span></p></article>';
      }

      return metrics.map(function (metric) {
        return '<article class="gw-perf-metric-pill"><p class="gw-perf-metric-label">' + metric.label + '</p><p class="gw-perf-metric-value">' + formatFPS(metric.value) + '<span class="gw-perf-metric-unit">FPS</span></p></article>';
      }).join("");
    }
  JS
  panel_js = <<~JS.chomp
    function buildPanelHTML(panelId, gameKey, gameData) {
      return '' +
        '<article id="' + panelId + '" class="gw-perf-game-panel" role="tabpanel">' +
          '<div class="gw-perf-metric-grid">' +
            buildMetricsHTML(gameData) +
          '</div>' +
          '<button type="button" class="gw-perf-settings-toggle" aria-expanded="false">View Test Settings</button>' +
          '<div class="gw-perf-settings-body"><div class="gw-perf-settings-grid">' + buildSettingsHTML(gameKey, gameData) + '</div></div>' +
        '</article>';
    }
  JS
  driver_type = perf.dig("driver_bar", "type")
  driver_text = perf.dig("driver_bar", "driver_text")
  driver_class, driver_logo = performance_driver_class_and_logo(driver_type)
  driver_text = "Driver Version: #{driver_text}".sub(/\ADriver Version:\s*Driver Version:\s*/i, "Driver Version: ")
  driver_text = "Driver Version: ..." if blankish?(driver_text.sub(/\ADriver Version:\s*/, ""))

  content = File.read(path)
  content.sub!(%r|\.gw-perf-widget-single \.gw-perf-metric-grid \{[^}]*\}|m, '.gw-perf-widget-single .gw-perf-metric-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(160px, 1fr)); gap: 10px; margin: 0 0 10px; }')
  if content.include?("function buildMetricsHTML(gameData)")
    content.sub!(/function buildMetricsHTML\(gameData\) \{.*?\n    \}/m, metrics_helper_js)
  elsif content.include?("function buildPanelHTML(panelId, gameKey, gameData)")
    content.sub!(/function buildPanelHTML\(panelId, gameKey, gameData\) \{/m, "#{metrics_helper_js}\n\n    function buildPanelHTML(panelId, gameKey, gameData) {")
  end
  content.sub!(/function buildPanelHTML\(panelId, gameKey, gameData\) \{.*?\n    \}/m, panel_js)
  content.sub!(/var GAME_ORDER = \[.*?\];/m, game_order_js)
  content.sub!(/var GAME_LABELS = \{.*?\};/m, game_labels_js)
  content.sub!(/var GAME_DATA = \{.*?\};/m, game_data_js)
  content.sub!(/var SETTINGS = \{.*?\};/m, settings_js)
  content.sub!(%r{<div class="gw-driver-bar\s+[^"]*"><span class="gw-driver-logo">.*?</span>.*?</div>}m, %(<div class="gw-driver-bar #{driver_class}"><span class="gw-driver-logo">#{driver_logo}</span>#{escape_html(driver_text)}</div>))

  File.write(path, content)
end

def collect_incomplete_fields(section, keys)
  return [] unless section.is_a?(Hash)

  keys.select { |key| blankish?(section[key]) }
end

def section_enabled?(build_data, key)
  section = build_data[key]
  section.is_a?(Hash) && section["enabled"] == true
end

def run_quality_audit(build_data, target_dir, component_headings)
  issues = []

  motherboard = build_data["motherboard_specs"]
  case_specs = build_data["case_specs"]
  psu_specs = build_data["psu_connectors"]

  if section_enabled?(build_data, "motherboard_specs")
    missing = collect_incomplete_fields(
      motherboard,
      %w[source_url chipset_socket form_factor cpu_support memory_support_html vrm_design
         graphics_card_compatibility_1_slot expansion_card_compatibility_html
         m2_compatibility_3_slots_html sata_storage networking_html rear_io_html
         front_io_headers_html audio]
    )
    issues << "motherboard_specs incomplete fields: #{missing.join(', ')}" unless missing.empty?
  end

  if section_enabled?(build_data, "case_specs")
    source_ref = case_specs["source_ref"]
    issues << "case_specs source_ref appears malformed: #{source_ref}" if source_ref.to_s.strip.end_with?("'")
    missing = collect_incomplete_fields(
      case_specs,
      %w[source_url form_factor motherboard_support dimensions_l_w_h pcie_slots colour pre_installed_fans]
    )
    issues << "case_specs incomplete fields: #{missing.join(', ')}" unless missing.empty?
  end

  if section_enabled?(build_data, "psu_connectors")
    missing = collect_incomplete_fields(psu_specs, %w[widget_title source_url])
    issues << "psu_connectors incomplete fields: #{missing.join(', ')}" unless missing.empty?
  end

  if section_enabled?(build_data, "performance_widget")
    perf = build_data["performance_widget"]
    parsed = parse_performance_results(perf["raw_results"])
    if parsed.empty?
      issues << "performance_widget raw_results is empty or invalid"
    end
  end

  checks = [
    ["motherboard_specs", "motherboard-specs-table", component_headings["motherboard"], "motherboard widget does not include component heading value"],
    ["case_specs", "pc-case-spec-table", component_headings["case"], "case widget does not include component heading value"],
    ["psu_connectors", "psu-connector-breakdown", component_headings["psu"], "psu widget does not include component heading value"]
  ]

  build_suffix = "-#{build_data.dig("build_meta", "build_code")}.html"
  target_files = Dir.children(target_dir).select { |name| name.end_with?(".html") }
  checks.each do |section_key, needle, expected, message|
    next unless section_enabled?(build_data, section_key)
    next if blankish?(expected)

    file_name = target_files.find { |f| f.include?(needle) && f.end_with?(build_suffix) } || target_files.find { |f| f.include?(needle) }
    file = file_name ? target_dir.join(file_name).to_s : nil
    next unless file && File.exist?(file)

    content = File.read(file)
    issues << "#{message}: expected `#{expected}` in #{File.basename(file)}" unless content.include?(expected)
  end

  if section_enabled?(build_data, "performance_widget")
    perf = build_data["performance_widget"]
    expected_results = parse_performance_results(perf["raw_results"])
    expected_keys = expected_results.map(&:first)
    perf_name = target_files.find { |f| f.include?("performance-graph-widget") && f.end_with?(build_suffix) } || target_files.find { |f| f.include?("performance-graph-widget") }
    if perf_name.nil?
      issues << "missing performance widget html for enabled performance_widget section"
    else
      perf_file = target_dir.join(perf_name).to_s
      perf_content = File.read(perf_file)

      match = perf_content.match(/var GAME_ORDER = \[(.*?)\];/m)
      html_keys = if match
                    match[1].scan(/"([^"]+)"/).flatten
                  else
                    []
                  end
      issues << "performance widget GAME_ORDER does not match YAML raw_results (expected #{expected_keys.join(', ')}, got #{html_keys.join(', ')})" if html_keys != expected_keys

      driver_text = perf.dig("driver_bar", "driver_text").to_s
      issues << "performance widget driver bar did not render expected driver text" unless driver_text.empty? || perf_content.include?(driver_text)

      if perf_content.include?("Driver Version: ??") || perf_content.include?("capture build")
        issues << "performance widget driver bar still contains placeholder text"
      end

      issues << "performance widget still uses static 3-pill metric rows (expected dynamic metric scaling)" unless perf_content.include?("buildMetricsHTML(gameData)")
    end
  end

  if section_enabled?(build_data, "cooler_temps_graph")
    cooler_name = target_files.find { |f| f.include?("cooler-temps-graph") && f.end_with?(build_suffix) } || target_files.find { |f| f.include?("cooler-temps-graph") }
    if cooler_name.nil?
      issues << "missing cooler temps graph html for enabled cooler_temps_graph section"
    else
      cooler_file = target_dir.join(cooler_name).to_s
      cooler_content = File.read(cooler_file)
      title = build_data.dig("cooler_temps_graph", "title").to_s
      highlight_name = build_data.dig("cooler_temps_graph", "highlight_name").to_s
      issues << "cooler temps graph did not render expected title" unless blankish?(title) || cooler_content.include?(title)
      issues << "cooler temps graph did not render expected highlight name" unless blankish?(highlight_name) || cooler_content.include?(highlight_name)
    end
  end

  if section_enabled?(build_data, "ssd_widget")
    ssd_name = target_files.find { |f| f.include?("ssd-speed") && f.end_with?(build_suffix) } || target_files.find { |f| f.include?("ssd-speed") }
    if ssd_name.nil?
      issues << "missing ssd widget html for enabled ssd_widget section"
    else
      ssd_file = target_dir.join(ssd_name).to_s
      ssd_content = File.read(ssd_file)
      read_value = "#{format_mb_s(build_data.dig("ssd_widget", "sequential_read_mb_s"))} MB/s"
      write_value = "#{format_mb_s(build_data.dig("ssd_widget", "sequential_write_mb_s"))} MB/s"
      issues << "ssd widget did not render expected sequential read value" unless ssd_content.include?(read_value)
      issues << "ssd widget did not render expected sequential write value" unless ssd_content.include?(write_value)
    end
  end

  audit_path = target_dir.join("build-audit.txt").to_s
  if issues.empty?
    File.write(audit_path, "OK: no audit issues found.\n")
  else
    report = ["ISSUES FOUND (#{issues.length})", *issues.map { |line| "- #{line}" }].join("\n") + "\n"
    File.write(audit_path, report)
    warn "Build audit found #{issues.length} issue(s). See: #{audit_path}"
  end
end

build_code = ARGV[0]&.strip
if build_code.nil? || build_code.empty?
  warn "Usage: #{File.basename($PROGRAM_NAME)} \"[DM92]\""
  exit 2
end

script_dir = Pathname.new(__FILE__).realpath.dirname
widget_root = script_dir.parent
target_dir = widget_root.join("builds", build_code)
yaml_path = target_dir.join("#{build_code}.yaml")

unless File.directory?(target_dir)
  warn "Missing build dir: #{target_dir}"
  exit 1
end

unless File.exist?(yaml_path)
  warn "Missing build yaml: #{yaml_path}"
  exit 0
end

build_data = YAML.load_file(yaml_path.to_s)
component_headings = build_data["component_headings"] || {}

target_files = Dir.children(target_dir).select { |f| f.end_with?(".html") }
component_headings_file =
  target_files
    .find { |f| f.include?("pc-build-component-headings") && f.end_with?("-#{build_code}.html") }
parts_list_file =
  target_files
    .find { |f| f.include?("pc-build-parts-list") && f.end_with?("-#{build_code}.html") }

component_headings_file = target_dir.join(component_headings_file).to_s if component_headings_file
parts_list_file = target_dir.join(parts_list_file).to_s if parts_list_file
motherboard_file = target_files.find { |f| f.include?("motherboard-specs-table") && f.end_with?("-#{build_code}.html") }
case_file = target_files.find { |f| f.include?("pc-case-spec-table") && f.end_with?("-#{build_code}.html") }
psu_file = target_files.find { |f| f.include?("psu-connector-breakdown") && f.end_with?("-#{build_code}.html") }
ssd_file = target_files.find { |f| f.include?("ssd-speed") && f.end_with?("-#{build_code}.html") }
cooler_file = target_files.find { |f| f.include?("cooler-temps-graph") && f.end_with?("-#{build_code}.html") }

motherboard_file = target_dir.join(motherboard_file).to_s if motherboard_file
case_file = target_dir.join(case_file).to_s if case_file
psu_file = target_dir.join(psu_file).to_s if psu_file
ssd_file = target_dir.join(ssd_file).to_s if ssd_file
cooler_file = target_dir.join(cooler_file).to_s if cooler_file
performance_file = target_files.find { |f| f.include?("performance-graph-widget") && f.end_with?("-#{build_code}.html") }
performance_file = target_dir.join(performance_file).to_s if performance_file

apply_component_headings!(component_headings_file, component_headings) if component_headings_file
apply_parts_list!(parts_list_file, build_data) if parts_list_file
apply_motherboard_specs!(motherboard_file, build_data) if motherboard_file
apply_case_specs!(case_file, build_data) if case_file
apply_cooler_temps_graph!(cooler_file, build_data) if cooler_file
apply_ssd_widget!(ssd_file, build_data) if ssd_file
apply_psu_specs!(psu_file, build_data) if psu_file
apply_performance_widget!(performance_file, build_data) if performance_file
write_shortcodes!(target_dir.join("shortcodes.txt").to_s, build_data)
run_quality_audit(build_data, target_dir, component_headings)

puts "Rendered build widgets from YAML for: #{build_code}"
