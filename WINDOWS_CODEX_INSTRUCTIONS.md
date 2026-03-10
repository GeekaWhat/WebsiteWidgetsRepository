# Windows 11 Codex Instructions (Match Mac Build Generation Flow)

Use these instructions in the Windows 11 Codex app so build generation behaves exactly like this repo's current workflow.

## Scope
- Repository root: `WebsiteGitRepo`
- Build system path: `PC Build Template Widgets`

## Required behavior
1. Do not hand-edit generated HTML unless explicitly asked.
2. Always generate builds by running the repository script, not by copying templates manually.
3. Always run generation from repo root with quoted paths (folder contains spaces).
4. Always run YAML-to-HTML rendering via the repo pipeline (already wired into generator).
5. Always run the repo validation step after generation (already wired into generator).
6. Never commit or push unless explicitly requested.
7. Do not stop solely because the YAML still contains placeholders somewhere in the file.
8. Fill active YAML fields from authoritative sources when the user has provided them or asked you to research them.
9. Treat placeholders in disabled or unused sections as a reporting item, not an automatic blocker.

## Execution environment (Windows 11)
- Preferred: WSL (Ubuntu) terminal in Codex app.
- Alternative: Git Bash if WSL is unavailable.
- Ruby must be available in shell PATH (`ruby --version`) because the renderer is Ruby-based.

## Canonical command
Run this from repo root:

```bash
"PC Build Template Widgets/scripts/generate-build-widgets.sh" "[DM92]"
```

Replace `"[DM92]"` with the target build code (including brackets).

## One-click Windows launcher
For Windows desktop usage, run:

```bat
generate-build-widgets-windows.bat [DM92]
```

If no build code is provided, the launcher prompts for it.
The launcher enforces the same pipeline and fails if `build-audit.txt` is missing or not clean.

## What this command must do (in order)
1. Copy templates into `PC Build Template Widgets/builds/<BUILD_CODE>/`
2. Run YAML renderer:
   - `PC Build Template Widgets/scripts/render-build-widgets.rb`
3. Run validator:
   - `PC Build Template Widgets/scripts/validate-build-widgets.sh`

## Expected success output
- `Generated <N> widget files in: ...`
- `Rendered build widgets from YAML for: [CODE]`
- `Validation passed: formatting checks succeeded for ...`

If any of the 3 messages is missing, treat generation as incomplete and fix the issue before reporting done.

## File contracts
- YAML input:
  - `PC Build Template Widgets/builds/<BUILD_CODE>/<BUILD_CODE>.yaml`
- Generated HTML:
  - `PC Build Template Widgets/builds/<BUILD_CODE>/*.html`
- Renderer-updated outputs:
  - `00-00-pc-build-component-headings-<BUILD_CODE>.html`
  - `01-01-pc-build-parts-list-<BUILD_CODE>.html`
  - `shortcodes.txt`

## Data rules
- `component_headings` controls component names.
- `parts_list` controls parts list content (name, image, alt, summary, specs, buy shortcode).
- `performance_widget.default_settings_locked` controls the per-game benchmark settings shown behind `View Test Settings`.
- Placeholder values (`"..."`, `"__AUTO_FROM_SOURCE__"`) are considered incomplete source data.
- For active widgets, replace placeholders from authoritative sources before claiming the build is complete.
- For disabled or unused widgets, placeholders may remain; report them separately instead of refusing to run the pipeline.
- Do not use a total placeholder count by itself to declare that the build was not generated.
- Do not create `missing-placeholder-keys.txt` unless the user explicitly asks for a placeholder inventory file.

## Performance widget handling
- If `performance_widget` is enabled, check `Game-Benchmark-Performance-Widget-Template.html` before finalizing the YAML.
- For games that already exist in that benchmark template, copy the full per-game settings block into `default_settings_locked`.
- Do not leave known benchmark-template games as empty arrays unless the user explicitly wants the minimal fallback.
- The fallback settings (`Resolution` + `As configured in benchmark run`) are valid renderer output but should be treated as incomplete when the benchmark template provides richer settings.

