# PC Build Template Widgets

Use `scripts/generate-build-widgets.sh` to batch-generate a full widget set for a build code.

## Naming convention

Generated files follow this format:

`NN-widget-name-[BUILD_CODE].html`

Example:

`04-cpu-comparison-table-v1-[DM059].html`

## Commands

Default placeholder code (`[****]`):

```bash
scripts/generate-build-widgets.sh
```

Specific build code:

```bash
scripts/generate-build-widgets.sh "[DM059]"
```

Output folder is created at:

`PC Build Template Widgets/[BUILD_CODE]/`

Widget numbering and order are controlled by:

`PC Build Template Widgets/widget-order.txt`
