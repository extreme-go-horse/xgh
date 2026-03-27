# xgh Documentation

xgh is a declarative AI ops plugin for Claude Code. It wires together Slack, Jira, GitHub, Confluence, and Figma into a unified context pipeline that feeds AI coding agents.

## Quick links

- [Getting Started](getting-started.md) -- Install, configure, and run your first briefing
- [Configuration](configuration.md) -- All config files: project.yaml, ingest.yaml, team.yaml, and more
- [Architecture](architecture.md) -- How the retrieve-analyze-brief pipeline works
- [Hooks](hooks.md) -- 10 lifecycle hooks: what fires when and what you see
- [Troubleshooting](troubleshooting.md) -- Common issues and `/xgh-doctor` output mapping

## Reference

- [Skills](skills/README.md) -- 28 skills: context retrieval, dispatch, PR management, and more
- [Commands](commands/README.md) -- 30 slash commands organized by workflow
- [Agents](agents/README.md) -- 11 specialized agents dispatched by skills

## Concepts

**Context pipeline**: xgh continuously retrieves context from your team's tools (Slack, Jira, GitHub, Confluence, Figma), classifies and extracts structured memories, and surfaces a prioritized briefing at session start.

**Skills are the logic layer**: Every xgh capability is a markdown skill file in `skills/`. Commands are thin wrappers that invoke skills. This means you can read exactly what any command does by reading its skill file.

**Preference cascade**: Project-level preferences live in `config/project.yaml`. Skills read from this file instead of hardcoding values. Hooks enforce preferences at runtime (blocking or warning based on severity).

**Multi-agent dispatch**: xgh can dispatch tasks to external AI CLIs (Codex, Gemini, OpenCode) using dedicated driver agents that handle flag detection, model fallback, and output parsing.

## Command families

| Family | Commands | Purpose |
|--------|----------|---------|
| **Context** | briefing, retrieve, analyze, index, track | Gather and process team context |
| **Dispatch** | codex, gemini, glm, opencode, dispatch, coding-agents | Route tasks to AI agents |
| **PR Management** | ship-prs, watch-prs, review-pr | Ship, monitor, and review PRs |
| **Setup** | init, seed, config, doctor, schedule, trigger | Configure and maintain xgh |
| **Validation** | validate-project-prefs, plugin-integrity, calibrate | Verify system health |
| **Development** | architecture, test-builder, todo-killer, profile | Development workflow tools |
| **Orchestration** | command-center, collab, help, for-against | Cross-project coordination |
