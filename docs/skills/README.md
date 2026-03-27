# Skills

xgh has 28 skills organized by workflow. Skills are the logic layer -- every `/xgh-*` command is a thin wrapper that invokes a skill.

## Context pipeline

| Skill | Command | Purpose |
|-------|---------|---------|
| [retrieve](retrieve.md) | `/xgh-retrieve` | Pull context from Slack, Jira, GitHub, Confluence, Figma |
| [analyze](analyze.md) | `/xgh-analyze` | Classify inbox, extract memories, generate digest |
| [briefing](briefing.md) | `/xgh-briefing` | Session briefing from all sources |
| [index](index.md) | `/xgh-index` | Index a codebase into memory |
| [track](track.md) | `/xgh-track` | Add a project to context monitoring |
| [calibrate](calibrate.md) | `/xgh-calibrate` | Tune dedup similarity threshold |

## Dispatch

| Skill | Command | Purpose |
|-------|---------|---------|
| [dispatch](dispatch.md) | `/xgh-dispatch` | Auto-route tasks to the best agent + model |
| [codex](codex.md) | `/xgh-codex` | Dispatch to Codex CLI |
| [gemini](gemini.md) | `/xgh-gemini` | Dispatch to Gemini CLI |
| [glm](glm.md) | `/xgh-glm` | Dispatch to Z.AI GLM via OpenCode |
| [opencode](opencode.md) | `/xgh-opencode` | Dispatch to OpenCode CLI |
| [coding-agents](coding-agents.md) | `/xgh-coding-agents` | List and manage AI coding agents |
| [seed](seed.md) | `/xgh-seed` | Push project context to other AI platforms |

## PR management

| Skill | Command | Purpose |
|-------|---------|---------|
| [ship-prs](ship-prs.md) | `/xgh-ship-prs` | Ship PRs: fix review comments, auto-merge |
| [watch-prs](watch-prs.md) | `/xgh-watch-prs` | Passively monitor PR status |
| [review-pr](review-pr.md) | `/xgh-review-pr` | Multi-persona deep code review |

## Setup and admin

| Skill | Command | Purpose |
|-------|---------|---------|
| [init](init.md) | `/xgh-init` | First-run onboarding |
| [doctor](doctor.md) | `/xgh-doctor` | Validate pipeline health |
| [schedule](schedule.md) | `/xgh-schedule` | Manage background scheduler |
| [trigger](trigger.md) | `/xgh-trigger` | Manage trigger engine |
| [validate-project-prefs](validate-project-prefs.md) | `/xgh-validate-project-prefs` | Validate preference compliance |
| [plugin-integrity](plugin-integrity.md) | `/xgh-plugin-integrity` | Check commands vs skills alignment |

## Development workflow

| Skill | Command | Purpose |
|-------|---------|---------|
| [architecture](architecture.md) | `/xgh-architecture` | Analyze codebase architecture |
| [test-builder](test-builder.md) | `/xgh-test-builder` | Generate test suites |
| [todo-killer](todo-killer.md) | `/xgh-todo-killer` | Systematically resolve TODOs |
| [profile](profile.md) | `/xgh-profile` | Engineer throughput analysis from Jira |

## Orchestration

| Skill | Command | Purpose |
|-------|---------|---------|
| [command-center](command-center.md) | `/xgh-command-center` | Cross-project briefing and dispatch |
| [for-against](for-against.md) | `/xgh-for-against` | FOR/AGAINST design review debate |
