# Phase 2: Validate + Observe — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make preferences enforceable by expanding PreToolUse with severity-aware validation (block/warn), adding PostToolUse drift detection for project.yaml edits, and PostToolUseFailure diagnosis for `gh` CLI errors.

**Architecture:** Extend Phase 1's hook lifecycle with 3 new capabilities: `lib/severity.sh` (configurable block/warn per check), PostToolUse snapshot diffing (YAML leaf comparison), PostToolUseFailure pattern matching (command+stderr dual-match). All hooks fail-open.

**Tech Stack:** Bash (`set -euo pipefail`), yq/Python (YAML read/diff), jq (JSON I/O), `lib/preferences.sh` (existing read layer)

---

## File Map

| File | Action | Responsibility |
|------|--------|---------------|
| `lib/severity.sh` | Create | Severity resolution: read `checks.<name>.severity` from project.yaml, fall back to hardcoded defaults |
| `hooks/pre-tool-use-preferences.sh` | Rewrite | 5 severity-aware checks: merge method, force-push, branch naming, protected branch, commit format |
| `hooks/post-tool-use-preferences.sh` | Create | Drift detection: snapshot diff of project.yaml leaf values on Write/Edit |
| `hooks/post-tool-use-failure-preferences.sh` | Create | Diagnosis: parse `gh` stderr for merge-method, reviewer, repo, auth errors |
| `hooks/session-start-preferences.sh` | Expand | Seed project.yaml snapshot to TMPDIR for drift detection |
| `.claude/settings.json` | Expand | Register PostToolUse and PostToolUseFailure hooks |
| `config/project.yaml` | Expand | Add `vcs.branches`, `vcs.checks`, `pr.checks` schema fields |
| `tests/test-severity.sh` | Create | `_severity_resolve` with configured, missing, invalid values |
| `tests/test-pre-tool-use-validation.sh` | Create | All 5 checks × block/warn severity |
| `tests/test-post-tool-use-drift.sh` | Create | Snapshot creation, leaf diff, missing snapshot, non-project.yaml exit |
| `tests/test-post-tool-use-failure-diagnosis.sh` | Create | All 4 diagnosis patterns, dual-match, fail-open |
| `tests/test-hook-ordering.sh` | Expand | Verify PostToolUse and PostToolUseFailure hook positions |
| `skills/validate-project-prefs/validate-project-prefs.md` | Expand | Audit Phase 2 fields: checks keys, severity values, protected branches, regex validity |
| `skills/_shared/references/project-preferences.md` | Expand | Document new vcs.branches, vcs.checks, pr.checks fields |

## Execution Waves

```
Wave 1 (parallel, no deps):     Task 1 [lib/severity.sh], Task 2 [project.yaml schema], Task 3 [settings.json hooks]
Wave 2 (depends on Wave 1):     Task 4 [PreToolUse rewrite], Task 5 [snapshot seeding]
Wave 3 (depends on Wave 2):     Task 6 [PostToolUse drift], Task 7 [PostToolUseFailure diagnosis]
Wave 4 (depends on all):        Task 8 [hook ordering tests], Task 9 [validation skill + references]
```

---

### Task 1: lib/severity.sh — Severity Resolution

**Files:**
- Create: `lib/severity.sh`
- Create: `tests/test-severity.sh`
- Read: `lib/preferences.sh` (provides `_pref_read_yaml`)
- Read: `.xgh/specs/2026-03-26-phase-2-validate-observe-design.md` (Section 5a)

**Context:**
- `_severity_resolve(domain, check_name)` reads `preferences.<domain>.checks.<check_name>.severity` from project.yaml
- Falls back to hardcoded defaults: `protected_branch=block`, `force_push=block`, `merge_method=block`, `branch_naming=warn`, `commit_format=warn`
- Requires `lib/preferences.sh` to be sourced first (provides `_pref_read_yaml`)
- Uses `declare -A` (bash 4+ associative array) for defaults map
- Strict mode guard: only `set -euo pipefail` when executed directly, not when sourced

- [ ] **Step 1: Write failing tests**

Create `tests/test-severity.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

PASS=0
FAIL=0

assert_equals() {
  local label="$1" expected="$2" actual="$3"
  if [[ "$expected" == "$actual" ]]; then
    PASS=$((PASS + 1))
  else
    echo "FAIL: $label — expected '$expected', got '$actual'"
    FAIL=$((FAIL + 1))
  fi
}

# Source dependencies
REPO_ROOT="$(git rev-parse --show-toplevel)"
source "$REPO_ROOT/lib/preferences.sh"
source "$REPO_ROOT/lib/severity.sh"

# --- Test 1: Default severity for safety-critical checks ---
result=$(_severity_resolve "pr" "merge_method")
assert_equals "merge_method default severity" "block" "$result"

result=$(_severity_resolve "vcs" "force_push")
assert_equals "force_push default severity" "block" "$result"

result=$(_severity_resolve "vcs" "protected_branch")
assert_equals "protected_branch default severity" "block" "$result"

# --- Test 2: Default severity for convention checks ---
result=$(_severity_resolve "vcs" "branch_naming")
assert_equals "branch_naming default severity" "warn" "$result"

result=$(_severity_resolve "vcs" "commit_format")
assert_equals "commit_format default severity" "warn" "$result"

# --- Test 3: Unknown check falls back to warn ---
result=$(_severity_resolve "vcs" "nonexistent_check")
assert_equals "unknown check falls back to warn" "warn" "$result"

# --- Test 4: Configured severity overrides default ---
# Use a temp project.yaml where force_push (default=block) is set to warn
TMPYAML=$(mktemp)
cat > "$TMPYAML" << 'YAMEOF'
preferences:
  vcs:
    checks:
      force_push: { severity: warn }
YAMEOF
# Override _pref_project_yaml to point at temp file
_pref_project_yaml() { echo "$TMPYAML"; }
result=$(_severity_resolve "vcs" "force_push")
assert_equals "configured warn overrides default block" "warn" "$result"
# Restore original
_pref_project_yaml() {
  local root; root=$(git rev-parse --show-toplevel 2>/dev/null || echo ".")
  echo "$root/config/project.yaml"
}
rm -f "$TMPYAML"

# --- Test 5: Invalid configured severity falls back to default ---
TMPYAML2=$(mktemp)
cat > "$TMPYAML2" << 'YAMEOF'
preferences:
  vcs:
    checks:
      force_push: { severity: invalid_value }
YAMEOF
_pref_project_yaml() { echo "$TMPYAML2"; }
result=$(_severity_resolve "vcs" "force_push")
assert_equals "invalid severity falls back to default" "block" "$result"
_pref_project_yaml() {
  local root; root=$(git rev-parse --show-toplevel 2>/dev/null || echo ".")
  echo "$root/config/project.yaml"
}
rm -f "$TMPYAML2"

echo ""
echo "Severity test: $PASS passed, $FAIL failed"
[[ "$FAIL" -eq 0 ]] || exit 1
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `bash tests/test-severity.sh`
Expected: FAIL — `lib/severity.sh` does not exist yet

- [ ] **Step 3: Implement lib/severity.sh**

Create `lib/severity.sh`:

```bash
#!/usr/bin/env bash
# lib/severity.sh — Severity resolution for preference checks
# Sourced by pre-tool-use-preferences.sh only.
# Requires: lib/preferences.sh must be sourced first (provides _pref_read_yaml).

# Strict mode guard — only when executed directly, not when sourced.
# (Matches convention used in other lib/ files.)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  set -euo pipefail
fi

# Hardcoded defaults (safety=block, convention=warn)
declare -A _SEVERITY_DEFAULTS=(
  [protected_branch]=block
  [force_push]=block
  [merge_method]=block
  [branch_naming]=warn
  [commit_format]=warn
)

