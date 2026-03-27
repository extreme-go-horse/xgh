---
name: glm
description: "Dispatch tasks to Z.AI GLM models via OpenCode CLI for parallel implementation or code review"
usage: "/xgh-glm [exec|review] <prompt>"
aliases: ["glm"]
---

> **Output format:** Follow the [xgh output style guide](../templates/output-style.md). Start with `## 🐴🤖 xgh glm`. Use markdown tables for structured data. Use ✅ ⚠️ ❌ for status. End with an italicized next step.

# /xgh-glm

> **Context-mode:** This skill primarily runs Bash commands. Use Bash directly for git
> and opencode commands (short output). Use `Read` to review opencode output files.

## Preamble — Execution mode

Follow the shared execution mode protocol in `skills/_shared/references/execution-mode-preamble.md`. Apply it to this skill's command name.

- `<SKILL_NAME>` = `glm`
- `<SKILL_LABEL>` = `GLM dispatch`

---

Read and follow the implementation spec at `skills/glm/glm.md`.
