#!/usr/bin/env bash
set -euo pipefail

# retrieve-all.sh — Discovery-based provider orchestrator
# Finds and runs all mode:bash fetch.sh scripts in ~/.xgh/providers/
# Skips mode:mcp providers (handled by separate CronCreate prompt)
# Called by CronCreate every 5 minutes (1 Bash turn, no Claude)

PROVIDERS_DIR="${XGH_PROVIDERS_DIR:-$HOME/.xgh/providers}"
INBOX_DIR="$HOME/.xgh/inbox"
LOG_FILE="$HOME/.xgh/logs/retriever.log"
PAUSE_FILE="$HOME/.xgh/scheduler-paused"

# Portable timeout: use gtimeout (brew coreutils) or timeout if available, else skip
run_with_timeout() {
    local secs=$1; shift
    if command -v gtimeout &>/dev/null; then
        gtimeout "$secs" "$@"
    elif command -v timeout &>/dev/null; then
        timeout "$secs" "$@"
    else
        "$@"
    fi
}

# Guard: check pause file
if [ -f "$PAUSE_FILE" ]; then
    echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) retriever: paused" >> "$LOG_FILE"
    exit 0
fi

# Guard: check inbox dir exists
mkdir -p "$INBOX_DIR" "$HOME/.xgh/logs"

# Discover and run providers
total=0
success=0
failed=0
items_before=$(find "$INBOX_DIR" -name "*.md" -not -name "WARN_*" | wc -l | tr -d ' ')

for provider_dir in "$PROVIDERS_DIR"/*/; do
    [ -d "$provider_dir" ] || continue
    name=$(basename "$provider_dir")
    script="$provider_dir/fetch.sh"

    # Skip MCP-mode providers (no fetch.sh — handled by MCP CronCreate prompt)
    if grep -q "^mode: mcp" "$provider_dir/provider.yaml" 2>/dev/null; then
        continue
    fi

    if [ ! -x "$script" ]; then
        echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) retriever: WARN $name — fetch.sh not found or not executable" >> "$LOG_FILE"
        continue
    fi

    total=$((total + 1))

    rc=0
    # fetch.sh may write a cursor file for incremental pagination on next run
    run_with_timeout 30 bash "$script" 2>>"$HOME/.xgh/logs/provider-$name.log" || rc=$?
    if [ "$rc" -eq 0 ]; then
        success=$((success + 1))
    else
        failed=$((failed + 1))
        echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) retriever: ERROR $name — exit code $rc" >> "$LOG_FILE"
    fi
done

items_after=$(find "$INBOX_DIR" -name "*.md" -not -name "WARN_*" | wc -l | tr -d ' ')
new_items=$((items_after - items_before))

echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) retriever: $total providers, $success ok, $failed failed, $new_items new items" >> "$LOG_FILE"
