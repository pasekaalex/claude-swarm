#!/usr/bin/env bash
# Launch a 4-window quad swarm in tmux. No headless -p — each pane is interactive.
# Usage: swarm-quad.sh [--dry-run] "<task>"
set -uo pipefail
DRY=0; [ "${1:-}" = "--dry-run" ] && { DRY=1; shift; }
TASK="${1:?task required}"
RUN="/tmp/swarm-$(date +%s 2>/dev/null || echo run)-$$"
SESSION="swarm-$$"
WINDOWS=("claude" "claude-tech" "claude-3" "claude-mini")

plan() {
  echo "run dir: $RUN"
  echo "primary: ${WINDOWS[0]} → /swarm now $TASK"
  for w in "${WINDOWS[@]:1}"; do echo "worker:  $w → /swarm join $RUN"; done
}

if [ "$DRY" -eq 1 ]; then plan; exit 0; fi
if ! command -v tmux >/dev/null 2>&1; then echo "tmux not found; here is the manual plan:"; plan; exit 1; fi

tmux new-session -d -s "$SESSION" -n swarm "${WINDOWS[0]}"
for w in "${WINDOWS[@]:1}"; do tmux split-window -t "$SESSION" "$w"; tmux select-layout -t "$SESSION" tiled; done
# Send the primary task and worker joins after a short settle.
tmux send-keys -t "$SESSION".0 "/swarm now $TASK" Enter
i=1; for _ in "${WINDOWS[@]:1}"; do tmux send-keys -t "$SESSION".$i "/swarm join $RUN" Enter; i=$((i+1)); done
tmux attach -t "$SESSION"
