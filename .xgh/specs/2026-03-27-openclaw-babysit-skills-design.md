# OpenClaw + Babysit-PR Skills Incorporation Design

**Date:** 2026-03-27
**Status:** Approved — ready for implementation
**Sources:** openclaw/openclaw (337K stars), openai/codex babysit-pr (60K stars)
**Adversarial rounds:** 4 (architecture, gh-issues, babysit-pr, watch-prs, full-design)

---

## Overview

Incorporate battle-tested PR workflow skills from openclaw and OpenAI's Codex into xgh. Three deliverables:

| Skill | Status | Source |
|---|---|---|
| `xgh:gh-issues` | New | openclaw/openclaw `skills/gh-issues/SKILL.md` |
| `xgh:babysit-pr` | New — replaces `xgh:ship-prs` | OpenAI Codex `babysit-pr` |
| `xgh:watch-prs` | Enriched | learnings from both sources |

**Deleted:** `xgh:ship-prs` (superseded by babysit-pr)

**Natural workflow chain:**
```
/xgh-gh-issues --label bug        →  opens fix/issue-N PRs in parallel
/xgh-babysit-pr start #42 #43     →  CI-aware, fixes reviews, auto-merges
/xgh-watch-prs start #42          →  passive triage view for stakeholders
```

---

## Deliverables Checklist

All of these must be completed for the implementation to be considered done:

- [ ] `skills/gh-issues/gh-issues.md` — new skill
- [ ] `skills/babysit-pr/babysit-pr.md` — new skill
- [ ] `skills/watch-prs/watch-prs.md` — updated skill
- [ ] `skills/ship-prs/ship-prs.md` — **deleted**
- [ ] `commands/gh-issues.md` — new command
- [ ] `commands/babysit-pr.md` — new command
- [ ] `commands/watch-prs.md` — updated command description
- [ ] `commands/ship-prs.md` — **deleted**
- [ ] `.claude-plugin/plugin.json` — add gh-issues, babysit-pr; remove ship-prs; update watch-prs description
- [ ] `tests/test-ship-prs*` — **deleted** (orphaned by ship-prs removal)
- [ ] `tests/test-gh-issues.sh` — new test file
- [ ] `tests/test-babysit-pr.sh` — new test file
- [ ] `tests/test-watch-prs.sh` — updated test file

---

## State File Paths

| Skill | Path | Purpose |
|---|---|---|
| babysit-pr | `.xgh/babysit-pr/<session-id>.json` | Per-session PR states, counters, baselines |
| gh-issues | `.xgh/locks/gh-issues-<issue-number>.lock` | Prevent double-spawn in cron mode |
| watch-prs | `.xgh/watch-prs/<pr-number>.json` | Per-PR baselines (existing, confirm path) |

---

## Section 1 — `xgh:gh-issues`

### Purpose
Fetch open GitHub issues → pre-flight filter → spawn parallel fix agents → open PRs → monitor review comments.

### Flags
```
/xgh-gh-issues [owner/repo]
  [--label <label>]          Filter by label (e.g. bug, enhancement)
  [--limit 10]               Max issues per poll
  [--milestone <title>]      Filter by milestone
  [--assignee <login|@me>]   Filter by assignee
  [--fork <user/repo>]       Push to fork, open PRs against source
  [--state open]             Issue state: open, closed, all
  [--dry-run]                Fetch and display only — no agents spawned
  [--yes]                    Skip confirmation (still enforces body-length gate)
  [--reviews-only]           Skip to Phase 6 (PR review handler only)
  [--cron]                   Fire-and-forget mode for scheduled execution
  [--model <name>]           Model override for spawned fix agents
```

### Phases

**Phase 1 — Parse Arguments**
Extract flags as above. Auto-detect `owner/repo` from `git remote get-url origin` if not provided (handles both HTTPS and SSH formats). Error if not in a git repo and no owner/repo given.

**Phase 2 — Fetch Issues**
Use `gh issue list` (not raw curl). Apply `--label`, `--milestone`, `--assignee`, `--state`, `--limit` filters.

**Phase 3 — Confirm**
Display fetched issues as a table (number, title, label, body preview). Ask user to confirm before spawning agents. `--yes` skips the prompt but does **not** skip the body-length hard gate (see below).

**Hard gate (not bypassable by `--yes`):** Skip any issue with body length < 100 characters — these almost always lack enough context for a code agent to produce a correct fix. Show skipped issues with reason.

