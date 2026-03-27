# Getting Started

This guide walks you through installing xgh, configuring your first project, and running your first session briefing.

## Prerequisites

- [Claude Code](https://claude.ai/code) installed and authenticated
- MCP servers for your team's tools (optional but recommended):
  - Slack MCP for channel monitoring
  - Jira/Confluence MCP for ticket and doc access
  - GitHub MCP (or `gh` CLI) for PR workflows
  - Figma MCP for design context

## Installation

xgh is a Claude Code plugin. Install it from the marketplace or as a local plugin:

```bash
# From marketplace (if registered)
# The plugin registers automatically on next session start

# Or install locally for development
cd ~/Developer/xgh
claude /install-local-plugin
```

After installation, start a new Claude Code session. xgh hooks activate automatically.

## First-time setup

Run the onboarding wizard:

```
/xgh-init
```

This walks you through 7 steps (takes about 5 minutes):

1. **Bootstrap** -- Creates `~/.xgh/` data directories and copies the config template
2. **Verify MCP connections** -- Checks which integrations are available (Slack, Jira, GitHub, etc.)
3. **Set up your profile** -- Name, Slack ID, team, platform
4. **Add your first project** -- Slack channels, Jira boards, GitHub repos to monitor
5. **Run initial retrieval** -- Pulls recent context from configured sources
6. **Profile your team** (optional) -- Analyzes Jira history for team throughput
7. **Index your codebase** (optional) -- Extracts module list and naming conventions

## Configuration files

After setup, you have two key config files:

| File | Location | Purpose |
|------|----------|---------|
| `~/.xgh/ingest.yaml` | User home | Your profile, projects, schedule, urgency settings |
| `config/project.yaml` | In the xgh repo | Project preferences: PR settings, VCS rules, severity levels |

Edit `~/.xgh/ingest.yaml` to add more projects:

```
/xgh-track
```

See [Configuration](configuration.md) for full details on all config files.

## Your first briefing

Once setup is complete, run:

```
/xgh-briefing
```

This aggregates recent activity from all your configured sources (Slack, Jira, GitHub) and presents a prioritized summary of what needs your attention.

The briefing runs automatically at session start once the scheduler is active.

## Daily workflow

A typical xgh-powered session looks like:

1. **Start session** -- xgh hooks inject context and preferences automatically
2. **Review briefing** -- `/xgh-briefing` shows what changed since your last session
3. **Work on tasks** -- Use `/xgh-dispatch` to route tasks to the best AI agent
4. **Ship PRs** -- `/xgh-ship-prs` handles review comments and auto-merges
5. **Monitor** -- `/xgh-watch-prs` passively tracks PR status

## Key commands to learn first

| Command | What it does |
|---------|-------------|
| `/xgh-help` | Shows all commands with contextual suggestions |
| `/xgh-briefing` | Session briefing from all sources |
| `/xgh-doctor` | Validates pipeline health |
| `/xgh-track` | Adds a project to monitoring |
| `/xgh-dispatch` | Routes a task to the best AI agent |

## What happens in the background

xgh runs two automated loops (configurable via `/xgh-schedule`):

- **Retriever** (every 5 min): Pulls new messages from Slack, Jira, GitHub
- **Analyzer** (every 30 min): Classifies inbox items, extracts memories, generates digests

These respect quiet hours (default: 10 PM - 7 AM) and quiet days (weekends).

## Next steps

- [Configuration](configuration.md) -- Customize preferences, add projects, tune urgency
- [Skills](skills/README.md) -- Browse all 28 skills
- [Architecture](architecture.md) -- Understand the retrieve-analyze-brief pipeline
- [Troubleshooting](troubleshooting.md) -- Fix common issues
