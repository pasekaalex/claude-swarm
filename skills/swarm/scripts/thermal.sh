#!/usr/bin/env bash
# Thermal governor for the swarm. Keeps the laptop from cooking under load.
# Usage:
#   thermal.sh get            # prints integer package temp (°C)
#   thermal.sh action         # prints "PAUSE <t>" | "HOLD <t>" | "OK <t>"
# Tunables: SWARM_HOT (default 82), SWARM_COOL (default 75).
# Test override: THERMAL_TEST_TEMP forces the reading.
set -uo pipefail

get_temp() {
  if [ -n "${THERMAL_TEST_TEMP:-}" ]; then printf '%s\n' "$THERMAL_TEST_TEMP"; return; fi
  local t=""
  if command -v sensors >/dev/null 2>&1; then
    t="$(sensors 2>/dev/null | awk '/Tctl|Package id 0|Tdie/{for(i=1;i<=NF;i++) if($i ~ /\+[0-9]/){gsub(/[+°C]/,"",$i); print int($i); exit}}')"
  fi
  if [ -z "$t" ]; then
    t="$(for f in /sys/class/hwmon/hwmon*/temp1_input; do [ -r "$f" ] && awk '{print int($1/1000)}' "$f"; done 2>/dev/null | sort -rn | head -1)"
  fi
  printf '%s\n' "${t:-0}"
}

cmd="${1:-action}"
case "$cmd" in
  get) get_temp ;;
  action)
    hot="${SWARM_HOT:-82}"; cool="${SWARM_COOL:-75}"; t="$(get_temp)"
    if   [ "$t" -ge "$hot" ];  then printf 'PAUSE %s\n' "$t"
    elif [ "$t" -lt "$cool" ]; then printf 'OK %s\n' "$t"
    else printf 'HOLD %s\n' "$t"; fi ;;
  *) echo "unknown cmd: $cmd" >&2; exit 2 ;;
esac
