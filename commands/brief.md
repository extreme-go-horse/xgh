---
name: xgh-brief
description: Run a session briefing — checks Slack, Jira, and GitHub and produces an actionable summary of what needs attention right now.
---

# /xgh-brief — Session Briefing

Run the `xgh:brief` skill to generate a structured morning/session briefing.

The briefing will:

1. Detect which integrations are available (Slack, Jira, GitHub, Cipher)
2. Query each source for urgent items, in-progress work, and incoming tasks
3. Produce a categorised summary with a single Suggested Focus
4. Ask how you'd like to proceed

## Usage

```
/xgh-brief
```

No arguments needed. Run it at the start of any work session to get oriented.

## Tips

- Set `XGH_BRIEFING=1` in your shell environment to trigger the briefing automatically at every Claude Code session start.
- Run `/xgh-setup` first if you haven't configured Slack, Jira, or GitHub integrations yet.
