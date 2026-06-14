#!/usr/bin/env bash
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$HERE/test/assert.sh"
Q="$HERE/skills/swarm/scripts/queue.sh"
RUN="$HERE/test/.tmp/run-$$"; rm -rf "$RUN"

bash "$Q" init "$RUN"
assert_ok "init creates queue dir" test -d "$RUN/queue"

# add 20 items
for i in $(seq 1 20); do echo "{\"i\":$i}" | bash "$Q" add "$RUN" "item$i"; done
assert_eq "20 items queued" "20" "$(ls "$RUN/queue" | wc -l | tr -d ' ')"

# 8 concurrent workers drain the queue
for w in $(seq 1 8); do
  ( while out=$(bash "$Q" claim "$RUN" "w$w"); do echo "$out" >> "$RUN/claims.$w"; done ) &
done
wait

total=$(cat "$RUN"/claims.* 2>/dev/null | wc -l | tr -d ' ')
uniq=$(cat "$RUN"/claims.* 2>/dev/null | sort -u | wc -l | tr -d ' ')
assert_eq "all 20 claimed" "20" "$total"
assert_eq "no double-claims" "20" "$uniq"
assert_ok "queue drained → drained returns 0" bash "$Q" drained "$RUN"
rm -rf "$RUN"

SQ="$HERE/skills/swarm/scripts/swarm-quad.sh"
out="$(bash "$SQ" --dry-run 'hello world' 2>&1)"
assert_ok "dry-run names primary" bash -c "echo \"$out\" | grep -q 'primary: claude'"
assert_ok "dry-run names claude-mini worker" bash -c "echo \"$out\" | grep -q 'worker:  claude-mini'"
