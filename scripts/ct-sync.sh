#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=scripts/ct-frontmatter.sh
source "$SCRIPT_DIR/ct-frontmatter.sh"
# shellcheck source=scripts/ct-scoring.sh
source "$SCRIPT_DIR/ct-scoring.sh"
# shellcheck source=scripts/ct-manifest.sh
source "$SCRIPT_DIR/ct-manifest.sh"

ct_sync_slugify() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g'
}

ct_sync_curate() {
  local root=".xgh/context-tree"
  local domain=""
  local topic=""
  local title=""
  local content=""

  while (( $# > 0 )); do
    case "$1" in
      --root)
        root=${2:?root required}
        shift 2
        ;;
      --domain)
        domain=${2:?domain required}
        shift 2
        ;;
      --topic)
        topic=${2:?topic required}
        shift 2
        ;;
      --title)
        title=${2:?title required}
        shift 2
        ;;
      --content)
        content=${2:?content required}
        shift 2
        ;;
      *)
        echo "Unknown option: $1" >&2
        return 1
        ;;
    esac
  done

  [[ -n "$domain" && -n "$topic" && -n "$title" && -n "$content" ]] || {
    echo "curate requires --domain --topic --title --content" >&2
    return 1
  }

  local domain_slug topic_slug title_slug rel_path file now
  domain_slug=$(ct_sync_slugify "$domain")
  topic_slug=$(ct_sync_slugify "$topic")
  title_slug=$(ct_sync_slugify "$title")

  rel_path="$domain_slug/$topic_slug/$title_slug.md"
  file="$root/$rel_path"
  now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  mkdir -p "$(dirname "$file")"
  ct_manifest_init "$root"

  if [[ -f "$file" ]]; then
    {
      echo ""
      echo "## Update ${now}"
      echo "$content"
    } >> "$file"
    ct_score_apply_event "$file" "update"
  else
    cat > "$file" <<EOF
---
title: ${title}
tags: [${domain_slug}, ${topic_slug}]
keywords: [${title_slug}]
importance: 50
recency: 1.0000
maturity: draft
accessCount: 0
updateCount: 0
createdAt: ${now}
updatedAt: ${now}
source: auto-curate
---

## Raw Concept
${content}

## Narrative
${content}

## Facts
- category: note
  fact: ${content}
EOF
    ct_score_recalculate "$file"
  fi

  ct_manifest_add "$root" "$rel_path"
  ct_manifest_update_indexes "$root"

  echo "$rel_path"
}

ct_sync_query() {
  local root=".xgh/context-tree"
  local query=""
  local top=10

  while (( $# > 0 )); do
    case "$1" in
      --root)
        root=${2:?root required}
        shift 2
        ;;
      --query)
        query=${2:?query required}
        shift 2
        ;;
      --top)
        top=${2:?top required}
        shift 2
        ;;
      *)
        echo "Unknown option: $1" >&2
        return 1
        ;;
    esac
  done

  [[ -n "$query" ]] || {
    echo "query requires --query" >&2
    return 1
  }

  "$SCRIPT_DIR/ct-search.sh" "$root" "$query" "$top"
}

ct_sync_refresh() {
  local root=${1:-.xgh/context-tree}
  ct_manifest_rebuild "$root"
  ct_manifest_update_indexes "$root"
}

usage() {
  cat <<'EOF'
Usage:
  ct-sync.sh curate --root <path> --domain <name> --topic <name> --title <title> --content <text>
  ct-sync.sh query --root <path> --query <text> [--top <n>]
  ct-sync.sh refresh [root]
EOF
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  cmd=${1:-}
  shift || true

  case "$cmd" in
    curate)
      ct_sync_curate "$@"
      ;;
    query)
      ct_sync_query "$@"
      ;;
    refresh)
      ct_sync_refresh "${1:-.xgh/context-tree}"
      ;;
    *)
      usage
      exit 1
      ;;
  esac
fi
