# Sourced helpers. Each increments PASS/FAIL and prints a line.
: "${PASS:=0}"; : "${FAIL:=0}"
assert_eq() { # msg expected actual
  local msg="$1" exp="$2" act="$3"
  if [ "$exp" = "$act" ]; then PASS=$((PASS+1)); echo "  ok   - $msg";
  else FAIL=$((FAIL+1)); echo "  FAIL - $msg (expected '$exp', got '$act')"; fi
}
assert_ok() { # msg cmd...
  local msg="$1"; shift
  if "$@" >/dev/null 2>&1; then PASS=$((PASS+1)); echo "  ok   - $msg";
  else FAIL=$((FAIL+1)); echo "  FAIL - $msg (command failed: $*)"; fi
}
assert_fail() { # msg cmd... (expect nonzero)
  local msg="$1"; shift
  if "$@" >/dev/null 2>&1; then FAIL=$((FAIL+1)); echo "  FAIL - $msg (expected failure)";
  else PASS=$((PASS+1)); echo "  ok   - $msg"; fi
}
