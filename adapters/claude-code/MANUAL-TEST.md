# Lento — manual test checklist

Run through this before tagging a release of the Claude Code adapter. It's structured to mirror Lento's own ethos: predict-then-check loops, headline first, one phase at a time. If anything fails, note which phase and step — that's the bug report.

> **Invocation note.** This checklist assumes the **plugin marketplace install path**, where commands are namespaced as `/lento:on`, `/lento:off`, `/lento:status`. If you installed via the clone path (`install.sh`), substitute `/lento-on`, `/lento-off`, `/lento-status` (hyphen, no colon) throughout. Behavior is identical.

## Setup

In a fresh terminal, in a scratch directory you don't mind the agent poking at:

```sh
mkdir -p /tmp/lento-test
cd /tmp/lento-test
echo "hello" > a.txt && echo "world" > b.txt && echo "third" > c.txt

# Make sure no leftover state from prior runs:
rm -f /tmp/lento-test/.lento-mode

# Launch Claude Code with the plugin loaded:
claude --plugin-dir /data/Code/lento/adapters/claude-code
```

You're now in an interactive Claude Code session with the Lento adapter loaded. Each phase below is a small interaction; don't combine them.

---

## Phase 1 — Toggle mechanics

These don't require the model to behave any particular way; they just verify the slash commands and state file work.

### 1.1 — Default state is off

**Predict:** what should `/lento:status` say in a fresh session?

**Run:** `/lento:status`

**Look for:** output line `Lento: off`. The state file `/tmp/lento-test/.lento-mode` should not exist.

**Verify state file (in a separate shell):** `ls /tmp/lento-test/.lento-mode 2>&1` → should say "No such file or directory".

### 1.2 — Turn on

**Run:** `/lento:on`

**Look for:** `Lento: on` in the output. State file `/tmp/lento-test/.lento-mode` now exists.

### 1.3 — Status while on

**Run:** `/lento:status`

**Look for:** `Lento: on`.

### 1.4 — Turn off

**Run:** `/lento:off`

**Look for:** `Lento: off`. State file is gone.

**Failure modes to flag:** wrong output text, state file in the wrong place, slash command not found.

---

## Phase 2 — Hook fires when Lento is on

### 2.1 — One-tool task

**Run first:** `/lento:on`

**Predict:** when the agent reads a file, what should happen *after* the file content comes back?

**Prompt:** `read /tmp/lento-test/a.txt`

**Look for:**
- Agent reads the file (one tool call).
- Agent's response after the read describes what was returned and what it means.
- Agent does **not** chain a second tool call ("let me also...") in the same turn.
- Agent's response invites you to react / asks what to do next.

**Failure modes:** agent chains multiple reads, agent says nothing about the file content, agent silently moves on.

### 2.2 — Hook stderr (sanity check)

The hook output isn't always shown directly, but its effect should be visible: the model behaves like it just got a "stop, explain, wait" instruction. If you have access to the Claude Code session log (`~/.claude/sessions/...`), you can grep for `[Lento]` to see the actual hook firing — but behavior change is the real signal.

---

## Phase 3 — Multi-step pacing (the main thing)

### 3.1 — A task that *would* normally chain

**Run first:** `/lento:status` (confirm: on)

**Predict:** without Lento, how many tool calls would Claude Code probably make to answer this prompt?

**Prompt:** `explore /tmp/lento-test and tell me what's there`

**Look for (Lento behavior):**
- Agent explains the plan first ("we'll start with `ls`...") before any tool call.
- **One** tool call this turn (probably `ls`).
- Agent explains what `ls` returned in plain language.
- Agent stops and asks if you want to dig into a specific file.

**Failure mode (drift):** agent runs `ls` then `cat a.txt` then `cat b.txt` etc. in one turn. That's the failure case the hook is supposed to prevent.

### 3.2 — Continue one step at a time

**Prompt:** `let's look at a.txt`

**Look for:**
- One read.
- Plain-language description after.
- Stop, wait.

### 3.3 — Five turns in, does it still pace?

Continue the conversation for several more turns ("now b.txt", "now c.txt", "compare them"). The drift test: does Lento still take one step per turn at turn 5+, or has it started chaining again?

