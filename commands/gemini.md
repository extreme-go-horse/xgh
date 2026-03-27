---
name: gemini
description: "Dispatch tasks to Gemini CLI for parallel implementation or code review"
usage: "/xgh-gemini [exec|review] <prompt>"
aliases: ["gem"]
---

> **Output format:** Follow the [xgh output style guide](../templates/output-style.md). Start with `## 🐴🤖 xgh gemini`. Use markdown tables for structured data. Use ✅ ⚠️ ❌ for status. End with an italicized next step.

# /xgh-gemini

> **Context-mode:** This skill primarily runs Bash commands. Use Bash directly for git
> and gemini commands (short output). Use `Read` to review gemini output files.

## Preamble — Execution mode

Follow the shared execution mode protocol in `skills/_shared/references/execution-mode-preamble.md`. Apply it to this skill's command name.

- `<SKILL_NAME>` = `gemini`
- `<SKILL_LABEL>` = `Gemini dispatch`

---

Read and follow the implementation spec at `skills/gemini/gemini.md`.
