# profile

Analyze an engineer's Jira history to produce throughput profiles, ticket affinity, and data-driven estimates.

## When it runs

- **On demand:** `/xgh-profile <name> [project-key]`

## Usage

```
/xgh-profile Alice           # Single engineer
/xgh-profile Alice PTECH     # Scoped to project
/xgh-profile Alice,Bob,Carol PTECH  # Team view
```

## What it does

1. Fetches Jira history for the named engineer(s)
2. Analyzes:
   - Throughput (tickets/week, story points/sprint)
   - Ticket type affinity (bugs vs features vs chores)
   - Time-to-completion distributions
3. If project key provided, estimates effort for open tickets
4. In team view, produces comparative analysis and assignment recommendations
