# seed

Push xgh project context to other AI coding platforms before dispatch.

## When it runs

- **On demand:** `/xgh-seed`

## What it does

1. Detects installed AI CLIs (Codex, Gemini, OpenCode)
2. For each detected CLI:
   - Copies AGENTS.md, skills, and conventions to the CLI's skill directory
   - Codex: `.agents/skills/xgh/`
   - Gemini: `.gemini/skills/xgh/`
   - OpenCode: `.opencode/skills/xgh/`
3. Ensures dispatched agents have full project context

## Why

External CLIs start with no project knowledge. Seeding gives them the same conventions, branch strategy, and workflow context that Claude Code has natively.
