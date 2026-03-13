#!/usr/bin/env bash
# xgh SessionStart hook
# Loads context tree, injects top core/validated knowledge files into the session.
# Output: JSON {"result": "...context to inject..."}
set -euo pipefail

# ── Configuration ──────────────────────────────────────────
# XGH_CONTEXT_TREE_PATH can be set by the installer or env; defaults to repo-relative path.
# The hook searches: env var > .xgh/context-tree > fallback message.
CONTEXT_TREE="${XGH_CONTEXT_TREE_PATH:-}"
MAX_FILES=5

# If not set via env, try to find it relative to the repo root
if [ -z "$CONTEXT_TREE" ]; then
  # Walk up to find .xgh/context-tree (handles being called from .claude/hooks/)
  SEARCH_DIR="$(pwd)"
  while [ "$SEARCH_DIR" != "/" ]; do
    if [ -d "${SEARCH_DIR}/.xgh/context-tree" ]; then
      CONTEXT_TREE="${SEARCH_DIR}/.xgh/context-tree"
      break
    fi
    SEARCH_DIR="$(dirname "$SEARCH_DIR")"
  done
fi

# ── Helper: escape string for JSON ────────────────────────
json_escape() {
  python3 -c "
import json, sys
text = sys.stdin.read()
print(json.dumps(text), end='')
" 2>/dev/null || {
    # Fallback: basic escaping if python3 unavailable
    sed 's/\\/\\\\/g; s/"/\\"/g; s/\t/\\t/g' | tr '\n' ' '
  }
}

# ── No context tree found ─────────────────────────────────
if [ -z "$CONTEXT_TREE" ] || [ ! -d "$CONTEXT_TREE" ]; then
  RESULT="[xgh] No context tree found. Run /xgh-curate to start building team knowledge, or run the xgh installer to initialize the context tree."
  echo "{\"result\": $(echo "$RESULT" | json_escape)}"
  exit 0
fi

MANIFEST="${CONTEXT_TREE}/_manifest.json"

if [ ! -f "$MANIFEST" ]; then
  RESULT="[xgh] Context tree exists at ${CONTEXT_TREE} but _manifest.json is missing. Run /xgh-status to diagnose."
  echo "{\"result\": $(echo "$RESULT" | json_escape)}"
  exit 0
fi

# ── Parse manifest and collect top knowledge files ─────────
# Uses python3 for reliable JSON parsing (available on macOS, most Linux)
CONTEXT_BLOCK=$(python3 << PYEOF
import json, os, sys

manifest_path = "${MANIFEST}"
context_tree = "${CONTEXT_TREE}"
max_files = ${MAX_FILES}

try:
    with open(manifest_path) as f:
        manifest = json.load(f)
except Exception as e:
    print(f"[xgh] Error reading manifest: {e}")
    sys.exit(0)

team = manifest.get("team", "unknown")

# Collect all topics with their metadata
entries = []
for domain in manifest.get("domains", []):
    for topic in domain.get("topics", []):
        maturity = topic.get("maturity", "draft")
        importance = topic.get("importance", 0)
        path = topic.get("path", "")
        name = topic.get("name", "")
        # Only consider core and validated files
        if maturity in ("core", "validated"):
            entries.append({
                "name": name,
                "path": path,
                "importance": importance,
                "maturity": maturity,
            })

# Sort by importance descending, core before validated at same importance
entries.sort(key=lambda e: (0 if e["maturity"] == "core" else 1, -e["importance"]))

# If we have fewer than max_files core/validated, fill with top draft files
if len(entries) < max_files:
    draft_entries = []
    for domain in manifest.get("domains", []):
        for topic in domain.get("topics", []):
            if topic.get("maturity", "draft") == "draft":
                draft_entries.append({
                    "name": topic.get("name", ""),
                    "path": topic.get("path", ""),
                    "importance": topic.get("importance", 0),
                    "maturity": "draft",
                })
    draft_entries.sort(key=lambda e: -e["importance"])
    entries.extend(draft_entries[:max_files - len(entries)])

# Take top N
top_entries = entries[:max_files]

# Build context block
lines = []
lines.append(f"[xgh] Team: {team} | Context tree loaded with {len(entries)} relevant entries.")
lines.append("")

if not top_entries:
    lines.append("No knowledge files found yet. Use /xgh-curate to start building team memory.")
else:
    lines.append("== Top Knowledge (auto-injected) ==")
    lines.append("")
    for entry in top_entries:
        filepath = os.path.join(context_tree, entry["path"])
        lines.append(f"--- {entry['name']} [{entry['maturity']}, importance:{entry['importance']}] ---")
        if os.path.isfile(filepath):
            try:
                with open(filepath) as f:
                    content = f.read().strip()
                # Extract title from YAML frontmatter if present, then strip frontmatter
                title = entry["name"]
                if content.startswith("---"):
                    parts = content.split("---", 2)
                    if len(parts) >= 3:
                        fm = parts[1]
                        for line in fm.splitlines():
                            if line.startswith("title:"):
                                title = line.split(":", 1)[1].strip().strip('"').strip("'")
                                break
                        content = parts[2].strip()
                lines.append(f"**{title}**")
                lines.append(content)
            except Exception:
                lines.append(f"(could not read {entry['path']})")
        else:
            lines.append(f"(file not found: {entry['path']})")
        lines.append("")

lines.append("== End xgh Context ==")

print("\n".join(lines))
PYEOF
)

# ── Output JSON ────────────────────────────────────────────
echo "{\"result\": $(echo "$CONTEXT_BLOCK" | json_escape)}"
exit 0
