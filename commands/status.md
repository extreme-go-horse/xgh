# /xgh status

Report xgh memory and context-tree health.

## Usage

`/xgh status`

## Checks

1. Verify context tree directory exists.
2. Verify `_manifest.json` exists and contains entries.
3. Show counts by maturity (`draft`, `validated`, `core`).
4. Show archive counts under `_archived/`.
5. Confirm required scripts and hooks are present.

## Suggested Commands

- `test -d .xgh/context-tree`
- `python3 -c 'import json; print(len(json.load(open(".xgh/context-tree/_manifest.json")).get("entries", [])))'`
- `find .xgh/context-tree -type f -name "*.md"`
