#!/usr/bin/env bash
# Lento UserPromptSubmit hook.
# Resets the per-turn tool counter at the start of every user turn so the
# PreToolUse hook can enforce "one tool per turn" cleanly.

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
STATE_FILE="$PROJECT_DIR/.lento-mode"
COUNTER_FILE="$PROJECT_DIR/.lento-turn-counter"

# Lento off → no-op.
[ ! -f "$STATE_FILE" ] && exit 0

echo "0" > "$COUNTER_FILE"
exit 0
