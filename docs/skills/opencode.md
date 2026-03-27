# opencode

Dispatch tasks to the OpenCode CLI for parallel implementation or code review.

## When it runs

- **On demand:** `/xgh-opencode`

## What it does

1. Resolves project context
2. Constructs OpenCode CLI invocation
3. Dispatches the `opencode-driver` agent which handles:
   - Command construction and model selection
   - Output parsing and error handling
   - Retry logic
4. Collects results back into the session

## Prerequisites

- OpenCode CLI installed: `npm i -g opencode-ai`
- Project context seeded: run `/xgh-seed` first

## Agent

Dispatches `opencode-driver` (sonnet)
