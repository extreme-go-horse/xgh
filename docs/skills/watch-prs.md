# watch-prs

Passively monitor PRs -- surfaces review changes, new comments, CI status, and merge-readiness. Never merges, never requests reviews, never dispatches agents.

## When it runs

- **On demand:** `/xgh-watch-prs start <PR> [<PR>...]`

## What it does

1. Polls each PR on a configurable interval
2. Reports changes between polls:
   - New comments
   - Review state changes
   - CI status updates
   - Merge-readiness changes
3. Read-only: takes no action

Use `/xgh-ship-prs` to actively drive PRs to merge.

## Usage

```
/xgh-watch-prs start 123 456 --interval 3m
/xgh-watch-prs poll-once 123
/xgh-watch-prs status
/xgh-watch-prs stop
```

## Agent

Dispatches `pr-poller` (haiku) in observe mode.

## Configuration

Reads defaults from `config/project.yaml` under `preferences.pr`.
