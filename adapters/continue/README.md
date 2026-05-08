# Lento — Continue adapter

Continue (continue.dev) supports custom prompts and rules but no equivalent of Claude Code's `PostToolUse` hook, so this adapter is **system-prompt-only**. Pacing tends to drift after a handful of turns; manually re-prompt with "follow Lento mode" to reset.

If anyone figures out a Continue-side enforcement mechanism, PRs welcome.

## Install

Copy the body of [`../../core/system-prompt.md`](../../core/system-prompt.md) into Continue's system message or rules. Two common places:

- **Workspace rules:** add the contents to `.continue/rules.md` (or whichever rules file your workspace uses).
- **Custom prompt:** create a custom prompt entry in your `config.json` whose `prompt` is the contents of `system-prompt.md`, and invoke it on demand.

## Toggle

No `/lento` command. To exit Lento mode, tell the assistant: *"Stop following Lento mode for this session."* Or remove the rules file / disable the custom prompt.

## Limitations vs. Claude Code

- No hook enforcement; pacing drifts after several turns.
- No first-class toggle — managed via configuration files.
- Predict-then-check is best-effort, no second-pass nudge.
