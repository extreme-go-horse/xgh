---
name: xgh-ship-prs
description: Ship a batch of PRs to merge automatically — fixes Copilot review comments, dispatches fix agents, auto-merges when approved
usage: "/xgh-ship-prs start <PR> [<PR>...] [--repo owner/repo] [--interval 3m] [--merge-method merge|squash|rebase] [--reviewer <login>] [--accept-suggestion-commits] [--require-resolved-threads] [--max-fix-cycles 3] [--post-merge-hook '<cmd>'] | /xgh-ship-prs poll-once <PR> [<PR>...] | /xgh-ship-prs <status|stop|pause|resume> | /xgh-ship-prs <hold|unhold> <PR> | /xgh-ship-prs <dry-run|log> [<PR>]"
---

> **Output format:** Follow the [xgh output style guide](../templates/output-style.md). Start with `## 🐴🤖 xgh ship-prs`. Use markdown tables for structured data. Use ✅ ⚠️ ❌ for status. Keep per-poll output terse.

# /xgh-ship-prs

> **Output format:** Start with `## 🐴🤖 xgh ship-prs`. Use markdown tables for structured data. Use ✅ ⚠️ ❌ for status. Keep per-poll output terse.

Read and follow the implementation spec at `skills/ship-prs/ship-prs.md`.
