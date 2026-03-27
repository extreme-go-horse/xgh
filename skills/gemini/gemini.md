---
name: xgh:gemini
description: "Dispatch tasks to Gemini CLI for parallel implementation or code review"
---

# xgh:gemini -- Gemini CLI Dispatch

Dispatch implementation tasks or code reviews to Google's Gemini CLI as a parallel or sequential agent. Gemini runs non-interactively via `-p` (headless mode), optionally in an isolated git worktree for safe parallel work alongside Claude Code.

> Steps 1, 3, 4, and 5 follow the shared dispatch workflow pattern.

## Prerequisites

Check Gemini CLI availability:

```bash
command -v gemini >/dev/null 2>&1 && gemini --version || echo "NOT_INSTALLED"
```

If `NOT_INSTALLED`, print: "Gemini CLI not found. Install from: https://github.com/google-gemini/gemini-cli" and stop.

## Input Parsing

Parse the user's request to determine dispatch parameters. Only extract what the user explicitly provides -- all other flags stay at Gemini CLI defaults.

**Spawning management flags** (always injected by the skill):

| Flag | Purpose |
|------|---------|
| `-p "<prompt>"` | Non-interactive headless execution |
| `--yolo` | Auto-approve all actions (no confirmation prompts) |

**Note:** Gemini CLI has no `-C` (working directory) or `-o` (output file) flags. Working directory is set via `cd` before invocation. Output is captured via shell redirection.

**User-controlled parameters** (only injected if the user explicitly provides them):

| Parameter | Default | User flag |
|-----------|---------|-----------|
| `type` | `exec` | first arg: `exec` or `review` |
| `isolation` | `worktree` (exec), `same-dir` (review) | `--worktree`, `--same-dir` |
| `prompt` | -- | remaining text after type |
| `effort` | CLI default | `--effort <level>` or `--thinking <level>` (translated to Gemini thinking config) |

