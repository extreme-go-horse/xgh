#!/usr/bin/env bash
# detect-agents.sh — detect which AI CLI agents are installed
# Usage: bash scripts/detect-agents.sh
# Output: space-separated list of detected agent IDs (e.g. "codex gemini opencode")
# Exit 0 always.

DETECTED=()

command -v codex    &>/dev/null && DETECTED+=(codex)
command -v gemini   &>/dev/null && DETECTED+=(gemini)
command -v opencode &>/dev/null && DETECTED+=(opencode)
command -v qwen     &>/dev/null && DETECTED+=(qwen)
command -v aider    &>/dev/null && DETECTED+=(aider)

if [[ ${#DETECTED[@]} -eq 0 ]]; then
  echo "none"
else
  echo "${DETECTED[*]}"
fi
