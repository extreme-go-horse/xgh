---
name: xgh-retrieve
description: Run the xgh context retrieval loop. Scans configured Slack channels, follows links to Jira/Confluence/GitHub/Figma, and stashes raw content to ~/.xgh/inbox/. Invoked by the scheduler every 5 minutes.
---

> **Output format:** Follow the [xgh output style guide](../templates/output-style.md). Start with `## 🐴🤖 xgh retrieve`. Use markdown tables for structured data. Use ✅ ⚠️ ❌ for status. End with an italicized next step.

# /xgh-retrieve — Context Retrieval Loop

Read and follow the implementation spec at `skills/retrieve/retrieve.md`.
