#!/usr/bin/env bash
# Lento Claude Code adapter — uninstaller for the clone-and-run install path.
# Removes the slash commands, the hooks, the binaries, and all Lento entries
# from settings.json.
#
# Note: per-directory `.lento-mode` and `.lento-turn-counter` files are NOT
# removed. They are benign empty/tiny files; users can:
#   find . -name '.lento-mode' -o -name '.lento-turn-counter' -delete
# to clean up.
set -euo pipefail

CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
LENTO_HOME="$CLAUDE_DIR/lento"
COMMANDS_DIR="$CLAUDE_DIR/commands"
SETTINGS="$CLAUDE_DIR/settings.json"

unregister_hook() {
  local event="$1" cmd="$2"
  [ -f "$SETTINGS" ] || return 0
  command -v jq >/dev/null 2>&1 || return 0
  local tmp
  tmp=$(mktemp)
  jq --arg event "$event" --arg cmd "$cmd" '
    if .hooks?[$event] then
      .hooks[$event] |= (
        map(.hooks |= map(select(.command != $cmd)))
        | map(select((.hooks // []) | length > 0))
      )
    else . end
  ' "$SETTINGS" > "$tmp"
  mv "$tmp" "$SETTINGS"
}

unregister_hook "UserPromptSubmit" "$LENTO_HOME/hooks/user-prompt-submit.sh"
unregister_hook "PreToolUse"       "$LENTO_HOME/hooks/pre-tool.sh"
unregister_hook "PostToolUse"      "$LENTO_HOME/hooks/post-tool.sh"
echo "Removed Lento hook entries from $SETTINGS"

for cmd in on off status; do
  rm -f "$COMMANDS_DIR/lento-$cmd.md"
done
rm -rf "$LENTO_HOME"

echo "Lento uninstalled."
echo "Note: any .lento-mode and .lento-turn-counter files in project directories were left in place."
