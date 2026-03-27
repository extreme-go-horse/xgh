# Architecture

xgh is a context pipeline that continuously feeds AI coding agents with team knowledge. This document explains how the pieces fit together.

## System overview

```
                     Slack / Jira / GitHub / Confluence / Figma
                                      |
                              [1] RETRIEVE
                           (every 5 min / on demand)
                                      |
                                      v
                             ~/.xgh/inbox/
                                      |
                              [2] ANALYZE
                           (every 30 min / on demand)
                                      |
                                      v
                          lossless-claude memory
                         (structured, deduplicated)
                                      |
                              [3] BRIEF
                           (session start / on demand)
                                      |
                                      v
                        Prioritized session briefing
                                      |
                              [4] ACT
                           (dispatch / ship / review)
                                      |
                                      v
                     Codex / Gemini / OpenCode / Claude Code
```

## Pipeline stages

### Stage 1: Retrieve

**Skill:** `retrieve` | **Schedule:** Every 5 minutes | **Model:** haiku

The retriever pulls raw context from configured sources:

- **Slack:** Recent messages from monitored channels
- **Jira:** Ticket updates, assignments, comments
- **GitHub:** PR activity, reviews, CI status
- **Confluence:** Page updates
- **Figma:** Design changes

Raw items land in `~/.xgh/inbox/` as frontmatter-tagged markdown files. Each item includes source, timestamp, project association, and raw content.

The **deep retriever** runs hourly with a wider lookback window (7 days of thread scanning, up to 5 pagination pages per channel).

### Stage 2: Analyze

**Skill:** `analyze` | **Schedule:** Every 30 minutes | **Model:** sonnet

The analyzer processes inbox items:

1. **Classify** -- Assigns a content type (decision, spec_change, p0, wip, awaiting_reply, etc.)
2. **Score urgency** -- Applies keyword matching and relevance weighting from `ingest.yaml`
3. **Extract memories** -- Pulls structured facts into lossless-claude workspace
4. **Dedup** -- Compares against existing memories using similarity threshold (default 0.85, tunable via `/xgh-calibrate`)
5. **Generate digest** -- Creates a daily summary in `~/.xgh/digests/`

Processed items move to `~/.xgh/inbox/processed/`.

### Stage 3: Brief

**Skill:** `briefing` | **Trigger:** Session start or `/xgh-briefing`

The briefing aggregates recent activity into a prioritized summary:

- What changed since your last session
- PRs needing attention
- Urgent items (above threshold)
- Assigned tickets
- Team decisions and spec changes

The briefing reads from lossless-claude memory, not raw inbox -- it sees the analyzed, deduplicated, scored view.

### Stage 4: Act

Skills that take action based on context:

- **dispatch** -- Routes tasks to the best agent based on learned performance
- **ship-prs** -- Handles review comments, dispatches fix agents, auto-merges
- **watch-prs** -- Monitors PR status without taking action
- **review-pr** -- Multi-persona code review (4 reviewers, 2 rounds)

## Hook system

xgh hooks inject context and enforce preferences at key lifecycle points:

```
Session start
    |-- session-start.sh (context tree injection)
    |-- session-start-preferences.sh (preference index)
    v
User prompt
    |-- prompt-submit.sh (memory decision table)
    v
Tool use (pre)
    |-- pre-tool-use-preferences.sh (5 severity checks)
    v
Tool use (post)
    |-- post-tool-use.sh (trigger engine events)
    |-- post-tool-use-preferences.sh (drift detection)
    |-- post-tool-use-shellcheck.sh (lint .sh files)
    v
Tool failure
    |-- post-tool-use-failure-preferences.sh (gh CLI diagnosis)
    v
Compaction
    |-- post-compact-preferences.sh (re-inject preferences)
```

See [Hooks](hooks.md) for details on each hook.

## Preference cascade

Preferences flow from `config/project.yaml` through the `lib/preferences.sh` layer:

```
config/project.yaml
    |
    v
lib/preferences.sh (11 loader functions)
    |
    v
lib/severity.sh (block/warn resolution)
    |
    v
hooks (enforce at runtime)
```

Each preference domain has a loader function (e.g., `load_pr_pref`, `load_vcs_pref`). Skills call these to get the effective value, respecting branch-specific overrides and user CLI overrides.

## Trigger engine

The trigger engine maps events to automated actions:

```
Event (inbox item or local command)
    |
    v
Match against triggers.yaml rules
    |
    v
Action level check (notify < create < mutate < autonomous)
    |
    v
Dispatch skill/agent with args
```

Triggers are defined in `config/triggers.yaml` and installed to `~/.xgh/triggers/` by `/xgh-init`. Manage via `/xgh-trigger`.

## Multi-agent dispatch

xgh can dispatch work to external AI CLIs through driver agents:

```
/xgh-dispatch "fix the login bug"
    |
    v
dispatch skill (evaluates task type, complexity, model fit)
    |
    v
codex-driver / opencode-driver / gemini (via bash invocation)
    |
    v
Results collected and integrated back into session
```

The `/xgh-seed` command pushes project context (AGENTS.md, skills, conventions) to each CLI's skill directory before dispatch.

## Data directories

| Directory | Purpose |
|-----------|---------|
| `~/.xgh/inbox/` | Raw retrieved items |
| `~/.xgh/inbox/processed/` | Analyzed items |
| `~/.xgh/digests/` | Daily digest files |
| `~/.xgh/logs/` | Hook and scheduler logs |
| `~/.xgh/triggers/` | Active trigger definitions |
| `~/.xgh/calibration/` | Dedup calibration data |
| `~/.xgh/user_providers/` | User-owned provider configs |

## Key libraries

| File | Purpose |
|------|---------|
| `lib/config-reader.sh` | Read YAML values from ingest.yaml and project.yaml |
| `lib/preferences.sh` | 11 domain-specific preference loaders |
| `lib/severity.sh` | Severity resolution (block/warn) for preference checks |
| `lib/usage-tracker.sh` | Token usage tracking and budget enforcement |