**Effort level translation** (accepts `--effort`, `--thinking` — maps to Gemini's model-dependent thinking config):

Gemini uses different thinking parameters depending on model generation:
- **Gemini 2.5 (Flash/Pro):** `thinking_budget` (integer tokens, 0-24576)
- **Gemini 3+:** `thinking_level` (enum: `MINIMAL`, `LOW`, `MEDIUM`, `HIGH`)

| User says | Gemini 3+ (`thinking_level`) | Gemini 2.5 (`thinking_budget`) |
|-----------|------------------------------|-------------------------------|
| `--effort low` / `--thinking low` | `LOW` | `1024` |
| `--effort medium` / `--thinking medium` | `MEDIUM` | `8192` |
| `--effort high` / `--thinking high` | `HIGH` | `16384` |
| `--effort max` / `--thinking max` | `HIGH` | `24576` |
| `--effort xhigh` / `--thinking xhigh` | `HIGH` | `24576` |
| `--effort minimal` / `--thinking minimal` | `MINIMAL` | `0` |

`--effort` and `--thinking` are aliases. `max` and `xhigh` (Anthropic/OpenAI jargon) both map to the maximum available. `minimal` maps to Gemini's native `MINIMAL` level. If the user passes a raw integer (e.g., `--thinking 16000`), treat it as a direct `thinking_budget` value for Gemini 2.5 models.

**Passthrough flags** (forwarded verbatim to Gemini CLI if the user includes them):

| Flag | What it controls |
|------|-----------------|
| `-m <model>` | Model override (e.g., `gemini-2.5-flash`) |
| `-s` | Enable sandbox mode |
| `--approval-mode <mode>` | Override approval (`default`, `auto_edit`, `yolo`, `plan`) |
| `--include-directories <dir>` | Additional workspace directories |
| `-e <ext>` | Limit to specific extensions |
| `--policy <file>` | Additional policy files |
| `-i <prompt>` | Execute prompt then continue interactively |
| `-o <format>` | Output format (`text`, `json`, `stream-json`) |
| `-r <session>` | Resume a previous session |

Any unrecognized flags are forwarded to `gemini` as-is.

---

## Step 1: Setup Workspace

Set up the workspace for Gemini dispatch.

Same-dir fallback flag: `--same-dir`.

---

## Step 2: Dispatch

### Exec dispatch

Build the command with only spawning management flags plus any user-specified passthrough flags:

```bash
OUTPUT_FILE="/tmp/gemini-exec-${TIMESTAMP}.md"
CMD=(
    gemini
    -p "<prompt>"
    --yolo
    # User passthrough flags appended here (e.g., -m gemini-2.5-flash -s)
)
cd "$WORK_DIR" && "${CMD[@]}" > "$OUTPUT_FILE" 2>&1
```

- **Worktree mode:** Run via Bash with `run_in_background: true`. Claude Code is free to continue other work while Gemini runs.
- **Same-dir mode:** Run synchronously. Claude Code waits for completion.

### Review dispatch

For code review, use `--approval-mode plan` (read-only mode) instead of `--yolo`:

```bash
OUTPUT_FILE="/tmp/gemini-review-${TIMESTAMP}.md"
CMD=(
    gemini
    -p "<review prompt>"
    --approval-mode plan
    # User passthrough flags appended here
)
cd "$WORK_DIR" && "${CMD[@]}" > "$OUTPUT_FILE" 2>&1
```

Review prompt examples:
- "Review all changes on this branch vs main. Focus on correctness and test coverage."
- "Review the uncommitted changes. Check for security issues and error handling."

---

## Step 3: Collect Results

Collect and present the Gemini dispatch results.

---

## Step 4: Integration (worktree mode only)

Integrate worktree changes back into the working branch.

---

## Step 5: Curate (if memory backend available)

**Write observation to model profiles** (always, regardless of lossless-claude):

After the dispatch completes, append one observation to `.xgh/model-profiles.yaml`. Create the file if it doesn't exist.

```yaml
# Append to .xgh/model-profiles.yaml
- agent: gemini
  model: <the -m flag value, or "default" if none was passed>
  effort: <the --effort value, or "default" if none was passed>
  archetype: <set by router if dispatched via /xgh-dispatch, otherwise "unknown">
  accepted: <true if worktree merged or user continued; false if re-dispatched or discarded>
  ts: <ISO 8601 timestamp>
```

Write using the same python one-liner pattern (stdlib only), with `'agent': 'gemini'`:

```bash
python3 -c "
import json, os, datetime
path = '.xgh/model-profiles.yaml'
os.makedirs(os.path.dirname(path), exist_ok=True)
try:
    data = json.load(open(path))
except (FileNotFoundError, json.JSONDecodeError):
    data = {'observations': []}
data.setdefault('observations', [])
data['observations'].append({
    'agent': 'gemini',
    'model': '<MODEL>',
    'effort': '<EFFORT>',
    'archetype': '<ARCHETYPE>',
    'accepted': True,  # or False based on outcome
    'ts': datetime.datetime.now(datetime.timezone.utc).isoformat()
})
json.dump(data, open(path, 'w'), indent=2)
"
```

Replace `<MODEL>`, `<EFFORT>`, `<ARCHETYPE>` with the actual values from the dispatch. Determine `accepted` from:
- Worktree merged → `true`
- User continued to next task → `true`
- User re-dispatched same task → `false`
- User discarded worktree → `false`

---

## Approval Modes

Gemini CLI has four approval modes. The skill selects automatically based on dispatch type:

| Dispatch type | Approval mode | Behavior |
|--------------|---------------|----------|
| exec | `--yolo` | Auto-approve all actions (full write access) |
| review | `--approval-mode plan` | Read-only mode (no file modifications) |

The user can override via `--approval-mode <mode>`:

| Mode | Behavior |
|------|----------|
| `default` | Prompt for approval on each action |
| `auto_edit` | Auto-approve edit tools only |
| `yolo` | Auto-approve everything |
| `plan` | Read-only, no edits allowed |

## Anti-Patterns

Shared anti-patterns for all dispatch skills:

Gemini-specific additions:
- **Vague prompts.** Gemini works best with focused, specific tasks. "Add unit tests for the TokenBucket.consume() method in src/lib/token-bucket.ts" will succeed where "Fix all the bugs" will not.

## Usage

```
/xgh-gemini exec "Add unit tests for the auth module"
/xgh-gemini review "Check for security issues in the latest changes"
/xgh-gemini exec --model gemini-2.5-flash --effort high "Fix lint warnings in src/utils/"
/xgh-gemini exec --same-dir --thinking xhigh "Add missing docstrings"
```
