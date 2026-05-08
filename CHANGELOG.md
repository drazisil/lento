# Changelog

All notable changes to Lento are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and Lento adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- **"Show the work, in plain language" rule** in the system prompt (and mirrored in the slash command body). Before running a non-trivial shell pipeline, regex, embedded script (Python heredoc, awk program, jq filter), or multi-step edit, the agent walks through the *shape* of the command — each pipeline stage, what any regex matches, what an embedded script's loop is doing, assumptions about input — so the user can predict the effect without reading man pages. Marked **non-negotiable** and explicitly extended to retries: "yes" / "try again" / "go ahead" waive the question, not the explanation. Plus a "prefer the simplest reasonable command" preference, so clever one-liners stay rare. Added after dogfooding showed the agent generating opaque pipelines on coarse-grained "yes" answers, then iterated after a Python heredoc retry skipped the explanation.
- **`PreToolUse` hard-block hook** (`hooks/pre-tool.sh`). Increments a per-turn counter; after the first tool call of a user turn, returns `{"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny"}}` — verified format from the `anthropics/claude-code/plugins/hookify` plugin. The model is hard-blocked from chaining a second tool call within a turn. This is the load-bearing enforcement.
- **`UserPromptSubmit` hook** (`hooks/user-prompt-submit.sh`). Resets the turn counter to `0` at the start of every user turn so `PreToolUse` can enforce one-tool-per-turn cleanly.
- **`./.lento-turn-counter`** state file (per-cwd, alongside `.lento-mode`). Used by the two new hooks; recommended to gitignore.

### Changed

- Split the single `/lento` slash command into three: `on`, `off`, `status`. Plugin commands are namespaced as `/<plugin>:<command>`, so a single command at `commands/lento.md` was registering as the awkward `/lento:lento`. The split gives clean invocations: `/lento:on`, `/lento:off`, `/lento:status`. Clone-path installs use `/lento-on` etc.
- Each slash command now uses single, unchained `!` bash blocks. Claude Code's permission system splits compound commands (with `&&`) into parts and rejects them when individual parts aren't pre-approved by `allowed-tools`.
- **State file moved to `./.lento-mode` in the session's working directory** (per-cwd, not global). Claude Code sandboxes slash command bash to the working directory; a global state file would need `permissions.additionalDirectories` granted by the user. Per-cwd is also semantically cleaner: Lento applies to the work in front of you. Binaries installed by the clone path still live at `~/.claude/lento/bin/` and `~/.claude/lento/hooks/`. Recommended: add `.lento-mode` to global gitignore.
- **`PostToolUse` hook is now advisory only.** Dogfooding showed that stderr feedback alone is treated as a hint, not a hard stop — the model continued chaining tool calls. Hard enforcement moved to `PreToolUse`. `PostToolUse` still fires (exits 2 with "stop, explain, wait" stderr) to nudge the model toward a thoughtful pause; the deny is in `PreToolUse`.
- Updated install.sh and uninstall.sh to register / unregister all three hook entries idempotently.
- Updated all docs (root README, adapter README, MANUAL-TEST, design.md, system prompt off-switch reference) to use the new invocations, state path, and three-hook architecture.

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
