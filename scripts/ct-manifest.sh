#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=scripts/ct-frontmatter.sh
source "$SCRIPT_DIR/ct-frontmatter.sh"

ct_manifest_file() {
  local root=${1:?root required}
  echo "$root/_manifest.json"
}

ct_manifest_init() {
  local root=${1:?root required}
  local manifest
  manifest=$(ct_manifest_file "$root")

  mkdir -p "$root"

  if [[ -f "$manifest" ]]; then
    python3 - "$manifest" <<'PY'
import json
import sys

path = sys.argv[1]
with open(path, "r", encoding="utf-8") as fh:
    data = json.load(fh)

if "entries" not in data or not isinstance(data["entries"], list):
    data["entries"] = []

with open(path, "w", encoding="utf-8") as fh:
    json.dump(data, fh, indent=2)
PY
    return 0
  fi

  local now
  now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  cat > "$manifest" <<EOF
{
  "version": "1.0.0",
  "team": "${XGH_TEAM:-my-team}",
  "created": "${now}",
  "domains": [],
  "entries": []
}
EOF
}

ct_manifest_add() {
  local root=${1:?root required}
  local rel_path=${2:?relative path required}
  local manifest
  manifest=$(ct_manifest_file "$root")
  local abs_path="$root/$rel_path"

  ct_manifest_init "$root"

  local title maturity importance updated_at
  title=$(ct_frontmatter_get "$abs_path" "title" 2>/dev/null || basename "$rel_path" .md)
  maturity=$(ct_frontmatter_get "$abs_path" "maturity" 2>/dev/null || echo "draft")
  importance=$(ct_frontmatter_get "$abs_path" "importance" 2>/dev/null || echo "50")
  updated_at=$(ct_frontmatter_get "$abs_path" "updatedAt" 2>/dev/null || date -u +"%Y-%m-%dT%H:%M:%SZ")

  python3 - "$manifest" "$rel_path" "$title" "$maturity" "$importance" "$updated_at" <<'PY'
import json
import sys

manifest, rel_path, title, maturity, importance, updated_at = sys.argv[1:]

with open(manifest, "r", encoding="utf-8") as fh:
    data = json.load(fh)

entries = data.setdefault("entries", [])
next_entries = [entry for entry in entries if entry.get("path") != rel_path]
next_entries.append(
    {
        "path": rel_path,
        "title": title,
        "maturity": maturity,
        "importance": int(importance) if str(importance).isdigit() else 50,
        "updatedAt": updated_at,
    }
)
next_entries.sort(key=lambda x: x["path"])

data["entries"] = next_entries

with open(manifest, "w", encoding="utf-8") as fh:
    json.dump(data, fh, indent=2)
PY
}

ct_manifest_remove() {
  local root=${1:?root required}
  local rel_path=${2:?relative path required}
  local manifest
  manifest=$(ct_manifest_file "$root")

  [[ -f "$manifest" ]] || return 0

  python3 - "$manifest" "$rel_path" <<'PY'
import json
import sys

manifest, rel_path = sys.argv[1:]
with open(manifest, "r", encoding="utf-8") as fh:
    data = json.load(fh)

entries = data.get("entries", [])
data["entries"] = [entry for entry in entries if entry.get("path") != rel_path]

with open(manifest, "w", encoding="utf-8") as fh:
    json.dump(data, fh, indent=2)
PY
}

