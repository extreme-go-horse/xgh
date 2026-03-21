#!/usr/bin/env bash
set -euo pipefail

PASS=0; FAIL=0

assert_file_exists() {
  [[ -f "$1" ]] && PASS=$((PASS+1)) || { echo "FAIL: missing $1"; FAIL=$((FAIL+1)); }
}
assert_contains() {
  grep -qi "$2" "$1" 2>/dev/null && PASS=$((PASS+1)) || { echo "FAIL: $1 missing '$2'"; FAIL=$((FAIL+1)); }
}
assert_output_valid() {
  local out
  out=$(bash "$1")
  # Must print "none" or a space-separated list of known agent IDs
  if echo "$out" | grep -qE '^(none|[a-z]+([ ][a-z]+)*)$'; then
    PASS=$((PASS+1))
  else
    echo "FAIL: $1 produced unexpected output: '$out'"
    FAIL=$((FAIL+1))
  fi
}

assert_file_exists "scripts/detect-agents.sh"
assert_contains "scripts/detect-agents.sh" "command -v codex"
assert_contains "scripts/detect-agents.sh" "command -v gemini"
assert_contains "scripts/detect-agents.sh" "command -v opencode"
assert_output_valid "scripts/detect-agents.sh"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