_severity_resolve() {
  local domain="$1" check_name="$2"
  local configured
  # _pref_read_yaml is provided by lib/preferences.sh (must be sourced first)
  configured=$(_pref_read_yaml "preferences.${domain}.checks.${check_name}.severity")
  if [[ "$configured" == "block" || "$configured" == "warn" ]]; then
    echo "$configured"
  else
    echo "${_SEVERITY_DEFAULTS[$check_name]:-warn}"
  fi
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `bash tests/test-severity.sh`
Expected: All PASS

- [ ] **Step 5: Commit**

```bash
git add lib/severity.sh tests/test-severity.sh
git commit -m "feat(phase2): add lib/severity.sh — configurable block/warn per check"
```

---

### Task 2: project.yaml Schema Expansion

**Files:**
- Modify: `config/project.yaml`
- Modify: `tests/test-preferences.sh` (add tests for new fields)

**Context:**
- Add `preferences.vcs.branches.<name>.protected: true` for main and master
- Add `preferences.vcs.checks.<name>.severity` for all 5 checks
- Add `preferences.pr.checks.merge_method.severity: block`
- Overwrite `preferences.vcs.commit_format` and `preferences.vcs.branch_naming` with regex values (spec puts regex directly in these fields, not separate `_regex` suffixed fields)
- The template strings (`<type>: <description>`) move to comments — the field values become the regex patterns used by PreToolUse validation

- [ ] **Step 1: Write failing tests for new schema fields**

Add to `tests/test-preferences.sh`:

```bash
# --- Phase 2: New schema fields ---

# vcs.branches.main.protected
result=$(_pref_read_yaml "preferences.vcs.branches.main.protected")
assert_equals "vcs.branches.main.protected" "true" "$result"

# vcs.branches.master.protected
result=$(_pref_read_yaml "preferences.vcs.branches.master.protected")
assert_equals "vcs.branches.master.protected" "true" "$result"

# vcs.checks.branch_naming.severity
result=$(_pref_read_yaml "preferences.vcs.checks.branch_naming.severity")
assert_equals "vcs.checks.branch_naming.severity" "warn" "$result"

# vcs.checks.protected_branch.severity
result=$(_pref_read_yaml "preferences.vcs.checks.protected_branch.severity")
assert_equals "vcs.checks.protected_branch.severity" "block" "$result"

# vcs.checks.commit_format.severity
result=$(_pref_read_yaml "preferences.vcs.checks.commit_format.severity")
assert_equals "vcs.checks.commit_format.severity" "warn" "$result"

# vcs.checks.force_push.severity
result=$(_pref_read_yaml "preferences.vcs.checks.force_push.severity")
assert_equals "vcs.checks.force_push.severity" "block" "$result"

# pr.checks.merge_method.severity
result=$(_pref_read_yaml "preferences.pr.checks.merge_method.severity")
assert_equals "pr.checks.merge_method.severity" "block" "$result"
```

- [ ] **Step 2: Run tests to verify new tests fail**

Run: `bash tests/test-preferences.sh`
Expected: New tests FAIL (fields don't exist in project.yaml yet)

- [ ] **Step 3: Expand project.yaml with new fields**

Add under `preferences.vcs`:

```yaml
  vcs:
    commit_format: "^(feat|fix|docs|chore|refactor|test|ci)(\\(.+\\))?: .+"  # was "<type>: <description>" — now regex for validation
    branch_naming: "^(feat|fix|docs|chore)/"  # was "<type>/<description>" — now regex for validation
    pr_template: ""
    branches:
      main:
        protected: true
      master:
        protected: true
    checks:
      branch_naming: { severity: warn }
      protected_branch: { severity: block }
      commit_format: { severity: warn }
      force_push: { severity: block }
```

Add under `preferences.pr`:

```yaml
    checks:
      merge_method: { severity: block }
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `bash tests/test-preferences.sh`
Expected: All PASS (including new Phase 2 tests)

- [ ] **Step 4b: Migrate protected branch data**

The existing `preferences.pr.branches.main` and `preferences.pr.branches.develop` entries stay (they hold `merge_method` overrides). Add `protected: true` to them as well, so both old and new paths work:

```yaml
  pr:
    branches:
      main:
        merge_method: merge
        required_approvals: 1
        protected: true    # ← add (backward compat for Phase 1 hook readers)
      develop:
        merge_method: squash
```

This ensures hooks that read `_pref_read_branch "pr" "main" "protected"` (Phase 1 path) still work alongside the new `preferences.vcs.branches.main.protected` path. The PreToolUse hook (Task 4) checks both paths as a fallback chain.

- [ ] **Step 5: Run tests to verify they pass**

Run: `bash tests/test-preferences.sh`
Expected: All PASS (including new Phase 2 tests)

- [ ] **Step 6: Commit**

```bash
git add config/project.yaml tests/test-preferences.sh
git commit -m "feat(phase2): expand project.yaml with vcs.branches, vcs.checks, pr.checks"
```

---

### Task 3: settings.json Hook Registration

**Files:**
- Modify: `.claude/settings.json`

**Context:**
- Add PostToolUse hook with matcher `Write|Edit|MultiEdit`, command `bash hooks/post-tool-use-preferences.sh`
- Add PostToolUseFailure hook with matcher `Bash`, command `bash hooks/post-tool-use-failure-preferences.sh`
- New hooks appended LAST in the file (coexistence contract)
- Existing hooks: PreToolUse (Bash), SessionStart, PostCompact — all remain unchanged

- [ ] **Step 1: Add PostToolUse and PostToolUseFailure hooks**

Expand `.claude/settings.json` to add the two new hook event types:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "bash hooks/pre-tool-use-preferences.sh"
          }
        ]
      }
    ],
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash hooks/session-start-preferences.sh"
          }
        ]
      }
    ],
    "PostCompact": [
      {
        "matcher": "manual|auto",
        "hooks": [
          {
            "type": "command",
            "command": "bash hooks/post-compact-preferences.sh"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Write|Edit|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "command": "bash hooks/post-tool-use-preferences.sh"
          }
        ]
      }
    ],
    "PostToolUseFailure": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "bash hooks/post-tool-use-failure-preferences.sh"
          }
        ]
      }
    ]
  }
}
```

- [ ] **Step 2: Validate JSON syntax**

Run: `jq '.' .claude/settings.json`
Expected: Valid JSON output, no errors

- [ ] **Step 3: Commit**

```bash
git add .claude/settings.json
git commit -m "feat(phase2): register PostToolUse and PostToolUseFailure hooks"
```

---

### Task 4: PreToolUse Full Validation (Rewrite)

**Files:**
- Rewrite: `hooks/pre-tool-use-preferences.sh`
- Create: `tests/test-pre-tool-use-validation.sh`
- Read: `lib/severity.sh` (from Task 1)
- Read: `lib/preferences.sh` (existing read layer)
- Read: `.xgh/specs/2026-03-26-phase-2-validate-observe-design.md` (Section 2)

**Context:**
- Replace Phase 1's 2 warn-only checks with 5 severity-aware checks
- Checks: merge method, force-push, branch naming, protected branch, commit format
- Source `lib/preferences.sh` and `lib/severity.sh` instead of `lib/config-reader.sh`
- `block` → `permissionDecision: "deny"` + `permissionDecisionReason`
- `warn` → `additionalContext` (existing pattern)
- Flag ordering handled with `.*` lookahead patterns
- Trigger patterns cover aliases: `git checkout -b` AND `git switch -c`, `-m` AND `--message`

- [ ] **Step 1: Write failing tests for all 5 checks**

Create `tests/test-pre-tool-use-validation.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
HOOK="${REPO_ROOT}/hooks/pre-tool-use-preferences.sh"
PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

run_hook() {
  local input="$1"
  (cd "$REPO_ROOT" && echo "$input" | bash "$HOOK" 2>/dev/null) || true
}

make_input() {
  local cmd="$1"
  printf '{"tool_name":"Bash","tool_input":{"command":"%s"}}' "$cmd"
}

echo "=== test-pre-tool-use-validation ==="

# --- Check 1: Merge method (block severity) ---
echo "--- 1. Merge method mismatch (block) ---"
# develop branch uses squash, so --merge should be blocked
output=$(run_hook "$(make_input "gh pr merge 42 --merge")")
if echo "$output" | jq -e '.hookSpecificOutput.permissionDecision == "deny"' >/dev/null 2>&1; then
  pass "merge method mismatch → deny"
else
  fail "merge method mismatch should deny. Output: $output"
fi

echo "--- 1b. Merge method match (pass-through) ---"
output=$(run_hook "$(make_input "gh pr merge 42 --squash")")
if [[ -z "$output" ]] || echo "$output" | jq -e '.hookSpecificOutput.permissionDecision == "deny"' >/dev/null 2>&1; then
  if [[ -z "$output" ]]; then
    pass "merge method match → silent pass-through"
  else
    fail "merge method match should pass through. Output: $output"
  fi
else
  pass "merge method match → no deny"
fi

# --- Check 2: Force-push on protected branch (block) ---
echo "--- 2. Force-push on protected branch (block) ---"
# main is protected in project.yaml
output=$(run_hook "$(make_input "git push origin main --force")")
if echo "$output" | jq -e '.hookSpecificOutput.permissionDecision == "deny"' >/dev/null 2>&1; then
  pass "force-push to main → deny"
else
  fail "force-push to main should deny. Output: $output"
fi

echo "--- 2b. Force-push on non-protected branch ---"
output=$(run_hook "$(make_input "git push origin feat/foo --force")")
if echo "$output" | jq -e '.hookSpecificOutput.permissionDecision == "deny"' >/dev/null 2>&1; then
  fail "force-push to feat/foo should not deny. Output: $output"
else
  pass "force-push to non-protected branch → pass-through"
fi

# --- Check 3: Branch naming convention (warn) ---
echo "--- 3. Branch naming (warn) ---"
output=$(run_hook "$(make_input "git checkout -b bad-branch-name")")
if echo "$output" | jq -e '.hookSpecificOutput.additionalContext' >/dev/null 2>&1; then
  # Should warn, not block
  if echo "$output" | jq -e '.hookSpecificOutput.permissionDecision == "deny"' >/dev/null 2>&1; then
    fail "branch naming should warn, not deny. Output: $output"
  else
    pass "bad branch name → warn via additionalContext"
  fi
else
  fail "bad branch name should produce warning. Output: $output"
fi

echo "--- 3b. Branch naming match ---"
output=$(run_hook "$(make_input "git checkout -b feat/new-feature")")
if [[ -z "$output" ]]; then
  pass "valid branch name → silent pass-through"
else
  if echo "$output" | jq -e '.hookSpecificOutput.additionalContext' >/dev/null 2>&1; then
    fail "valid branch name should not warn. Output: $output"
  else
    pass "valid branch name → no warning"
  fi
fi

echo "--- 3c. Branch naming with git switch -c ---"
output=$(run_hook "$(make_input "git switch -c bad-branch-name")")
if echo "$output" | jq -e '.hookSpecificOutput.additionalContext' >/dev/null 2>&1; then
  pass "git switch -c bad name → warn"
else
  fail "git switch -c bad name should warn. Output: $output"
fi

# --- Check 4: Protected branch (block) — direct commit ---
echo "--- 4. Commit on protected branch (block) ---"
# This check fires when the user is ON a protected branch and tries to commit.
# We can't easily test being on main without switching branches, so we test the
# pattern matching logic by checking that the hook handles git commit commands.
# The actual protection depends on current branch = protected.
# For testing, we verify the check structure exists by testing a non-protected scenario:
output=$(run_hook "$(make_input "git commit -m 'test'")")
# On develop (not protected), should pass through
if echo "$output" | jq -e '.hookSpecificOutput.permissionDecision == "deny"' >/dev/null 2>&1; then
  fail "commit on develop should not deny. Output: $output"
else
  pass "commit on non-protected branch → pass-through"
fi

# --- Check 5: Commit format (warn) ---
echo "--- 5. Commit format (warn) ---"
output=$(run_hook "$(make_input "git commit -m 'bad format no type prefix'")")
if echo "$output" | jq -e '.hookSpecificOutput.additionalContext' >/dev/null 2>&1; then
  if echo "$output" | jq -e '.hookSpecificOutput.permissionDecision == "deny"' >/dev/null 2>&1; then
    fail "commit format should warn, not deny. Output: $output"
  else
    pass "bad commit format → warn"
  fi
else
  fail "bad commit format should warn. Output: $output"
fi

echo "--- 5b. Valid commit format ---"
output=$(run_hook "$(make_input "git commit -m 'feat: add new feature'")")
if [[ -z "$output" ]]; then
  pass "valid commit format → silent pass-through"
else
  if echo "$output" | jq -e '.hookSpecificOutput.additionalContext' >/dev/null 2>&1; then
    # Check if the warning is about commit format (might be about protected branch)
    ctx=$(echo "$output" | jq -r '.hookSpecificOutput.additionalContext // ""')
    if [[ "$ctx" == *"commit format"* ]] || [[ "$ctx" == *"commit_format"* ]]; then
      fail "valid commit format should not warn about format. Output: $output"
    else
      pass "valid commit format → no format warning"
    fi
  else
    pass "valid commit format → no warning"
  fi
fi

echo "--- 5c. Commit format with --message flag ---"
output=$(run_hook "$(make_input "git commit --message 'bad format'")")
if echo "$output" | jq -e '.hookSpecificOutput.additionalContext' >/dev/null 2>&1; then
  pass "git commit --message bad format → warn"
else
  fail "git commit --message bad format should warn. Output: $output"
fi

# --- Check 6: Non-matching command (pass-through) ---
echo "--- 6. Non-matching command ---"
output=$(run_hook "$(make_input "ls -la")")
if [[ -z "$output" ]]; then
  pass "non-matching command → silent pass-through"
else
  fail "non-matching command should produce no output. Output: $output"
fi

# --- Check 7: Non-Bash tool (early exit) ---
echo "--- 7. Non-Bash tool ---"
output=$(cd "$REPO_ROOT" && echo '{"tool_name":"Write","tool_input":{"file_path":"/tmp/test"}}' | bash "$HOOK" 2>/dev/null || true)
if [[ -z "$output" ]]; then
  pass "non-Bash tool → silent exit"
else
  fail "non-Bash tool should produce no output. Output: $output"
fi

# --- Summary ---
echo ""
echo "PreToolUse validation: $PASS passed, $FAIL failed"
[[ "$FAIL" -eq 0 ]] || exit 1
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `bash tests/test-pre-tool-use-validation.sh`
Expected: Several FAIL (Phase 1 hook lacks severity-aware output, new checks don't exist)

- [ ] **Step 3: Rewrite pre-tool-use-preferences.sh**

Rewrite `hooks/pre-tool-use-preferences.sh` with all 5 severity-aware checks:

```bash
#!/usr/bin/env bash
# hooks/pre-tool-use-preferences.sh — PreToolUse preference validation hook
#
# Phase 2: 5 severity-aware checks (block or warn per config).
# Reads stdin JSON: { tool_name, tool_input: { command } }
# Block: { hookSpecificOutput: { hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: "..." } }
# Warn:  { hookSpecificOutput: { hookEventName: "PreToolUse", additionalContext: "..." } }
# Any failure = silent pass-through (exit 0, no output).
set -euo pipefail

# ── Read stdin ──────────────────────────────────────────────────────────
INPUT=$(cat 2>/dev/null) || exit 0
[ -n "$INPUT" ] || exit 0

# ── Fast exit: only Bash tool ───────────────────────────────────────────
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null) || exit 0
[ "$TOOL_NAME" = "Bash" ] || exit 0

# ── Extract command ─────────────────────────────────────────────────────
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null) || exit 0
[ -n "$COMMAND" ] || exit 0

