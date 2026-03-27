# dispatch

Auto-route tasks to the best agent, model, and effort level based on task type and learned performance.

## When it runs

- **On demand:** `/xgh-dispatch`

## What it does

1. Parses the task description
2. Evaluates task type, complexity, and requirements
3. Matches against agent capabilities from `config/agents.yaml`
4. Routes to the best-fit agent with appropriate model and effort level
5. Falls back to `preferences.dispatch.fallback_agent` (default: codex) if no match

## Configuration

- `preferences.dispatch.default_agent`: Default router (default: `xgh:dispatch`)
- `preferences.dispatch.fallback_agent`: Fallback agent (default: `xgh:codex`)
- `preferences.dispatch.exec_effort`: Default effort for execution tasks
- `preferences.dispatch.review_effort`: Default effort for review tasks
