#!/usr/bin/env bash
# File-based atomic work queue for cross-window swarm coordination.
# Usage:
#   queue.sh init <run>
#   echo '<json>' | queue.sh add <run> <id>
#   queue.sh claim <run> <worker>     # prints claimed item path, exit 0; exit 1 if empty
#   queue.sh result <run> <id> <file> # records a result
#   queue.sh drained <run>            # exit 0 if nothing left to claim
set -uo pipefail
cmd="${1:-}"; run="${2:-}"
case "$cmd" in
  init)
    mkdir -p "$run/queue" "$run/locks" "$run/claimed" "$run/results" ;;
  add)
    id="${3:?id required}"; cat > "$run/queue/$id.json" ;;
  claim)
    worker="${3:?worker required}"
    shopt -s nullglob
    for item in "$run"/queue/*.json; do
      id="$(basename "$item" .json)"
      if mkdir "$run/locks/$id" 2>/dev/null; then
        printf '%s\n' "$worker" > "$run/locks/$id/owner"
        mv "$item" "$run/claimed/$id.json" 2>/dev/null || { rmdir "$run/locks/$id" 2>/dev/null; continue; }
        printf '%s\n' "$id"
        exit 0
      fi
    done
    exit 1 ;;
  result)
    id="${3:?id required}"; src="${4:?file required}"
    cp "$src" "$run/results/$id.json" ;;
  drained)
    shopt -s nullglob; items=("$run"/queue/*.json)
    [ "${#items[@]}" -eq 0 ] && exit 0 || exit 1 ;;
  *)
    echo "unknown cmd: $cmd" >&2; exit 2 ;;
esac
