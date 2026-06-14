#!/usr/bin/env bash
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$HERE/test/assert.sh"
DEST="$HERE/test/.tmp/cfg-$$"; rm -rf "$DEST"

CLAUDE_CONFIG_DIR="$DEST" bash "$HERE/install.sh" >/dev/null 2>&1
assert_ok "skill installed" test -f "$DEST/skills/swarm/SKILL.md"
assert_ok "queue script installed + executable" test -x "$DEST/skills/swarm/scripts/queue.sh"
assert_ok "command installed" test -f "$DEST/commands/swarm.md"
# idempotent: run again, still fine
CLAUDE_CONFIG_DIR="$DEST" bash "$HERE/install.sh" >/dev/null 2>&1
assert_ok "idempotent reinstall" test -f "$DEST/skills/swarm/SKILL.md"
rm -rf "$DEST"
