---
name: xgh:coding-agents
description: "Use when the user asks to \"/xgh-coding-agents\", wants to see available coding agents (Codex, OpenCode, Gemini), probe CLI capabilities, or refresh model mappings."
---

# xgh:coding-agents — Coding Agent Management

List and manage AI coding CLI agents (Codex, OpenCode, Gemini) and their model capabilities.

## Usage

```bash
/xgh-coding-agents                    # List all agents + their models
/xgh-coding-agents opencode           # Show OpenCode details
/xgh-coding-agents --refresh          # Re-probe all agents
/xgh-coding-agents opencode --refresh # Re-probe just OpenCode
```

## Implementation

See [implementation plan](/Users/pedro/Developer/xgh/docs/superpowers/plans/2026-03-22-dynamic-model-detection.md).
