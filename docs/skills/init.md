# init

First-run onboarding wizard. Verifies MCP connections, sets up profile, adds first project, and runs initial retrieval.

## When it runs

- **On demand:** `/xgh-init`

## What it does

Walks through 7 steps (about 5 minutes):

1. **Bootstrap** -- Creates `~/.xgh/` data directories, copies ingest.yaml from template
2. **Verify MCP connections** -- Checks Slack, Jira, GitHub, Confluence, Figma
3. **Set up profile** -- Name, Slack ID, role, team, platforms
4. **Add first project** -- Slack channels, Jira boards, GitHub repos
5. **Initial retrieval** -- Pulls recent context from configured sources
6. **Profile team** (optional) -- Analyzes Jira history for throughput
7. **Index codebase** (optional) -- Extracts module list and conventions

## Agent

Dispatches `onboarding-guide` (sonnet) for interactive guidance.
