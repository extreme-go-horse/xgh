#!/usr/bin/env bash
set -euo pipefail

PASS=0
FAIL=0

assert_file_exists() {
  if [[ -f "$1" ]]; then
    PASS=$((PASS + 1))
  else
    echo "FAIL: missing file $1"
    FAIL=$((FAIL + 1))
  fi
}

assert_contains() {
  if grep -qi "$2" "$1" 2>/dev/null; then
    PASS=$((PASS + 1))
  else
    echo "FAIL: $1 missing '$2'"
    FAIL=$((FAIL + 1))
  fi
}

# --- File existence ---
assert_file_exists "skills/codex/codex.md"
assert_file_exists "commands/codex.md"
assert_file_exists "tests/skill-triggering/prompts/codex.txt"

# --- Skill content ---
assert_contains "skills/codex/codex.md" "codex exec"
assert_contains "skills/codex/codex.md" "codex review"
assert_contains "skills/codex/codex.md" "worktree"
assert_contains "skills/codex/codex.md" "same-dir"
assert_contains "skills/codex/codex.md" "gpt-5.4"
assert_contains "skills/codex/codex.md" "full-auto"
assert_contains "skills/codex/codex.md" "run_in_background"
assert_contains "skills/codex/codex.md" "lossless-claude"

# --- Command content ---
assert_contains "commands/codex.md" "xgh:codex"
assert_contains "commands/codex.md" "/xgh-codex"
assert_contains "commands/codex.md" "exec"
assert_contains "commands/codex.md" "review"

# --- Agents.yaml codex entry ---
assert_contains "config/agents.yaml" "codex:"
assert_contains "config/agents.yaml" "exec:"
assert_contains "config/agents.yaml" "review:"
assert_contains "config/agents.yaml" "full-auto"

# --- Help command references codex ---
assert_contains "commands/help.md" "/xgh-codex"

echo ""
echo "Codex dispatch test: $PASS passed, $FAIL failed"
[[ "$FAIL" -eq 0 ]] || exit 1
