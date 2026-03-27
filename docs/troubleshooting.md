# Troubleshooting

Common issues and their fixes. Start with `/xgh-doctor` for automated diagnostics.

## Quick diagnosis

```
/xgh-doctor
```

This validates the full pipeline: config, MCP connectivity, scheduler freshness, and workspace stats.

## Common issues

### "xgh commands not found" or not appearing in palette

**Cause:** Plugin not installed or cache is stale.

**Fix:**
1. Check if the plugin is installed: look for xgh in `~/.claude/plugins/installed_plugins.json`
2. If installed but commands are missing, clear the cache:
   ```bash
   rm -rf ~/.claude/plugins/cache/*/xgh/
   ```
3. Run `/reload-plugins` in your Claude Code session
4. If still missing, check `~/.claude/commands/` for conflicting global commands

### "ingest.yaml not found"

**Cause:** First-run setup was not completed.

**Fix:** Run `/xgh-init` to create `~/.xgh/ingest.yaml` from the template.

### Briefing shows no data

**Cause:** Retriever has not run yet, or no projects are configured.

**Fix:**
1. Check if projects are configured: `cat ~/.xgh/ingest.yaml | grep "status: active"`
2. Run a manual retrieval: `/xgh-retrieve`
3. Run analysis: `/xgh-analyze`
4. Check scheduler: `/xgh-schedule` -- make sure jobs are not paused

### MCP connection failures

**Cause:** MCP server not running or not configured.

**Fix:**
1. `/xgh-doctor` will show which MCP connections are failing
2. Verify MCP servers are listed in your Claude Code settings
3. Restart Claude Code to reconnect MCP servers

### PreToolUse hook blocking actions

**Cause:** A preference check with `severity: block` is denying the action.

**Fix:**
1. Read the denial reason -- it tells you which check failed
2. Common blocks:
   - **Protected branch:** You're trying to commit directly to main/master. Create a feature branch first.
   - **Force push:** Force push to protected branches is blocked. Use a regular push.
   - **Merge method:** Wrong merge method for this branch. Check `config/project.yaml` for the correct method.
3. To change severity from block to warn, edit `config/project.yaml`:
   ```yaml
   preferences:
     vcs:
       checks:
         protected_branch: { severity: warn }  # was: block
   ```

### Preference drift warnings

**Cause:** `config/project.yaml` was edited mid-session and the preferences changed from what was loaded at session start.

**Fix:** This is informational -- no action needed unless the change was unintentional. The drift detection hook shows old-to-new values so you can verify the change was correct.

### gh CLI errors with unhelpful messages

**Cause:** The `gh` CLI sometimes returns cryptic errors.

**Fix:** The `post-tool-use-failure-preferences.sh` hook automatically parses gh errors and suggests fixes. If the hook did not fire:
1. Check if the hook is registered: look for `PostToolUseFailure` in `.claude/settings.json`
2. Verify `gh` is authenticated: `gh auth status`

### Shellcheck warnings after editing .sh files

**Cause:** The shellcheck hook found issues in a script Claude wrote or edited.

**Fix:** This is intentional -- the warnings are injected as context so Claude can self-correct. If shellcheck is too noisy:
1. Add inline directives to suppress specific warnings: `# shellcheck disable=SC2086`
2. Or remove the hook from settings.json (not recommended)

### Token budget exceeded

**Cause:** Daily token cap reached.

**Fix:**
1. Check usage: the usage tracker in `lib/usage-tracker.sh` tracks session usage
2. Increase the cap in `~/.xgh/ingest.yaml`:
   ```yaml
   budget:
     daily_token_cap: 4000000  # doubled from default
   ```
3. Or wait until the next day (cap resets daily)

### Scheduler not running

**Cause:** Scheduler is paused or quiet hours are active.

**Fix:**
1. Check status: `/xgh-schedule`
2. Resume if paused: `/xgh-schedule resume`
3. Check quiet hours in `~/.xgh/ingest.yaml` -- default is 10 PM to 7 AM

### Triggers not firing

**Cause:** Trigger conditions not met, or trigger is silenced.

**Fix:**
1. List triggers: `/xgh-trigger list`
2. Test a trigger: `/xgh-trigger test <name>`
3. Check if silenced: `/xgh-trigger history`
4. Verify the event matches the trigger's `when` conditions in `config/triggers.yaml`

### Dedup removing too many items

**Cause:** Similarity threshold is too aggressive.

**Fix:** Calibrate the threshold:
```
/xgh-calibrate
```
This evaluates real memory pairs and uses F1 scoring to find the optimal threshold. Default is 0.85.

## Error log locations

| Log | Location | Contains |
|-----|----------|----------|
| Hook logs | `~/.xgh/logs/` | Hook execution output and errors |
| Scheduler logs | `~/.xgh/logs/` | Scheduler job execution |
| Inbox | `~/.xgh/inbox/` | Raw retrieved items (before processing) |
| Processed | `~/.xgh/inbox/processed/` | Items after analysis |
| Digests | `~/.xgh/digests/` | Daily summaries |

## Getting help

- `/xgh-help` -- Contextual command reference with suggestions
- `/xgh-doctor` -- Full pipeline health check
- File issues at the xgh repository
