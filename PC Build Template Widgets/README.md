# PC Build Template Widgets

Use `PC Build Template Widgets/scripts/generate-build-widgets.sh` to batch-generate a full widget set for a build code.

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

Output folder is created at:

`PC Build Template Widgets/builds/[BUILD_CODE]/`

Widget numbering and order are controlled by:

`PC Build Template Widgets/config/widget-order.txt`

Templates used for generation live in:

`PC Build Template Widgets/templates/`

The file list and sequence are controlled by:

`PC Build Template Widgets/config/widget-order.txt`

The generator uses this order exactly, so article flow is defined line-by-line in that file.
