# glm

Dispatch tasks to Z.AI GLM models via the OpenCode CLI.

## When it runs

- **On demand:** `/xgh-glm`

## What it does

1. Resolves project context
2. Constructs OpenCode CLI invocation with GLM model specification
3. Dispatches using the `--model` flag with the appropriate GLM provider/model
4. Collects results back into the session

## Prerequisites

- OpenCode CLI installed: `npm i -g opencode-ai`
- Project context seeded: run `/xgh-seed` first
