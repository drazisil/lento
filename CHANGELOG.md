# Changelog

All notable changes to Lento are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and Lento adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-05-08

### Added

- Slash command `/lento` (toggles mode and loads the Lento system prompt).
- PostToolUse hook that injects "stop, explain, wait" feedback after every tool call when Lento is on.
- `bin/lento` shell helper (`on` | `off` | `status`) backing a state file at `~/.claude/lento/active`.
- `install.sh` and `uninstall.sh` for one-line setup and removal.
- Pedagogical system prompt: pair-programmer voice, ADHD-friendly chunking, predict-then-check loops, reframing over re-explaining.
- `docs/design.md` and `docs/pedagogy.md`.

[Unreleased]: https://github.com/drazisil/lento/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/drazisil/lento/releases/tag/v0.1.0
