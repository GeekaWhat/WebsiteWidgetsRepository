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
6. If placeholders remain in source YAML (`"..."` or `"__AUTO_FROM_SOURCE__"`), report incomplete keys instead of claiming fully populated output.
7. Never `git commit` or `git push` unless the user explicitly asks.

## Windows 11 Codex Notes

- Preferred shell: WSL Bash.
- Acceptable fallback: Git Bash.
- Ruby must be available in PATH for YAML rendering.
- Additional operating instructions: `WINDOWS_CODEX_INSTRUCTIONS.md`.
