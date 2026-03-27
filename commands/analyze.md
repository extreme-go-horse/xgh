---
name: xgh-analyze
description: Run the xgh context analysis loop. Reads ~/.xgh/inbox/, classifies and extracts structured memories, writes to lossless-claude workspace, and generates a daily digest. Invoked by the scheduler every 30 minutes.
---

> **Output format:** Follow the [xgh output style guide](../templates/output-style.md). Start with `## 🐴🤖 xgh analyze`. Use markdown tables for structured data. Use ✅ ⚠️ ❌ for status. End with an italicized next step.

# /xgh-analyze — Context Analysis Loop

Read and follow the implementation spec at `skills/analyze/analyze.md`.
