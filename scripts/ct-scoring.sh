#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=scripts/ct-frontmatter.sh
source "$SCRIPT_DIR/ct-frontmatter.sh"

ct_score_now() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

ct_score_recency() {
  local updated_at=${1:?updated_at required}

  python3 - "$updated_at" <<'PY'
from datetime import datetime, timezone
import math
import sys

value = sys.argv[1]
try:
    dt = datetime.strptime(value, "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=timezone.utc)
except ValueError:
    print("1.0000")
    raise SystemExit(0)

now = datetime.now(timezone.utc)
days = max((now - dt).total_seconds() / 86400.0, 0.0)
half_life_days = 21.0
recency = math.exp(-math.log(2.0) * (days / half_life_days))
print(f"{recency:.4f}")
PY
}

ct_score_maturity() {
  local importance=${1:?importance required}

  if (( importance >= 85 )); then
    echo "core"
  elif (( importance >= 65 )); then
    echo "validated"
  else
    echo "draft"
  fi
}

ct_score_recalculate() {
  local file=${1:?file required}
  local importance
  local updated_at

  importance=$(ct_frontmatter_get "$file" "importance" 2>/dev/null || echo "50")
  updated_at=$(ct_frontmatter_get "$file" "updatedAt" 2>/dev/null || ct_score_now)

  if [[ ! "$importance" =~ ^-?[0-9]+$ ]]; then
    importance=50
  fi

  local recency
  local maturity
  recency=$(ct_score_recency "$updated_at")
  maturity=$(ct_score_maturity "$importance")

  ct_frontmatter_set "$file" "importance" "$importance"
  ct_frontmatter_set "$file" "updatedAt" "$updated_at"
  ct_frontmatter_set "$file" "recency" "$recency"
  ct_frontmatter_set "$file" "maturity" "$maturity"
}

ct_score_apply_event() {
  local file=${1:?file required}
  local event=${2:-update}

  local delta
  case "$event" in
    search-hit)
      delta=3
      ;;
    update)
      delta=5
      ;;
    manual)
      delta=10
      ;;
    *)
      echo "Unknown score event: $event" >&2
      return 1
      ;;
  esac

  local importance
  importance=$(ct_frontmatter_get "$file" "importance" 2>/dev/null || echo "50")
  if [[ ! "$importance" =~ ^-?[0-9]+$ ]]; then
    importance=50
  fi

  local next=$((importance + delta))
  if (( next > 100 )); then
    next=100
  fi
  if (( next < 0 )); then
    next=0
  fi

  ct_frontmatter_set "$file" "importance" "$next"
  ct_frontmatter_set "$file" "updatedAt" "$(ct_score_now)"

  case "$event" in
    search-hit)
      ct_frontmatter_increment_int "$file" "accessCount"
      ;;
    update|manual)
      ct_frontmatter_increment_int "$file" "updateCount"
      ;;
  esac

  ct_score_recalculate "$file"
}

usage() {
  cat <<'EOF'
Usage:
  ct-scoring.sh recalculate <file>
  ct-scoring.sh bump <file> <search-hit|update|manual>
EOF
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  cmd=${1:-}

  case "$cmd" in
    recalculate)
      ct_score_recalculate "${2:?file required}"
      ;;
    bump)
      ct_score_apply_event "${2:?file required}" "${3:-update}"
      ;;
    *)
      usage
      exit 1
      ;;
  esac
fi
