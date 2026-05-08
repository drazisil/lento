# Lento — Claude Code adapter

This is the full-featured adapter: slash command + PostToolUse hook + state file. Claude Code is the only target where Lento gets the hook-enforced pacing; on every other agent, only the system prompt portion applies (see [other adapters](../)).

## Install — pick one path

### A) Plugin marketplace (recommended)

In Claude Code:

```
/plugin marketplace add drazisil/lento
/plugin install lento@drazisil-lento
```

That's the whole install. No shell scripts run; the source is on GitHub for you to read first. Updates and uninstall go through `/plugin` too.

### B) Clone and run (audit-then-execute)

If you'd rather not use the marketplace, or you want to hack on Lento locally:

```sh
git clone https://github.com/drazisil/lento
cd lento
# read adapters/claude-code/install.sh — it's about 50 lines
./adapters/claude-code/install.sh
```

The installer copies the slash command, hook, and toggle helper into `~/.claude/`, and patches `~/.claude/settings.json` (via `jq`) to register the PostToolUse hook. Idempotent — re-running it is safe.

**Don't install via both paths simultaneously** — you'll end up with the hook registered twice.

## Use

In Claude Code:

```
/lento on
/lento off
/lento status
```

From your shell (clone path only — adds `~/.claude/lento/bin/lento`):

```sh
~/.claude/lento/bin/lento on
~/.claude/lento/bin/lento off
~/.claude/lento/bin/lento status
```

Optional: add `~/.claude/lento/bin` to your `PATH`.

## How it works

Three small pieces:

- **`commands/lento.md`** — the slash command. Toggles state inline, then loads the Lento system prompt into the conversation.
- **`hooks/post-tool.sh`** (registered via `hooks/hooks.json`) — fires after every tool call. When the state file exists, exits with code 2 and stderr feedback that Claude Code feeds back to the model: *stop, explain, wait.*
- **State file at `~/.claude/lento/active`** — exists when Lento is on. Hook reads it on every tool call. Toggling is instant.

The system prompt does the *teaching*; the hook does the *pacing*. Both are needed — without the hook, the prompt erodes after a few turns; without the prompt, the hook is just confirmation fatigue.

## Uninstall

**Plugin path:** `/plugin uninstall lento`

**Clone path:** `~/.claude/lento/uninstall.sh`
