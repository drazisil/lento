# Lento — design

## What problem this solves

Most agentic AI tools optimize for throughput: take a task, do many steps, return a finished result. That's the right shape when the user already understands the domain and wants the work done.

It is exactly the wrong shape when the user is *learning* the domain, debugging carefully, or working in a part of a system they don't yet trust. Fast autonomous execution there makes mistakes invisible, hides the reasoning, and leaves the user no more capable than they started.

Lento is for those cases. It slows the agent to one step per turn, makes it explain what it's doing before and after, and treats every tool call as a moment to check in. The trade is throughput for understanding.

## Architecture: core + adapters

Lento has two layers:

- **`core/system-prompt.md`** — the canonical Lento mode rules. Voice, pacing, ADHD-friendly framing, predict-then-check loops. Plain markdown, portable across agents.
- **`adapters/<agent>/`** — agent-specific glue. Each adapter loads `core/system-prompt.md` (or a copy of it) into that agent's context using whatever mechanism the agent provides.

This split is honest about what's portable and what's not. The system prompt is the bulk of Lento's identity, and that travels. The hook-based pacing enforcement does not — it's specific to Claude Code's `PostToolUse` hook protocol.

## Why Claude Code gets full enforcement

The system prompt does the teaching. The hook does the pacing.

Without the hook, the system prompt erodes within five or six turns: the model starts chaining tool calls again, batching steps, treating "explain after" as optional. With the hook, every tool call is followed by a stderr nudge that Claude Code feeds back to the model — re-anchoring it.

Other agents (Cursor, Continue, Aider) don't expose a mid-conversation hook equivalent. So on those agents, Lento is system-prompt-only, and we say so plainly.

If/when other agents expose hook-like enforcement points, those adapters can level up.

## Plugin install vs. clone install (Claude Code)

The Claude Code adapter ships two install paths:

- **Plugin marketplace** (recommended). User adds `drazisil/lento` as a marketplace and enables the plugin. No shell scripts. Source is on GitHub for inspection. Updates and uninstall handled by `/plugin`.
- **Clone-and-run**. User clones the repo, reads `install.sh`, runs it. The installer copies files into `~/.claude/`, patches `settings.json` via `jq`. Used for hacking on Lento or for environments without marketplace access.

We deliberately do **not** offer a `curl | bash` install. Piping unauthenticated remote shell scripts into bash is a bad security model and we shouldn't normalize it. Both supported paths give the user a chance to read the source before executing.

## Why a state file instead of a settings.json toggle

The state file at `~/.claude/lento/active` is one byte (existence). Flipping it is `touch` or `rm`. The hook checks it on every tool call, so toggling takes effect on the very next tool — no reload, no race. Stuffing this into `settings.json` would mix runtime state with user configuration and would slow the toggle.

## Why a PostToolUse hook, not a PreToolUse hook

`PreToolUse` fires *before* the tool runs and would have to either block (interrupting the user's intent) or be a no-op. `PostToolUse` fires after the tool returns and lets the model see the actual result. We want the model to react to the result *and then stop*, which is exactly what `PostToolUse` with exit code 2 does — Claude Code feeds the stderr back to the model, the model integrates the feedback, and the turn ends naturally.

## What Lento is NOT

- Not a replacement for Claude Code's permission system. Per-tool permission prompts are still the user's veto.
- Not sticky — `/lento off` returns to normal behavior on the very next turn.
- Not telemetric. Nothing leaves the user's machine.
- Not a model. Lento doesn't change which model you use, only the conversation shape.

## Open design questions

- Should there be a `lento step` command that turns Lento on for exactly one tool call, then auto-disables?
- Should the system prompt include language about a declared learning goal (`/lento on "learn how this parser works"`)? Tempting; risks getting clever.
- Multi-tier modes (lite / strict) were considered and rejected for v0.1 — too many knobs to debug. Revisit if usage shows people want a softer version.
