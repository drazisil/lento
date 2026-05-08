# Lento

> A slow, ADHD-friendly pair-programming mode for AI coding agents. Lento tells the agent to take one step, explain what just happened, and wait for you before moving on.

## What it does

When Lento is on:

- **One step at a time.** The agent makes one tool call — read, edit, run — and stops.
- **Says what it's about to do, before it does it.** And invites you to predict the outcome or push back.
- **Says what just happened, after.** No silent chains.
- **Waits for you.** Every step gets your eyes on it before the agent moves on.

It's optimized for *understanding*, not throughput. Use it when you're learning something new, debugging carefully, or working in a part of a system you don't yet trust.

## Repo layout

```
core/system-prompt.md     The portable Lento system prompt — voice, pacing, ADHD-friendly framing.
                          This is the canonical text every adapter loads.
adapters/
  claude-code/            Full version: slash commands + PostToolUse hook + state file.
                          Hook enforcement keeps pacing from drifting after a few turns.
  cursor/                 System-prompt-only. Drop core/system-prompt.md into .cursorrules.
  continue/               System-prompt-only. Add to Continue rules or custom prompts.
  aider/                  System-prompt-only. Use --read or .aider.conf.yml.
docs/
  design.md               What Lento is, why it's shaped this way.
  pedagogy.md             Voice principles the system prompt encodes.
```

## Install — pick your agent

| Agent       | Install path                                         | Enforcement | Invocations |
|-------------|------------------------------------------------------|-------------|-------------|
| Claude Code | [`adapters/claude-code/`](adapters/claude-code/)     | Full (slash + hook) | `/lento:on`, `/lento:off`, `/lento:status` |
| Cursor      | [`adapters/cursor/`](adapters/cursor/)               | Prompt-only | (rules file; no toggle) |
| Continue    | [`adapters/continue/`](adapters/continue/)           | Prompt-only | (rules file; no toggle) |
| Aider       | [`adapters/aider/`](adapters/aider/)                 | Prompt-only | (`--read` flag; no live toggle) |

**Claude Code is the only adapter with full enforcement.** It's the only target with a mid-conversation hook system that lets us re-anchor pacing after every tool call. On other agents, the system prompt erodes after a handful of turns; you can manually re-prompt to reset it.

If you use an agent not listed here and you'd like to add an adapter, open an issue or PR.

## How it works

Two components, both lightweight:

1. **The system prompt** ([`core/system-prompt.md`](core/system-prompt.md)) does the *teaching* — voice, pacing rules, pair-programmer framing, predict-then-check loops. It carries most of Lento's identity and is portable across agents.

2. **The PostToolUse hook** (Claude Code only) does the *pacing*. After every tool call, it tells the model: stop, explain, wait. This is what stops drift after a few turns.

Both are needed for the full effect. Without the hook, the system prompt erodes. Without the system prompt, the hook is just confirmation fatigue.

See [docs/design.md](docs/design.md) for more.

## License

MIT — see [LICENSE](LICENSE).
