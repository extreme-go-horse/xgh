# codex

Dispatch tasks to the Codex CLI for parallel implementation or code review.

## When it runs

- **On demand:** `/xgh-codex`

## What it does

1. Resolves project context
2. Constructs Codex CLI invocation with correct flags
3. Dispatches the `codex-driver` agent which handles:
   - Flag detection and model fallback
   - Sandbox configuration
   - Output parsing and retry logic
4. Collects results and integrates back into the session

## Prerequisites

- Codex CLI installed: `npm i -g @openai/codex`
- Project context seeded: run `/xgh-seed` first

## Agent

Dispatches `codex-driver` (sonnet)
