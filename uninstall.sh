#!/usr/bin/env bash
# Lento uninstaller. Removes the slash command, the hook, the state directory,
# and the PostToolUse entry from settings.json.
set -euo pipefail

CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
LENTO_DIR="$CLAUDE_DIR/lento"
COMMANDS_DIR="$CLAUDE_DIR/commands"
SETTINGS="$CLAUDE_DIR/settings.json"
HOOK_CMD="$LENTO_DIR/hooks/post-tool.sh"

if [ -f "$SETTINGS" ] && command -v jq >/dev/null 2>&1; then
  TMP_SETTINGS=$(mktemp)
  jq --arg cmd "$HOOK_CMD" '
    if .hooks?.PostToolUse then
      .hooks.PostToolUse |= (
        map(.hooks |= map(select(.command != $cmd)))
        | map(select((.hooks // []) | length > 0))
      )
    else . end
  ' "$SETTINGS" > "$TMP_SETTINGS"
  mv "$TMP_SETTINGS" "$SETTINGS"
  echo "Removed Lento hook from $SETTINGS"
fi

rm -f "$COMMANDS_DIR/lento.md"
rm -rf "$LENTO_DIR"

echo "Lento uninstalled."
