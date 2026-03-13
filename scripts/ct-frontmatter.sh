#!/usr/bin/env bash
set -euo pipefail

ct_frontmatter_has() {
  local file=${1:?file required}
  [[ -f "$file" ]] || return 1

  local first_line
  first_line=$(head -n 1 "$file" 2>/dev/null || true)
  [[ "$first_line" == "---" ]] || return 1

  tail -n +2 "$file" | grep -m1 -x -- '---' >/dev/null
}

ct_frontmatter_get() {
  local file=${1:?file required}
  local key=${2:?key required}

  awk -v key="$key" '
    BEGIN { in_fm = 0; found = 0 }

    NR == 1 && $0 == "---" {
      in_fm = 1
      next
    }

    in_fm && $0 == "---" {
      exit
    }

    in_fm {
      if ($0 ~ "^[[:space:]]*" key ":[[:space:]]*") {
        value = $0
        sub("^[[:space:]]*" key ":[[:space:]]*", "", value)
        gsub(/^"|"$/, "", value)
        gsub(/^'"'"'|'"'"'$/, "", value)
        print value
        found = 1
        exit
      }
    }

    END {
      if (found == 0) {
        exit 1
      }
    }
  ' "$file"
}

ct_frontmatter_set() {
  local file=${1:?file required}
  local key=${2:?key required}
  local value=${3:?value required}
  local tmp
  tmp=$(mktemp)

  if [[ ! -f "$file" ]]; then
    {
      echo "---"
      echo "$key: $value"
      echo "---"
    } > "$tmp"
    mv "$tmp" "$file"
    return 0
  fi

  if ! ct_frontmatter_has "$file"; then
    {
      echo "---"
      echo "$key: $value"
      echo "---"
      cat "$file"
    } > "$tmp"
    mv "$tmp" "$file"
    return 0
  fi

  awk -v key="$key" -v value="$value" '
    BEGIN { in_fm = 0; replaced = 0 }

    NR == 1 && $0 == "---" {
      in_fm = 1
      print
      next
    }

    in_fm && $0 == "---" {
      if (replaced == 0) {
        print key ": " value
      }
      in_fm = 0
      print
      next
    }

    in_fm {
      if ($0 ~ "^[[:space:]]*" key ":[[:space:]]*") {
        print key ": " value
        replaced = 1
        next
      }
    }

    { print }
  ' "$file" > "$tmp"

  mv "$tmp" "$file"
}

ct_frontmatter_increment_int() {
  local file=${1:?file required}
  local key=${2:?key required}
  local current=0

  if current=$(ct_frontmatter_get "$file" "$key" 2>/dev/null); then
    :
  else
    current=0
  fi

  if [[ ! "$current" =~ ^-?[0-9]+$ ]]; then
    current=0
  fi

  ct_frontmatter_set "$file" "$key" "$((current + 1))"
}

usage() {
  cat <<'EOF'
Usage:
  ct-frontmatter.sh has <file>
  ct-frontmatter.sh get <file> <key>
  ct-frontmatter.sh set <file> <key> <value>
  ct-frontmatter.sh inc <file> <key>
EOF
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  cmd=${1:-}

  case "$cmd" in
    has)
      ct_frontmatter_has "${2:?file required}"
      ;;
    get)
      ct_frontmatter_get "${2:?file required}" "${3:?key required}"
      ;;
    set)
      ct_frontmatter_set "${2:?file required}" "${3:?key required}" "${4:?value required}"
      ;;
    inc)
      ct_frontmatter_increment_int "${2:?file required}" "${3:?key required}"
      ;;
    *)
      usage
      exit 1
      ;;
  esac
fi
