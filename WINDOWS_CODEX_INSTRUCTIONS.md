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
- Placeholder values (`"..."`, `"__AUTO_FROM_SOURCE__"`) are considered incomplete source data.
- If placeholders remain in YAML, report exactly which keys are incomplete.

## Verification checks (required before claiming done)
After generation, verify key values exist in the generated parts-list HTML:

```bash
rg -n "CPU:|GPU:|SSD:|Motherboard:|RAM:|Case:|PSU:" "PC Build Template Widgets/builds/[DM92]/01-01-pc-build-parts-list-[DM92].html"
```

Also verify heading widget got updated:

```bash
rg -n "<h2 class=\"gw-part-title\"" "PC Build Template Widgets/builds/[DM92]/00-00-pc-build-component-headings-[DM92].html"
```

## Reporting format
When complete, report:
1. Build code generated.
2. Files generated count.
3. Renderer + validation success.
4. Whether placeholders still exist in YAML (yes/no + key list if yes).

## Safety / hygiene
- Do not rename files outside the requested build unless asked.
- Do not change generator scripts unless user requests tooling changes.
- Ignore unrelated dirty files.
