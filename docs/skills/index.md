# index

Extract a codebase inventory (module list, key files, naming conventions) into lossless-claude memory.

## When it runs

- **On demand:** `/xgh-index`

## What it does

1. Resolves active project from `~/.xgh/ingest.yaml`
2. Checks index freshness in lossless-claude memory
3. If stale or missing, scans the codebase:
   - Module boundaries and dependency graph
   - Key files (entry points, configs, tests)
   - Naming conventions and patterns
4. Stores structured inventory in lossless-claude memory

## Model

sonnet (needs code understanding)
