# OpenClaw + Babysit-PR Skills Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `xgh:gh-issues` and `xgh:babysit-pr` skills, enrich `xgh:watch-prs`, and delete `xgh:ship-prs`.

**Architecture:** Three skill markdown files + two command files + two test files. Plugin auto-discovers skills/commands from directories — no plugin.json edits needed. Skills follow `skills/<name>/<name>.md` convention; commands follow `commands/<name>.md`. Tests use `assert_file_exists` / `assert_contains` bash helpers.

**Tech Stack:** Bash, Markdown, `gh` CLI, `git`

**Spec:** `.xgh/specs/2026-03-27-openclaw-babysit-skills-design.md`

---

## File Map

| Action | Path | Purpose |
|---|---|---|
| Delete | `skills/ship-prs/ship-prs.md` | Superseded by babysit-pr |
| Delete | `commands/ship-prs.md` | Superseded |
| Create | `skills/gh-issues/gh-issues.md` | Auto-fix issues with parallel agents |
| Create | `commands/gh-issues.md` | Command entry point |
| Create | `skills/babysit-pr/babysit-pr.md` | CI-aware multi-PR babysitter |
| Create | `commands/babysit-pr.md` | Command entry point |
| Modify | `skills/watch-prs/watch-prs.md` | Add CI classification + bot filter + handoff |
| Modify | `commands/watch-prs.md` | Update description |
| Create | `tests/test-gh-issues.sh` | Verify gh-issues structure |
| Create | `tests/test-babysit-pr.sh` | Verify babysit-pr structure |
| Modify | `tests/test-watch-prs.sh` | Add assertions for new sections |

---

## Task 1: Delete ship-prs

**Files:**
- Delete: `skills/ship-prs/ship-prs.md`
- Delete: `commands/ship-prs.md`

- [ ] **Step 1: Verify no ship-prs test files exist**

```bash
ls tests/ | grep ship
```

Expected: empty output (no test files to delete).

- [ ] **Step 2: Delete skill and command files**

```bash
rm skills/ship-prs/ship-prs.md
rmdir skills/ship-prs
rm commands/ship-prs.md
```

- [ ] **Step 3: Verify deletion**

```bash
ls skills/ | grep ship
ls commands/ | grep ship
```

Expected: both return empty.

- [ ] **Step 4: Run existing tests to confirm nothing breaks**

```bash
cd /Users/pedro/Developer/xgh && bash tests/test-workflow-skills.sh 2>&1 | tail -3
bash tests/test-skills.sh 2>&1 | tail -3
```

Expected: all pass (ship-prs had no test coverage).

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat: delete xgh:ship-prs (superseded by xgh:babysit-pr)"
```

---

## Task 2: Create xgh:gh-issues skill

**Files:**
- Create: `skills/gh-issues/gh-issues.md`

- [ ] **Step 1: Create directory**

```bash
mkdir -p skills/gh-issues
```

- [ ] **Step 2: Write skill file**

Create `skills/gh-issues/gh-issues.md` with this exact content:

```markdown
---
name: xgh:gh-issues
description: "Fetch open GitHub issues, spawn parallel agents to implement fixes and open PRs, then monitor and address PR review comments. Usage: /xgh-gh-issues [owner/repo] [--label bug] [--limit 10] [--milestone v1.0] [--assignee @me] [--fork user/repo] [--state open] [--dry-run] [--yes] [--reviews-only] [--watch] [--interval 5m] [--cron] [--model <name>]"
user-invocable: true
---

# xgh:gh-issues — Auto-fix GitHub Issues with Parallel Agents

> **Output format:** Start with `## 🐴🤖 xgh gh-issues`. Use markdown tables for structured data. Use ✅ ⚠️ ❌ for status.

## Phase 1 — Parse Arguments

Parse the arguments string provided after /xgh-gh-issues.

**Positional:**
- `owner/repo` — optional. Auto-detect from `git remote get-url origin` if omitted (handles HTTPS and SSH). Error if not in a git repo and no owner/repo provided.

**Flags:**

| Flag | Default | Description |
|------|---------|-------------|
| `--label` | none | Filter by label (e.g. `bug`, `enhancement`) |
| `--limit` | 10 | Max issues to fetch per poll |
| `--milestone` | none | Filter by milestone title |
| `--assignee` | none | Filter by assignee (`@me` for self) |
| `--fork` | none | Your fork (`user/repo`) to push branches; PRs open from fork to source |
| `--state` | open | Issue state: open, closed, all |
| `--dry-run` | false | Fetch and display only — no agents spawned |
| `--yes` | false | Skip confirmation prompt (body-length gate still applies) |
| `--reviews-only` | false | Skip to Phase 7 (PR review handler only) |
| `--watch` | false | Keep polling for new issues and review comments |
| `--interval` | 5m | Minutes between watch polls (only with `--watch`) |
| `--cron` | false | Fire-and-forget mode for scheduled execution |
| `--model` | none | Model override for spawned fix agents |

## Phase 2 — Fetch Issues

```bash
gh issue list \
  --repo <owner/repo> \
  --state <state> \
  --limit <limit> \
  [--label <label>] \
  [--milestone <milestone>] \
  [--assignee <assignee>] \
  --json number,title,body,labels,assignees,url
```

