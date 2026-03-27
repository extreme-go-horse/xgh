# Commands

xgh has 30 slash commands. Most are thin wrappers that invoke a skill -- all logic lives in `skills/`.

## Context pipeline

| Command | What it does | Skill |
|---------|-------------|-------|
| `/xgh-retrieve` | Pull context from Slack, Jira, GitHub | [retrieve](../skills/retrieve.md) |
| `/xgh-analyze` | Classify inbox, extract memories | [analyze](../skills/analyze.md) |
| `/xgh-briefing` | Full session briefing | [briefing](../skills/briefing.md) |
| `/xgh-index` | Index a codebase into memory | [index](../skills/index.md) |
| `/xgh-track` | Add project to monitoring | [track](../skills/track.md) |
| `/xgh-calibrate` | Tune dedup threshold | [calibrate](../skills/calibrate.md) |

## Dispatch

| Command | What it does | Skill |
|---------|-------------|-------|
| `/xgh-dispatch` | Auto-route to best agent + model | [dispatch](../skills/dispatch.md) |
| `/xgh-codex` | Dispatch to Codex CLI | [codex](../skills/codex.md) |
| `/xgh-gemini` | Dispatch to Gemini CLI | [gemini](../skills/gemini.md) |
| `/xgh-glm` | Dispatch to GLM via OpenCode | [glm](../skills/glm.md) |
| `/xgh-opencode` | Dispatch to OpenCode CLI | [opencode](../skills/opencode.md) |
| `/xgh-coding-agents` | List AI coding agents | [coding-agents](../skills/coding-agents.md) |
| `/xgh-seed` | Push context to other AI platforms | [seed](../skills/seed.md) |

## PR management

| Command | What it does | Skill |
|---------|-------------|-------|
| `/xgh-ship-prs` | Ship PRs with auto-merge | [ship-prs](../skills/ship-prs.md) |
| `/xgh-watch-prs` | Monitor PR status passively | [watch-prs](../skills/watch-prs.md) |
| `/xgh-review-pr` | Multi-persona code review | [review-pr](../skills/review-pr.md) |

## Setup and admin

| Command | What it does | Skill |
|---------|-------------|-------|
| `/xgh-init` | First-run onboarding | [init](../skills/init.md) |
| `/xgh-doctor` | Pipeline health check | [doctor](../skills/doctor.md) |
| `/xgh-schedule` | Manage scheduler | [schedule](../skills/schedule.md) |
| `/xgh-trigger` | Manage trigger engine | [trigger](../skills/trigger.md) |
| `/xgh-validate-project-prefs` | Validate preference compliance | [validate-project-prefs](../skills/validate-project-prefs.md) |
| `/xgh-plugin-integrity` | Check commands vs skills | [plugin-integrity](../skills/plugin-integrity.md) |

## Development workflow

| Command | What it does | Skill |
|---------|-------------|-------|
| `/xgh-architecture` | Analyze codebase architecture | [architecture](../skills/architecture.md) |
| `/xgh-test-builder` | Generate test suites | [test-builder](../skills/test-builder.md) |
| `/xgh-todo-killer` | Resolve TODOs | [todo-killer](../skills/todo-killer.md) |
| `/xgh-profile` | Engineer throughput analysis | [profile](../skills/profile.md) |

## Orchestration

| Command | What it does | Skill |
|---------|-------------|-------|
| `/xgh-command-center` | Cross-project orchestrator | [command-center](../skills/command-center.md) |
| `/xgh-for-against` | Design review debate | [for-against](../skills/for-against.md) |

## Self-contained commands

These commands contain their own logic (not thin wrappers):

| Command | What it does |
|---------|-------------|
| `/xgh-collab` | Multi-agent collaboration with workflow templates (plan-review, parallel-impl, validation, security-review) |
| `/xgh-config` | Structured editor for `~/.xgh/ingest.yaml` (show, set, add-project, remove-project, validate) |
| `/xgh-help` | Contextual guide with command reference and "what to do next" suggestions |
