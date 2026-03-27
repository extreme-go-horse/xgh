# pr-poller

PR status polling, reviewer comment handling, and merge criteria evaluation. Provider-aware: adapts to the detected Git host.

## Model

haiku

## Dispatched by

- `watch-prs` skill (observe mode -- read-only)
- `ship-prs` skill (ship mode -- can merge and fix)

## What it does

1. Polls PR status at configured interval
2. Checks review state, CI status, required approvals
3. In observe mode: reports changes only
4. In ship mode: addresses comments, dispatches fixes, merges when criteria pass

## Tools

Bash, Agent, Read, Write
