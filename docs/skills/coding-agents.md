# coding-agents

List and manage available AI coding CLI agents and their model capabilities.

## When it runs

- **On demand:** `/xgh-coding-agents`

## What it does

1. Reads agent registry from `config/agents.yaml`
2. Detects which CLIs are installed (Codex, OpenCode, Gemini)
3. Reports each agent's capabilities, model support, and installation status
4. Shows model profiles and performance characteristics

## Configuration

Agent definitions live in `config/agents.yaml`. See [Configuration](../configuration.md).