# ── Resolve repo root and source libraries ──────────────────────────────
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
PROJECT_YAML="${REPO_ROOT}/config/project.yaml"
[ -f "$PROJECT_YAML" ] || exit 0

# Source preference read layer and severity resolver
# shellcheck source=../lib/preferences.sh
source "${REPO_ROOT}/lib/preferences.sh" 2>/dev/null || exit 0
# shellcheck source=../lib/severity.sh
source "${REPO_ROOT}/lib/severity.sh" 2>/dev/null || exit 0

# ── Output helpers ──────────────────────────────────────────────────────
_emit_block() {
  local reason="$1"
  jq -n --arg reason "$reason" '{
    "hookSpecificOutput": {
      "hookEventName": "PreToolUse",
      "permissionDecision": "deny",
      "permissionDecisionReason": $reason
    }
  }'
}

_emit_warn() {
  local msg="$1"
  jq -n --arg msg "$msg" '{
    "hookSpecificOutput": {
      "hookEventName": "PreToolUse",
      "additionalContext": $msg
    }
  }'
}

_emit() {
  local severity="$1" message="$2"
  if [[ "$severity" == "block" ]]; then
    _emit_block "$message"
  else
    _emit_warn "$message"
  fi
}

# ── Check 1: gh pr merge — merge method validation ─────────────────────
if echo "$COMMAND" | grep -q 'gh pr merge'; then
  CMD_METHOD=""
  if echo "$COMMAND" | grep -qE -- '--squash'; then
    CMD_METHOD="squash"
  elif echo "$COMMAND" | grep -qE -- '--merge'; then
    CMD_METHOD="merge"
  elif echo "$COMMAND" | grep -qE -- '--rebase'; then
    CMD_METHOD="rebase"
  fi
  [ -n "$CMD_METHOD" ] || exit 0

  # Determine target branch
  PR_NUMBER=$(echo "$COMMAND" | grep -oE 'gh pr merge[[:space:]]+([0-9]+)' | grep -oE '[0-9]+' || true)
  TARGET_BRANCH=""
  if [ -n "$PR_NUMBER" ]; then
    TARGET_BRANCH=$(gh pr view "$PR_NUMBER" --json baseRefName -q .baseRefName 2>/dev/null || true)
  fi

  CONFIGURED_METHOD=$(load_pr_pref "merge_method" "" "$TARGET_BRANCH")
  [ -n "$CONFIGURED_METHOD" ] || exit 0

  if [ "$CMD_METHOD" != "$CONFIGURED_METHOD" ]; then
    BRANCH_MSG=""
    [ -n "$TARGET_BRANCH" ] && BRANCH_MSG=" for branch ${TARGET_BRANCH}"
    severity=$(_severity_resolve "pr" "merge_method")
    _emit "$severity" "[xgh] Merge method mismatch: command uses --${CMD_METHOD} but config/project.yaml specifies ${CONFIGURED_METHOD}${BRANCH_MSG}. Use --${CONFIGURED_METHOD} instead."
  fi
  exit 0
