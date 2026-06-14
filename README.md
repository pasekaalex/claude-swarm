# claude-swarm

Adaptive multi-agent **swarm** for Claude Code. Turn one task into a panel-of-agents
deliberation with a judged synthesis — scaled across one window or four
(`claude` + `claude-tech` + `claude-3` + `claude-mini`). No API keys. No OpenRouter.
No headless `-p`.

## What it does

`/swarm <task>` detects the task type (research / review / build / ops), fans out a panel
of agents (Opus for judging/verification, Sonnet for breadth, MiniMax M3 as a free extra
window), verifies findings adversarially, loops until the topic is dry, and synthesizes a
final answer with a structured judge rubric (consensus / contradictions / partial coverage /
unique insights / blind spots).

A built-in **thermal governor** keeps your laptop from cooking under load.

## Install

**As a plugin:**
```
/plugin marketplace add pasekaalex/claude-swarm
/plugin install swarm@claude-swarm
```
> Installed as a plugin the command is namespaced — **`/swarm:swarm`**. Install as a skill (below) to get the bare **`/swarm`**.

**As a skill:**
```
git clone https://github.com/pasekaalex/claude-swarm
cd claude-swarm && ./install.sh
```

## Usage

```
/swarm research the best vector DB for on-device RAG
/swarm now review the current diff for security bugs
/swarm +500k build a REST wrapper from this OpenAPI spec
/swarm --opus-only audit this contract
/swarm --no-mini --concurrency 5 <task>     # lighter / cooler
/swarm join /tmp/swarm-1234                  # join a quad run as a worker
```

Flags: `now` (skip confirm) · `+Nk` (token budget) · `--opus-only` · `--lean` ·
`--no-mini` · `--concurrency N`.

## Quad mode

Open four windows (one per login) and run `swarm-quad.sh "<task>"`, or start them by hand:
the primary window runs `/swarm <task>`; the others run `/swarm join <run-id>`. They share a
file-based work queue and the primary does the final Opus merge. **MiniMax is the
`claude-mini` window — never a subprocess.**

## Portability

- **Anthropic-specific:** the Opus/Sonnet model tiers and the optional reset-schedule note.
- **Portable:** the quad-window pattern, the work queue, the judge rubric, the thermal governor.
- The `claude-mini` / MiniMax window is **optional** (`--no-mini`).

## License

MIT
