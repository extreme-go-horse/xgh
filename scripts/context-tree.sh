#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=scripts/ct-frontmatter.sh
source "$SCRIPT_DIR/ct-frontmatter.sh"
# shellcheck source=scripts/ct-scoring.sh
source "$SCRIPT_DIR/ct-scoring.sh"
# shellcheck source=scripts/ct-manifest.sh
source "$SCRIPT_DIR/ct-manifest.sh"
# shellcheck source=scripts/ct-archive.sh
source "$SCRIPT_DIR/ct-archive.sh"

CT_ROOT=${XGH_CONTEXT_TREE:-.xgh/context-tree}

ct_now() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

ct_create_entry() {
  local rel_path=${1:?relative path required}
  local title=${2:?title required}
  local content=${3:-}

  local file="$CT_ROOT/$rel_path"
  mkdir -p "$(dirname "$file")"

  if [[ -f "$file" ]]; then
    echo "Entry already exists: $rel_path" >&2
    return 1
  fi

  local now
  now=$(ct_now)

  cat > "$file" <<EOF
---
title: ${title}
tags: []
keywords: []
importance: 50
recency: 1.0000
maturity: draft
accessCount: 0
updateCount: 0
createdAt: ${now}
updatedAt: ${now}
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
  ct_manifest_add "$CT_ROOT" "$rel_path"
  ct_manifest_update_indexes "$CT_ROOT"
}

ct_read_entry() {
  local rel_path=${1:?relative path required}
  cat "$CT_ROOT/$rel_path"
}

ct_update_entry() {
  local rel_path=${1:?relative path required}
  local content=${2:?content required}
  local file="$CT_ROOT/$rel_path"

  [[ -f "$file" ]] || {
    echo "Entry not found: $rel_path" >&2
    return 1
  }

  {
    echo ""
    echo "## Update $(ct_now)"
    echo "$content"
  } >> "$file"

  ct_score_apply_event "$file" "update"
  ct_manifest_add "$CT_ROOT" "$rel_path"
  ct_manifest_update_indexes "$CT_ROOT"
}

ct_delete_entry() {
  local rel_path=${1:?relative path required}
  local file="$CT_ROOT/$rel_path"

  [[ -f "$file" ]] || {
    echo "Entry not found: $rel_path" >&2
    return 1
  }

  rm -f "$file"
  ct_manifest_remove "$CT_ROOT" "$rel_path"
  ct_manifest_update_indexes "$CT_ROOT"
}

ct_list_entries() {
  find "$CT_ROOT" -type f -name "*.md" ! -name "_index.md" ! -path "$CT_ROOT/_archived/*" | \
    sed "s#^$CT_ROOT/##" | sort
}

ct_search_entries() {
  local query=${1:?query required}
  local top=${2:-10}
  "$SCRIPT_DIR/ct-search.sh" "$CT_ROOT" "$query" "$top"
}

ct_score_entry() {
  local rel_path=${1:?relative path required}
  local event=${2:-update}
  local file="$CT_ROOT/$rel_path"

  ct_score_apply_event "$file" "$event"
  ct_manifest_add "$CT_ROOT" "$rel_path"
  ct_manifest_update_indexes "$CT_ROOT"
}

ct_init_tree() {
  mkdir -p "$CT_ROOT"
  ct_manifest_init "$CT_ROOT"
  ct_manifest_update_indexes "$CT_ROOT"
}

usage() {
  cat <<'EOF'
Usage:
  context-tree.sh init
  context-tree.sh create <relative-path> <title> [content]
  context-tree.sh read <relative-path>
  context-tree.sh update <relative-path> <content>
  context-tree.sh delete <relative-path>
  context-tree.sh list
  context-tree.sh search <query> [top]
  context-tree.sh score <relative-path> [search-hit|update|manual]
  context-tree.sh archive
  context-tree.sh restore <archived-full-file>
  context-tree.sh sync <curate|query|refresh> [args...]
  context-tree.sh manifest <init|add|remove|list|rebuild|update-indexes> [args...]

Environment:
  XGH_CONTEXT_TREE   Context tree root (default: .xgh/context-tree)
EOF
}

main() {
  local cmd=${1:-}
  shift || true

  case "$cmd" in
    init)
      ct_init_tree
      ;;
    create)
      ct_create_entry "${1:?relative path required}" "${2:?title required}" "${3:-}"
      ;;
    read)
      ct_read_entry "${1:?relative path required}"
      ;;
    update)
      ct_update_entry "${1:?relative path required}" "${2:?content required}"
      ;;
    delete)
      ct_delete_entry "${1:?relative path required}"
      ;;
    list)
      ct_list_entries
      ;;
    search)
      ct_search_entries "${1:?query required}" "${2:-10}"
      ;;
    score)
      ct_score_entry "${1:?relative path required}" "${2:-update}"
      ;;
    archive)
      ct_archive_run "$CT_ROOT"
      ;;
    restore)
      ct_archive_restore "$CT_ROOT" "${1:?archived full file required}"
      ;;
    sync)
      "$SCRIPT_DIR/ct-sync.sh" "$@"
      ;;
    manifest)
      "$SCRIPT_DIR/ct-manifest.sh" "$@"
      ;;
    *)
      usage
      exit 1
      ;;
  esac
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
