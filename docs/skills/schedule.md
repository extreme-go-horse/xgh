# schedule

Manage the xgh background scheduler -- list, pause, resume, or run retrieve/analyze jobs.

## When it runs

- **On demand:** `/xgh-schedule`

## Subcommands

| Command | Action |
|---------|--------|
| `/xgh-schedule` or `status` | Show scheduler status |
| `pause retrieve` | Pause retrieval jobs |
| `pause analyze` | Pause analysis jobs |
| `resume retrieve` | Resume retrieval jobs |
| `resume analyze` | Resume analysis jobs |
| `run retrieve` | Run retrieval immediately |
| `run analyze` | Run analysis immediately |

## Configuration

Schedule settings in `~/.xgh/ingest.yaml` under `schedule`:
- `paused`: Global pause flag
- `jobs`: Custom periodic jobs
