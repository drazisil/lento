# Changelog

All notable changes to Lento are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and Lento adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-05-08

### Added

- **`core/system-prompt.md`** — portable system prompt encoding the Lento voice and pacing rules. Single source of truth that every adapter loads.
- **Claude Code adapter** at `adapters/claude-code/`, full-featured:
  - Plugin manifest (`.claude-plugin/plugin.json`) for marketplace install.
  - Slash command `/lento [on|off|status]` (toggles inline, loads system prompt).
  - PostToolUse hook (`hooks/post-tool.sh` + `hooks/hooks.json`) that injects "stop, explain, wait" feedback after every tool call when Lento is on.
  - `bin/lento` shell helper.
  - `install.sh` / `uninstall.sh` for clone-and-run installs (no `curl | bash`).
- **Stub adapters** for Cursor, Continue, and Aider — README per agent explaining how to load `core/system-prompt.md` into that tool. System-prompt-only; no hook enforcement.
- `docs/design.md`, `docs/pedagogy.md`, MIT license.

[Unreleased]: https://github.com/drazisil/lento/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/drazisil/lento/releases/tag/v0.1.0
