---
description: Run an adaptive multi-agent swarm over a task (research/review/build/ops), with judge synthesis and a thermal governor.
argument-hint: "[now] [+500k] [--opus-only|--lean|--no-mini] [--concurrency N] <task>  |  join <run-id>"
---

Use the `swarm` skill to handle this request: $ARGUMENTS

Follow `skills/swarm/SKILL.md` exactly — detect the task type, warn-first unless `now`,
set model tiers + thermal limits, and run solo or quad. Do not use headless `-p`.
