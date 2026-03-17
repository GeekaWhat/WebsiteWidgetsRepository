# AGENTS

## Cross-Platform Build Generation (macOS + Windows 11)

These rules apply to all Codex runs in this repository.

1. Always generate builds via:
   - `"PC Build Template Widgets/scripts/generate-build-widgets.sh" "[BUILD_CODE]"`
2. Do not manually copy template files to build folders.
3. Do not hand-edit generated HTML unless explicitly requested.
4. The generation flow must include (in this order):
   - template copy
   - YAML render pass (`PC Build Template Widgets/scripts/render-build-widgets.rb`)
   - validation (`PC Build Template Widgets/scripts/validate-build-widgets.sh`)
5. Treat generation as successful only if output includes:
   - `Generated <N> widget files in: ...`
   - `Rendered build widgets from YAML for: [CODE]`
   - `Validation passed: formatting checks succeeded for ...`
6. Placeholder handling:
   - Placeholders in active fields should be filled before claiming the build is complete.
   - Placeholders in disabled or unused sections are not, by themselves, a blocker to running the generator.
   - If placeholders remain after generation, report them separately and distinguish active/blocking placeholders from disabled-or-unused placeholders.
7. If the user provides a source article, spreadsheet, official spec URL, or explicitly asks Codex to research missing values, Codex should populate the active YAML fields from those authoritative sources instead of stopping at placeholder detection.
8. Do not treat a raw placeholder count as the primary success/failure signal. The primary checks are:
   - canonical generator output
   - rendered HTML content for active widgets
   - validation result
   - build audit result
9. Performance widget rule:
   - If `performance_widget` is enabled and the games appear in `Game-Benchmark-Performance-Widget-Template.html`, copy the full per-game settings block into YAML.
   - Do not treat empty `default_settings_locked` arrays for known benchmark-template games as complete.
   - The generic fallback (`Resolution` + `As configured in benchmark run`) is a last resort only.
10. If generated HTML passes validation/audit but some disabled sections still contain placeholders, report the remaining placeholders without saying the build was not generated.
11. Never create sidecar blocker files such as `missing-placeholder-keys.txt` unless the user explicitly asks for them.
12. Never `git commit` or `git push` unless the user explicitly asks.

## Windows 11 Codex Notes

- Preferred shell: WSL Bash.
- Acceptable fallback: Git Bash.
- Ruby must be available in PATH for YAML rendering.
- Additional operating instructions: `docs/windows/WINDOWS_CODEX_INSTRUCTIONS.md`.