fi

# ── Check 2: git push --force on protected branches ────────────────────
if echo "$COMMAND" | grep -qE 'git push.*(--force|[ ]-f[ ]|[ ]-f$)'; then
  PUSH_ARGS=$(echo "$COMMAND" | sed 's/git push//' | sed 's/--force-with-lease//g' | sed 's/--force//g' | sed 's/-f//g' | sed 's/--no-verify//g' | xargs)
  PUSH_BRANCH=""
  if [ -n "$PUSH_ARGS" ]; then
    PUSH_BRANCH=$(echo "$PUSH_ARGS" | awk '{print $2}')
    PUSH_BRANCH=$(echo "$PUSH_BRANCH" | sed 's/:.*//')
  fi
  [ -z "$PUSH_BRANCH" ] && PUSH_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)
  [ -n "$PUSH_BRANCH" ] || exit 0

  IS_PROTECTED=$(_pref_read_yaml "preferences.vcs.branches.${PUSH_BRANCH}.protected")
  # Also check pr.branches for backward compat
  if [[ "$IS_PROTECTED" != "true" ]]; then
    IS_PROTECTED=$(_pref_read_branch "pr" "$PUSH_BRANCH" "protected")
  fi

  if [[ "$IS_PROTECTED" == "true" ]]; then
    severity=$(_severity_resolve "vcs" "force_push")
    _emit "$severity" "[xgh] Force-push to protected branch '${PUSH_BRANCH}'. config/project.yaml marks this branch as protected."
  fi
  exit 0
fi

# ── Check 3: Branch naming convention ───────────────────────────────────
if echo "$COMMAND" | grep -qE 'git (checkout -b|switch -c)'; then
  # Extract branch name (last argument after -b or -c)
  BRANCH_NAME=$(echo "$COMMAND" | grep -oE '(checkout -b|switch -c)[[:space:]]+([^ ]+)' | awk '{print $NF}')
  [ -n "$BRANCH_NAME" ] || exit 0

  PATTERN=$(_pref_read_yaml "preferences.vcs.branch_naming")
  [ -n "$PATTERN" ] || exit 0

  if ! echo "$BRANCH_NAME" | grep -qE "$PATTERN" 2>/dev/null; then
    severity=$(_severity_resolve "vcs" "branch_naming")
    _emit "$severity" "[xgh] Branch name '${BRANCH_NAME}' does not match convention: ${PATTERN}. Check preferences.vcs.branch_naming."
  fi
  exit 0
fi

# ── Check 4: Commit on protected branch ─────────────────────────────────
if echo "$COMMAND" | grep -qE 'git commit'; then
  CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)
  [ -n "$CURRENT_BRANCH" ] || exit 0

  IS_PROTECTED=$(_pref_read_yaml "preferences.vcs.branches.${CURRENT_BRANCH}.protected")
  if [[ "$IS_PROTECTED" != "true" ]]; then
    IS_PROTECTED=$(_pref_read_branch "pr" "$CURRENT_BRANCH" "protected")
  fi

  if [[ "$IS_PROTECTED" == "true" ]]; then
    severity=$(_severity_resolve "vcs" "protected_branch")
    _emit "$severity" "[xgh] Direct commit on protected branch '${CURRENT_BRANCH}'. Use a feature branch instead."
    exit 0
  fi

  # ── Check 5: Commit format (only if not on protected branch) ──────────
  COMMIT_MSG=""
  if echo "$COMMAND" | grep -qE -- '-m[[:space:]]'; then
    COMMIT_MSG=$(echo "$COMMAND" | sed -n "s/.*-m[[:space:]]*['\"]\\(.*\\)['\"].*/\\1/p")
  elif echo "$COMMAND" | grep -qE -- '--message[[:space:]]'; then
    COMMIT_MSG=$(echo "$COMMAND" | sed -n "s/.*--message[[:space:]]*['\"]\\(.*\\)['\"].*/\\1/p")
  fi
  [ -n "$COMMIT_MSG" ] || exit 0

  FORMAT_REGEX=$(_pref_read_yaml "preferences.vcs.commit_format")
  [ -n "$FORMAT_REGEX" ] || exit 0

  if ! echo "$COMMIT_MSG" | grep -qE "$FORMAT_REGEX" 2>/dev/null; then
    severity=$(_severity_resolve "vcs" "commit_format")
    _emit "$severity" "[xgh] Commit message does not match format: ${FORMAT_REGEX}. Check preferences.vcs.commit_format."
  fi
  exit 0
fi

# ── No checks matched — silent pass-through ─────────────────────────────
exit 0
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `bash tests/test-pre-tool-use-validation.sh`
Expected: All PASS

- [ ] **Step 5: Also run Phase 1 tests to check no regressions**

Run: `bash tests/test-preferences.sh && bash tests/test-severity.sh`
Expected: All PASS

- [ ] **Step 6: Commit**

```bash
git add hooks/pre-tool-use-preferences.sh tests/test-pre-tool-use-validation.sh
git commit -m "feat(phase2): rewrite PreToolUse with 5 severity-aware checks"
```

---

### Task 5: Snapshot Seeding in SessionStart

**Files:**
- Modify: `hooks/session-start-preferences.sh`
- Modify: `tests/test-session-start-preferences.sh` (add snapshot test)

**Context:**
- Add ~5 lines at end of session-start-preferences.sh to copy project.yaml to TMPDIR
- Session ID from stdin JSON `session_id` field, fallback to `$$-$(date +%s)`
- Path: `${REPO_ROOT}/.xgh/run/xgh-${SESSION_ID}-project-yaml.yaml`
- The existing hook reads stdin via _build_pref_index (consumes it), so we need to read stdin first and pass it through
- Actually: session-start-preferences.sh doesn't read stdin at all currently — it ignores it. We need to read stdin JSON for session_id.

- [ ] **Step 1: Write failing test for snapshot seeding**

Add to `tests/test-session-start-preferences.sh`:

```bash
# Test 11: Snapshot file created in TMPDIR
echo "--- 11. Snapshot seeding ---"
test_session_id="test-snapshot-$(date +%s)"
snapshot_input="{\"session_id\": \"${test_session_id}\"}"
snapshot_output=$(cd "$REPO_ROOT" && echo "$snapshot_input" | bash "$HOOK" 2>/dev/null || true)
snapshot_path="${REPO_ROOT}/.xgh/run/xgh-${test_session_id}-project-yaml.yaml"
if [[ -f "$snapshot_path" ]]; then
  pass "snapshot file created at $snapshot_path"
  rm -f "$snapshot_path"
else
  fail "snapshot file not created at $snapshot_path"
fi
```

- [ ] **Step 2: Run tests to verify new test fails**

Run: `bash tests/test-session-start-preferences.sh`
Expected: Test 11 FAIL (snapshot seeding not implemented yet)

- [ ] **Step 3: Restructure session-start-preferences.sh for stdin capture + snapshot seeding**

