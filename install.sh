#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
mkdir -p "$DEST/skills" "$DEST/commands"
rm -rf "$DEST/skills/swarm"
cp -R "$HERE/skills/swarm" "$DEST/skills/swarm"
cp "$HERE/commands/swarm.md" "$DEST/commands/swarm.md"
chmod +x "$DEST/skills/swarm/scripts/"*.sh
echo "Installed swarm skill → $DEST/skills/swarm and /swarm command → $DEST/commands/swarm.md"
