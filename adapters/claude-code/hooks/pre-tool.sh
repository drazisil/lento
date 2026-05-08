#!/usr/bin/env bash
# Lento PreToolUse hook.
# Enforces "one tool call per user turn" when Lento is on. The counter is
# reset at the start of every user turn by hooks/user-prompt-submit.sh.
# After the first tool, returns a permissionDecision: deny JSON which Claude
# Code treats as a hard block (verified against anthropics/claude-code's
# hookify plugin).

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
STATE_FILE="$PROJECT_DIR/.lento-mode"
COUNTER_FILE="$PROJECT_DIR/.lento-turn-counter"

# Lento off → no-op.
[ ! -f "$STATE_FILE" ] && exit 0

# Read counter (default 0), increment, persist.
N=0
if [ -f "$COUNTER_FILE" ]; then
  N=$(cat "$COUNTER_FILE" 2>/dev/null || echo 0)
fi
N=$((N + 1))
echo "$N" > "$COUNTER_FILE"

if [ "$N" -gt 1 ]; then
  cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny"
  },
  "systemMessage": "[Lento] One tool call per user turn. Stop here, explain what you've learned so far in plain language, and wait for the user before doing anything else."
}
EOF
  exit 0
fi

# First tool of the turn — allow.
exit 0