The current hook ignores stdin. We need to capture stdin at the top (for `session_id`), then run existing logic, then seed snapshot at end. **Restructure the hook** — add stdin capture after the YAML validation block, before `_build_pref_index`:

After line `if [[ $yaml_status -eq 1 ]]; then ... fi` (the YAML validation block), and before sourcing the builder, add:

```bash
# ── Capture stdin for session_id (SessionStart sends JSON on stdin) ────
HOOK_INPUT=$(cat 2>/dev/null) || HOOK_INPUT=""
SESSION_ID=""
if [[ -n "$HOOK_INPUT" ]]; then
  SESSION_ID=$(printf '%s' "$HOOK_INPUT" | jq -r '.session_id // empty' 2>/dev/null || true)
fi
[[ -z "$SESSION_ID" ]] && SESSION_ID="$$-$(date +%s)"
```

Then at the very end of the file (after the `_build_pref_index` output block), add:

```bash
# ── Seed project.yaml snapshot for PostToolUse drift detection ──────────
REPO_ROOT_SNAP=$(git rev-parse --show-toplevel 2>/dev/null || echo ".")
mkdir -p "${REPO_ROOT_SNAP}/.xgh/run" 2>/dev/null || true
cp "$PROJ_YAML" "${REPO_ROOT_SNAP}/.xgh/run/xgh-${SESSION_ID}-project-yaml.yaml" 2>/dev/null || true
```

**Note:** `.xgh/run/` must be in `.gitignore` — add `run/` entry to `.xgh/.gitignore` if it doesn't exist. These are ephemeral session-scoped files.

**Key insight:** `cat` reads stdin once — `_build_pref_index` doesn't read stdin (it reads files), so capturing stdin before it doesn't break anything. The `SESSION_ID` variable is set early and used at the end.

- [ ] **Step 4: Run tests to verify all pass**

Run: `bash tests/test-session-start-preferences.sh`
Expected: All 11 tests PASS

- [ ] **Step 4c: Ensure .xgh/run/ is gitignored**

Add `run/` to `.xgh/.gitignore` if not already present (ephemeral session files):
```bash
echo "run/" >> .xgh/.gitignore  # if not already there
```

- [ ] **Step 5: Commit**

```bash
git add hooks/session-start-preferences.sh tests/test-session-start-preferences.sh .xgh/.gitignore
git commit -m "feat(phase2): seed project.yaml snapshot for drift detection"
```

---

### Task 6: PostToolUse Drift Detection

**Files:**
- Create: `hooks/post-tool-use-preferences.sh`
- Create: `tests/test-post-tool-use-drift.sh`
- Read: `.xgh/specs/2026-03-26-phase-2-validate-observe-design.md` (Section 3)

**Context:**
- Matcher: `Write|Edit|MultiEdit` — fires after file writes/edits (including bulk edits)
- Extract `tool_input.file_path` from stdin JSON
- Compare against `$PROJECT_ROOT/config/project.yaml` (absolute path match)
- If file is not project.yaml → exit 0 silently
- If snapshot missing → write current state as baseline, emit initialization message
- If snapshot exists → diff leaf values at depth ≤3, report changes
- Update snapshot after comparison
- YAML diff via `yq -o=json` or Python `yaml.safe_load`, compare JSON keys recursively
- Output: `hookSpecificOutput.hookEventName: "PostToolUse"` + `additionalContext`

- [ ] **Step 1: Write failing tests**

Create `tests/test-post-tool-use-drift.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
HOOK="${REPO_ROOT}/hooks/post-tool-use-preferences.sh"
PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

echo "=== test-post-tool-use-drift ==="

# --- Test 1: Non-project.yaml file → silent exit ---
echo "--- 1. Non-project.yaml file ---"
output=$(cd "$REPO_ROOT" && echo '{"tool_name":"Write","tool_input":{"file_path":"/tmp/something.txt"}}' | bash "$HOOK" 2>/dev/null || true)
if [[ -z "$output" ]]; then
  pass "non-project.yaml → silent exit"
else
  fail "non-project.yaml should be silent. Output: $output"
fi

# --- Test 2: Missing snapshot → initialization message ---
echo "--- 2. Missing snapshot → init ---"
test_session="drift-test-$(date +%s)"
snapshot="${REPO_ROOT}/.xgh/run/xgh-${test_session}-project-yaml.yaml"
rm -f "$snapshot"
proj_yaml_abs="${REPO_ROOT}/config/project.yaml"
input="{\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":\"${proj_yaml_abs}\"},\"session_id\":\"${test_session}\"}"
output=$(cd "$REPO_ROOT" && echo "$input" | bash "$HOOK" 2>/dev/null || true)
if echo "$output" | jq -e '.hookSpecificOutput.additionalContext' >/dev/null 2>&1; then
  ctx=$(echo "$output" | jq -r '.hookSpecificOutput.additionalContext')
  if [[ "$ctx" == *"snapshot initialized"* ]]; then
    pass "missing snapshot → initialization message"
  else
    fail "expected 'snapshot initialized' in context. Got: $ctx"
  fi
else
  fail "missing snapshot should emit init message. Output: $output"
fi
# Verify snapshot was created
if [[ -f "$snapshot" ]]; then
  pass "snapshot file created"
else
  fail "snapshot file should be created at $snapshot"
fi
rm -f "$snapshot"

# --- Test 3: Snapshot exists, no changes → silent ---
echo "--- 3. No changes → silent ---"
cp "$proj_yaml_abs" "$snapshot"
output=$(cd "$REPO_ROOT" && echo "$input" | bash "$HOOK" 2>/dev/null || true)
if [[ -z "$output" ]]; then
  pass "no changes → silent"
else
  # Some implementations may still emit empty context
  ctx=$(echo "$output" | jq -r '.hookSpecificOutput.additionalContext // ""' 2>/dev/null || true)
  if [[ -z "$ctx" ]]; then
    pass "no changes → no meaningful output"
  else
    fail "no changes should be silent. Output: $output"
  fi
fi
rm -f "$snapshot"

# --- Test 4: hookEventName is PostToolUse ---
echo "--- 4. hookEventName correct ---"
rm -f "$snapshot"
output=$(cd "$REPO_ROOT" && echo "$input" | bash "$HOOK" 2>/dev/null || true)
if echo "$output" | jq -e '.hookSpecificOutput.hookEventName == "PostToolUse"' >/dev/null 2>&1; then
  pass "hookEventName is PostToolUse"
else
  fail "hookEventName should be PostToolUse. Output: $output"
fi
rm -f "$snapshot"

# --- Test 5: Snapshot exists with different values → reports changes ---
echo "--- 5. Value change detected ---"
# Create a snapshot with a modified merge_method
cp "$proj_yaml_abs" "$snapshot"
# Change merge_method from squash to merge in the snapshot (so current file looks "changed")
if command -v sed >/dev/null 2>&1; then
  sed -i.bak 's/merge_method: squash/merge_method: rebase/' "$snapshot" 2>/dev/null || true
  rm -f "${snapshot}.bak"
fi
output=$(cd "$REPO_ROOT" && echo "$input" | bash "$HOOK" 2>/dev/null || true)
if echo "$output" | jq -e '.hookSpecificOutput.additionalContext' >/dev/null 2>&1; then
  ctx=$(echo "$output" | jq -r '.hookSpecificOutput.additionalContext')
  if [[ "$ctx" == *"changed"* ]] || [[ "$ctx" == *"merge_method"* ]]; then
    pass "value change detected and reported"
  else
    fail "expected change report mentioning merge_method. Got: $ctx"
  fi
else
  fail "value change should produce report. Output: $output"
fi
rm -f "$snapshot"

# --- Summary ---
echo ""
echo "PostToolUse drift: $PASS passed, $FAIL failed"
[[ "$FAIL" -eq 0 ]] || exit 1
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `bash tests/test-post-tool-use-drift.sh`
Expected: FAIL — hook file doesn't exist yet

- [ ] **Step 3: Implement post-tool-use-preferences.sh**

Create `hooks/post-tool-use-preferences.sh`:

```bash
#!/usr/bin/env bash
# hooks/post-tool-use-preferences.sh — PostToolUse drift detection
#
# Phase 2 Epic 2.2: Detect when config/project.yaml is edited mid-session.
# Report which preference fields changed with old → new values.
# Matcher: Write|Edit
#
# Stdin: { tool_name, tool_input: { file_path, ... }, session_id }
# Output: hookSpecificOutput with additionalContext on change, silent otherwise.
set -euo pipefail

