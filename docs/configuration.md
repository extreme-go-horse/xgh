# Configuration

xgh uses YAML config files organized in two locations: the plugin's `config/` directory (project-level defaults) and `~/.xgh/` (user-specific settings).

## Config file overview

| File | Location | Purpose | Edited by |
|------|----------|---------|-----------|
| `ingest.yaml` | `~/.xgh/` | Your profile, projects, schedule, urgency | `/xgh-init`, `/xgh-track`, or manual |
| `project.yaml` | `config/` | Preference cascade: PR, VCS, dispatch, testing | Manual edit |
| `team.yaml` | `config/` | Conventions, naming, branch strategy, iron laws | Manual edit |
| `agents.yaml` | `config/` | Agent registry: capabilities, models, tools | Manual edit |
| `triggers.yaml` | `config/` | Automation triggers: when X happens, do Y | Manual edit |
| `workflow.yaml` | `config/` | Development phases: design, implementation, review | Manual edit |
| `ingest-template.yaml` | `config/` | Template for new `~/.xgh/ingest.yaml` | Not edited directly |

## ingest.yaml (user config)

Location: `~/.xgh/ingest.yaml`

This is your personal configuration. Created from `config/ingest-template.yaml` during `/xgh-init`.

### Profile

```yaml
profile:
  name: YOUR_NAME
  slack_id: UXXXXXXXXX
  role: engineer
  squad: your-team
  platforms: [ios, android, web]
  also_monitor: []
```

Your profile determines relevance scoring -- messages from your platform and squad are weighted higher.

### Projects

Add projects via `/xgh-track` or edit manually:

```yaml
projects:
  my-feature:
    status: active          # active | paused
    my_role: ios-lead
    my_intent: "Own iOS implementation, coordinate backend changes"
    providers:
      slack:      { access: read }
      jira:       { access: read }
      github:     { access: read }
    slack:
      - "#team-general"
      - "#team-engineering"
    jira: PROJECT-KEY
    github:
      - org/repo
    figma:
      - https://figma.com/design/abc123/screens
```

**Provider access levels:**
- `read` -- Read-only monitoring (default)
- `ask` -- Can ask clarifying questions
- `auto` -- Fully autonomous actions

### Urgency

Controls how messages are scored and filtered:

```yaml
urgency:
  keywords:
    critical: [hotfix, P0, rollback, revert]
    deadline: [EOD, "code freeze", deadline]
    scope: ["requirement changed", pivot]
    infra: ["5xx", outage, incident]
  relevance:
    my_platform: 2.0
    my_squad: 1.5
    also_monitor: 1.0
    other_platform: 0.3
  thresholds:
    log: 0        # Store everything
    digest: 31    # Include in daily digest
    high: 56      # Surface immediately
    critical: 80  # Trigger urgent notification
```

### Schedule

```yaml
schedule:
  retriever: "*/5 * * * *"      # Pull new context every 5 min
  analyzer: "*/30 * * * *"      # Classify and extract every 30 min
  deep_retriever: "0 * * * *"   # Full scan every hour
  quiet_hours: "22:00-07:00"
  quiet_days: [saturday, sunday]
```

Manage via `/xgh-schedule` (list, pause, resume, run).

### Budget

```yaml
budget:
  daily_token_cap: 2000000
  warn_at_percent: 80
  cost_tracking: true
  pause_on_cap: true
```

### Models

```yaml
models:
  retriever: haiku      # Cheapest for simple fetching
  analyzer: sonnet      # Needs classification ability
  urgency: haiku        # Simple scoring
  indexer: sonnet        # Needs code understanding
```

## project.yaml (project preferences)

Location: `config/project.yaml`

The preference cascade. Skills read from this file instead of hardcoding values. Users can override at call time.

### Preference domains

```yaml
preferences:
  pr:
    provider: github
    repo: org/repo
    reviewer: copilot-pull-request-reviewer[bot]
    merge_method: squash
    auto_merge: true
    checks:
      merge_method: { severity: block }
    branches:
      main:
        merge_method: merge
        required_approvals: 1
        protected: true
      develop:
        merge_method: squash

  vcs:
    commit_format: "^(feat|fix|docs|chore|refactor|test|ci)(\\(.+\\))?: .+"
    branch_naming: "^(feat|fix|docs|chore)/"
    branches:
      main: { protected: true }
      master: { protected: true }
    checks:
      branch_naming: { severity: warn }
      protected_branch: { severity: block }
      commit_format: { severity: warn }
      force_push: { severity: block }

  dispatch:
    default_agent: xgh:dispatch
    fallback_agent: xgh:codex
    exec_effort: high
    review_effort: normal

  superpowers:
    implementation_model: sonnet
    review_model: opus
    effort: normal

  design:
    model: opus
    effort: max

  agents:
    default_model: sonnet

  pair_programming:
    enabled: true
    tool: "xgh:dispatch"
    effort: high
    phases: [design, per_task]

  scheduling:
    retrieve_interval: "30m"
    analyze_interval: "1h"

  notifications:
    delivery: "inline"
    batching: false

  retrieval:
    depth: "normal"
    max_age: "7d"
    context_tree_sync: true

  testing:
    timeout: "120s"
```

