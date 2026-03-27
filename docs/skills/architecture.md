# architecture (skill)

Analyze codebase architecture -- module boundaries, dependency graph, critical paths, and public surfaces.

## When it runs

- **On demand:** `/xgh-architecture`

## What it does

1. Resolves active project from `~/.xgh/ingest.yaml`
2. Checks index freshness -- requires a recent `/xgh-index` run
3. Analyzes:
   - Module boundaries and layering
   - Dependency graph (imports, includes)
   - Critical paths (hot code paths)
   - Public surfaces (APIs, exports)
4. Produces a structured architecture report
