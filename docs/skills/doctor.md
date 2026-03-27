# doctor

Validate the full xgh ingest pipeline -- config, connectivity, scheduler freshness, and workspace stats.

## When it runs

- **On demand:** `/xgh-doctor`

## What it checks

1. **Config** -- ingest.yaml exists, valid YAML, required fields present
2. **Connectivity** -- Each configured MCP server responds
3. **Scheduler** -- Jobs registered, last run timestamps, freshness
4. **Workspace** -- Inbox size, processed backlog, digest freshness

## Agent

Dispatches `pipeline-doctor` (sonnet) for diagnostics.