Use `gh auth` throughout. No `GH_TOKEN` raw curl calls.

## Phase 3 — Confirm

Display fetched issues as a table:

```
## 🐴🤖 xgh gh-issues — 5 issues from owner/repo

| # | Title | Labels | Body preview |
|---|-------|--------|-------------|
| 42 | Fix null pointer in auth | bug | "Steps to reproduce: 1. Login with..." |
| 43 | Add retry logic to fetch | enhancement | "The fetch function should retry on..." |

⚠️  Skipped 1 issue: #41 body too short (<100 chars)
```

Ask for confirmation: "Spawn fix agents for 2 issues? [y/N]"

`--yes` skips the prompt but does NOT skip the body-length gate.

**Hard gate (not bypassable by `--yes`):** Skip any issue with `len(body) < 100`. Show skipped issues with reason "body too short".

## Phase 4 — Fork Auth Pre-flight (only with `--fork`)

```bash
gh repo view <fork-owner>/<fork-repo> --json id
```

If this fails: error immediately with "Cannot write to fork <fork>. Run `gh auth` with write access." Do not proceed to spawn agents.

## Phase 5 — Cron Lock Check (only with `--cron`)

For each issue number N:
1. Check `.xgh/locks/gh-issues-<N>.lock`
2. If lock exists: skip issue, report "agent already running for #N"
3. If no lock: write lock file before spawning agent
4. Agent MUST delete lock file on exit (success or failure)

## Phase 6 — Spawn Fix Agents (Parallel)

One isolated worktree per issue. Spawn agents in parallel.

**Conflict warning (not blocking):** Before spawning, note if multiple issues appear to touch related areas based on titles/labels. Warn the user but proceed — let GitHub surface actual git conflicts naturally.

**Per-agent task prompt:**

```
You are fixing GitHub issue #<N>: <title>

Issue body:
<body>

Issue comments:
<comments>

Your task:
1. Read the issue carefully to understand what needs to change
2. Find the relevant code files
3. Implement the fix
4. Commit with: fix: <issue title> (closes #<N>)
5. Push branch fix/issue-<N> to <PUSH_REPO>
6. Create PR: gh pr create --repo <SOURCE_REPO> --head <HEAD> --base <BASE_BRANCH> \
     --title "fix: <title>" \
     --body "## Summary\n\n<description>\n\n## Changes\n\n<bullets>\n\n## Testing\n\n<what was tested>\n\nFixes <SOURCE_REPO>#<N>"
7. Report: PR URL, files changed, fix summary, any caveats

If using --fork: HEAD = "<fork-owner>:fix/issue-<N>", push to fork remote.
If not using --fork: HEAD = "fix/issue-<N>", push to origin.
```

**Results collection:**
```
## 🐴🤖 xgh gh-issues — results

| # | Title | Result | PR |
|---|-------|--------|----|
| 42 | Fix null pointer in auth | ✅ PR opened | https://github.com/... |
| 43 | Add retry logic to fetch | ❌ Failed: could not find relevant code | — |

Processed 2 issues: 1 PR opened, 1 failed, 0 skipped.
```

## Phase 7 — PR Review Handler

Monitor open `fix/issue-<N>` PRs for review comments. Spawn fix sub-agents for PRs with unaddressed actionable comments.

**Discover PRs to monitor:**
```bash
gh pr list --repo <SOURCE_REPO> --state open \
  --json number,headRefName,url,title \
  | jq '[.[] | select(.headRefName | startswith("fix/issue-"))]'
```

**Fetch review comments per PR:**
```bash
# Issue comments
gh api repos/<SOURCE_REPO>/issues/<PR>/comments?per_page=100
# Inline review comments
gh api repos/<SOURCE_REPO>/pulls/<PR>/comments?per_page=100
# Review submissions
gh api repos/<SOURCE_REPO>/pulls/<PR>/reviews?per_page=100
```

**With `--cron`:** Check lock `.xgh/locks/gh-issues-review-<PR>.lock`. If no lock: spawn ONE fix agent for the first PR with unaddressed comments, fire-and-forget, exit immediately.

**Without `--cron`:** Process all PRs with unaddressed comments sequentially.

## Phase 8 — Watch Mode (with `--watch`)

After processing each batch:
1. Add processed issue numbers to `PROCESSED_ISSUES` set
2. Sleep for `--interval` minutes
3. Return to Phase 2 — `gh issue list` with `--state open` (new issues only, filtered by PROCESSED_ISSUES)
4. Run Phase 7 for all tracked PRs
5. If no new issues AND no new review comments: report "No new activity. Polling in <interval>m..."
6. User can say "stop" to exit watch mode

**Context hygiene between polls:** Only retain:
- `PROCESSED_ISSUES` set
- `OPEN_PRS` list (number, branch, URL)
- Parsed arguments from Phase 1
- `SOURCE_REPO`, `PUSH_REPO`, `BASE_BRANCH`, `FORK_MODE`
```

- [ ] **Step 3: Verify file created**

```bash
wc -l skills/gh-issues/gh-issues.md
head -5 skills/gh-issues/gh-issues.md
```

Expected: file exists, frontmatter visible.

---

## Task 3: Create xgh:gh-issues command

**Files:**
- Create: `commands/gh-issues.md`

- [ ] **Step 1: Write command file**

Create `commands/gh-issues.md`:

```markdown
---
name: xgh-gh-issues
description: Fetch open GitHub issues, spawn parallel agents to implement fixes and open PRs, then monitor PR review comments
usage: "/xgh-gh-issues [owner/repo] [--label <label>] [--limit 10] [--milestone <title>] [--assignee <login|@me>] [--fork <user/repo>] [--state open] [--dry-run] [--yes] [--reviews-only] [--watch] [--interval 5m] [--cron] [--model <name>]"
---