### Severity levels

Preference checks use two severity levels:

- **block** -- Denies the action (PreToolUse returns `permissionDecision: deny`)
- **warn** -- Allows the action but injects a warning as context

Example: `force_push: { severity: block }` prevents force-pushing to protected branches.

## team.yaml (conventions)

Location: `config/team.yaml`

Defines team conventions used by AGENTS.md generation and agent instructions.

### Key sections

```yaml
conventions:
  general:
    - "Test-first: Write a failing test before implementing"
    - "Shell conventions: #!/usr/bin/env bash + set -euo pipefail"
    - "Minimal diffs: smallest correct change"
    - "No secrets: use env vars only"

  naming:
    - "Bash functions: lower_snake_case"
    - "Constants: UPPER_SNAKE_CASE"
    - "YAML keys: snake_case"
    - "Skills: one dir per skill, file matches dir name"

  branch_strategy:
    - "Feature: branch off develop -> PR targets develop"
    - "Release: PR from develop -> main"
    - "Never open a feature PR against main"

iron_laws:
  - title: "Never break existing tests"
  - title: "If you call it, test it"
  - title: "Never commit secrets"
```

## triggers.yaml (automation)

Location: `config/triggers.yaml`

Defines what happens automatically when events occur.

### Trigger structure

```yaml
triggers:
  - name: pr-opened
    description: "GitHub PR opened - dispatch reviewer"
    when:
      source: github
      type: pull_request
      match:
        event_type: "^opened$"
    then:
      - action_level: autonomous
        type: dispatch
        skill: xgh:pr-reviewer
        args: "{item.url}"
```

### When fields

| Field | Description |
|-------|-------------|
| `source` | Event source: `github`, `slack`, `jira`, `local` |
| `type` | Event type: `pull_request`, `mention`, `issue`, `file_created` |
| `match` | Regex patterns on event fields |
| `command` | Regex on command (local events only) |
| `exit_code` | Exact match on exit code (local events only) |
| `cron` | Matched against current time (schedule events only) |

### Action levels (ascending)

| Level | Behavior |
|-------|----------|
| `notify` | Surface information, no action |
| `create` | Create artifacts (files, tickets) |
| `mutate` | Modify existing state |
| `autonomous` | Full autonomous action |

### Default triggers

- **pr-opened** -- Dispatches PR reviewer on new PRs
- **pr-review-requested** -- Dispatches reviewer when review is requested
- **slack-mention** -- Runs briefing on @mentions
- **jira-assigned** -- Dispatches implementer on ticket assignment
- **digest-ready** -- Seeds memory when digest is created
- **security-alert** -- Dispatches investigator on security advisories

Manage triggers via `/xgh-trigger` (list, test, silence, history).

## agents.yaml (agent registry)

Location: `config/agents.yaml`

Declares all available agents and their capabilities.

### External agents

```yaml
agents:
  claude-code:
    type: primary
    capabilities: [architecture, implementation, planning, review]

  codex:
    type: secondary
    capabilities: [fast-implementation, code-review, test-generation]

  gemini:
    type: secondary
    capabilities: [implementation, code-review, test-generation]

  opencode:
    type: secondary
    capabilities: [fast-implementation, code-review, test-generation]
```

### Local agents

```yaml
local_agents:
  code-reviewer:    { model: sonnet, capabilities: [code-review, architecture] }
  codex-driver:     { model: sonnet, capabilities: [codex-dispatch, retry-logic] }
  opencode-driver:  { model: sonnet, capabilities: [opencode-dispatch, output-parsing] }
  pr-poller:        { model: haiku, capabilities: [pr-polling, merge-criteria] }
  pr-reviewer:      { model: sonnet, capabilities: [pr-review, github] }
  context-curator:  { model: haiku, capabilities: [context-tree, curation] }
  # ... and more
```

## workflow.yaml (development phases)

Location: `config/workflow.yaml`

Defines the three-phase development workflow: Design, Implementation, Review.

### Phases

| Phase | Model | Effort | Key steps |
|-------|-------|--------|-----------|
| Design | opus | max | Brief, retrieve, propose approaches, write spec + plan, Copilot review |
| Implementation | sonnet | normal | Branch from develop, subagent-driven, two-stage review |
| Review | opus | max | Full review, test suite, analyze learnings, PR to develop |

### Test commands

```yaml
test_commands:
  - command: "bash tests/test-config.sh"
  - command: "bash tests/test-skills.sh"
  - command: "bash tests/test-commands.sh"
  - command: "bash tests/test-no-dangling-references.sh"
```

## Validating configuration

Run the preference validator to check for issues:

```
/xgh-validate-project-prefs
```

This checks:
- No hardcoded values in skill files
- All 11 preference domains present in project.yaml
- All 11 loader functions in lib/preferences.sh
- Hook ordering contract
- Cross-domain dependencies
- Severity values are valid (block/warn)
- Protected branches exist
- Regex patterns are syntactically valid