# ── Read stdin ──────────────────────────────────────────────────────────
INPUT=$(cat 2>/dev/null) || exit 0
[ -n "$INPUT" ] || exit 0

# ── Extract file path ──────────────────────────────────────────────────
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_response.filePath // empty' 2>/dev/null) || exit 0
[ -n "$FILE_PATH" ] || exit 0

# ── Resolve repo root ─────────────────────────────────────────────────
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
PROJ_YAML="${REPO_ROOT}/config/project.yaml"

# ── Only care about project.yaml (absolute path match) ─────────────────
# Normalize both paths for comparison
REAL_PROJ=$(realpath "$PROJ_YAML" 2>/dev/null || echo "$PROJ_YAML")
REAL_FILE=$(realpath "$FILE_PATH" 2>/dev/null || echo "$FILE_PATH")
[[ "$REAL_FILE" == "$REAL_PROJ" ]] || exit 0

# ── Resolve session ID for snapshot path ───────────────────────────────
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty' 2>/dev/null || true)
[[ -z "$SESSION_ID" ]] && SESSION_ID="$$-$(date +%s)"
mkdir -p "${REPO_ROOT}/.xgh/run" 2>/dev/null || true
SNAPSHOT="${REPO_ROOT}/.xgh/run/xgh-${SESSION_ID}-project-yaml.yaml"

# ── Output helper ──────────────────────────────────────────────────────
_emit_context() {
  local msg="$1"
  jq -n --arg msg "$msg" '{
    "hookSpecificOutput": {
      "hookEventName": "PostToolUse",
      "additionalContext": $msg
    }
  }'
}

# ── No snapshot → initialize baseline ──────────────────────────────────
if [[ ! -f "$SNAPSHOT" ]]; then
  cp "$PROJ_YAML" "$SNAPSHOT" 2>/dev/null || true
  _emit_context "[xgh] project.yaml snapshot initialized — future edits will be tracked"
  exit 0
fi

# ── Diff: compare leaf values between snapshot and current ──────────────
CHANGES=""
if command -v yq >/dev/null 2>&1; then
  # Use yq to convert both to flat JSON, then diff keys
  OLD_JSON=$(yq -o=json '.' "$SNAPSHOT" 2>/dev/null || echo "{}")
  NEW_JSON=$(yq -o=json '.' "$PROJ_YAML" 2>/dev/null || echo "{}")
  CHANGES=$(python3 - "$OLD_JSON" "$NEW_JSON" << 'PYEOF'
import sys, json

def flatten(obj, prefix="", depth=0, max_depth=5):
    items = {}
    if depth >= max_depth or not isinstance(obj, dict):
        items[prefix] = obj
        return items
    for k, v in obj.items():
        new_key = f"{prefix}.{k}" if prefix else k
        if isinstance(v, dict) and depth < max_depth - 1:
            items.update(flatten(v, new_key, depth + 1, max_depth))
        else:
            items[new_key] = v
    return items

old = flatten(json.loads(sys.argv[1]))
new = flatten(json.loads(sys.argv[2]))

changes = []
all_keys = set(old.keys()) | set(new.keys())
for k in sorted(all_keys):
    if not k.startswith("preferences"):
        continue
    old_v = old.get(k)
    new_v = new.get(k)
    if old_v != new_v:
        if k not in old:
            changes.append(f"{k} added: {new_v}")
        elif k not in new:
            changes.append(f"{k} removed (was: {old_v})")
        else:
            changes.append(f"{k}: {old_v} → {new_v}")

print(", ".join(changes) if changes else "")
PYEOF
  ) || CHANGES=""
elif python3 -c "import yaml" 2>/dev/null; then
  CHANGES=$(python3 - "$SNAPSHOT" "$PROJ_YAML" << 'PYEOF'
import sys, yaml, json

def flatten(obj, prefix="", depth=0, max_depth=5):
    items = {}
    if depth >= max_depth or not isinstance(obj, dict):
        items[prefix] = obj
        return items
    for k, v in obj.items():
        new_key = f"{prefix}.{k}" if prefix else k
        if isinstance(v, dict) and depth < max_depth - 1:
            items.update(flatten(v, new_key, depth + 1, max_depth))
        else:
            items[new_key] = v
    return items

with open(sys.argv[1]) as f:
    old = flatten(yaml.safe_load(f) or {})
with open(sys.argv[2]) as f:
    new = flatten(yaml.safe_load(f) or {})

changes = []
all_keys = set(old.keys()) | set(new.keys())
for k in sorted(all_keys):
    if not k.startswith("preferences"):
        continue
    old_v = old.get(k)
    new_v = new.get(k)
    if old_v != new_v:
        if k not in old:
            changes.append(f"{k} added: {new_v}")
        elif k not in new:
            changes.append(f"{k} removed (was: {old_v})")
        else:
            changes.append(f"{k}: {old_v} → {new_v}")

print(", ".join(changes) if changes else "")
PYEOF
  ) || CHANGES=""
fi

# ── Update snapshot ────────────────────────────────────────────────────
cp "$PROJ_YAML" "$SNAPSHOT" 2>/dev/null || true

# ── Report changes ─────────────────────────────────────────────────────
if [[ -n "$CHANGES" ]]; then
  _emit_context "[xgh] config/project.yaml changed: ${CHANGES}"
fi

exit 0
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `bash tests/test-post-tool-use-drift.sh`
Expected: All PASS

- [ ] **Step 5: Commit**

```bash
git add hooks/post-tool-use-preferences.sh tests/test-post-tool-use-drift.sh
git commit -m "feat(phase2): add PostToolUse drift detection for project.yaml"
```

---

### Task 7: PostToolUseFailure Diagnosis

**Files:**
- Create: `hooks/post-tool-use-failure-preferences.sh`
- Create: `tests/test-post-tool-use-failure-diagnosis.sh`
- Read: `.xgh/specs/2026-03-26-phase-2-validate-observe-design.md` (Section 4)

**Context:**
- Matcher: `Bash` — fires when a Bash command fails
- Parse `gh` CLI stderr for 4 patterns: merge method mismatch, stale reviewer, wrong repo, auth required
- Dual-match: both command context AND stderr signal must match
- Defensive stderr extraction: check `tool_response.stderr`, `tool_response.output`, flat `tool_response`
- `hookEventName: "PostToolUseFailure"` (NOT "PostToolUse")
- Fail-open: unrecognized failures exit silently

- [ ] **Step 1: Write failing tests**

