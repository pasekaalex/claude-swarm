#!/usr/bin/env bash
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PASS=0 FAIL=0
for t in "$HERE"/test/*.test.sh; do
  echo "# $(basename "$t")"
  # shellcheck disable=SC1090
  source "$t"
done
if command -v node >/dev/null 2>&1 && [ -f "$HERE/test/templates.test.mjs" ]; then
  echo "# templates.test.mjs"
  if node --test "$HERE/test/templates.test.mjs"; then PASS=$((PASS+1)); echo "  ok   - node template tests";
  else FAIL=$((FAIL+1)); echo "  FAIL - node template tests"; fi
fi
echo "-----"; echo "PASS=$PASS FAIL=$FAIL"
[ "$FAIL" -eq 0 ]
