# Hooks

xgh uses 10 hook scripts across 6 Claude Code lifecycle events. Hooks fire automatically -- you do not invoke them directly.

## Overview

| Event | Hook | What it does | Visible to user? |
|-------|------|-------------|------------------|
| SessionStart | `session-start.sh` | Injects context tree knowledge | No |
| SessionStart | `session-start-preferences.sh` | Injects preference index from project.yaml | No |
| UserPromptSubmit | `prompt-submit.sh` | Exits cleanly (minimal) | No |
| UserPromptSubmit | `xgh-prompt-submit.sh` | Injects memory decision table | No |
| PreToolUse | `pre-tool-use-preferences.sh` | 5 severity-aware validation checks | Yes (block/warn) |
| PostToolUse | `post-tool-use.sh` | Captures events for trigger engine | No |
| PostToolUse | `post-tool-use-preferences.sh` | Detects project.yaml drift | Yes (on change) |
| PostToolUse | `post-tool-use-shellcheck.sh` | Lints .sh files with shellcheck | Yes (on violations) |
| PostToolUseFailure | `post-tool-use-failure-preferences.sh` | Diagnoses gh CLI failures | Yes (on failure) |
| PostCompact | `post-compact-preferences.sh` | Re-injects preferences after compaction | No |

## SessionStart hooks

### session-start.sh

**What it does:** Loads the xgh context tree and injects core knowledge files into the session. This gives Claude immediate access to validated project knowledge without manual retrieval.

**What you see:** Nothing visible. Context is silently available in the session.

**Configuration:** The context tree is maintained in `~/.xgh/context-tree/`. Files are scored by importance (0-100) using rules in `config/context-tree-rules.md`.

### session-start-preferences.sh

**What it does:** Reads `config/project.yaml` and builds a compact preference index. This index tells Claude what the project's defaults are (merge method, branch protection, commit format, etc.).

**What you see:** Nothing visible. Preferences are available to all skills.

**Coexistence contract:** Must be LAST in the SessionStart hook array.

## UserPromptSubmit hooks

### prompt-submit.sh

**What it does:** Minimal hook -- exits cleanly with no output. Static instructions have been moved to reference files.

### xgh-prompt-submit.sh

**Location:** `.claude/hooks/xgh-prompt-submit.sh`

**What it does:** Detects the intent of your prompt and injects a memory decision table as `additionalContext`. This helps Claude decide whether to store, retrieve, or ignore context for the current action.

## PreToolUse hooks

### pre-tool-use-preferences.sh

**What it does:** Runs 5 severity-aware checks before Claude executes a tool:

1. **Protected branch check** -- Prevents direct commits to protected branches (main, master)
2. **Force push check** -- Blocks force-push to protected branches
3. **Merge method check** -- Enforces the configured merge method per branch
4. **Branch naming check** -- Validates branch names match the configured pattern
5. **Commit format check** -- Validates commit messages match the configured format

**What you see:**
- **Block (severity: block):** The tool use is denied with a reason message
- **Warn (severity: warn):** The tool use proceeds, but a warning is injected as context

**Configuration:** Severity levels are set per check in `config/project.yaml` under `preferences.vcs.checks` and `preferences.pr.checks`.

**Safety:** Any hook failure (parse error, missing config) silently passes through -- the hook never blocks Claude due to its own bugs.

## PostToolUse hooks

### post-tool-use.sh

**What it does:** Captures local command events for the xgh trigger engine. When Claude runs a Bash command, this hook checks if any trigger in `~/.xgh/triggers/` has `source: local` and matches the command. If so, it writes a `local_command` inbox item.

**What you see:** Nothing visible. Events are silently captured.

### post-tool-use-preferences.sh

**Matcher:** Write, Edit, MultiEdit

**What it does:** Detects when `config/project.yaml` is edited mid-session. Reports which preference fields changed with old-to-new values.

**What you see:** When project.yaml changes, you see a summary like:
```
Preference drift detected:
  pr.merge_method: squash -> merge
  vcs.checks.force_push.severity: block -> warn
```

**Why it matters:** Preferences injected at session start may become stale if the config is edited. This hook surfaces the drift so you can act on it.

### post-tool-use-shellcheck.sh

**Matcher:** Write, Edit, MultiEdit

**What it does:** Runs `shellcheck` on any `.sh` file that Claude writes or edits. Injects violations as `additionalContext` so Claude can self-correct.

**What you see:** If shellcheck finds issues:
```
shellcheck found 2 issues in hooks/my-hook.sh:
  SC2086: Double quote to prevent globbing (line 15)
  SC2154: var is referenced but not assigned (line 22)
```

**Requirement:** `shellcheck` must be installed (`brew install shellcheck`). Silent if not installed.

## PostToolUseFailure hooks

### post-tool-use-failure-preferences.sh

**Matcher:** Bash

**What it does:** Parses `gh` CLI stderr on failure and injects targeted fix suggestions. Uses dual-matching: both the command context AND stderr signal must match.

**What you see:** On gh CLI failures:
```
gh CLI error diagnosed:
  Error: HTTP 422 — merge method not allowed
  Fix: This repo requires squash merges. Use: gh pr merge --squash
```

## PostCompact hooks

### post-compact-preferences.sh

**What it does:** Re-reads `config/project.yaml` and rebuilds the preference index after context compaction. This handles the case where you switched branches mid-session (different branches may have different merge methods or protection rules).

**What you see:** Nothing visible. Preferences are silently refreshed.

**Coexistence contract:** Must be LAST in the PostCompact hook array.

## Helper scripts

### _pref-index-builder.sh

Not a hook itself. Sourced by `session-start-preferences.sh` and `post-compact-preferences.sh` to build the preference index. Sets the `PREF_INDEX_CONTEXT` variable with formatted preference data.

## Hook ordering contract

The preference hooks follow a strict ordering contract:

- **PreToolUse:** First Bash-matcher hook must reference `pre-tool-use-preferences`
- **SessionStart:** Last hook must reference `session-start-preferences`
- **PostCompact:** Must include `post-compact-preferences`

This is validated by `/xgh-validate-project-prefs` (check 7).