Create `tests/test-post-tool-use-failure-diagnosis.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
HOOK="${REPO_ROOT}/hooks/post-tool-use-failure-preferences.sh"
PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

echo "=== test-post-tool-use-failure-diagnosis ==="

# --- Test 1: Merge method mismatch ---
echo "--- 1. Merge method mismatch ---"
input='{"tool_name":"Bash","tool_input":{"command":"gh pr merge 42 --merge"},"tool_response":{"stderr":"merge_method is not allowed for this repository"}}'
output=$(cd "$REPO_ROOT" && echo "$input" | bash "$HOOK" 2>/dev/null || true)
if echo "$output" | jq -e '.hookSpecificOutput.additionalContext' >/dev/null 2>&1; then
  ctx=$(echo "$output" | jq -r '.hookSpecificOutput.additionalContext')
  if [[ "$ctx" == *"merge_method"* ]] || [[ "$ctx" == *"Merge failed"* ]] || [[ "$ctx" == *"merge method"* ]]; then
    pass "merge method mismatch diagnosed"
  else
    fail "expected merge method diagnosis. Got: $ctx"
  fi
else
  fail "merge method mismatch should produce diagnosis. Output: $output"
fi

# --- Test 2: Stale reviewer ---
echo "--- 2. Stale reviewer ---"
input='{"tool_name":"Bash","tool_input":{"command":"gh pr edit 42 --add-reviewer someone"},"tool_response":{"stderr":"Could not resolve to a User"}}'
output=$(cd "$REPO_ROOT" && echo "$input" | bash "$HOOK" 2>/dev/null || true)
if echo "$output" | jq -e '.hookSpecificOutput.additionalContext' >/dev/null 2>&1; then
  ctx=$(echo "$output" | jq -r '.hookSpecificOutput.additionalContext')
  if [[ "$ctx" == *"reviewer"* ]] || [[ "$ctx" == *"Reviewer"* ]]; then
    pass "stale reviewer diagnosed"
  else
    fail "expected reviewer diagnosis. Got: $ctx"
  fi
else
  fail "stale reviewer should produce diagnosis. Output: $output"
fi

# --- Test 3: Wrong repo ---
echo "--- 3. Wrong repo ---"
input='{"tool_name":"Bash","tool_input":{"command":"gh pr list"},"tool_response":{"stderr":"Could not resolve to a Repository with the name"}}'
output=$(cd "$REPO_ROOT" && echo "$input" | bash "$HOOK" 2>/dev/null || true)
if echo "$output" | jq -e '.hookSpecificOutput.additionalContext' >/dev/null 2>&1; then
  ctx=$(echo "$output" | jq -r '.hookSpecificOutput.additionalContext')
  if [[ "$ctx" == *"repo"* ]] || [[ "$ctx" == *"Repository"* ]]; then
    pass "wrong repo diagnosed"
  else
    fail "expected repo diagnosis. Got: $ctx"
  fi
else
  fail "wrong repo should produce diagnosis. Output: $output"
fi

# --- Test 4: Auth required ---
echo "--- 4. Auth required ---"
input='{"tool_name":"Bash","tool_input":{"command":"gh pr list"},"tool_response":{"stderr":"authentication required, please run gh auth login"}}'
output=$(cd "$REPO_ROOT" && echo "$input" | bash "$HOOK" 2>/dev/null || true)
if echo "$output" | jq -e '.hookSpecificOutput.additionalContext' >/dev/null 2>&1; then
  ctx=$(echo "$output" | jq -r '.hookSpecificOutput.additionalContext')
  if [[ "$ctx" == *"auth"* ]] || [[ "$ctx" == *"Auth"* ]]; then
    pass "auth required diagnosed"
  else
    fail "expected auth diagnosis. Got: $ctx"
  fi
else
  fail "auth required should produce diagnosis. Output: $output"
fi

# --- Test 5: Dual-match — command without gh ---
echo "--- 5. Non-gh command → silent ---"
input='{"tool_name":"Bash","tool_input":{"command":"ls -la"},"tool_response":{"stderr":"No such file or directory"}}'
output=$(cd "$REPO_ROOT" && echo "$input" | bash "$HOOK" 2>/dev/null || true)
if [[ -z "$output" ]]; then
  pass "non-gh command → silent"
else
  fail "non-gh command should be silent. Output: $output"
fi

# --- Test 6: gh command with unrecognized error → fail-open ---
echo "--- 6. Unrecognized gh error → fail-open ---"
input='{"tool_name":"Bash","tool_input":{"command":"gh api /repos/foo/bar"},"tool_response":{"stderr":"rate limit exceeded"}}'
output=$(cd "$REPO_ROOT" && echo "$input" | bash "$HOOK" 2>/dev/null || true)
if [[ -z "$output" ]]; then
  pass "unrecognized gh error → fail-open (silent)"
else
  fail "unrecognized error should be silent. Output: $output"
fi

# --- Test 7: hookEventName is PostToolUseFailure ---
echo "--- 7. hookEventName correct ---"
input='{"tool_name":"Bash","tool_input":{"command":"gh pr merge 42 --merge"},"tool_response":{"stderr":"merge_method is not allowed"}}'
output=$(cd "$REPO_ROOT" && echo "$input" | bash "$HOOK" 2>/dev/null || true)
if echo "$output" | jq -e '.hookSpecificOutput.hookEventName == "PostToolUseFailure"' >/dev/null 2>&1; then
  pass "hookEventName is PostToolUseFailure"
else
  fail "hookEventName should be PostToolUseFailure. Output: $output"
fi

# --- Test 8: Dual-match — stderr without command context ---
echo "--- 8. Dual-match: reviewer error without --add-reviewer → silent ---"
input='{"tool_name":"Bash","tool_input":{"command":"gh pr list"},"tool_response":{"stderr":"Could not resolve to a User"}}'
output=$(cd "$REPO_ROOT" && echo "$input" | bash "$HOOK" 2>/dev/null || true)
if [[ -z "$output" ]]; then
  pass "reviewer error without --add-reviewer → silent"
else
  fail "should require --add-reviewer in command for reviewer diagnosis. Output: $output"
fi

# --- Summary ---
echo ""
echo "PostToolUseFailure diagnosis: $PASS passed, $FAIL failed"
[[ "$FAIL" -eq 0 ]] || exit 1
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `bash tests/test-post-tool-use-failure-diagnosis.sh`
Expected: FAIL — hook file doesn't exist yet

- [ ] **Step 3: Implement post-tool-use-failure-preferences.sh**

Create `hooks/post-tool-use-failure-preferences.sh`:

```bash
#!/usr/bin/env bash
# hooks/post-tool-use-failure-preferences.sh — PostToolUseFailure diagnosis
#
# Phase 2 Epic 2.3: Parse gh CLI stderr on failure and inject targeted fix suggestions.
# Matcher: Bash
#
# Stdin: { tool_name, tool_input: { command }, tool_response: { stderr?, output? } }
# Output: hookSpecificOutput with additionalContext on match, silent otherwise.
# Dual-match: both command context AND stderr signal must match.
set -euo pipefail

# ── Read stdin ──────────────────────────────────────────────────────────
INPUT=$(cat 2>/dev/null) || exit 0
[ -n "$INPUT" ] || exit 0

# ── Extract command ─────────────────────────────────────────────────────
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null) || exit 0
[ -n "$COMMAND" ] || exit 0

# ── Check if gh appears in command ──────────────────────────────────────
echo "$COMMAND" | grep -qwE 'gh' || exit 0

# ── Defensive stderr extraction ─────────────────────────────────────────
STDERR=$(echo "$INPUT" | jq -r '.tool_response.stderr // empty' 2>/dev/null) || STDERR=""
if [[ -z "$STDERR" ]]; then
  STDERR=$(echo "$INPUT" | jq -r '.tool_response.output // empty' 2>/dev/null) || STDERR=""
fi
if [[ -z "$STDERR" ]]; then
  STDERR=$(echo "$INPUT" | jq -r '.tool_response // empty' 2>/dev/null) || STDERR=""
fi
[ -n "$STDERR" ] || exit 0

# ── Resolve repo root for preference reads ──────────────────────────────
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
PREFS="${REPO_ROOT}/lib/preferences.sh"
if [[ -f "$PREFS" ]]; then
  # shellcheck source=../lib/preferences.sh
  source "$PREFS" 2>/dev/null || true
fi

# ── Output helper ──────────────────────────────────────────────────────
_emit_diagnosis() {
  local msg="$1"
  jq -n --arg msg "$msg" '{
    "hookSpecificOutput": {
      "hookEventName": "PostToolUseFailure",
      "additionalContext": $msg
    }
  }'
}

# ── Pattern 1: Merge method mismatch ───────────────────────────────────
# Command: gh pr merge  |  Stderr: "merge_method"
if echo "$COMMAND" | grep -q 'gh pr merge'; then
  if echo "$STDERR" | grep -qi 'merge_method'; then
    CONFIGURED=""
    if declare -f load_pr_pref >/dev/null 2>&1; then
      CONFIGURED=$(load_pr_pref "merge_method" "" "" 2>/dev/null || true)
    fi
    HINT=""
    [[ -n "$CONFIGURED" ]] && HINT=" Check preferences.pr.merge_method (currently: ${CONFIGURED})."
    _emit_diagnosis "[xgh] Merge failed — repo requires a different merge method than the command used.${HINT}"
    exit 0
  fi
fi

# ── Pattern 2: Stale/wrong reviewer ────────────────────────────────────
# Command: --add-reviewer in command  |  Stderr: "Could not resolve"
if echo "$COMMAND" | grep -q '\-\-add-reviewer'; then
  if echo "$STDERR" | grep -qi 'could not resolve'; then
    REVIEWER=""
    if declare -f load_pr_pref >/dev/null 2>&1; then
      REVIEWER=$(load_pr_pref "reviewer" "" "" 2>/dev/null || true)
    fi
    HINT=""
    [[ -n "$REVIEWER" ]] && HINT=" Current config: ${REVIEWER}."
    _emit_diagnosis "[xgh] Reviewer not found — verify preferences.pr.reviewers and bot installation.${HINT}"
    exit 0
  fi
