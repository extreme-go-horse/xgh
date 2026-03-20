#!/usr/bin/env bash
set -euo pipefail
PASS=0; FAIL=0
assert_equals() { if [ "$1" = "$2" ]; then PASS=$((PASS+1)); else echo "FAIL: expected '$2', got '$1'"; FAIL=$((FAIL+1)); fi; }
assert_contains() { if grep -q "$2" "$1" 2>/dev/null; then PASS=$((PASS+1)); else echo "FAIL: $1 missing '$2'"; FAIL=$((FAIL+1)); fi; }
assert_file_exists() { if [ -f "$1" ]; then PASS=$((PASS+1)); else echo "FAIL: $1 does not exist"; FAIL=$((FAIL+1)); fi; }

# Setup temp environment
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

PROVIDERS="$TMPDIR/user_providers"
INBOX="$TMPDIR/.xgh/inbox"
LOGS="$TMPDIR/.xgh/logs"
mkdir -p "$PROVIDERS/test-cli" "$INBOX" "$LOGS"

# Create a mock provider.yaml
cat > "$PROVIDERS/test-cli/provider.yaml" << 'YAML'
service: test
mode: cli
cursor_strategy: iso8601
YAML

# Create a mock fetch.sh that validates contract env vars
cat > "$PROVIDERS/test-cli/fetch.sh" << 'FETCH'
#!/usr/bin/env bash
# Validate env vars are set
[ -n "$PROVIDER_DIR" ] || { echo "PROVIDER_DIR not set" >&2; exit 1; }
[ -n "$CURSOR_FILE" ] || { echo "CURSOR_FILE not set" >&2; exit 1; }
[ -n "$INBOX_DIR" ] || { echo "INBOX_DIR not set" >&2; exit 1; }
[ -n "$TOKENS_FILE" ] || { echo "TOKENS_FILE not set" >&2; exit 1; }

# Write a test inbox item
cat > "$INBOX_DIR/2026-03-20T00-00-00Z_test_item_test_1.md" << 'ITEM'
---
type: test_item
source_type: test_item
source: test
project: test-project
timestamp: 2026-03-20T00:00:00Z
urgency_score: 0
processed: false
tags: []
---
Test item content
ITEM

# Write cursor
echo "2026-03-20T00:00:00Z" > "$CURSOR_FILE"

echo "fetched=1"
exit 0
FETCH
chmod +x "$PROVIDERS/test-cli/fetch.sh"

# Run retrieve-all.sh against mock environment
export XGH_PROVIDERS_DIR="$PROVIDERS"
export HOME="$TMPDIR"
mkdir -p "$TMPDIR/.xgh/logs" "$TMPDIR/.xgh/inbox"

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
bash "$REPO_ROOT/scripts/retrieve-all.sh" 2>/dev/null

# Verify contract
assert_file_exists "$INBOX/2026-03-20T00-00-00Z_test_item_test_1.md"
assert_file_exists "$PROVIDERS/test-cli/cursor"
assert_contains "$PROVIDERS/test-cli/cursor" "2026-03-20T00:00:00Z"
assert_contains "$LOGS/retriever.log" "1 providers"
assert_contains "$LOGS/retriever.log" "1 ok"

# Test exit code 2 (partial failure)
cat > "$PROVIDERS/test-cli/fetch.sh" << 'FETCH2'
#!/usr/bin/env bash
echo "fetched=0"
exit 2
FETCH2
chmod +x "$PROVIDERS/test-cli/fetch.sh"

bash "$REPO_ROOT/scripts/retrieve-all.sh" 2>/dev/null
assert_contains "$LOGS/retriever.log" "WARN test-cli"

# Test MCP provider is skipped
mkdir -p "$PROVIDERS/test-mcp"
cat > "$PROVIDERS/test-mcp/provider.yaml" << 'YAML'
service: test-mcp
mode: mcp
mcp_server: test
YAML
# No fetch.sh — should be skipped without error

bash "$REPO_ROOT/scripts/retrieve-all.sh" 2>/dev/null
# Should still show 1 provider (mcp skipped)
assert_contains "$LOGS/retriever.log" "1 providers"

echo ""; echo "Provider contract: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
