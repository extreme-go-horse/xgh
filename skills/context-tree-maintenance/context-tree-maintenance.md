# xgh Context Tree Maintenance

Keep context-tree quality high through scoring, indexing, and archive hygiene.

## Maintenance Loop

1. Recalculate scores after updates.
2. Rebuild `_manifest.json` and `_index.md` files.
3. Archive low-importance draft entries using `context-tree.sh archive`.
4. Restore archived entries only when they become relevant.

## Operational Commands

- `scripts/ct-scoring.sh bump <file> <event>`
- `scripts/ct-manifest.sh rebuild <root>`
- `scripts/ct-manifest.sh update-indexes <root>`
- `scripts/ct-archive.sh run <root>`

Archive decisions should preserve recoverability through `.full.md` snapshots.
