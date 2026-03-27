# Agents

xgh has 11 local agents that are dispatched by skills for specialized tasks. You do not invoke agents directly -- skills dispatch them automatically.

## Agent index

| Agent | Model | Dispatched by | Purpose |
|-------|-------|---------------|---------|
| [code-reviewer](code-reviewer.md) | sonnet | review-pr | Code review with focus areas |
| [codex-driver](codex-driver.md) | sonnet | codex | Codex CLI dispatch with flag detection and retry |
| [collaboration-dispatcher](collaboration-dispatcher.md) | sonnet | collab | Multi-agent workflow orchestration |
| [context-curator](context-curator.md) | haiku | analyze | Context classification and memory extraction |
| [investigation-lead](investigation-lead.md) | opus | (standalone) | Systematic debugging from bug reports |
| [onboarding-guide](onboarding-guide.md) | sonnet | init | First-run setup guidance |
| [opencode-driver](opencode-driver.md) | sonnet | opencode | OpenCode CLI dispatch with model selection |
| [pipeline-doctor](pipeline-doctor.md) | sonnet | doctor | Pipeline health diagnostics |
| [pr-poller](pr-poller.md) | haiku | watch-prs, ship-prs | PR status polling and merge criteria |
| [pr-reviewer](pr-reviewer.md) | sonnet | review-pr | Multi-persona PR review execution |
| [retrieval-auditor](retrieval-auditor.md) | haiku | retrieve | Provider health and retrieval quality audit |

## External agents

xgh also dispatches to external AI CLIs through driver agents:

| CLI | Driver agent | Dispatch skill |
|-----|-------------|----------------|
| Codex | codex-driver | `/xgh-codex` |
| OpenCode | opencode-driver | `/xgh-opencode` |
| Gemini | (direct invocation) | `/xgh-gemini` |
| GLM | (via OpenCode) | `/xgh-glm` |

## Model selection

Agents use the cheapest model that can do the job:

- **haiku** -- Simple tasks: polling, auditing, curation
- **sonnet** -- Most tasks: driving CLIs, code review, orchestration
- **opus** -- Complex tasks: investigation, debugging with root-cause analysis

The default model for agents without explicit configuration is set in `config/project.yaml` under `preferences.agents.default_model`.

## Agent capabilities

Each agent declares its capabilities in `config/agents.yaml`. The dispatch skill uses these to match tasks to the best agent:

```yaml
local_agents:
  code-reviewer:
    capabilities: [code-review, architecture, conventions]
  pr-poller:
    capabilities: [pr-polling, review-status, merge-criteria]
```

See [Configuration](../configuration.md) for the full agent registry.
