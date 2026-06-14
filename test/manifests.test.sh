#!/usr/bin/env bash
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$HERE/test/assert.sh"

assert_ok "plugin.json is valid JSON" jq -e . "$HERE/.claude-plugin/plugin.json"
assert_ok "marketplace.json is valid JSON" jq -e . "$HERE/.claude-plugin/marketplace.json"
assert_eq "plugin name is swarm" "swarm" "$(jq -r .name "$HERE/.claude-plugin/plugin.json")"
assert_eq "marketplace lists plugin swarm" "swarm" "$(jq -r '.plugins[0].name' "$HERE/.claude-plugin/marketplace.json")"
assert_eq "plugin source is ./" "./" "$(jq -r '.plugins[0].source' "$HERE/.claude-plugin/marketplace.json")"
assert_eq "license is MIT" "MIT" "$(jq -r .license "$HERE/.claude-plugin/plugin.json")"

assert_ok "judge-rubric exists" test -f "$HERE/skills/swarm/references/judge-rubric.md"
assert_ok "rubric has Consensus" grep -q "Consensus" "$HERE/skills/swarm/references/judge-rubric.md"
assert_ok "rubric has Blind spots" grep -qi "blind spot" "$HERE/skills/swarm/references/judge-rubric.md"
assert_ok "patterns lists all 4 templates" bash -c 'for t in research review build ops; do grep -q "$t.js" "'"$HERE"'/skills/swarm/references/patterns.md" || exit 1; done'

assert_ok "SKILL.md exists" test -f "$HERE/skills/swarm/SKILL.md"
assert_ok "SKILL has name frontmatter" grep -q "^name: swarm" "$HERE/skills/swarm/SKILL.md"
assert_ok "SKILL has description frontmatter" grep -q "^description:" "$HERE/skills/swarm/SKILL.md"
assert_ok "SKILL references templates" grep -q "templates/" "$HERE/skills/swarm/SKILL.md"
assert_ok "no CLAUDE.md shipped" bash -c '! test -f "'"$HERE"'/CLAUDE.md" && ! test -f "'"$HERE"'/skills/swarm/CLAUDE.md"'

assert_ok "command exists" test -f "$HERE/commands/swarm.md"
assert_ok "command invokes skill" grep -qi "swarm. skill\|swarm skill\|skills/swarm" "$HERE/commands/swarm.md"
