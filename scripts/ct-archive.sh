#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=scripts/ct-frontmatter.sh
source "$SCRIPT_DIR/ct-frontmatter.sh"
# shellcheck source=scripts/ct-manifest.sh
source "$SCRIPT_DIR/ct-manifest.sh"

ct_archive_run() {
  local root=${1:?root required}
  local archived_count=0

  mkdir -p "$root/_archived"

  while IFS= read -r file; do
    local rel
    rel=${file#"$root/"}

    local importance maturity title
    importance=$(ct_frontmatter_get "$file" "importance" 2>/dev/null || echo "50")
    maturity=$(ct_frontmatter_get "$file" "maturity" 2>/dev/null || echo "draft")
    title=$(ct_frontmatter_get "$file" "title" 2>/dev/null || basename "$file" .md)

    if [[ ! "$importance" =~ ^-?[0-9]+$ ]]; then
      importance=50
    fi

    if [[ "$maturity" == "draft" ]] && (( importance < 35 )); then
      local rel_dir rel_base archive_dir full_file stub_file
      rel_dir=$(dirname "$rel")
      rel_base=$(basename "$rel" .md)

      archive_dir="$root/_archived"
      if [[ "$rel_dir" != "." ]]; then
        archive_dir="$archive_dir/$rel_dir"
      fi

      mkdir -p "$archive_dir"

      full_file="$archive_dir/${rel_base}.full.md"
      stub_file="$archive_dir/${rel_base}.stub.md"

      cp "$file" "$full_file"

      cat > "$stub_file" <<EOF
---
title: ${title}
archivedFrom: ${rel}
importance: ${importance}
maturity: draft
---

This entry was archived because it is low-importance draft knowledge.

Full content: ${rel_base}.full.md
EOF

      rm -f "$file"
      ct_manifest_remove "$root" "$rel" || true
      archived_count=$((archived_count + 1))
    fi
  done < <(find "$root" -type f -name "*.md" ! -name "_index.md" ! -path "$root/_archived/*")

  ct_manifest_update_indexes "$root"

  echo "$archived_count"
}

ct_archive_restore() {
  local root=${1:?root required}
  local archived_full=${2:?archived full file required}

  if [[ "$archived_full" != "$root/"* ]]; then
    archived_full="$root/$archived_full"
  fi

  [[ -f "$archived_full" ]] || {
    echo "Archived file not found: $archived_full" >&2
    return 1
  }

  local rel
  rel=${archived_full#"$root/_archived/"}
  rel=${rel%.full.md}.md

  local destination="$root/$rel"
  mkdir -p "$(dirname "$destination")"
  cp "$archived_full" "$destination"

  ct_manifest_add "$root" "$rel"
  ct_manifest_update_indexes "$root"

  echo "$rel"
}

usage() {
  cat <<'EOF'
Usage:
  ct-archive.sh run <root>
  ct-archive.sh restore <root> <archived-full-file>
EOF
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  cmd=${1:-}

  case "$cmd" in
    run)
      ct_archive_run "${2:?root required}"
      ;;
    restore)
      ct_archive_restore "${2:?root required}" "${3:?archived full file required}"
      ;;
    *)
      usage
      exit 1
      ;;
  esac
fi
