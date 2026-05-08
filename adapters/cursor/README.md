# Lento — Cursor adapter

Cursor doesn't have a mid-conversation hook system equivalent to Claude Code's `PostToolUse`, so this adapter is **system-prompt-only**. The pacing instructions tend to drift after a handful of turns without the hook to re-anchor. You can manually re-prompt with "follow Lento mode" to reset.

If anyone figures out a Cursor-side enforcement mechanism, PRs welcome.

## Install

Copy the body of [`../../core/system-prompt.md`](../../core/system-prompt.md) into Cursor's project rules:

- **Project rules:** create `.cursorrules` at your project root and paste the contents.
- **Global rules:** Cursor Settings → Rules for AI → paste the contents.

That's it. No scripts, no patching.

## Toggle

There's no toggle — the rules apply whenever loaded. To turn Lento "off" for a session, tell the assistant: *"Stop following Lento mode for this session."*

## Limitations vs. Claude Code

- No hook enforcement; pacing drifts after several turns.
- No `/lento` command — turning Lento on/off means editing the rules file or telling the assistant in chat.
- The "predict-then-check" loop depends entirely on the model, with no second-pass nudge.
