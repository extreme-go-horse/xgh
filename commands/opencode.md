---
name: opencode
description: "Dispatch tasks to OpenCode CLI for parallel implementation or code review"
usage: "/xgh-opencode [exec|review] <prompt>"
aliases: ["oc"]
---

> **Output format:** Follow the [xgh output style guide](../templates/output-style.md). Start with `## 🐴🤖 xgh opencode`. Use markdown tables for structured data. Use ✅ ⚠️ ❌ for status. End with an italicized next step.

# /xgh-opencode

> **Context-mode:** This skill primarily runs Bash commands. Use Bash directly for git
> and opencode commands (short output). Use `Read` to review opencode output files.

## Preamble — Execution mode

Follow the shared execution mode protocol in `skills/_shared/references/execution-mode-preamble.md`. Apply it to this skill's command name.

- `<SKILL_NAME>` = `opencode`
- `<SKILL_LABEL>` = `OpenCode dispatch`

---

Read and follow the implementation spec at `skills/opencode/opencode.md`.
