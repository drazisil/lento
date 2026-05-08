# Lento — Aider adapter

Aider doesn't have a hook system equivalent to Claude Code's `PostToolUse`, so this adapter is **system-prompt-only**. Pacing drifts after a handful of turns; manually re-prompt with "follow Lento mode" to reset.

If anyone figures out an Aider-side enforcement mechanism, PRs welcome.

## Install

Aider supports a `--read` flag that loads a file as context, and a project-level `.aider.conf.yml`.

**Per-invocation:**

```sh
aider --read /path/to/lento/core/system-prompt.md
```

**Project default — add to `.aider.conf.yml`:**

```yaml
read:
  - /path/to/lento/core/system-prompt.md
```

Replace `/path/to/lento/` with wherever you cloned the repo.

## Toggle

No `/lento` command. To exit Lento mode mid-session, tell the assistant: *"Stop following Lento mode for this session."* For a clean exit, restart aider without the `--read` flag.

## Limitations vs. Claude Code

- No hook enforcement; pacing drifts after several turns.
- No live toggle — controlled by aider invocation flags or config.
- Predict-then-check is best-effort, no second-pass nudge.
