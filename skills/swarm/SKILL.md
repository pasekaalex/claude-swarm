---
name: swarm
description: Run a large multi-agent swarm over a task — fan-out across Opus/Sonnet/MiniMax with blind-panel + judge synthesis, loop-until-dry, adversarial verify, and a thermal governor. Use when the user types /swarm, or asks to run a big agent swarm, fan a task across many agents, or run research/review/build/ops "harder/bigger".
---

# Swarm

Adaptive, high-throughput multi-agent runner. Turns one task into a panel-of-agents
deliberation and a judged synthesis, scaled across one or four Claude Code windows.

## When invoked

Parse `$ARGUMENTS` for flags then the task text:
- `now` → skip the warn-first confirmation.
- `+<N>k` / `+<N>` → token budget ceiling (governs orchestration depth — fewer rounds / background workflows as the ceiling nears).
- `--opus-only` → all tiers Opus. `--lean` → more Sonnet/MiniMax, fewer Opus.
- `--no-mini` → omit the MiniMax window/tier. `--concurrency N` → per-window cap.
- `join <run-id>` → act as a **worker** for an existing quad run (see Quad mode).

## Step 1 — Detect task type

Read `references/patterns.md`. Classify the task as **research / review / build / ops**
(default research). Pick the matching `templates/<type>.js`.

## Step 2 — Warn-first (unless `now`)

Print ONE line: `<type> · <template> · ~<agents> agents · est ~<tokens> · <headroom note>`
and wait for the user to say go. Headroom note uses the user's account reset schedule if they
have one configured; otherwise omit.

## Step 3 — Set model tiers + concurrency

Default tier (subscription window): wide=`sonnet`, judge=`opus`; `--opus-only` sets both
`opus`; `--lean` sets wide=`sonnet`. In a MiniMax (`claude-mini`) window everything is the
window's native model — pass wide/judge as the default and let the window resolve them.
Per-window concurrency default 7 for subscription windows (≈15% trim for thermals), 10 for
the MiniMax window; `--concurrency N` overrides.

## Step 4 — Thermal governor

Before each heavy batch, run `scripts/thermal.sh action`. If it returns `PAUSE`, wait and
re-check until `OK`; if it stays hot, drop concurrency by 2 and continue. Honor `SWARM_HOT`/
`SWARM_COOL` if the user set them.

## Step 5 — Run

**Solo** (one window): invoke the chosen template via the **Workflow tool** with
`args = { ...task, tier }`. Concurrency and token budget are enforced by the orchestrator
(background-workflow count + thermal governor + loop depth), not passed into the template.
For more than ~14-wide, launch up to 3 background Workflow calls over shards of the work and merge.

**Quad** (four windows): the user opens `claude`, `claude-tech`, `claude-3`,
`claude-mini` windows (or runs `scripts/swarm-quad.sh "<task>"`). Coordination:
1. Primary window: `scripts/queue.sh init <run>`, decompose the task into items
   (`queue.sh add`), then work the queue with the template.
2. Other windows run `/swarm join <run>` → claim items via `queue.sh claim`, process with
   the template, write results via `queue.sh result`.
3. When `queue.sh drained <run>` is true, the primary runs the **judge merge** over
   `<run>/results/*` using `references/judge-rubric.md` (Opus).

## Step 6 — Report

Output the judged final answer. For research/review include the structured-rubric sections;
for build/ops summarize per-unit/item outcomes and flag anything unverified.

## Notes
- Never use headless `-p` against the subscription accounts. MiniMax participates only as the
  `claude-mini` window (its agents are natively MiniMax-M3).
- All judges/verifiers run on Opus. Honor normal Claude Code permission gating (no auto-approve).
- The helper scripts (`scripts/queue.sh`, `scripts/thermal.sh`, `scripts/swarm-quad.sh`) live in
  this skill's own directory — resolve them relative to this file (e.g.
  `${CLAUDE_PLUGIN_ROOT}/skills/swarm/scripts/...` when installed as a plugin, or
  `~/.claude/skills/swarm/scripts/...` when installed via `install.sh`).
