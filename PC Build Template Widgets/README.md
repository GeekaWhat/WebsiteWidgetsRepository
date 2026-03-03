# PC Build Template Widgets

Use `PC Build Template Widgets/scripts/generate-build-widgets.sh` to batch-generate a full widget set for a build code.
Generation now includes an automatic formatting validation pass.

## Naming convention

Generated files follow this format:

`NN-widget-name-[BUILD_CODE].html`

Example:

`04-cpu-comparison-table-v1-[DM059].html`

## Commands

Default placeholder code (`[****]`):

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

## Formatting guardrails

`generate-build-widgets.sh` will fail if required line-break formatting (`<br>`) drifts in the motherboard spec widget for these fields:

- `Memory Support`
- `Expansion Card Compatibility`
- `M.2 Compatibility (3 Slots)`
- `Networking`
- `Rear I/O`
- `Front I/O Headers`