**Phase 4 — Fork Auth Pre-flight** (only with `--fork`)
Run `gh repo view <fork-owner>/<fork-repo> --json id` to verify write access before spawning any agents. Fail fast with a clear error if this fails.

**Phase 5 — Cron Lock Check** (only with `--cron`)
For each issue, check for `.xgh/locks/gh-issues-<N>.lock`. If a lock exists, skip that issue and report "agent already running for #N". Write lock before spawning; agent must delete lock on exit.

**Phase 6 — Spawn Fix Agents (Parallel)**
One isolated worktree per issue. Agent task:
1. Read issue body + comments
2. Find relevant code
3. Implement fix
4. Commit: `fix: <issue title> (closes #<N>)`
5. Push branch `fix/issue-<N>` to `PUSH_REPO` (fork or source)
6. Open PR via `gh pr create` — head from fork if `--fork`, base to source repo
7. Report: PR URL, files changed, fix summary, any caveats

**Conflict warning (not blocking):** Before spawning, note if two issues' titles or labels suggest overlapping areas. Warn user but proceed in parallel — let GitHub surface actual conflicts naturally. Do not serialize based on speculation.

**Phase 7 — PR Review Handler**
Monitor open `fix/issue-N` PRs for review comments. Spawn one fix sub-agent per PR with unaddressed actionable comments. With `--cron`: fire-and-forget, check lock first, exit immediately after spawn.

**Phase 8 — Watch Mode** (with `--watch`)
After each batch: poll for new issues (filtered to exclude already-processed issue numbers) then run Phase 7. Report "next poll in N minutes" and loop.

### Auth
Use `gh auth` throughout. No `GH_TOKEN` raw curl calls.

### Stripped from openclaw
- Telegram `--notify-channel` / `message` tool — removed entirely
- `curl` API calls — replaced with `gh` CLI
- OpenClaw-specific YAML frontmatter fields

---

## Section 2 — `xgh:babysit-pr` (replaces ship-prs)

### Purpose
Multi-PR batch babysitter: CI-aware polling, review comment fixing, conflict resolution, and optional auto-merge. Combines ship-prs' batch power with babysit-pr's intelligence.

### Commands
```
/xgh-babysit-pr start <PR> [<PR>...]
  [--repo owner/repo]
  [--interval 1m]
  [--merge-method squash|merge|rebase]
  [--auto-merge]                    Off by default. See safety warning below.
  [--max-flaky-retries 3]           Max CI reruns per SHA (no code change)
  [--max-agent-pushes 3]            Max code-fix pushes per PR (replaces --max-fix-cycles)
  [--require-resolved-threads]      Block merge on unresolved threads
  [--post-merge-hook '<command>']   Shell command after auto-merge

/xgh-babysit-pr poll-once <PR> [<PR>...]
/xgh-babysit-pr status
/xgh-babysit-pr pause
/xgh-babysit-pr resume
/xgh-babysit-pr hold <PR>
/xgh-babysit-pr unhold <PR>
/xgh-babysit-pr dry-run [<PR>]
/xgh-babysit-pr log [<PR>]
/xgh-babysit-pr stop
```

Defaults are read from `config/project.yaml` → `preferences.pr`, then CLI flags override.

### Per-PR State Machine

Each PR cycles through these states independently:

| State | Description |
|---|---|
| `pending-ci` | Polling CI; classify failures |
| `fixing-ci` | Fixing branch-related failure; push; restart CI watch |
| `retrying-flaky` | Rerunning failed jobs (up to `--max-flaky-retries`) |
| `conflict` | PR has git conflict; attempt rebase; push; or `blocked` on failure |
| `awaiting-review` | Re-requesting review via reviewer-list cycle |
| `fixing-review` | Addressing actionable review comments; push; resume CI watch |
| `merge-ready` | All green + review-clean + mergeable |
| `merging` | Executing auto-merge (only if `--auto-merge`) |
| `done` | Merged or closed |
| `blocked` | Strict stop: infra outage, exhausted retries, unresolvable conflict, ambiguous review |

### Polling Cadence (Behavioral)

Per PR, independently:
- CI pending/failing: poll every 1 min
- CI green: exponential backoff (1m → 2m → 4m … cap 1hr); reset on any state change
- **Round-robin across PRs** — complete one poll cycle per PR before looping back
- **Priority reset:** after any push to PR #N, that PR moves to front of the next round-robin cycle

### CI Failure Classification

