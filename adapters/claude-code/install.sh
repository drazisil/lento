#!/usr/bin/env bash
# Lento Claude Code adapter — clone-and-run installer.
#
# This is the non-marketplace install path. Run it from inside a cloned copy
# of the lento repository. For the cleaner plugin-marketplace install, see
# README.md — that path doesn't run any shell scripts.
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

install -m 0755 "$ADAPTER_DIR/bin/lento"          "$LENTO_HOME/bin/lento"
install -m 0755 "$ADAPTER_DIR/hooks/post-tool.sh" "$LENTO_HOME/hooks/post-tool.sh"
install -m 0755 "$ADAPTER_DIR/uninstall.sh"       "$LENTO_HOME/uninstall.sh"
install -m 0644 "$ADAPTER_DIR/commands/lento.md"  "$COMMANDS_DIR/lento.md"

HOOK_CMD="$LENTO_HOME/hooks/post-tool.sh"

if command -v jq >/dev/null 2>&1 && [ -f "$SETTINGS" ]; then
  if jq -e --arg cmd "$HOOK_CMD" '
    [.hooks.PostToolUse // [] | .[] | .hooks // [] | .[]?]
    | map(select(.command == $cmd)) | length > 0
  ' "$SETTINGS" >/dev/null; then
    echo "Hook already registered in $SETTINGS"
  else
    TMP=$(mktemp)
    jq --arg cmd "$HOOK_CMD" '
      .hooks //= {} |
      .hooks.PostToolUse //= [] |
      .hooks.PostToolUse += [{
        "matcher": "*",
        "hooks": [{"type": "command", "command": $cmd, "timeout": 5}]
      }]
    ' "$SETTINGS" > "$TMP"
    mv "$TMP" "$SETTINGS"
    echo "Patched $SETTINGS"
  fi
else
  echo "Warning: jq not found or $SETTINGS missing."
  echo "Add this PostToolUse hook manually:"
  echo "  matcher: \"*\""
  echo "  command: $HOOK_CMD"
fi

cat <<EOF

Lento installed (clone path).

  In Claude Code:  /lento [on|off|status]
  From the shell:  $LENTO_HOME/bin/lento [on|off|status]

For the marketplace plugin path (no shell script needed), see:
  adapters/claude-code/README.md
EOF
