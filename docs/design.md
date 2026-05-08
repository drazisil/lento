# Lento — design

## What problem this solves

Most agentic AI tools optimize for throughput: take a task, do many steps, return a finished result. That's the right shape when the user already understands the domain and wants the work done.

It is exactly the wrong shape when the user is *learning* the domain, debugging carefully, or working in a part of a system they don't yet trust. Fast autonomous execution there makes mistakes invisible, hides the reasoning, and leaves the user no more capable than they started.

Lento is for those cases. It slows the agent to one step per turn, makes it explain what it's doing before and after, and treats every tool call as a moment to check in. The trade is throughput for understanding.

## What it is, mechanically

Lento is three small files plus a `settings.json` patch:

- A slash command `/lento` (in `~/.claude/commands/lento.md`) that toggles a state file and loads the Lento system prompt into the conversation.
- A PostToolUse hook (in `~/.claude/lento/hooks/post-tool.sh`) that fires after every tool call. When Lento is on, it returns feedback to the model: stop, explain, wait.
- A toggle script (`~/.claude/lento/bin/lento`) that flips the state file, callable from the shell or via the slash command.

That's the whole thing. No new agent, no new runtime, no proxy, no daemon. It rides on top of Claude Code.

## Why both a system prompt AND a hook

The **system prompt** does the teaching — voice, pacing instructions, pair-programmer framing. It carries most of the behavior on a fresh turn.

The **hook** does the enforcement. It catches the model when it starts to drift back into chained-tool habits, which happens after a few turns even with a strong prompt. The hook's stderr feedback gets fed straight back to the model and re-anchors it.

Without the hook, the system prompt erodes within five or six turns. Without the system prompt, the hook is just noisy confirmation fatigue. Both are needed; neither alone is enough.

## What Lento is NOT

- **Not a replacement for the permission system.** Claude Code's existing per-tool permission prompts are still the user's veto. Lento doesn't try to gate tools; it gates the *next-step decision* between tools.
- **Not sticky.** `/lento off` returns to normal behavior on the very next turn. No reload, no restart.
- **Not telemetric.** Nothing leaves the user's machine. Nothing writes outside `~/.claude/lento/` and the one settings.json patch.
- **Not a model.** Lento doesn't change which model Claude Code uses or how it talks to the API. It only changes the conversation shape.

## Why a state file instead of a settings toggle

The state file is one byte (existence). Flipping it is `touch` or `rm`. The hook checks it on every tool call, so toggling takes effect on the very next tool — no reload, no race. Stuffing this into `settings.json` would mix runtime state with user configuration and would slow the toggle.

## Why a PostToolUse hook, not a PreToolUse hook

PreToolUse fires *before* the tool runs and would have to either block (interrupting the user's intent) or be a no-op. PostToolUse fires after the tool returns and lets the model see the actual result. We want the model to react to the result *and then stop*, which is exactly what PostToolUse with exit code 2 does — Claude Code feeds the stderr back to the model, the model integrates the feedback, and the turn ends naturally.

## Open design questions

- Should there be a `lento step` command that turns Lento on for exactly one tool call, then auto-disables? Possibly useful for "I want one careful step in the middle of a fast workflow."
- Should the system prompt include language about the user's specific learning goals if they declare one (`/lento on "learn how this parser works"`)? Tempting; risks getting too clever.
- A multi-tier mode (lite / strict) was considered and rejected for v0.1 — too many knobs to debug. Revisit if usage shows people want a softer version.
