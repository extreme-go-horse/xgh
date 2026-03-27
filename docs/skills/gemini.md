# gemini

Dispatch tasks to the Gemini CLI for parallel implementation or code review.

## When it runs

- **On demand:** `/xgh-gemini`

## What it does

1. Resolves project context
2. Constructs Gemini CLI invocation
3. Dispatches task with appropriate flags:
   - `--yolo` for execution
   - `--approval-mode plan` for review
4. Collects results back into the session

## Prerequisites

- Gemini CLI installed
- Project context seeded: run `/xgh-seed` first
