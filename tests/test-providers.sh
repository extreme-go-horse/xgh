#!/usr/bin/env bash
set -euo pipefail
PASS=0; FAIL=0
assert_file_exists() { if [ -f "$1" ]; then PASS=$((PASS+1)); else echo "FAIL: $1 does not exist"; FAIL=$((FAIL+1)); fi; }
assert_contains() { if grep -q "$2" "$1" 2>/dev/null; then PASS=$((PASS+1)); else echo "FAIL: $1 does not contain '$2'"; FAIL=$((FAIL+1)); fi; }

# scripts/retrieve-all.sh references user_providers
assert_file_exists "scripts/retrieve-all.sh"
assert_contains "scripts/retrieve-all.sh" "user_providers"

# skills/track/track.md references user_providers
assert_file_exists "skills/track/track.md"
assert_contains "skills/track/track.md" "user_providers"

# skills/doctor/doctor.md references user_providers
assert_file_exists "skills/doctor/doctor.md"
assert_contains "skills/doctor/doctor.md" "user_providers"

echo ""; echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
