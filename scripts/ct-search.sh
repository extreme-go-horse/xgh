#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=scripts/ct-frontmatter.sh
source "$SCRIPT_DIR/ct-frontmatter.sh"

ct_search_run() {
  local root=${1:?root required}
  local query=${2:?query required}
  local top=${3:-10}

  local bm25_json
  bm25_json=$(python3 "$SCRIPT_DIR/bm25.py" --root "$root" --top "$top" "$query")

    python3 - "$root" "$bm25_json" <<'PY'
import json
import pathlib
import re
import sys

root = pathlib.Path(sys.argv[1])
raw = json.loads(sys.argv[2] or "[]")
if not raw:
    print("[]")
    raise SystemExit(0)

frontmatter_re = re.compile(r"^([A-Za-z0-9_]+):\s*(.*)$")


def parse_meta(path: pathlib.Path):
    importance = 50
    recency = 1.0
    maturity = "draft"

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
            if key == "importance":
                try:
                    importance = int(value)
                except ValueError:
                    importance = 50
            elif key == "recency":
                try:
                    recency = float(value)
                except ValueError:
                    recency = 1.0
            elif key == "maturity":
                maturity = value or "draft"

    return importance, recency, maturity

max_bm25 = max((item.get("score", 0.0) for item in raw), default=1.0)
if max_bm25 <= 0:
    max_bm25 = 1.0

scored = []
for item in raw:
    rel = item.get("path", "")
    file_path = root / rel
    importance, recency, maturity = parse_meta(file_path)

    bm25_norm = float(item.get("score", 0.0)) / max_bm25
    importance_norm = max(min(importance / 100.0, 1.0), 0.0)
    recency_norm = max(min(recency, 1.0), 0.0)

    maturity_boost = 1.15 if maturity == "core" else 1.0

    score = (0.3 * bm25_norm + 0.1 * importance_norm + 0.1 * recency_norm) * maturity_boost

    scored.append(
        {
            "path": rel,
            "title": item.get("title", pathlib.Path(rel).stem),
            "bm25": round(float(item.get("score", 0.0)), 6),
            "importance": importance,
            "recency": round(recency_norm, 4),
            "maturity": maturity,
            "score": round(score, 6),
            "snippet": item.get("snippet", ""),
        }
    )

scored.sort(key=lambda x: x["score"], reverse=True)
print(json.dumps(scored, indent=2))
PY
}

usage() {
  cat <<'EOF'
Usage:
  ct-search.sh <root> <query> [top]
EOF
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  if (( $# < 2 )); then
    usage
    exit 1
  fi

  ct_search_run "$1" "$2" "${3:-10}"
fi