ct_manifest_rebuild() {
  local root=${1:?root required}
  local manifest
  manifest=$(ct_manifest_file "$root")

  ct_manifest_init "$root"

  python3 - "$root" "$manifest" <<'PY'
import json
import pathlib
import re
import sys

root = pathlib.Path(sys.argv[1])
manifest = pathlib.Path(sys.argv[2])

frontmatter_re = re.compile(r"^([A-Za-z0-9_]+):\s*(.*)$")


def parse_frontmatter(path: pathlib.Path):
    title = path.stem
    maturity = "draft"
    importance = 50
    updated_at = ""

    text = path.read_text(encoding="utf-8")
    lines = text.splitlines()
    if len(lines) >= 3 and lines[0].strip() == "---":
        for line in lines[1:]:
            if line.strip() == "---":
                break
            m = frontmatter_re.match(line.strip())
            if not m:
                continue
            key, value = m.groups()
            value = value.strip().strip('"').strip("'")
            if key == "title":
                title = value or title
            elif key == "maturity":
                maturity = value or maturity
            elif key == "importance":
                try:
                    importance = int(value)
                except ValueError:
                    importance = 50
            elif key == "updatedAt":
                updated_at = value

    return {
        "title": title,
        "maturity": maturity,
        "importance": importance,
        "updatedAt": updated_at,
    }

with open(manifest, "r", encoding="utf-8") as fh:
    data = json.load(fh)

entries = []
for path in root.rglob("*.md"):
    rel = path.relative_to(root).as_posix()
    if rel.startswith("_archived/"):
        continue
    if path.name == "_index.md":
        continue

    meta = parse_frontmatter(path)
    entries.append({"path": rel, **meta})

entries.sort(key=lambda x: x["path"])
data["entries"] = entries

with open(manifest, "w", encoding="utf-8") as fh:
    json.dump(data, fh, indent=2)
PY
}

ct_manifest_list() {
  local root=${1:?root required}
  local manifest
  manifest=$(ct_manifest_file "$root")

  [[ -f "$manifest" ]] || return 0

  python3 - "$manifest" <<'PY'
import json
import sys

with open(sys.argv[1], "r", encoding="utf-8") as fh:
    data = json.load(fh)

for entry in data.get("entries", []):
    print(entry.get("path", ""))
PY
}

ct_manifest_update_indexes() {
  local root=${1:?root required}
  local manifest
  manifest=$(ct_manifest_file "$root")

  ct_manifest_init "$root"

  python3 - "$root" "$manifest" <<'PY'
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
manifest = pathlib.Path(sys.argv[2])

with open(manifest, "r", encoding="utf-8") as fh:
    entries = json.load(fh).get("entries", [])

root_index = root / "_index.md"
root_index.parent.mkdir(parents=True, exist_ok=True)

lines = ["# Context Tree Index", "", "Generated from `_manifest.json`.", ""]
if not entries:
    lines.append("No knowledge entries yet.")
else:
    for entry in entries:
        path = entry.get("path", "")
        title = entry.get("title", pathlib.Path(path).stem)
        lines.append(f"- [{title}]({path})")

root_index.write_text("\n".join(lines) + "\n", encoding="utf-8")

by_domain = {}
for entry in entries:
    path = entry.get("path", "")
    parts = pathlib.Path(path).parts
    if not parts:
        continue
    domain = parts[0]
    by_domain.setdefault(domain, []).append(entry)

for domain, domain_entries in by_domain.items():
    domain_dir = root / domain
    domain_dir.mkdir(parents=True, exist_ok=True)
    domain_index = domain_dir / "_index.md"

    lines = [f"# {domain} Index", "", "Entries in this domain:", ""]
    for entry in sorted(domain_entries, key=lambda x: x.get("path", "")):
        path = entry.get("path", "")
        title = entry.get("title", pathlib.Path(path).stem)
        rel = pathlib.Path(path).relative_to(domain).as_posix()
        lines.append(f"- [{title}]({rel})")

    domain_index.write_text("\n".join(lines) + "\n", encoding="utf-8")
PY
}

usage() {
  cat <<'EOF'
Usage:
  ct-manifest.sh init <root>
  ct-manifest.sh add <root> <relative-path>
  ct-manifest.sh remove <root> <relative-path>
  ct-manifest.sh list <root>
  ct-manifest.sh rebuild <root>
  ct-manifest.sh update-indexes <root>
EOF
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  cmd=${1:-}

  case "$cmd" in
    init)
      ct_manifest_init "${2:?root required}"
      ;;
    add)
      ct_manifest_add "${2:?root required}" "${3:?relative path required}"
      ;;
    remove)
      ct_manifest_remove "${2:?root required}" "${3:?relative path required}"
      ;;
    list)
      ct_manifest_list "${2:?root required}"
      ;;
    rebuild)
      ct_manifest_rebuild "${2:?root required}"
      ;;
    update-indexes)
      ct_manifest_update_indexes "${2:?root required}"
      ;;
    *)
      usage
      exit 1
      ;;
  esac
fi
