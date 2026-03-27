# retrieve

Pull context from Slack, Jira, GitHub, Confluence, and Figma into `~/.xgh/inbox/`.

## When it runs

- **Automatically:** Every 5 minutes via scheduler
- **On demand:** `/xgh-retrieve`

## What it does

1. Checks daily token cap and quiet hours -- exits silently if either applies
2. Reads project configs from `~/.xgh/ingest.yaml`
3. For each active project, scans configured sources:
   - Slack: recent messages from monitored channels
   - Jira: ticket updates, assignments, comments
   - GitHub: PR activity, reviews, CI status
   - Confluence: page updates
   - Figma: design changes
4. Follows links found in messages (cross-source enrichment)
5. Writes raw items to `~/.xgh/inbox/` as frontmatter-tagged markdown

## Deep retriever

Runs hourly with wider scope: 7-day thread lookback, up to 5 pagination pages per channel.

## Model

haiku (cheapest -- simple fetching)

## Configuration

- Sources: `~/.xgh/ingest.yaml` under each project's `slack`, `jira`, `github`, `confluence`, `figma` keys
- Schedule: `schedule.retriever` in ingest.yaml (default: `*/5 * * * *`)
- Budget: `budget.retriever_max_turns` and `budget.retriever_timeout`
