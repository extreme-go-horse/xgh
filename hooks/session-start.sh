#!/usr/bin/env bash
set -euo pipefail

CONTEXT_TREE_PATH="${XGH_CONTEXT_TREE:-.xgh/context-tree}"
MAX_FILES="${XGH_SESSION_START_MAX_FILES:-5}"

python3 - "$CONTEXT_TREE_PATH" "$MAX_FILES" <<'PY'
import json
import pathlib
import re
import sys

root = pathlib.Path(sys.argv[1])
max_files = int(sys.argv[2])

if not root.exists():
	print(
		json.dumps(
			{
				"result": f"xgh: context tree not found at {root}",
				"contextFiles": [],
				"decisionTable": [
					"Before writing code: run cipher_memory_search first.",
					"After significant work: run cipher_extract_and_operate_memory.",
				],
			}
		)
	)
	raise SystemExit(0)

frontmatter_re = re.compile(r"^([A-Za-z0-9_]+):\s*(.*)$")


def parse_entry(path: pathlib.Path):
	text = path.read_text(encoding="utf-8")
	lines = text.splitlines()
	meta = {
		"title": path.stem,
		"importance": 50,
		"maturity": "draft",
		"updatedAt": "",
	}

	content_start = 0
	if len(lines) >= 3 and lines[0].strip() == "---":
		content_start = 1
		for idx, line in enumerate(lines[1:], start=1):
			if line.strip() == "---":
				content_start = idx + 1
				break

			match = frontmatter_re.match(line.strip())
			if not match:
				continue
			key, value = match.groups()
			value = value.strip().strip('"').strip("'")

			if key == "title":
				meta["title"] = value or meta["title"]
			elif key == "importance":
				try:
					meta["importance"] = int(value)
				except ValueError:
					pass
			elif key == "maturity":
				meta["maturity"] = value or meta["maturity"]
			elif key == "updatedAt":
				meta["updatedAt"] = value

	body_lines = [line.strip() for line in lines[content_start:] if line.strip()]
	excerpt = " ".join(body_lines[:3])

	maturity_rank = {"core": 3, "validated": 2, "draft": 1}.get(meta["maturity"], 0)
	score = maturity_rank * 100 + meta["importance"]

	return {
		"path": path.relative_to(root).as_posix(),
		"title": meta["title"],
		"importance": meta["importance"],
		"maturity": meta["maturity"],
		"updatedAt": meta["updatedAt"],
		"excerpt": excerpt,
		"_score": score,
	}


entries = []
for file_path in root.rglob("*.md"):
	rel = file_path.relative_to(root).as_posix()
	if rel.startswith("_archived/"):
		continue
	if file_path.name == "_index.md":
		continue
	entries.append(parse_entry(file_path))

entries.sort(key=lambda item: item["_score"], reverse=True)
selected = entries[:max_files]
for item in selected:
	item.pop("_score", None)

result = {
	"result": f"xgh: session-start loaded {len(selected)} context files",
	"contextFiles": selected,
	"decisionTable": [
		"Before writing code: run cipher_memory_search first.",
		"After significant work: run cipher_extract_and_operate_memory.",
		"For architectural choices: store rationale with cipher_store_reasoning_memory.",
	],
}

print(json.dumps(result))
PY
