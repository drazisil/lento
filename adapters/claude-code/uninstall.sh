#!/usr/bin/env bash
# Lento Claude Code adapter — uninstaller for the clone-and-run install path.
# Removes the slash command, the hook, the state directory, and the
# PostToolUse entry from settings.json.
set -euo pipefail

CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
LENTO_HOME="$CLAUDE_DIR/lento"
COMMANDS_DIR="$CLAUDE_DIR/commands"
SETTINGS="$CLAUDE_DIR/settings.json"
HOOK_CMD="$LENTO_HOME/hooks/post-tool.sh"

if [ -f "$SETTINGS" ] && command -v jq >/dev/null 2>&1; then
  TMP=$(mktemp)
  jq --arg cmd "$HOOK_CMD" '
    if .hooks?.PostToolUse then
      .hooks.PostToolUse |= (
        map(.hooks |= map(select(.command != $cmd)))
        | map(select((.hooks // []) | length > 0))
      )
    else . end
  ' "$SETTINGS" > "$TMP"
  mv "$TMP" "$SETTINGS"
  echo "Removed Lento hook from $SETTINGS"
fi

rm -f "$COMMANDS_DIR/lento.md"
rm -rf "$LENTO_HOME"

echo "Lento uninstalled."
