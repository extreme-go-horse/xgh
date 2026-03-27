# pr-reviewer

Multi-persona PR review execution -- runs independent review passes with cross-pollination.

## Model

sonnet

## Dispatched by

`review-pr` skill

## What it does

1. Receives PR diff and review assignment
2. Reviews from a specific persona/focus area
3. Produces structured findings
4. In round 2: incorporates other reviewers' findings for cross-pollination

## Tools

Read, Grep, Glob, Bash
