#!/usr/bin/env bash
# hooks/post-tool-use-shellcheck.sh — PostToolUse shellcheck linting
#
# Runs shellcheck on any .sh file Claude writes or edits.
# Injects violations as additionalContext so Claude can self-correct.
# Silent if shellcheck is not installed or no issues found.
#
# Matcher: Write|Edit|MultiEdit
set -euo pipefail

INPUT=$(cat 2>/dev/null) || exit 0
[ -n "$INPUT" ] || exit 0

FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null) || exit 0
[ -n "$FILE_PATH" ] || exit 0

[[ "$FILE_PATH" == *.sh ]] || exit 0
command -v shellcheck >/dev/null 2>&1 || exit 0

ISSUES=$(shellcheck --format=gcc "$FILE_PATH" 2>&1) || true
[ -n "$ISSUES" ] || exit 0

jq -n --arg msg "[shellcheck] ${FILE_PATH}:
${ISSUES}" '{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": $msg
  }
}'
