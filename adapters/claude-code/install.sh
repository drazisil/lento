#!/usr/bin/env bash
# Lento Claude Code adapter — clone-and-run installer.
#
# Use this if you don't want to install via the Claude Code plugin marketplace.
# Run from inside a cloned copy of the lento repository. The marketplace path
# (see README.md) is preferred — it doesn't run any shell scripts and uses
# the plugin manager for updates.
#
# Note: this clone path installs the slash commands at ~/.claude/commands/
# with `lento-` prefixes (not the `lento:` namespace), since the namespace
# scoping only applies when loaded as a plugin. Invocations on this path are
# /lento-on, /lento-off, /lento-status (no colon).
set -euo pipefail

CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
ADAPTER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LENTO_HOME="$CLAUDE_DIR/lento"
COMMANDS_DIR="$CLAUDE_DIR/commands"
SETTINGS="$CLAUDE_DIR/settings.json"

if [ ! -d "$CLAUDE_DIR" ]; then
  echo "Error: $CLAUDE_DIR does not exist. Is Claude Code installed?" >&2
  exit 1
fi

if [ ! -f "$ADAPTER_DIR/.claude-plugin/plugin.json" ]; then
  echo "Error: install.sh must be run from inside the cloned lento repository." >&2
  echo "Expected layout: <repo>/adapters/claude-code/install.sh" >&2
  exit 1
fi

mkdir -p "$LENTO_HOME/bin" "$LENTO_HOME/hooks" "$COMMANDS_DIR"

install -m 0755 "$ADAPTER_DIR/bin/lento"                   "$LENTO_HOME/bin/lento"
install -m 0755 "$ADAPTER_DIR/hooks/post-tool.sh"          "$LENTO_HOME/hooks/post-tool.sh"
install -m 0755 "$ADAPTER_DIR/hooks/pre-tool.sh"           "$LENTO_HOME/hooks/pre-tool.sh"
install -m 0755 "$ADAPTER_DIR/hooks/user-prompt-submit.sh" "$LENTO_HOME/hooks/user-prompt-submit.sh"
install -m 0755 "$ADAPTER_DIR/uninstall.sh"                "$LENTO_HOME/uninstall.sh"

# Slash commands: install with lento- prefix so they don't collide with
# unrelated commands in ~/.claude/commands/.
for cmd in on off status; do
  install -m 0644 "$ADAPTER_DIR/commands/$cmd.md" "$COMMANDS_DIR/lento-$cmd.md"
done

# Register all three Lento hooks in settings.json. Idempotent.
register_hook() {
  local event="$1" cmd="$2"
  if jq -e --arg event "$event" --arg cmd "$cmd" '
    [.hooks[$event] // [] | .[] | .hooks // [] | .[]?]
    | map(select(.command == $cmd)) | length > 0
  ' "$SETTINGS" >/dev/null; then
    echo "Hook ($event) already registered."
    return
  fi
  local tmp matcher_args
  tmp=$(mktemp)
  if [ "$event" = "UserPromptSubmit" ]; then
    jq --arg event "$event" --arg cmd "$cmd" '
      .hooks //= {} | .hooks[$event] //= [] |
      .hooks[$event] += [{
        "hooks": [{"type": "command", "command": $cmd, "timeout": 5}]
      }]
    ' "$SETTINGS" > "$tmp"
  else
    jq --arg event "$event" --arg cmd "$cmd" '
      .hooks //= {} | .hooks[$event] //= [] |
      .hooks[$event] += [{
        "matcher": "*",
        "hooks": [{"type": "command", "command": $cmd, "timeout": 5}]
      }]
    ' "$SETTINGS" > "$tmp"
  fi
  mv "$tmp" "$SETTINGS"
  echo "Registered hook: $event → $cmd"
}

if command -v jq >/dev/null 2>&1 && [ -f "$SETTINGS" ]; then
  register_hook "UserPromptSubmit" "$LENTO_HOME/hooks/user-prompt-submit.sh"
  register_hook "PreToolUse"       "$LENTO_HOME/hooks/pre-tool.sh"
  register_hook "PostToolUse"      "$LENTO_HOME/hooks/post-tool.sh"
else
  echo "Warning: jq not found or $SETTINGS missing. Add these hooks manually:"
  echo "  UserPromptSubmit (no matcher) → $LENTO_HOME/hooks/user-prompt-submit.sh"
  echo "  PreToolUse  matcher \"*\"      → $LENTO_HOME/hooks/pre-tool.sh"
  echo "  PostToolUse matcher \"*\"      → $LENTO_HOME/hooks/post-tool.sh"
fi

cat <<EOF

Lento installed (clone path).

  In Claude Code:  /lento-on, /lento-off, /lento-status
  From the shell:  $LENTO_HOME/bin/lento [on|off|status]

State files (per working directory):
  .lento-mode           — Lento on/off marker
  .lento-turn-counter   — internal turn-counter (used by hooks)

Recommended: add both filenames to your global gitignore.

For the marketplace plugin path (uses /lento:on, /lento:off, /lento:status), see:
  adapters/claude-code/README.md
EOF
