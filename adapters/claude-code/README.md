# Lento — Claude Code adapter

This is the full-featured adapter: slash commands + PostToolUse hook + state file. Claude Code is the only target where Lento gets the hook-enforced pacing; on other agents, only the system prompt portion applies (see [other adapters](../)).

## Install — pick one path

### A) Plugin marketplace (recommended)

In Claude Code:

```
/plugin marketplace add drazisil/lento
/plugin install lento@drazisil-lento
```

That's the whole install. No shell scripts run; the source is on GitHub for you to read first. Updates and uninstall go through `/plugin` too.

Invocations on this path use the plugin namespace:

```
/lento:on
/lento:off
/lento:status
```

### B) Clone and run (audit-then-execute)

If you'd rather not use the marketplace, or you want to hack on Lento locally:

```sh
git clone https://github.com/drazisil/lento
cd lento
# read adapters/claude-code/install.sh — it's about 70 lines
./adapters/claude-code/install.sh
```

The installer copies the slash commands (with a `lento-` prefix to avoid collisions), the hook, and the toggle helper into `~/.claude/`, and patches `~/.claude/settings.json` to register the PostToolUse hook. Idempotent — re-running it is safe.

Invocations on this path use the prefix instead of the namespace:

```
/lento-on
/lento-off
/lento-status
```

The functional behavior is identical — the difference is purely how Claude Code scopes user-installed commands vs. plugin-shipped commands.

**Don't install via both paths simultaneously** — you'll end up with the hook registered twice and two sets of commands.

## Use

Once installed, type the appropriate `on` / `off` / `status` command (with `:` or `-` depending on install path). From the shell, the helper takes the same words:

```sh
~/.claude/lento/bin/lento on
~/.claude/lento/bin/lento off
~/.claude/lento/bin/lento status
```

Optional: add `~/.claude/lento/bin` to your `PATH`.

## How it works

Slash commands and three hooks, all in the plugin:

- **Slash commands** (`commands/{on,off,status}.md`) — toggle `./.lento-mode` inline; `on.md` also loads the Lento system prompt into the conversation.
- **`UserPromptSubmit` hook** (`hooks/user-prompt-submit.sh`) — at the start of every user turn, resets `./.lento-turn-counter` to `0`.
- **`PreToolUse` hook** (`hooks/pre-tool.sh`) — increments the counter before every tool call. After the first tool of the turn, returns a JSON `permissionDecision: deny` that Claude Code treats as a hard block. The model literally cannot make a second tool call until you respond. (This is the load-bearing piece.)
- **`PostToolUse` hook** (`hooks/post-tool.sh`) — after the first tool call, exits 2 with stderr feedback nudging the model to explain what it learned and wait. Advisory, not enforcing — the hard enforcement is in `PreToolUse`.
- **Per-directory state files** at `./.lento-mode` (toggle) and `./.lento-turn-counter` (internal). Per-cwd because Claude Code sandboxes slash command bash to the working directory; a global state location would require user permission grants we'd rather not ask for. Per-cwd also fits the use case: you turn Lento on for the work in front of you, not as a global mode. Recommended: add both filenames to your global gitignore.

The system prompt does the *teaching*; the hook does the *pacing*. Both are needed — without the hook, the prompt erodes after a few turns; without the prompt, the hook is just confirmation fatigue.

## Uninstall

**Plugin path:** `/plugin uninstall lento`

**Clone path:** `~/.claude/lento/uninstall.sh`
