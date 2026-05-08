#!/usr/bin/env bash
# Lento installer. Drops the slash command, hook, and toggle helper into ~/.claude/,
# and patches settings.json to register the PostToolUse hook.
set -euo pipefail

CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
LENTO_DIR="$CLAUDE_DIR/lento"
COMMANDS_DIR="$CLAUDE_DIR/commands"
SETTINGS="$CLAUDE_DIR/settings.json"

if [ ! -d "$CLAUDE_DIR" ]; then
  echo "Error: $CLAUDE_DIR does not exist. Is Claude Code installed?" >&2
  exit 1
fi

# Resolve the source directory. Two cases:
#   1. Running from a local checkout (install.sh sits next to skill/, hooks/, bin/).
#   2. curl | bash — no local checkout; download the tarball.
SCRIPT_PATH="${BASH_SOURCE[0]:-$0}"
if [ -f "$SCRIPT_PATH" ] && [ -d "$(dirname "$SCRIPT_PATH")/skill" ]; then
  SRC_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
  CLEANUP=""
else
  TMP=$(mktemp -d)
  CLEANUP="$TMP"
  trap '[ -n "${CLEANUP:-}" ] && rm -rf "$CLEANUP"' EXIT
  echo "Downloading Lento..."
  curl -fsSL https://github.com/drazisil/lento/archive/refs/heads/main.tar.gz \
    | tar -xz -C "$TMP"
  SRC_DIR="$TMP/lento-main"
fi

mkdir -p "$LENTO_DIR/bin" "$LENTO_DIR/hooks" "$COMMANDS_DIR"

install -m 0755 "$SRC_DIR/bin/lento"          "$LENTO_DIR/bin/lento"
install -m 0755 "$SRC_DIR/hooks/post-tool.sh" "$LENTO_DIR/hooks/post-tool.sh"
install -m 0755 "$SRC_DIR/uninstall.sh"       "$LENTO_DIR/uninstall.sh"
install -m 0644 "$SRC_DIR/skill/lento.md"     "$COMMANDS_DIR/lento.md"

HOOK_CMD="$LENTO_DIR/hooks/post-tool.sh"

if [ -f "$SETTINGS" ] && command -v jq >/dev/null 2>&1; then
  if jq -e --arg cmd "$HOOK_CMD" '
    [.hooks.PostToolUse // [] | .[] | .hooks // [] | .[]?]
    | map(select(.command == $cmd)) | length > 0
  ' "$SETTINGS" >/dev/null; then
    echo "Hook already registered in $SETTINGS"
  else
    TMP_SETTINGS=$(mktemp)
    jq --arg cmd "$HOOK_CMD" '
      .hooks //= {} |
      .hooks.PostToolUse //= [] |
      .hooks.PostToolUse += [{
        "matcher": "*",
        "hooks": [{"type": "command", "command": $cmd, "timeout": 5}]
      }]
    ' "$SETTINGS" > "$TMP_SETTINGS"
    mv "$TMP_SETTINGS" "$SETTINGS"
    echo "Patched $SETTINGS"
  fi
else
  echo "Warning: jq not found or $SETTINGS missing."
  echo "Add this PostToolUse hook manually:"
  echo "  matcher: \"*\""
  echo "  command: $HOOK_CMD"
fi

echo
echo "Lento installed."
echo "  In Claude Code:  /lento [on|off|status]"
echo "  From the shell:  $LENTO_DIR/bin/lento [on|off|status]"
echo
echo "Optional — add Lento's bin to your PATH:"
echo "  export PATH=\"\$PATH:$LENTO_DIR/bin\""
