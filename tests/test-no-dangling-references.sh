#!/usr/bin/env bash
set -euo pipefail

PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

echo "=== test-no-dangling-references ==="

# Check that no skill or command references deleted _shared/references/ files
MATCHES=$(grep -rn "_shared/references/" skills/ commands/ --include="*.md" 2>/dev/null || true)
if [[ -z "$MATCHES" ]]; then
  pass "no skills or commands reference _shared/references/"
else
  fail "dangling _shared/references/ paths found:"
  echo "$MATCHES" | while IFS= read -r line; do
    echo "    $line"
  done
fi

# Check that every command that says "Read and follow ... skills/X/X.md" points to an existing file
for cmd_file in commands/*.md; do
  [ -f "$cmd_file" ] || continue
  ref=$(grep -oE 'skills/[a-z0-9_-]+/[a-z0-9_-]+\.md' "$cmd_file" 2>/dev/null | head -1 || true)
  if [[ -n "$ref" ]]; then
    if [[ -f "$ref" ]]; then
      pass "$(basename "$cmd_file") -> $ref exists"
    else
      fail "$(basename "$cmd_file") references $ref but file does not exist"
    fi
  fi
done

echo ""
echo "Dangling references test: $PASS passed, $FAIL failed"
[[ "$FAIL" -eq 0 ]] || exit 1