| Class | Evidence | Action |
|---|---|---|
| Branch-related | Compile/lint/test failures in files touched by this PR | Fix locally, commit, push |
| Flaky/unrelated | DNS timeouts, runner provisioning, rate limits, non-deterministic unrelated tests | Rerun failed jobs (up to `--max-flaky-retries`) |
| Infrastructure | Confirmed outage, retry limit exhausted | Stop; report to user |

If uncertain: inspect failed logs once via `gh run view --log-failed` before choosing rerun.

### Conflict Resolution (`conflict` state)

When `gh pr view` returns `mergeable: CONFLICTING` or `mergeableState: DIRTY`:
1. `git fetch origin`
2. `git rebase origin/<base-branch>`
3. If rebase succeeds: push, transition to `pending-ci`
4. If rebase fails (unresolvable conflicts): transition to `blocked`, report conflict details

### Review Comment Handling

**Trust model:**
- Surface: OWNER, MEMBER, COLLABORATOR, `copilot-pull-request-reviewer[bot]`
- Ignore: other bots, already-resolved threads
- **Priority: process actionable review comments BEFORE retrying flaky CI** — a new push retriggers CI anyway, making the flaky retry moot

**When comment is actionable:**
1. Patch code locally
2. Commit: `fix: address PR review feedback (#<N>)`
3. Push to PR head branch
4. Transition to `pending-ci` on new SHA; that PR jumps to front of next round-robin cycle

**When comment is non-actionable:** record as handled; continue loop

**Agreement criteria — address when:**
- Technically correct
- Actionable in the current branch
- Does not conflict with user's explicit instructions
- Can be made safely without unrelated refactors

**Do not auto-fix when:**
- Comment is ambiguous
- Conflicts with explicit user instructions
- Requires product/design decisions not yet made

### Copilot Quirks (ported from ship-prs)

- **NEVER** use `@copilot` in comments — triggers SWE delegation agent which opens a new PR
- Re-request review via reviewer-list cycle only:
  ```bash
  gh pr edit $PR --repo $REPO --remove-reviewer copilot-pull-request-reviewer
  gh pr edit $PR --repo $REPO --add-reviewer copilot-pull-request-reviewer
  ```
- REST API requires `[bot]` suffix; `gh pr edit` (GraphQL) does not — use `gh pr edit` for reviewer list changes
- Only re-request after at least one poll interval has elapsed (prevent spam)

### `--auto-merge` Safety Warning

Baked into skill output when `--auto-merge` is active:

> "⚠️ auto-merge is enabled. Requires repo branch protection with required status checks. Without this, a CI failure misclassified as flaky, retried to green, will auto-merge broken code."

### `--post-merge-hook` Safety Note

Hook command is executed via shell. **Never interpolate PR metadata (title, branch name, body) into the hook string** — this is a command injection vector. Use fixed commands only (e.g. `--post-merge-hook 'make deploy'`).

### Counter Semantics

| Flag | Counts | Resets on |
|---|---|---|
| `--max-flaky-retries` | CI reruns (no code change) | New SHA pushed to PR |
| `--max-agent-pushes` | Agent-pushed code commits | Never within a session |

### Strict Stop Conditions

Stop polling a PR and report when:
- PR is merged or closed (`done` state)
- `--max-flaky-retries` exhausted on same SHA
- `--max-agent-pushes` exhausted
- Rebase conflict unresolvable (`blocked`)
- CI failure classified as infrastructure outage
- Review comment is ambiguous and requires user clarification

### State File

`.xgh/babysit-pr/<session-id>.json`:
```json
{
  "started_at": "ISO8601",
  "prs": {
    "42": {
      "state": "pending-ci",
      "baseline_sha": "abc123",
      "baseline_review_at": null,
      "baseline_comment_count": 0,
      "flaky_retry_count": 0,
      "agent_push_count": 0,
      "last_review_request_at": null,
      "action_log": []
    }
  }
}
```

---

## Section 3 — `xgh:watch-prs` Enrichment

### Contract Preserved
Read-only. Never merges, never fixes, never requests reviews. No exceptions.

### Three Concrete Changes

**1. CI check classification in output (lazy evaluation)**

Show per-check breakdown with classification label. **Only classify when CI status changes to failing** (transition: not-failing → failing). Cache classification until SHA changes. This keeps API calls at 1 per failure event, not 1 per poll.

```
CI: 2 failing
  • lint             branch-related ⚠️
  • docker-build     likely flaky 🔁
```

Uses same heuristics as babysit-pr (branch-related / flaky / infra) — display only, no action taken.

**2. Bot filter in review display**

Collapse authors whose login ends in `[bot]` or `[app]` by default. Human reviewers always surface regardless of their association level (OWNER, MEMBER, COLLABORATOR, NONE — all shown). Expand bot activity with `--show-bots`.

