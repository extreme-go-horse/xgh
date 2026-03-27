---
name: xgh-watch-prs
description: Passively monitor PRs — surfaces review changes, new comments, CI status, and merge-readiness without touching anything. Never merges, never fixes, never requests reviews.
usage: "/xgh-watch-prs <start|poll-once> <PR> [<PR>...] [--repo owner/repo] [--interval 3m] [--reviewer <login>] | /xgh-watch-prs <status|stop>"
---

> **Output format:** Follow the [xgh output style guide](../templates/output-style.md). Start with `## 🐴🤖 xgh watch-prs`. Use markdown tables for state snapshots. Use ✅ ⚠️ ❌ for status. Keep per-poll output terse.

# /xgh-watch-prs

> **Output format:** Start with `## 🐴🤖 xgh watch-prs`. Use markdown tables for state snapshots. Use ✅ ⚠️ ❌ for status. Show change-log between polls as bullet list. Keep per-poll output terse.

Read and follow the implementation spec at `skills/watch-prs/watch-prs.md`.