fi

# ── Pattern 3: Wrong repo/fork ─────────────────────────────────────────
# Command: any gh command  |  Stderr: "Could not resolve to a Repository"
if echo "$STDERR" | grep -qi 'could not resolve to a repository'; then
  REPO=""
  if declare -f load_pr_pref >/dev/null 2>&1; then
    REPO=$(load_pr_pref "repo" "" "" 2>/dev/null || true)
  fi
  HINT=""
  [[ -n "$REPO" ]] && HINT=" Check preferences.pr.repo (currently: ${REPO})."
  _emit_diagnosis "[xgh] Repository not found — verify preferences.pr.repo matches remote.${HINT}"
  exit 0
fi

# ── Pattern 4: Auth required ───────────────────────────────────────────
# Command: any gh command  |  Stderr: "authentication" or "auth login"
if echo "$STDERR" | grep -qiE 'authentication|auth login'; then
  _emit_diagnosis "[xgh] GitHub auth required — run 'gh auth login' or check your token."
  exit 0
fi

# ── No match → fail-open ───────────────────────────────────────────────
exit 0
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `bash tests/test-post-tool-use-failure-diagnosis.sh`
Expected: All PASS

- [ ] **Step 5: Commit**

```bash
git add hooks/post-tool-use-failure-preferences.sh tests/test-post-tool-use-failure-diagnosis.sh
git commit -m "feat(phase2): add PostToolUseFailure gh CLI diagnosis"
```

---

### Task 8: Hook Ordering Tests Expansion

**Files:**
- Modify: `tests/test-hook-ordering.sh`

**Context:**
- Add checks for PostToolUse hook (last must be post-tool-use-preferences)
- Add checks for PostToolUseFailure hook (last must be post-tool-use-failure-preferences)
- The existing test already has stub checks for PostToolUse (lines 110-121) — expand them
- The test already handles missing hook types gracefully with NOTE messages

- [ ] **Step 1: Update hook ordering test**

The existing `tests/test-hook-ordering.sh` already has future-proofed stubs for PostToolUse (lines 110-121). After Task 3 registers the hooks, these stubs will activate automatically. Verify they work:

Add a PostToolUseFailure check (similar pattern):

```bash
# --- PostToolUseFailure: last hook must be post-tool-use-failure-preferences ---
failure_count=$(jq '.hooks.PostToolUseFailure | length // 0' "$SETTINGS")
if [[ "$failure_count" -gt 0 ]]; then
  last_failure_cmd=$(jq -r '.hooks.PostToolUseFailure[-1].hooks[-1].command // ""' "$SETTINGS")

  assert_contains_str \
    "PostToolUseFailure: last hook command contains 'post-tool-use-failure-preferences'" \
    "$last_failure_cmd" \
    "post-tool-use-failure-preferences"
else
  echo "NOTE: No PostToolUseFailure hooks registered — skipping PostToolUseFailure ordering check"
fi
```

- [ ] **Step 2: Run hook ordering tests**

Run: `bash tests/test-hook-ordering.sh`
Expected: All PASS (including new PostToolUse and PostToolUseFailure checks)

- [ ] **Step 3: Commit**

```bash
git add tests/test-hook-ordering.sh
git commit -m "test(phase2): expand hook ordering tests for PostToolUse and PostToolUseFailure"
```

---

### Task 9: Validation Skill + References Expansion

**Files:**
- Modify: `skills/validate-project-prefs/validate-project-prefs.md`
- Modify: `skills/_shared/references/project-preferences.md`

**Context:**
- Validation skill needs 4 new checks: checks keys valid, severity values valid, protected branches exist, regex validity
- References doc needs: `vcs.branches.<name>.protected`, `vcs.checks.<name>.severity`, `pr.checks.<name>.severity`, `commit_format_regex`, `branch_naming_regex`

- [ ] **Step 1: Expand validation skill with Phase 2 checks**

Add 4 new checks to `skills/validate-project-prefs/validate-project-prefs.md`:

```markdown
### 9. Phase 2: Check keys validation

Verify `checks` keys in project.yaml match known check names:

```bash
KNOWN_PR_CHECKS="merge_method"
KNOWN_VCS_CHECKS="branch_naming protected_branch commit_format force_push"

# PR checks
PR_CHECK_KEYS="$(yq -r '.preferences.pr.checks | keys | .[]' config/project.yaml 2>/dev/null || true)"
for key in $PR_CHECK_KEYS; do
  if ! echo "$KNOWN_PR_CHECKS" | grep -qw "$key"; then
    echo "WARN: unknown pr check key: $key"
  fi
done

# VCS checks
VCS_CHECK_KEYS="$(yq -r '.preferences.vcs.checks | keys | .[]' config/project.yaml 2>/dev/null || true)"
for key in $VCS_CHECK_KEYS; do
  if ! echo "$KNOWN_VCS_CHECKS" | grep -qw "$key"; then
    echo "WARN: unknown vcs check key: $key"
  fi
done
```

### 10. Phase 2: Severity values validation

Verify `severity` values are `block` or `warn`:

```bash
ALL_SEVERITIES="$(yq -r '.. | select(has("severity")) | .severity' config/project.yaml 2>/dev/null || true)"
INVALID=""
for sev in $ALL_SEVERITIES; do
  if [[ "$sev" != "block" && "$sev" != "warn" ]]; then
    INVALID="$INVALID $sev"
  fi
done
if [[ -z "$INVALID" ]]; then
  echo "PASS: all severity values are block or warn"
else
  echo "FAIL: invalid severity values:$INVALID"
fi
```

### 11. Phase 2: Protected branches exist in repo

```bash
PROTECTED_BRANCHES="$(yq -r '.preferences.vcs.branches | to_entries[] | select(.value.protected == true) | .key' config/project.yaml 2>/dev/null || true)"
for branch in $PROTECTED_BRANCHES; do
  if git show-ref --verify "refs/heads/$branch" >/dev/null 2>&1 || \
     git show-ref --verify "refs/remotes/origin/$branch" >/dev/null 2>&1; then
    echo "PASS: protected branch '$branch' exists"
  else
    echo "WARN: protected branch '$branch' not found locally or in origin"
  fi
done
```

### 12. Phase 2: Regex validity

```bash
for field in commit_format branch_naming; do
  REGEX="$(yq -r ".preferences.vcs.${field} // \"\"" config/project.yaml 2>/dev/null || true)"
  if [[ -n "$REGEX" ]]; then
    # Test regex syntax by checking grep's exit code on empty string
    # grep returns 1 (no match) for valid regex, 2 for invalid syntax
    echo "" | grep -qE "$REGEX" 2>/dev/null
    grep_exit=$?
    if [[ $grep_exit -le 1 ]]; then
      echo "PASS: $field is a valid regex"
    else
      echo "FAIL: $field has regex syntax errors: $REGEX"
    fi
  fi
done
```
```

- [ ] **Step 2: Expand references doc with Phase 2 fields**

Add to `skills/_shared/references/project-preferences.md` in the `vcs` domain section:

```markdown
- `commit_format`: regex pattern for validating commit messages (e.g. `^(feat|fix|docs|chore)...`) — Phase 2 changed from template string to regex
- `branch_naming`: regex pattern for validating branch names (e.g. `^(feat|fix|docs|chore)/`) — Phase 2 changed from template string to regex
- `branches.<name>.protected`: whether branch is protected from direct commits and force-push (`true` | `false`)
- `checks.<name>.severity`: enforcement level for each check (`block` | `warn`)
```

Add to the `pr` domain section:

```markdown
- `checks.<name>.severity`: enforcement level for PR checks (`block` | `warn`)
```

- [ ] **Step 3: Commit**

```bash
git add skills/validate-project-prefs/validate-project-prefs.md skills/_shared/references/project-preferences.md
git commit -m "docs(phase2): expand validation skill and references for Phase 2 fields"
```

---

## Full Test Suite

After all tasks complete, run the full test suite:

```bash
bash tests/test-severity.sh && \
bash tests/test-preferences.sh && \
bash tests/test-pre-tool-use-validation.sh && \
bash tests/test-post-tool-use-drift.sh && \
bash tests/test-post-tool-use-failure-diagnosis.sh && \
bash tests/test-session-start-preferences.sh && \
bash tests/test-post-compact-preferences.sh && \
bash tests/test-hook-ordering.sh
```

Expected: All PASS, zero failures.
