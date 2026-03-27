# track

Add a new project to xgh context monitoring via interactive onboarding.

## When it runs

- **On demand:** `/xgh-track`

## What it does

1. Collects project details interactively:
   - Project name and your role
   - Slack channels to monitor
   - Jira project key
   - GitHub repos
   - Confluence pages
   - Figma links
2. Writes project config to `~/.xgh/ingest.yaml`
3. Runs initial retrieval for the new project

## Configuration

Edits `~/.xgh/ingest.yaml` directly. See [Configuration](../configuration.md) for project schema.
