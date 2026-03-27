---
name: codex
description: "Dispatch tasks to Codex CLI for parallel implementation or code review"
usage: "/xgh-codex [exec|review] <prompt>"
aliases: ["cdx"]
---

> **Output format:** Follow the [xgh output style guide](../templates/output-style.md). Start with `## 🐴🤖 xgh codex`. Use markdown tables for structured data. Use ✅ ⚠️ ❌ for status. End with an italicized next step.

# /xgh-codex

> **Context-mode:** This skill primarily runs Bash commands. Use Bash directly for git
> and codex commands (short output). Use `Read` to review codex output files.

## How to dispatch

**ALWAYS dispatch via the `xgh:codex-driver` agent** using the Agent tool with `subagent_type: "xgh:codex-driver"`.

The `xgh:codex-driver` agent handles:
- Flag detection and command construction
- Model fallback
- Sandbox config
- Output parsing
- Retry logic

> **WARNING: Do NOT run `codex` CLI commands directly via Bash.**
> Invoking `codex exec` or `codex review` directly bypasses flag detection, model fallback, sandbox config, output parsing, and retry logic. All dispatch MUST go through the `xgh:codex-driver` agent.

See [Step 2: Dispatch](#step-2-dispatch) for the agent prompt format.

---

## Preamble — Execution mode

Follow the shared execution mode protocol in `skills/_shared/references/execution-mode-preamble.md`. Apply it to this skill's command name.

- `<SKILL_NAME>` = `codex`
- `<SKILL_LABEL>` = `Codex dispatch`

---

Read and follow the implementation spec at `skills/codex/codex.md`.
