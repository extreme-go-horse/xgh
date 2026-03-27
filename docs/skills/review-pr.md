# review-pr

Run a deep multi-persona code review on one or more PRs.

## When it runs

- **On demand:** `/xgh-review-pr 123 456`

## What it does

1. Fetches PR diffs
2. Dispatches 4 parallel review personas (via `pr-reviewer` and `code-reviewer` agents)
3. Each persona reviews independently with different focus areas
4. Second round: cross-pollination where reviewers see each other's findings
5. Synthesizes a final review report

## Usage

```
/xgh-review-pr 123 456       # Review specific PRs
/xgh-review-pr               # Auto-detect open PRs by current user
/xgh-review-pr 123 --rounds 1  # Single round only
```

## Agents

Dispatches `pr-reviewer` and `code-reviewer` (sonnet).
