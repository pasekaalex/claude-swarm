# Swarm Patterns (per task type)

The dispatcher detects the task type from the prompt and selects a template.
All patterns share the spine: **blind independent panel → structured judge rubric
→ loop-until-dry → completeness critic**, with **adversarial verify** on high-stakes findings.

| Type | Trigger words | Template | Shape |
|---|---|---|---|
| research | "research", "investigate", "find out", "compare", a question | `research.js` | search fan-out (4 angles) → adversarial verify → cited synthesis |
| review | "review", "audit", "find bugs", "security", a diff/PR | `review.js` | finders by dimension → skeptic-verify each → confirmed-only report |
| build | "build", "implement", "add feature", "refactor", a spec | `build.js` | decompose → implement (optional worktree isolation) → verify |
| ops | "process", "sweep", "triage", "for each", a list | `ops.js` | map items → transform → judge batch |

If ambiguous, default to **research** and state the assumption in the warn-first line.
