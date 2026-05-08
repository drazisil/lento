# Lento

> A slow, ADHD-friendly Claude Code mode. Lento turns Claude Code into a pair programmer that takes one step, explains what just happened, and waits for you before doing anything else.

## What it does

When `/lento` is on:

- **One step at a time.** The agent makes one tool call — read, edit, run — and stops.
- **Says what it's about to do, before it does it.** And invites you to predict the outcome or push back.
- **Says what just happened, after.** No silent chains.
- **Waits for you.** Every step goes through Claude Code's normal permission prompt.

It's optimized for *understanding*, not throughput. Use it when you're learning something new, debugging carefully, or working in a part of a system you don't yet trust.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/drazisil/lento/main/install.sh | bash
```

Requires Claude Code already installed (the installer writes into `~/.claude/`). `jq` is recommended for the settings.json patch; the installer falls back to manual instructions if `jq` is missing.

## Use

Inside Claude Code:

```
/lento on
/lento off
/lento status
```

From your shell (after install adds `~/.claude/lento/bin` to your PATH, or via the full path):

```sh
lento on
lento off
lento status
```

## How it works

Three small pieces, all under `~/.claude/`:

1. **Slash command** at `~/.claude/commands/lento.md` — toggles state and loads the Lento system prompt (pair-programmer voice, one-step-then-pause, ADHD-friendly chunking, ready for pushback or reframing).
2. **PostToolUse hook** at `~/.claude/lento/hooks/post-tool.sh` — fires after every tool call. When Lento is on, it tells the model: stop, explain what just happened, wait for the user. This is what stops drift after a few turns.
3. **State file** at `~/.claude/lento/active` — exists when Lento is on, absent when it's off. The hook reads it on every tool call, so toggling is instant.

The system prompt does the *teaching*. The hook does the *pacing*. Both are needed; neither alone is enough.

See [docs/design.md](docs/design.md) for the longer story and [docs/pedagogy.md](docs/pedagogy.md) for the voice principles the system prompt encodes.

## Uninstall

```sh
~/.claude/lento/uninstall.sh
```

Removes the slash command, the hook, the state directory, and the settings.json patch.

## License

MIT — see [LICENSE](LICENSE).
