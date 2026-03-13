#!/usr/bin/env bash
set -euo pipefail

PROMPT_INPUT="${XGH_PROMPT_INPUT:-}"

# If the runner provides stdin, consume it as prompt text.
if [[ -z "$PROMPT_INPUT" ]] && [[ ! -t 0 ]]; then
  PROMPT_INPUT=$(cat)
fi

python3 - "$PROMPT_INPUT" <<'PY'
import json
import re
import sys

prompt = sys.argv[1] if len(sys.argv) > 1 else ""
looks_like_code_change = bool(
	re.search(r"\b(implement|refactor|fix|build|code|write|change|feature|bug)\b", prompt, re.IGNORECASE)
)

actions = [
	"Run cipher_memory_search before writing code.",
	"Use context-tree search for conventions and prior decisions.",
	"After changes, run cipher_extract_and_operate_memory to store learnings.",
	"For non-trivial architecture decisions, run cipher_store_reasoning_memory.",
]

result = {
	"result": "xgh: prompt-submit decision table injected",
	"promptIntent": "code-change" if looks_like_code_change else "general",
	"requiredActions": actions,
	"toolHints": [
		"cipher_memory_search",
		"cipher_extract_and_operate_memory",
		"cipher_store_reasoning_memory",
	],
}

print(json.dumps(result))
PY
