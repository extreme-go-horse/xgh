# pipeline-doctor

Pipeline health diagnostics -- checks config, connectivity, scheduler, and workspace.

## Model

sonnet

## Dispatched by

`doctor` skill

## What it checks

1. Config validity (ingest.yaml structure)
2. MCP server connectivity
3. Scheduler job registration and freshness
4. Inbox/processed/digest workspace stats

## Tools

Read, Grep, Glob, Bash
