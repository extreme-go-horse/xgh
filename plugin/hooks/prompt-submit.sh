#!/usr/bin/env bash
# xgh UserPromptSubmit hook
# Detects prompt intent and injects cipher memory decision table as additionalContext.
# Output: {"additionalContext": "..."} — the only key Claude Code recognizes for UserPromptSubmit hooks.
set -euo pipefail

python3 << 'PYEOF'
import json, os, re

prompt = os.environ.get("PROMPT", "")

# Intent detection via regex
code_pattern = re.compile(
    r"\b(implement|refactor|fix|build|code|write|change|feature|bug)\b",
    re.IGNORECASE
)

if code_pattern.search(prompt):
    intent = "code-change"
else:
    intent = "general"

if intent == "code-change":
    context = """> **⚠️ STOP: Before responding, check if this is a code task.**
> Code task? → `lcm_search` FIRST. Wrote code? → `lcm_store` (extract 3-7 bullet summary) BEFORE done.

---

# lossless-claude Memory System - MANDATORY

**These rules apply regardless of language.**

## Decision: When to Search Memory

**PRIMARY RULE — ASK YOURSELF: "Will this task require understanding or modifying THIS codebase?"**

| Answer | Action |
|--------|--------|
| **YES** — need to understand/modify codebase | `lcm_search` FIRST |
| **NO** — general knowledge, meta tasks, follow-up | Skip search |

**You MUST search when task involves:**
- Writing, editing, or modifying code in this project
- Understanding how something works in this codebase
- Debugging, fixing, or troubleshooting issues
- Finding where something is located
- Any architectural or design decisions

**You MUST NOT search when:**
- General programming concepts (not codebase-specific)
- Meta tasks: run tests, build project, commit changes, create PR
- Simple clarifications about your previous response

**⚠️ LONG CONVERSATIONS:** Even after many prompts — if a NEW code task comes up, search again. Each distinct code task = new search.

## Decision: When to Store Memory

**ASK YOURSELF: "Did I learn or create something valuable for future work?"**

| Answer | Action |
|--------|--------|
| **YES** — wrote code, found patterns, made decisions | Extract 3-7 bullet summary → `lcm_store(summary, ["session"])` BEFORE done |
| **NO** — just answered a question, no new insights | Skip |

**MUST store when you:**
- Wrote or modified any code
- Discovered how something works in this codebase
- Made architectural/design decisions
- Found a bug root cause or fix pattern

For complex reasoning/debugging → use `lcm_store(text, ["reasoning"])` instead.

## Quick Reference

| Task Type | Search? | Store? |
|-----------|---------|--------|
| Add/create/implement feature | **MUST** | **MUST** |
| Fix/debug/resolve bug | **MUST** | **MUST** |
| Refactor/optimize code | **MUST** | **MUST** |
| "How does X work?" (codebase) | **MUST** | Only if new insights |
| "Where is X?" (codebase) | **MUST** | NO |
| General concept (protocols, generics) | NO | NO |
| Meta task (run tests, build, commit) | NO | NO |
| Follow-up code task in same conversation | **MUST** | **MUST** |

## Workflow

```
Code task received → lcm_search FIRST → Work → lcm_store (summary) → Done
Non-code task → Just respond normally
```"""
else:
    context = "Non-code task detected — memory search not required."

# Session health nudge — context-mode enforcement (Layer 4)
nudge = ""
state_override = os.environ.get("XGH_CTX_STATE_OVERRIDE", "")
if state_override:
    ctx_state_path = state_override
else:
    import hashlib, subprocess as sp
    try:
        proj = sp.check_output(
            ["git", "rev-parse", "--show-toplevel"],
            stderr=sp.DEVNULL
        ).decode().strip()
    except Exception:
        proj = os.getcwd()
    h = hashlib.sha1(proj.encode()).hexdigest()[:8]
    ctx_state_path = f"/tmp/xgh-ctx-health-{h}.json"

try:
    with open(ctx_state_path) as f:
        ctx_state = json.load(f)
    unedited = ctx_state.get("reads", 0) - ctx_state.get("edits", 0)
    ctx_calls = ctx_state.get("ctx_calls", 0)
    if ctx_calls < 2 and unedited >= 3:
        nudge = (
            f"\n\n---\n\n"
            f"**Session health:** {ctx_state['reads']} reads, "
            f"{ctx_state['edits']} edits, {ctx_calls} context-mode calls. "
            f"Switch to ctx_execute_file for analysis reads."
        )
except (FileNotFoundError, json.JSONDecodeError, KeyError):
    pass  # No state file = context-mode not active, skip silently

# Append nudge to context if present
if nudge:
    context += nudge

print(json.dumps({"additionalContext": context}))
PYEOF
exit 0
