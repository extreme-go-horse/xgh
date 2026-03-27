# ship-prs

Ship a batch of PRs to merge automatically -- fixes review comments, dispatches fix agents, and auto-merges when approved.

## When it runs

- **On demand:** `/xgh-ship-prs start <PR> [<PR>...]`

## What it does

1. Polls each PR for review status on a configurable interval
2. When reviewer comments arrive, analyzes and addresses them
3. Dispatches fix agents if code changes are needed
4. Auto-merges when all criteria pass (approvals, CI, resolved threads)

## Usage

```
/xgh-ship-prs start 123 456 --interval 3m --merge-method squash
/xgh-ship-prs poll-once 123
/xgh-ship-prs status
/xgh-ship-prs stop | pause | resume
/xgh-ship-prs hold 123 | unhold 123
/xgh-ship-prs dry-run 123 | log 123
```

## Key flags

- `--repo owner/repo` -- Override repository
- `--interval 3m` -- Poll interval (default: 3m)
- `--merge-method merge|squash|rebase` -- Override merge method
- `--reviewer <login>` -- Override reviewer
- `--max-fix-cycles 3` -- Max fix attempts before stopping
- `--post-merge-hook '<cmd>'` -- Command to run after merge

## Agent

Dispatches `pr-poller` (haiku) for status polling.

## Configuration

Reads defaults from `config/project.yaml` under `preferences.pr`.