> **Output format:** Follow the [xgh output style guide](../templates/output-style.md). Start with `## 🐴🤖 xgh gh-issues`. Use markdown tables for structured data. Use ✅ ⚠️ ❌ for status.

Read and follow the implementation spec at `skills/gh-issues/gh-issues.md`.
```

- [ ] **Step 2: Verify**

```bash
head -8 commands/gh-issues.md
```

Expected: frontmatter with name, description, usage.

---

## Task 4: Create xgh:gh-issues tests

**Files:**
- Create: `tests/test-gh-issues.sh`

- [ ] **Step 1: Write test file**

Create `tests/test-gh-issues.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

PASS=0
FAIL=0

assert_file_exists() {
  if [[ -f "$1" ]]; then
    PASS=$((PASS + 1))
  else
    echo "FAIL: missing file $1"
    FAIL=$((FAIL + 1))
  fi
}

assert_not_exists() {
  if [[ ! -f "$1" ]]; then
    PASS=$((PASS + 1))
  else
    echo "FAIL: file should not exist: $1"
    FAIL=$((FAIL + 1))
  fi
}

assert_contains() {
  if grep -qi "$2" "$1" 2>/dev/null; then
    PASS=$((PASS + 1))
  else
    echo "FAIL: $1 missing '$2'"
    FAIL=$((FAIL + 1))
  fi
}

# Skill file exists
assert_file_exists "skills/gh-issues/gh-issues.md"
assert_file_exists "commands/gh-issues.md"

# ship-prs deleted
assert_not_exists "skills/ship-prs/ship-prs.md"
assert_not_exists "commands/ship-prs.md"

# Skill frontmatter
assert_contains "skills/gh-issues/gh-issues.md" "name: xgh:gh-issues"
assert_contains "skills/gh-issues/gh-issues.md" "user-invocable: true"

# Flags present
assert_contains "skills/gh-issues/gh-issues.md" "\-\-label"
assert_contains "skills/gh-issues/gh-issues.md" "\-\-dry-run"
assert_contains "skills/gh-issues/gh-issues.md" "\-\-fork"
assert_contains "skills/gh-issues/gh-issues.md" "\-\-cron"
assert_contains "skills/gh-issues/gh-issues.md" "\-\-reviews-only"
assert_contains "skills/gh-issues/gh-issues.md" "\-\-watch"
assert_contains "skills/gh-issues/gh-issues.md" "\-\-yes"

# Body-length hard gate
assert_contains "skills/gh-issues/gh-issues.md" "100"
assert_contains "skills/gh-issues/gh-issues.md" "body"
assert_contains "skills/gh-issues/gh-issues.md" "Hard gate"

# Fork auth pre-flight
assert_contains "skills/gh-issues/gh-issues.md" "Fork Auth Pre-flight"
assert_contains "skills/gh-issues/gh-issues.md" "gh repo view"

# Cron lock file
assert_contains "skills/gh-issues/gh-issues.md" "lock"
assert_contains "skills/gh-issues/gh-issues.md" ".xgh/locks"

# Uses gh CLI not curl
assert_contains "skills/gh-issues/gh-issues.md" "gh issue list"
assert_contains "skills/gh-issues/gh-issues.md" "gh pr create"

# No Telegram
if grep -qi "notify-channel\|telegram\|message tool" "skills/gh-issues/gh-issues.md" 2>/dev/null; then
  echo "FAIL: skills/gh-issues/gh-issues.md should not contain Telegram references"
  FAIL=$((FAIL + 1))
else
  PASS=$((PASS + 1))
fi

# Phase 7 - PR review handler
assert_contains "skills/gh-issues/gh-issues.md" "Phase 7"
assert_contains "skills/gh-issues/gh-issues.md" "fix/issue-"

# Command file
assert_contains "commands/gh-issues.md" "xgh-gh-issues"
assert_contains "commands/gh-issues.md" "/xgh-gh-issues"

echo ""
echo "gh-issues tests: $PASS passed, $FAIL failed"
[[ "$FAIL" -eq 0 ]] || exit 1
```

- [ ] **Step 2: Make executable and run**

```bash
chmod +x tests/test-gh-issues.sh
cd /Users/pedro/Developer/xgh && bash tests/test-gh-issues.sh
```

Expected: all pass.

- [ ] **Step 3: Commit**

```bash
git add skills/gh-issues/ commands/gh-issues.md tests/test-gh-issues.sh
git commit -m "feat: add xgh:gh-issues skill (openclaw port, parallel issue auto-fix)"
```

---

## Task 5: Create xgh:babysit-pr skill

**Files:**
- Create: `skills/babysit-pr/babysit-pr.md`

- [ ] **Step 1: Create directory**

```bash
mkdir -p skills/babysit-pr
```

- [ ] **Step 2: Write skill file**

Create `skills/babysit-pr/babysit-pr.md`:

```markdown
---
name: xgh:babysit-pr
description: "CI-aware multi-PR babysitter — polls CI, classifies failures (branch-related/flaky/infra), fixes review comments, resolves conflicts, and auto-merges when ready. Replaces xgh:ship-prs. Usage: /xgh-babysit-pr start <PR> [<PR>...] [--repo owner/repo] [--interval 1m] [--merge-method squash|merge|rebase] [--auto-merge] [--max-flaky-retries 3] [--max-agent-pushes 3] [--require-resolved-threads] [--post-merge-hook '<cmd>']"
user-invocable: true
---

