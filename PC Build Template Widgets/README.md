# PC Build Template Widgets

Use `PC Build Template Widgets/scripts/generate-build-widgets.sh` to batch-generate a full widget set for a build code.
Generation now includes an automatic formatting validation pass.

## Naming convention

Generated files follow this format:

`NN-widget-name-[BUILD_CODE].html`

Example:

`04-cpu-comparison-table-v1-[DM059].html`

## Commands

Default placeholder code (`[CODE]`):

```bash
"PC Build Template Widgets/scripts/generate-build-widgets.sh"
```

Specific build code:

```bash
"PC Build Template Widgets/scripts/generate-build-widgets.sh" "[DM059]"
```

Validation only:

```bash
"PC Build Template Widgets/scripts/validate-build-widgets.sh" "[DM059]"
```

Output folder is created at:

`PC Build Template Widgets/builds/[BUILD_CODE]/`

Widget numbering and order are controlled by:

`PC Build Template Widgets/config/widget-order.txt`

Templates used for generation live in:

`PC Build Template Widgets/templates/`

The file list and sequence are controlled by:

`PC Build Template Widgets/config/widget-order.txt`

The generator uses this order exactly, so article flow is defined line-by-line in that file.

## Source Of Truth

When working in this repo, treat these as the main sources of truth:

- `PC Build Template Widgets/templates/`
  The canonical HTML widget templates used by the generator.
- `PC Build Template Widgets/scripts/build_meta.yaml`
  The shared starter template for new build YAML files.
- `PC Build Template Widgets/builds/[BUILD_CODE]/[BUILD_CODE].yaml`
  The per-build YAML that drives rendered widget content for that build.

Generated HTML inside `PC Build Template Widgets/builds/[BUILD_CODE]/` is output, not the primary source of truth, unless you are intentionally making a one-off manual edit for that specific build.

## Build Codes

Build code prefixes such as `DP`, `DM`, and `SR` are meaningful identifiers and should be preserved as-is.
Do not rename or normalize them into a different scheme.

## Generated Vs Manual Edits

- Prefer editing YAML when the change should survive regeneration.
- Prefer editing template HTML when the change should apply to future builds.
- Only hand-edit generated HTML when you intentionally want a one-off build-specific change.
- Do not regenerate a build for every wording tweak by default, especially if a generated widget has already been manually refined.

## Live Cooler Graph Data

The cooler temperature graph now supports live data import from a Google Sheet CSV export during render.

Use these fields in the build YAML:

- `cooler_temps_graph.data_source_url`
  Put the Google Sheet tab URL here if you want the graph data pulled fresh during generation.
- `cooler_temps_graph.highlight_name`
  The cooler name to highlight in the graph.
- `cooler_temps_graph.cta_url`
  Optional reader-facing link if you want to point users to the source sheet.

Behavior:

- If `data_source_url` is present and the sheet can be read, the renderer will replace the cooler graph arrays with the latest sheet data.
- If the sheet fetch fails, generation still continues and the YAML cooler arrays remain as fallback data.
- The current sheet format supported by the renderer is the benchmark layout used by the GeekaWhat cooler spreadsheet:
  - `Cinebench R23 4 Threads`
  - `Cinebench 8 Threads`
  - `CPU-Z 8 Threads`

## Formatting guardrails

`generate-build-widgets.sh` will fail if required line-break formatting (`<br>`) drifts in the motherboard spec widget for these fields:

- `Memory Support`
- `Expansion Card Compatibility`
- `M.2 Compatibility (3 Slots)`
- `Networking`
- `Rear I/O`
- `Front I/O Headers`
