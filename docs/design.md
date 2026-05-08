# Lento — design

## What problem this solves

Most agentic AI tools optimize for throughput: take a task, do many steps, return a finished result. That's the right shape when the user already understands the domain and wants the work done.

It is exactly the wrong shape when the user is *learning* the domain, debugging carefully, or working in a part of a system they don't yet trust. Fast autonomous execution there makes mistakes invisible, hides the reasoning, and leaves the user no more capable than they started.

Lento is for those cases. It slows the agent to one step per turn, makes it explain what it's doing before and after, and treats every tool call as a moment to check in. The trade is throughput for understanding.

## Architecture: core + adapters

Lento has two layers:

- **`core/system-prompt.md`** — the canonical Lento mode rules. Voice, pacing, ADHD-friendly framing, predict-then-check loops. Plain markdown, portable across agents.
- **`adapters/<agent>/`** — agent-specific glue. Each adapter loads `core/system-prompt.md` (or a copy of it) into that agent's context using whatever mechanism the agent provides.

This split is honest about what's portable and what's not. The system prompt is the bulk of Lento's identity, and that travels. The hook-based pacing enforcement does not — it's specific to Claude Code's hook protocol (`UserPromptSubmit`, `PreToolUse`, `PostToolUse`).

## Why Claude Code gets full enforcement

Three layers, each doing different work:

- **System prompt** — teaching. Voice, pacing instructions, pair-programmer framing. Shapes *how* the agent talks when it's behaving.
- **`PreToolUse` hard block** — enforcement. After the first tool call of a user turn, the hook returns a JSON `permissionDecision: deny` that Claude Code treats as a hard stop. The model literally cannot make a second tool call until the user responds. This is the load-bearing piece.
- **`PostToolUse` advisory** — handoff. Exits 2 with stderr "explain what you learned, wait for the user." Not enforcement (the model can drift past stderr feedback) — it's just a nudge so the model produces a thoughtful pause rather than a silent stop.

A `UserPromptSubmit` hook resets the per-turn tool counter at the start of every turn, so `PreToolUse` can enforce one-tool-per-turn cleanly.

Other agents (Cursor, Continue, Aider) don't expose mid-conversation hook equivalents — definitely not `PreToolUse` with deny-decisions. So on those agents, Lento is system-prompt-only, and we say so plainly.

If/when other agents expose hook-like enforcement points, those adapters can level up.

## Plugin install vs. clone install (Claude Code)

The Claude Code adapter ships two install paths:

- **Plugin marketplace** (recommended). User adds `drazisil/lento` as a marketplace and enables the plugin. No shell scripts. Source is on GitHub for inspection. Updates and uninstall handled by `/plugin`.
- **Clone-and-run**. User clones the repo, reads `install.sh`, runs it. The installer copies files into `~/.claude/`, patches `settings.json` via `jq`. Used for hacking on Lento or for environments without marketplace access.

We deliberately do **not** offer a `curl | bash` install. Piping unauthenticated remote shell scripts into bash is a bad security model and we shouldn't normalize it. Both supported paths give the user a chance to read the source before executing.

## Why a state file instead of a settings.json toggle

The state file at `./.lento-mode` (in the session's working directory) is one byte (existence). Flipping it is `touch` or `rm`. The hook checks it on every tool call, so toggling takes effect on the very next tool — no reload, no race. Stuffing this into `settings.json` would mix runtime state with user configuration and would slow the toggle.

State is per-directory rather than global because Claude Code sandboxes slash command bash to the session's working directory. A global state file (e.g., `~/.local/state/lento/active`) would require the user to grant `permissions.additionalDirectories` access in their settings — not a pleasant first-run experience. Per-directory state happens to be a better fit anyway: Lento exists to slow down work on a particular task, and "this task is in this directory" is a reasonable scope.

## Why both `PreToolUse` AND `PostToolUse`

The original v0.1 design used only `PostToolUse` with exit code 2 + stderr feedback ("stop, explain, wait"). Dogfooding the architecture exposed that this isn't enforcement — it's advice. Claude Code feeds the stderr back to the model, but the model's agentic loop keeps emitting `tool_use` blocks anyway. In one test session of 266 entries, the model chained roughly 3.6 tool calls per real user input; the user had to ctrl-c three times to stop it.

The fix was to add a `PreToolUse` hook that returns the JSON shape:

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny"
  },
  "systemMessage": "..."
}
```

This format is the canonical block — verified by reading the rule engine in `anthropics/claude-code/plugins/hookify`. Claude Code treats it as a hard stop on the tool call. The model can't drift past it.

`PostToolUse` is still useful: after the *first* tool of the turn, its stderr nudge tells the model what to *do* (explain in plain language). Without it, the model would just emit another `tool_use` block, get blocked by `PreToolUse`, and the conversation would feel like hitting a wall instead of a thoughtful pause.

So: `PreToolUse` enforces, `PostToolUse` shapes the handoff. Both are needed.

## What Lento is NOT

- Not a replacement for Claude Code's permission system. Per-tool permission prompts are still the user's veto.
- Not sticky — `/lento off` returns to normal behavior on the very next turn.
- Not telemetric. Nothing leaves the user's machine.
- Not a model. Lento doesn't change which model you use, only the conversation shape.

## Open design questions

- Should there be a `lento step` command that turns Lento on for exactly one tool call, then auto-disables?
- Should the system prompt include language about a declared learning goal (`/lento on "learn how this parser works"`)? Tempting; risks getting clever.
- Multi-tier modes (lite / strict) were considered and rejected for v0.1 — too many knobs to debug. Revisit if usage shows people want a softer version.
