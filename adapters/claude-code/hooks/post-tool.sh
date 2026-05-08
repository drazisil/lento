#!/usr/bin/env bash
# Lento PostToolUse hook.
# When the state file exists in the project working directory, exit 2 with
# stderr feedback that Claude Code feeds back to the model — forcing a pause
# after every tool call. When the state file is absent, this hook is a
# no-op (exit 0).

# Claude Code sets CLAUDE_PROJECT_DIR for hooks; fall back to PWD.
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
STATE_FILE="${LENTO_STATE_FILE:-$PROJECT_DIR/.lento-mode}"

if [ ! -f "$STATE_FILE" ]; then
  exit 0
fi

cat >&2 <<'EOF'
[Lento] Stop here. Before any further action:
  1. Say in plain language what this tool returned (one or two sentences).
  2. Say what you learned and how it changes the plan.
  3. Wait for the user to respond.

Do not chain another tool call in this turn.
EOF
exit 2
