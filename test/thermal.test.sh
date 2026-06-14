#!/usr/bin/env bash
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$HERE/test/assert.sh"
T="$HERE/skills/swarm/scripts/thermal.sh"

assert_eq "hot → PAUSE" "PAUSE" "$(THERMAL_TEST_TEMP=90 bash "$T" action | awk '{print $1}')"
assert_eq "cool → OK"   "OK"   "$(THERMAL_TEST_TEMP=60 bash "$T" action | awk '{print $1}')"
assert_eq "mid → HOLD"  "HOLD" "$(THERMAL_TEST_TEMP=78 bash "$T" action | awk '{print $1}')"
assert_eq "boundary 82 → PAUSE" "PAUSE" "$(THERMAL_TEST_TEMP=82 bash "$T" action | awk '{print $1}')"
assert_eq "custom hot 70 → PAUSE at 72" "PAUSE" "$(SWARM_HOT=70 THERMAL_TEST_TEMP=72 bash "$T" action | awk '{print $1}')"
assert_eq "get prints temp" "65" "$(THERMAL_TEST_TEMP=65 bash "$T" get)"