**3. Babysit-pr handoff prompts**

When a PR transitions to a state that warrants action, surface a one-liner:
```
⚠️  #42 blocked on branch-related CI failure → /xgh-babysit-pr start 42 to fix
✅  #43 merge-ready                           → /xgh-babysit-pr start 43 --auto-merge to ship
🔀  #44 has git conflict                      → /xgh-babysit-pr start 44 to rebase
```

### Additional Changes

**Merged/closed detection:** When `gh pr view` returns state `MERGED` or `CLOSED`, stop polling that PR immediately and report the terminal state. Previously, only user-initiated `stop` command ended polling.

**Polling:** Fixed 3-minute interval (unchanged). No exponential backoff — predictability is the priority for a stakeholder ticker.

### Output Format (updated tick)
```
## xgh watch-prs — tick 2026-03-27T10:00:00Z

| PR  | State | Mergeable | Review       | CI                        | Comments |
|-----|-------|-----------|--------------|---------------------------|----------|
| #42 | OPEN  | ✅        | APPROVED ✅  | 1 failing (branch-rel ⚠️) | 3        |
| #43 | OPEN  | ✅        | COMMENTED ⚠️ | all green ✅              | 7 (+2)   |

Changes since last tick:
• #42: CI failure classified as branch-related
• #43: 2 new comments from @alice (MEMBER)

⚠️  #42 needs CI fix → /xgh-babysit-pr start 42 to fix
```

---

## Testing Strategy

### `tests/test-gh-issues.sh`
- dry-run mode: verify no agents are spawned, issues are displayed
- body-length gate: issues with body < 100 chars are skipped even with `--yes`
- fork auth pre-flight: `gh repo view` failure stops execution before spawning
- lock file: cron mode checks `.xgh/locks/gh-issues-<N>.lock` before spawning; skips if present
- `--reviews-only`: skips Phases 1-6, runs only Phase 7

### `tests/test-babysit-pr.sh`
- state transitions: pending-ci → fixing-ci → pending-ci (after push)
- flaky retry counter: increments on rerun, caps at `--max-flaky-retries`, transitions to `blocked`
- agent push counter: increments on code push, caps at `--max-agent-pushes`, transitions to `blocked`
- conflict path: DIRTY state triggers rebase attempt
- auto-merge blocked: `merge-ready` state does NOT merge without `--auto-merge` flag
- round-robin priority: pushed PR appears first in next cycle
- Copilot re-request: uses reviewer-list cycle, never `@copilot` in comments
- stop command: cleans up state file

### `tests/test-watch-prs.sh` (updated)
- bot filter: human NONE-association comments surface; `[bot]` logins collapse
- `--show-bots`: expands collapsed bot entries
- merged/closed detection: polling stops immediately on MERGED/CLOSED state
- CI classification caches per SHA: second poll with same SHA and same failure doesn't re-fetch logs
- handoff prompts: branch-related failure surfaces babysit-pr suggestion

### Deleted
- `tests/test-ship-prs*` — deleted alongside `skills/ship-prs/` and `commands/ship-prs.md`

---

## Key Decisions Log

| Decision | Rationale |
|---|---|
| babysit-pr replaces ship-prs | ship-prs had no CI awareness; babysit-pr is strictly better in every dimension when enhanced with batch + auto-merge |
| No Telegram notifications | Stripped from openclaw gh-issues; adds dependency for minor value |
| Pure `gh` CLI, no Python watcher script | xgh skills are markdown instructions to Claude; the Python watcher is a Codex-specific artifact; Claude normalizes state inline |
| Actionability filter → confirmation step | LLM scoring on issue text is unreliable; user confirmation + body-length hard gate is simpler and more honest |
| Conflict pre-flight is warning-only | Pre-flight can't predict actual file overlap; GitHub surfaces real conflicts; don't serialize on speculation |
| Bot filter by login suffix, not association | Human NONE-association reviewers (common in open source) must not be silently hidden |
| CI classification lazy (on change, per SHA) | Fetching failed run logs on every poll is expensive; classify once per failure event |
| `--max-fix-cycles` renamed `--max-agent-pushes` | Distinction from `--max-flaky-retries` was confusing; new name is self-documenting |
| Round-robin with priority reset on push | Ensures CI results from a just-fixed PR are checked promptly; not starved by other PRs |
| watch-prs keeps fixed 3min interval | Predictability matters for stakeholder ticker; exponential backoff is wrong here |
