#!/usr/bin/env bash
# Run all xgh skill triggering tests
# Usage: ./run-all.sh
#
# NOTE: This is an opt-in test suite — it invokes claude -p and costs API tokens.
# Do NOT call from tests/test-config.sh.
# Run manually when editing skill trigger descriptions.
#
# Cost estimate: ~8 prompts × 1 turn ≈ ~$0.40 per full suite run.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROMPTS_DIR="$SCRIPT_DIR/prompts"

# skill-name → prompt-file mapping
# Format: "xgh:skill:prompt_file" — colon separates namespace:skill from filename
# (all prompt filenames must be colon-free)
TESTS=(
    "xgh:retrieve:retrieve.txt"
    "xgh:analyze:analyze.txt"
    "xgh:briefing:briefing.txt"
    "xgh:implement:implement.txt"
    "xgh:investigate:investigate.txt"
    "xgh:track:track.txt"
    "xgh:doctor:doctor.txt"
    "xgh:index:index.txt"
)

echo "=== xgh Skill Triggering Test Suite ==="
echo "Plugin dir: $(cd "$SCRIPT_DIR/../.." && pwd)"
echo ""

PASSED=0
FAILED=0
RESULTS=()

for entry in "${TESTS[@]}"; do
    # Parse "namespace:skill:file" — split on last colon for the file
    SKILL="${entry%:*}"          # everything before last colon = skill name (e.g. xgh:briefing)
    PROMPT_FILE="${entry##*:}"   # everything after last colon = filename

    FULL_PROMPT="$PROMPTS_DIR/$PROMPT_FILE"

    if [ ! -f "$FULL_PROMPT" ]; then
        echo "⚠️  SKIP: No prompt file for $SKILL ($FULL_PROMPT)"
        continue
    fi

    echo "--- Testing: $SKILL ---"

    if "$SCRIPT_DIR/run-test.sh" "$SKILL" "$FULL_PROMPT"; then
        PASSED=$((PASSED + 1))
        RESULTS+=("✅ $SKILL")
    else
        FAILED=$((FAILED + 1))
        RESULTS+=("❌ $SKILL")
    fi

    echo ""
done

echo "=== Summary ==="
for result in "${RESULTS[@]}"; do
    echo "  $result"
done
echo ""
echo "Passed: $PASSED / $((PASSED + FAILED))"

if [ "$FAILED" -gt 0 ]; then
    exit 1
fi