**This is the load-bearing test.** Without the `PreToolUse` hard-block, the system prompt typically erodes around turn 5. If pacing holds at turn 8+, the hook is doing its job.

### 3.4 — Hard-block in action

**Predict:** what *should* the system do if the model tries to make a second tool call in a single user turn?

**Setup:** make sure Lento is on (`/lento:on`). Then ask the agent something it'll be tempted to chain on, e.g.:

**Prompt:** `read all three files and tell me what's in them`

**Look for:**
- Agent reads one file (e.g., `a.txt`).
- Agent describes the contents and stops.
- Agent does **not** read `b.txt` or `c.txt` in the same turn.

If the agent attempts a second tool call, you should see (visible or behaviorally evident) a `permissionDecision: deny` response with reason `[Lento] One tool call per user turn…` That's `PreToolUse` doing its job.

**Verify counter file (in another shell while a turn is in flight):**
`cat /tmp/lento-test/.lento-turn-counter` should show `1` after the first tool call. After your next prompt, it should reset to `0` (then increment to `1` again on the next tool).

**Failure mode:** the agent successfully chains. Means either the hook isn't registered (`claude plugin validate` should pass), the `permissionDecision: deny` isn't being honored (Claude Code version mismatch?), or the counter logic has a bug.

---

## Phase 4 — Voice

### 4.1 — "We" vs "I"

Scan the agent's responses across phases 2–3. Mostly "we"-flavored ("we'll start by..."), or mostly "I"-flavored ("I'll run...")?

**Look for:** "we" predominates. Occasional "I" is fine. "I'll do X then Y then Z" without your input is a regression.

### 4.2 — Pushback invitation

In phase 3 the agent should at some point invite pushback explicitly — something like "does that match what you'd expect?" or "want me to come at this differently?"

**If absent across the whole conversation:** voice prompt may not be loading. Check that the slash command body actually got included.

---

## Phase 5 — Reframing

### 5.1 — Push back

After any explanation the agent gives, reply: `I don't get it, can you come at it from a different angle?`

**Look for:**
- Agent offers a *different* metaphor / starting point / angle. Not the same words louder.
- Agent doesn't get defensive or restate the original plan.

**Failure mode:** agent repeats itself, or says "as I said before..."

---

## Phase 6 — Off behavior is normal

### 6.1 — Turn off mid-session

**Run:** `/lento:off`

**Look for:** "Lento off, back to normal" or similar matter-of-fact response. No protest, no "are you sure?"

### 6.2 — Same task, no Lento

**Prompt:** `explore /tmp/lento-test again and summarize`

**Look for:**
- Agent now batches normally — multiple tool calls per turn are fine.
- No `[Lento]` hook feedback (confirmed by behavior).
- Voice may or may not still feel pair-programmer-y; that's fine.

**Failure mode:** agent still paces one-step-at-a-time. That'd mean the state file isn't being read, or the hook isn't checking it.

---

## Phase 7 — Edge cases

### 7.1 — Hook with state file gone mid-session

**Run:** `/lento:on`, then in another shell: `rm /tmp/lento-test/.lento-mode`. Then in Claude Code: `read a.txt`.

**Look for:** no hook feedback (state file gone = hook is no-op). Agent behaves normally.

### 7.2 — Toggle from the shell helper

In another shell: `~/.claude/lento/bin/lento status` should return on/off matching the slash-command state. Toggling via the shell helper should be visible to the next slash command (`/lento:status`).

---

## Cleanup

```sh
/lento:off
exit
rm -rf /tmp/lento-test
```

---

## Pass criteria for tagging v0.1.0

All of:

- [ ] Phase 1 (toggle mechanics) — all four steps pass.
- [ ] Phase 2 (hook fires) — agent visibly pauses after the single tool call.
- [ ] Phase 3 (multi-step pacing) — one step per turn through at least turn 5. **Load-bearing.**
- [ ] Phase 4 (voice) — pair-programmer voice present, pushback invitations appear.
- [ ] Phase 5 (reframing) — agent reframes when asked, doesn't restate.
- [ ] Phase 6 (off behavior) — normal batching returns when Lento is off.
- [ ] Phase 7 (edge cases) — hook is correctly stateless; shell helper agrees with slash commands.

Anything failing → file an issue describing which phase, what was expected, what happened. Don't tag.
