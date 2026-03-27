# retrieval-auditor

Audit provider health and retrieval quality -- checks fetch logs, inbox quality, and coverage gaps.

## Model

haiku

## Dispatched by

`retrieve` skill (post-retrieval quality check)

## What it does

1. Reviews fetch logs for errors
2. Checks inbox quality metrics
3. Identifies coverage gaps (sources that should have data but don't)
4. Reports provider health status

## Tools

Read, Grep, Glob
