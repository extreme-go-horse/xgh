# command-center

Global orchestrator view -- cross-project briefing, triage, and dispatch.

## When it runs

- **On demand:** `/xgh-command-center`

## What it does

1. Aggregates status across all active projects
2. Triages items by urgency and relevance
3. In `auto_dispatch` mode, routes actionable items to appropriate skills
4. Presents a cross-project dashboard

## Dispatch modes

- `alert_only` -- Surface items, take no action
- `auto_triage` -- Surface and categorize (default)
- `auto_dispatch` -- Surface, categorize, and dispatch

## Configuration

Settings in `~/.xgh/ingest.yaml` under `command_center`:
- `dispatch_mode`: How aggressively to act
- `schedule.morning_briefing`: Full briefing cron
- `schedule.pulse`: Quick pulse cron
