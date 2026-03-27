# briefing

Session briefing that aggregates Slack, Jira, GitHub, and team memory into a prioritized summary.

## When it runs

- **On demand:** `/xgh-briefing` or `/xgh-brief`
- **Automatically:** At session start if `XGH_BRIEFING=1` is set

## What it does

1. Queries lossless-claude memory for recent activity
2. Aggregates changes since your last session
3. Prioritizes items by urgency score
4. Presents a summary: PRs needing attention, urgent items, assigned tickets, team decisions

## Model

Uses the session's current model.

## Configuration

- Set `XGH_BRIEFING=1` in environment for automatic briefing at session start
- Respects `XGH_TEAM` for workspace memory queries