# xgh:babysit-pr — CI-Aware Multi-PR Babysitter

> **Output format:** Start with `## 🐴🤖 xgh babysit-pr`. Use markdown tables for structured data. Use ✅ ⚠️ ❌ 🔁 🔀 for status. Keep per-poll output terse.

## Commands

```
/xgh-babysit-pr start <PR> [<PR>...] [--repo owner/repo] [--interval 1m]
                 [--merge-method squash|merge|rebase]
                 [--auto-merge]
                 [--max-flaky-retries 3]
                 [--max-agent-pushes 3]
                 [--require-resolved-threads]
                 [--post-merge-hook '<command>']
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

## Step 0 — Bootstrap

### Step 0a — Load preferences from project.yaml

```bash
# Load defaults (override with CLI flags)
REPO=$(yq '.project.github.repo // ""' config/project.yaml 2>/dev/null || echo "")
MERGE_METHOD=$(yq '.preferences.pr.merge_method // "squash"' config/project.yaml 2>/dev/null || echo "squash")
INTERVAL=$(yq '.preferences.pr.interval // "1m"' config/project.yaml 2>/dev/null || echo "1m")
```

CLI flags always override project.yaml values.

### Step 0b — Session state file

State file: `.xgh/babysit-pr/<session-id>.json`

**session-id** is a timestamp: `YYYY-MM-DD-HHMMSS`

On `start`: check for existing `.xgh/babysit-pr/*.json`. If found, warn: "Active session found at <path>. Resume it? [y/N] Or overwrite? [o]". If `status`: read most recently modified `.xgh/babysit-pr/*.json`.

State schema:
```json
{
  "started_at": "ISO8601",
  "repo": "owner/repo",
  "options": {},
  "prs": {
    "42": {
      "state": "pending-ci",
      "baseline_sha": "abc123",
      "baseline_review_at": null,
      "baseline_comment_count": 0,
      "flaky_retry_count": 0,
      "agent_push_count": 0,
      "last_review_request_at": null,
      "held": false,
      "action_log": []
    }
  }
}
```

## Per-PR State Machine

Each PR has an independent state. States are checked on every poll cycle.

| State | Description |
|---|---|
| `pending-ci` | Polling CI; classify any failures |
| `fixing-ci` | Fixing branch-related CI failure; push in progress |
| `retrying-flaky` | Rerunning failed jobs (up to `--max-flaky-retries`) |
| `conflict` | PR has git conflict — **reachable from ANY non-terminal state**; attempt rebase or go to `blocked` |
| `awaiting-review` | Re-requesting review via reviewer-list cycle |
| `fixing-review` | Addressing actionable review comments; push in progress |
| `merge-ready` | All green + review-clean + mergeable |
| `merging` | Executing auto-merge (only if `--auto-merge`) |
| `done` | Merged or closed |
| `blocked` | Strict stop — see Stop Conditions |

**Conflict check runs on every poll**, not only from `pending-ci`. Check:
```bash
gh pr view $PR --repo $REPO --json mergeable,mergeableState \
  | jq -r '.mergeableState'
```
If `DIRTY` or `CONFLICTING` → enter `conflict` state immediately.

## Polling Cadence

Per PR, independently (behavioral — Claude manages the bookkeeping):

- CI pending/failing: poll every 1 min
- CI green: exponential backoff (1m → 2m → 4m → 8m … cap 1hr); reset on any state change
- **Round-robin** — complete one poll cycle per PR before looping back
- **Priority reset:** after any push to PR #N, that PR moves to front of the next round-robin cycle

## CI Failure Classification

```bash
# Get check summary
gh pr checks $PR --repo $REPO --json name,state,conclusion

# Get failed run logs when needed
gh run view <run-id> --repo $REPO --log-failed 2>&1 | head -100
```

| Class | Evidence | Action |
|---|---|---|
| **Branch-related** | Compile/lint/test failures in files the PR touches | Fix locally → commit → push |
| **Flaky/unrelated** | DNS timeouts, runner provisioning errors, rate limits, non-deterministic unrelated tests | Rerun: `gh run rerun <run-id> --failed --repo $REPO` (up to `--max-flaky-retries`) |
| **Infrastructure** | Confirmed GitHub outage, or flaky retry limit exhausted | `blocked` state; report to user |

If uncertain: fetch failed logs once before deciding.

## Conflict Resolution (`conflict` state)

```bash
git fetch origin
git rebase origin/<BASE_BRANCH>
```

- Rebase succeeds → `git push --force-with-lease origin <branch>` → transition to `pending-ci`
- Rebase fails → `git rebase --abort` → transition to `blocked` → report conflict details

## Review Comment Handling

**Fetch review data:**
```bash
# Inline review comments
gh api repos/$REPO/pulls/$PR/comments?per_page=100
# Review submissions
gh api repos/$REPO/pulls/$PR/reviews?per_page=100
# Issue comments on PR
gh api repos/$REPO/issues/$PR/comments?per_page=100
```

**Trust model:**
- Surface: author_association in {OWNER, MEMBER, COLLABORATOR}; login contains "copilot-pull-request-reviewer"
- Ignore: other bot logins, already-resolved threads

**Priority: process actionable review comments BEFORE retrying flaky CI.** A new push retriggers CI, making the flaky retry moot.

**When actionable:**
1. Apply code fix locally
2. Commit: `fix: address PR review feedback (#<PR>)`
3. `git push origin <branch>`
4. Transition to `pending-ci`; this PR jumps to front of next round-robin cycle
5. Increment `agent_push_count`

**Agreement criteria — address when:**
- Technically correct
- Actionable in current branch
- Does not conflict with user's explicit instructions
- Can be made safely without unrelated refactors

**Do not auto-fix when:**
- Comment is ambiguous — transition to `blocked`, report for user clarification
- Conflicts with explicit user instructions
- Requires product/design decisions not yet made

## Copilot Quirks

**NEVER** use `@copilot` in comments — triggers SWE delegation agent which opens a new PR.

Re-request review via reviewer-list cycle ONLY:
```bash
# Remove then re-add (GraphQL via gh, no [bot] suffix needed)
gh pr edit $PR --repo $REPO --remove-reviewer copilot-pull-request-reviewer
gh pr edit $PR --repo $REPO --add-reviewer copilot-pull-request-reviewer
```

REST API alternatives require `[bot]` suffix:
```bash
gh api repos/$REPO/pulls/$PR/requested_reviewers \
  -X DELETE -f "reviewers[]=copilot-pull-request-reviewer[bot]"
gh api repos/$REPO/pulls/$PR/requested_reviewers \
  -X POST -f "reviewers[]=copilot-pull-request-reviewer[bot]"
```

Only re-request after at least one poll interval has elapsed (prevent spam). Track `last_review_request_at` in state.

## Merge Logic

**Check merge-readiness:**
```bash
gh pr view $PR --repo $REPO \
  --json state,mergeable,mergeableState,reviewDecision,statusCheckRollup
```

Merge-ready conditions:
- `state == "OPEN"`
- `mergeableState == "CLEAN"` (or `"HAS_HOOKS"`)
- `reviewDecision != "REVIEW_REQUIRED"` AND `!= "CHANGES_REQUESTED"`
- All status checks passing
- If `--require-resolved-threads`: no unresolved threads

**With `--auto-merge`:**
```bash
gh pr merge $PR --repo $REPO --<merge-method> --auto
```

**⚠️ auto-merge safety warning** (display when `--auto-merge` is active):
> "auto-merge is enabled. Requires repo branch protection with required status checks. Without this, a CI failure misclassified as flaky, retried to green, will auto-merge broken code."

**`--post-merge-hook` safety note:** Hook is executed via shell. Never interpolate PR metadata (title, branch name, body) — command injection risk. Use fixed commands only (e.g. `make deploy`).

## Counter Semantics

| Flag | Counts | Resets on |
|---|---|---|
| `--max-flaky-retries` | CI reruns with no code change | New SHA pushed to PR |
| `--max-agent-pushes` | Agent-pushed code commits | Never within a session |

## Strict Stop Conditions

Stop polling a PR and transition to `blocked` when:
- PR is merged or closed → `done`
- `flaky_retry_count >= --max-flaky-retries` on same SHA
- `agent_push_count >= --max-agent-pushes`
- Rebase conflict unresolvable
- CI failure classified as infrastructure outage
- Review comment ambiguous → report for user clarification

## Output Format

```
## 🐴🤖 xgh babysit-pr — tick 2026-03-27T10:00:00Z

| PR  | State          | CI              | Review       | Mergeable | Flaky | Pushes |
|-----|----------------|-----------------|--------------|-----------|-------|--------|
| #42 | pending-ci     | 1 failing ⚠️   | APPROVED ✅  | ✅        | 0/3   | 0/3    |
| #43 | fixing-review  | all green ✅    | COMMENTED ⚠️ | ✅        | 1/3   | 1/3    |

Actions this tick:
• #43: pushed review fix (agent_push_count: 1) — moved to front of next cycle
• #42: CI failure classified as branch-related — entering fixing-ci

⚠️ auto-merge is enabled. Requires repo branch protection with required status checks.
```
```

- [ ] **Step 3: Verify**

```bash
wc -l skills/babysit-pr/babysit-pr.md
grep "name: xgh:babysit-pr" skills/babysit-pr/babysit-pr.md
```

Expected: file exists with correct frontmatter.

---

## Task 6: Create xgh:babysit-pr command

**Files:**
- Create: `commands/babysit-pr.md`

- [ ] **Step 1: Write command file**

Create `commands/babysit-pr.md`:

```markdown
---
name: xgh-babysit-pr
description: CI-aware multi-PR babysitter — polls CI, classifies failures, fixes review comments, resolves conflicts, and auto-merges. Replaces xgh:ship-prs.
usage: "/xgh-babysit-pr start <PR> [<PR>...] [--repo owner/repo] [--interval 1m] [--merge-method squash|merge|rebase] [--auto-merge] [--max-flaky-retries 3] [--max-agent-pushes 3] [--require-resolved-threads] [--post-merge-hook '<cmd>'] | /xgh-babysit-pr poll-once <PR> [<PR>...] | /xgh-babysit-pr <status|stop|pause|resume> | /xgh-babysit-pr <hold|unhold> <PR> | /xgh-babysit-pr <dry-run|log> [<PR>]"
---

> **Output format:** Follow the [xgh output style guide](../templates/output-style.md). Start with `## 🐴🤖 xgh babysit-pr`. Use markdown tables for structured data. Use ✅ ⚠️ ❌ 🔁 🔀 for status. Keep per-poll output terse.

Read and follow the implementation spec at `skills/babysit-pr/babysit-pr.md`.
```

---

## Task 7: Create xgh:babysit-pr tests

**Files:**
- Create: `tests/test-babysit-pr.sh`

- [ ] **Step 1: Write test file**

Create `tests/test-babysit-pr.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

PASS=0
FAIL=0

assert_file_exists() {
  if [[ -f "$1" ]]; then
    PASS=$((PASS + 1))
  else
    echo "FAIL: missing file $1"
    FAIL=$((FAIL + 1))
  fi
}

assert_not_exists() {
  if [[ ! -f "$1" ]]; then
    PASS=$((PASS + 1))
  else
    echo "FAIL: file should not exist: $1"
    FAIL=$((FAIL + 1))
  fi
}

assert_contains() {
  if grep -qi "$2" "$1" 2>/dev/null; then
    PASS=$((PASS + 1))
  else
    echo "FAIL: $1 missing '$2'"
    FAIL=$((FAIL + 1))
  fi
}

# Files exist
assert_file_exists "skills/babysit-pr/babysit-pr.md"
assert_file_exists "commands/babysit-pr.md"

# ship-prs gone
assert_not_exists "skills/ship-prs/ship-prs.md"
assert_not_exists "commands/ship-prs.md"

# Frontmatter
assert_contains "skills/babysit-pr/babysit-pr.md" "name: xgh:babysit-pr"
assert_contains "skills/babysit-pr/babysit-pr.md" "user-invocable: true"

# State machine — all states present
assert_contains "skills/babysit-pr/babysit-pr.md" "pending-ci"
assert_contains "skills/babysit-pr/babysit-pr.md" "fixing-ci"
assert_contains "skills/babysit-pr/babysit-pr.md" "retrying-flaky"
assert_contains "skills/babysit-pr/babysit-pr.md" "conflict"
assert_contains "skills/babysit-pr/babysit-pr.md" "awaiting-review"
assert_contains "skills/babysit-pr/babysit-pr.md" "fixing-review"
assert_contains "skills/babysit-pr/babysit-pr.md" "merge-ready"
assert_contains "skills/babysit-pr/babysit-pr.md" "merging"
assert_contains "skills/babysit-pr/babysit-pr.md" "done"
assert_contains "skills/babysit-pr/babysit-pr.md" "blocked"

# Conflict state reachable from any non-terminal state
assert_contains "skills/babysit-pr/babysit-pr.md" "ANY non-terminal"

# CI classification
assert_contains "skills/babysit-pr/babysit-pr.md" "Branch-related"
assert_contains "skills/babysit-pr/babysit-pr.md" "Flaky"
assert_contains "skills/babysit-pr/babysit-pr.md" "Infrastructure"

# Counters with distinct names
assert_contains "skills/babysit-pr/babysit-pr.md" "max-flaky-retries"
assert_contains "skills/babysit-pr/babysit-pr.md" "max-agent-pushes"

# Copilot quirks
assert_contains "skills/babysit-pr/babysit-pr.md" "NEVER"
assert_contains "skills/babysit-pr/babysit-pr.md" "remove-reviewer"
assert_contains "skills/babysit-pr/babysit-pr.md" "add-reviewer"
assert_contains "skills/babysit-pr/babysit-pr.md" "\[bot\]"

# auto-merge safety warning
assert_contains "skills/babysit-pr/babysit-pr.md" "auto-merge"
assert_contains "skills/babysit-pr/babysit-pr.md" "required status checks"

# post-merge-hook safety note
assert_contains "skills/babysit-pr/babysit-pr.md" "post-merge-hook"
assert_contains "skills/babysit-pr/babysit-pr.md" "injection"

# Session-id definition
assert_contains "skills/babysit-pr/babysit-pr.md" "YYYY-MM-DD-HHMMSS"

# State file path
assert_contains "skills/babysit-pr/babysit-pr.md" ".xgh/babysit-pr/"

# Round-robin + priority reset
assert_contains "skills/babysit-pr/babysit-pr.md" "Round-robin"
assert_contains "skills/babysit-pr/babysit-pr.md" "Priority reset"

# Conflict resolution — rebase
assert_contains "skills/babysit-pr/babysit-pr.md" "git rebase"
assert_contains "skills/babysit-pr/babysit-pr.md" "rebase --abort"

# Command file
assert_contains "commands/babysit-pr.md" "xgh-babysit-pr"
assert_contains "commands/babysit-pr.md" "/xgh-babysit-pr"

echo ""
echo "babysit-pr tests: $PASS passed, $FAIL failed"
[[ "$FAIL" -eq 0 ]] || exit 1
```

- [ ] **Step 2: Make executable and run**

```bash
chmod +x tests/test-babysit-pr.sh
cd /Users/pedro/Developer/xgh && bash tests/test-babysit-pr.sh
```

Expected: all pass.

- [ ] **Step 3: Commit**

```bash
git add skills/babysit-pr/ commands/babysit-pr.md tests/test-babysit-pr.sh
git commit -m "feat: add xgh:babysit-pr skill (replaces ship-prs, CI-aware multi-PR babysitter)"
```

---

## Task 8: Enrich xgh:watch-prs

**Files:**
- Modify: `skills/watch-prs/watch-prs.md`
- Modify: `commands/watch-prs.md`

Read `skills/watch-prs/watch-prs.md` before editing.

- [ ] **Step 1: Update skill description in frontmatter**

In `skills/watch-prs/watch-prs.md`, update the description to:
```
description: "Passively monitor PRs — surfaces review changes, new comments, CI status with classification (branch-related/flaky), and merge-readiness. Never merges, never fixes. Use /xgh-babysit-pr to act on findings."
```

- [ ] **Step 2: Add CI classification section**

After the existing "A — Fetch current state (read-only)" step, add a new subsection:

```markdown
#### A1 — CI Classification (lazy — only on status change to failing)

When CI status transitions from non-failing to failing for the current SHA:

```bash
gh run view <run-id> --repo $REPO --log-failed 2>&1 | head -100
```

Classify each failing check:
- **Branch-related ⚠️** — compile/lint/test failures in files the PR touches
- **Likely flaky 🔁** — DNS timeouts, runner provisioning, rate limits, unrelated non-deterministic tests
- **Infrastructure ❌** — confirmed outage

Cache classification per SHA. Do NOT re-fetch logs on subsequent polls with the same SHA and same failing checks. Clear cache when `baseline_sha` changes.

Display:
```
CI: 2 failing
  • lint          branch-related ⚠️
  • docker-build  likely flaky 🔁
```
```

- [ ] **Step 3: Add bot filter to review display**

In the "C — Print change-log" section, update the review comment display:

```markdown
#### Review comment filtering

**Default:** Collapse authors whose login ends in `[bot]` or `[app]`. All human reviewers surface regardless of association level (OWNER, MEMBER, COLLABORATOR, NONE — all shown).

**`--show-bots` flag:** Expand collapsed bot entries.

In the change-log, collapsed bots appear as:
```
• #42: [3 bot comments collapsed — use --show-bots to expand]
```
```

- [ ] **Step 4: Add babysit-pr handoff prompts**

At the end of the "C — Print change-log" section, add:

```markdown
#### Handoff prompts

After printing the change-log, surface one-liners for PRs requiring action:

```
⚠️  #42 blocked on branch-related CI failure → /xgh-babysit-pr start 42 to fix
✅  #43 merge-ready                           → /xgh-babysit-pr start 43 --auto-merge to ship
🔀  #44 has git conflict                      → /xgh-babysit-pr start 44 to rebase
```

Only emit a handoff prompt when the state **changed** this tick (don't repeat on every poll).
```

- [ ] **Step 5: Add merged/closed detection**

In the "D — Update state" section, add:

```markdown
#### Merged/closed detection

On every poll, check:
```bash
gh pr view $PR --repo $REPO --json state | jq -r '.state'
```

If state is `MERGED` or `CLOSED`: stop polling this PR immediately. Report:
```
✅ PR #42 merged — removing from watch list.
```

Remove the PR from the active session. If no PRs remain, stop the session.
```

- [ ] **Step 6: Update change-log output example**

Replace the existing output example with the enriched format:

```markdown
```
## 🐴🤖 xgh watch-prs — tick 2026-03-27T10:00:00Z

| PR  | State | Mergeable | Review       | CI                          | Comments |
|-----|-------|-----------|--------------|------------------------------|----------|
| #42 | OPEN  | ✅        | APPROVED ✅  | 1 failing (branch-rel ⚠️)   | 3        |
| #43 | OPEN  | ✅        | COMMENTED ⚠️ | all green ✅                 | 7 (+2)   |

Changes since last tick:
• #42: CI failure classified as branch-related
• #43: 2 new comments from @alice (MEMBER)
• #43: [1 bot comment collapsed — use --show-bots to expand]

⚠️  #42 needs CI fix → /xgh-babysit-pr start 42 to fix
```

If no changes: `✅ No changes since last tick.`
```

- [ ] **Step 7: Update the existing ship-prs reference**

Search for `/xgh-ship-prs` in the skill file and replace with `/xgh-babysit-pr`:

```bash
grep -n "ship-prs" skills/watch-prs/watch-prs.md
```

Replace any `ship-prs` reference in handoff hints with `babysit-pr`.

- [ ] **Step 8: Update commands/watch-prs.md description**

In `commands/watch-prs.md`, update the description frontmatter:
```
description: Passively monitor PRs — surfaces CI classification, review changes, merge-readiness, and handoff prompts for /xgh-babysit-pr. Never merges, never fixes.
```

- [ ] **Step 9: Verify changes**

```bash
grep -n "babysit-pr\|bot\|classification\|handoff\|MERGED\|CLOSED" skills/watch-prs/watch-prs.md | head -20
grep -c "ship-prs" skills/watch-prs/watch-prs.md
```

Expected: multiple babysit-pr references, 0 ship-prs references.

- [ ] **Step 10: Commit**

```bash
git add skills/watch-prs/watch-prs.md commands/watch-prs.md
git commit -m "feat: enrich xgh:watch-prs with CI classification, bot filter, and babysit-pr handoffs"
```

---

## Task 9: Update watch-prs tests

**Files:**
- Modify: `tests/test-watch-prs.sh` (create if doesn't exist)

- [ ] **Step 1: Check if test file exists**

```bash
ls tests/ | grep watch
```

- [ ] **Step 2: Create or update test file**

If file doesn't exist, create `tests/test-watch-prs.sh`. If it exists, append the new assertions.

New assertions to add:

```bash
# Bot filter — new
assert_contains "skills/watch-prs/watch-prs.md" "\[bot\]"
assert_contains "skills/watch-prs/watch-prs.md" "show-bots"

# Merged/closed detection — new
assert_contains "skills/watch-prs/watch-prs.md" "MERGED"
assert_contains "skills/watch-prs/watch-prs.md" "CLOSED"

# CI classification — new
assert_contains "skills/watch-prs/watch-prs.md" "branch-related"
assert_contains "skills/watch-prs/watch-prs.md" "flaky"
assert_contains "skills/watch-prs/watch-prs.md" "lazy"

# Handoff prompts to babysit-pr — new
assert_contains "skills/watch-prs/watch-prs.md" "babysit-pr"
assert_contains "skills/watch-prs/watch-prs.md" "xgh-babysit-pr"

# No ship-prs references remaining
if grep -qi "ship-prs" "skills/watch-prs/watch-prs.md" 2>/dev/null; then
  echo "FAIL: watch-prs still references ship-prs"
  FAIL=$((FAIL + 1))
else
  PASS=$((PASS + 1))
fi

# Read-only contract still intact
assert_contains "skills/watch-prs/watch-prs.md" "Never merges"
```

- [ ] **Step 3: Run**

```bash
chmod +x tests/test-watch-prs.sh 2>/dev/null || true
cd /Users/pedro/Developer/xgh && bash tests/test-watch-prs.sh
```

Expected: all pass.

- [ ] **Step 4: Commit**

```bash
git add tests/test-watch-prs.sh
git commit -m "test: add watch-prs assertions for CI classification, bot filter, babysit-pr handoffs"
```

---

## Task 10: Integration verification

- [ ] **Step 1: Run full test suite**

```bash
cd /Users/pedro/Developer/xgh && bash tests/run-all.sh 2>&1 | tail -20
```

Expected: new tests pass; pre-existing failures unchanged.

- [ ] **Step 2: Verify plugin structure**

```bash
ls skills/ | grep -E "gh-issues|babysit-pr|watch-prs|ship-prs"
ls commands/ | grep -E "gh-issues|babysit-pr|watch-prs|ship-prs"
```

Expected:
- `gh-issues`, `babysit-pr`, `watch-prs` present
- `ship-prs` absent in both

- [ ] **Step 3: Verify state directories documented**

```bash
grep -r ".xgh/babysit-pr\|.xgh/locks\|.xgh/watch-prs" skills/ commands/
```

Expected: babysit-pr and gh-issues reference their respective state paths.

- [ ] **Step 4: Run individual new tests**

```bash
cd /Users/pedro/Developer/xgh
bash tests/test-gh-issues.sh
bash tests/test-babysit-pr.sh
bash tests/test-watch-prs.sh
```

Expected: all pass.

- [ ] **Step 5: Final commit**

```bash
git add -A
git status  # verify nothing unexpected staged
git commit -m "chore: openclaw + babysit-pr skills incorporation — complete

- xgh:gh-issues: parallel issue auto-fix (ported from openclaw)
- xgh:babysit-pr: CI-aware multi-PR babysitter (replaces ship-prs)
- xgh:watch-prs: enriched with CI classification, bot filter, handoffs
- xgh:ship-prs: deleted (superseded)"
```

---

## Self-Review Checklist

- [x] **Spec coverage:** All 13 deliverables from spec checklist covered (skills, commands, tests, deletions)
- [x] **Placeholder scan:** No TBD/TODO — all steps contain actual code/commands
- [x] **Type consistency:** `--max-agent-pushes` (not `--max-fix-cycles`) used consistently throughout
- [x] **State file paths:** `.xgh/babysit-pr/<session-id>.json`, `.xgh/locks/gh-issues-<N>.lock` specified
- [x] **ship-prs references:** Task 8 Step 7 explicitly hunts and removes remaining ship-prs references in watch-prs
- [x] **No test-ship-prs files to delete** — confirmed in Task 1 Step 1
- [x] **plugin.json:** No explicit registration needed — directory scanning auto-discovers skills/commands
- [x] **watch-prs state file path confirmed:** `.xgh/watch-prs-state.json` (single file, not per-PR)