## Active vs non-blocking placeholders
- Active/blocking placeholders:
  - fields consumed by enabled widgets
  - fields needed for renderer substitutions in the generated HTML
  - fields that cause validator or audit failures
- Non-blocking placeholders:
  - fields in disabled widgets
  - fields in YAML sections the renderer does not consume for the current build

If unsure, run the generator first, inspect the rendered HTML plus `build-audit.txt`, and then decide what is still blocking.

## Verification checks (required before claiming done)
After generation, verify key values exist in the generated parts-list HTML:

```bash
rg -n "CPU:|GPU:|SSD:|Motherboard:|RAM:|Case:|PSU:" "PC Build Template Widgets/builds/[DM92]/01-01-pc-build-parts-list-[DM92].html"
```

Also verify heading widget got updated:

```bash
rg -n "<h2 class=\"gw-part-title\"" "PC Build Template Widgets/builds/[DM92]/00-00-pc-build-component-headings-[DM92].html"
```

Also verify the build audit:

```bash
cat "PC Build Template Widgets/builds/[DM92]/build-audit.txt"
```

If audit passes and validator passes, do not report `NOT generated` just because disabled sections still have placeholders.

## Repair workflow when YAML is incomplete
1. Inspect the target YAML and identify which enabled sections are still incomplete.
2. Use the user-provided article, spreadsheet, product pages, and official spec URLs to fill those active fields in the YAML.
3. Re-run the canonical generator command.
4. Check rendered HTML, validator output, and `build-audit.txt`.
5. Only after that, report any remaining placeholders in disabled or unused sections.

Do not stop at a global placeholder scan if the active build can be completed from the available sources.

## Build Workflow Example
For any build code such as `[DM79]`, `[DP061]`, or `[SR190]`, this is the expected decision process:

1. If `parts_list`, `motherboard_specs`, `ram_widget`, `ssd_widget`, `case_specs`, `psu_connectors`, or `performance_widget` still contain placeholders and those widgets are enabled, fill those active fields first from the provided article/spec links/sheets.
2. If `performance_widget` is enabled and its games appear in `Game-Benchmark-Performance-Widget-Template.html`, populate `default_settings_locked` with the full benchmark settings instead of leaving generic fallback rows.
3. If `cpu_comparison_table`, `gpu_comparison_table`, `cooler_temps_graph`, or `peripherals` are disabled or not required for the current build, their leftover placeholders should be reported but should not cause `NOT generated`.
4. Run the canonical generator anyway once active fields are in place.
5. If the generated HTML contains the correct headings/content, the validator passes, and `build-audit.txt` is clean, report the build as generated even if disabled YAML sections still contain placeholders.

Wrong behavior:
- counting all placeholders in the YAML and stopping before completing active sections
- generating HTML from fallback headings only, while leaving active `parts_list` summaries/specs blank
- leaving performance-widget settings at the generic fallback when richer settings already exist in the benchmark template
- creating `missing-placeholder-keys.txt` as a blocker artifact without user request

Correct behavior:
- complete active YAML fields
- copy full performance settings from the benchmark template for known games
- run generator
- verify rendered HTML, validator, and audit
- report remaining disabled-section placeholders separately

## False-positive audit guidance
- If a performance-widget placeholder warning appears, inspect the generated HTML and distinguish:
  - real rendered placeholder text visible in the widget
  - placeholder text inside comments or dead template examples
- If the issue is caused by template comments, fix the template source rather than editing the generated HTML by hand, unless the user explicitly asked for manual HTML edits.

## Reporting format
When complete, report:
1. Build code generated.
2. Files generated count.
3. Renderer status.
4. Validator status.
5. Audit status.
6. Remaining placeholders, split into:
   - active/blocking
   - disabled-or-unused/non-blocking

## Safety / hygiene
- Do not rename files outside the requested build unless asked.
- Do not change generator scripts unless user requests tooling changes.
- Ignore unrelated dirty files.
