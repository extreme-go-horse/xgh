# Context-Mode Routing Rules

When context-mode is available, use it to keep raw output out of the context window.
Even a single call can save 40% of context and significant token cost.

## Routing Table

| Action | Tool | When |
|--------|------|------|
| Understand / analyze a file | `ctx_execute_file(path)` | Always, unless Edit follows within 1-2 tool calls |
| Read a file to Edit it | `Read` | Only when the next action is Edit on the same file |
| Run multiple commands / searches | `ctx_batch_execute(commands, queries)` | Any multi-command research |
| Run builds, tests, log processing | `ctx_execute(language, code)` | Output expected >20 lines |
| Quick git/mkdir/rm | `Bash` | Output expected <20 lines |

## The "Next Action Test"

Before using `Read`, ask: **"Will my next 1-2 actions be an Edit on this same file?"**

- **Yes** → Use `Read` (Edit requires file content in context)
- **No** → Use `ctx_execute_file` (keeps raw content in sandbox)

## Phase-Specific Guidance

### Investigation / Debugging (Phase 1-3)

All file reads are analysis reads. Use `ctx_execute_file` for everything.
Use `ctx_batch_execute` for parallel searches (grep, glob, multi-file analysis).
Switch to `Read` only when you have identified the exact file to edit and are ready.

### Implementation (Phase 4)

Use `Read` for files you are about to `Edit`.
Use `ctx_execute(language, code)` for running builds, tests, and log processing.
Use `ctx_batch_execute` for verification commands.

## Common Mistakes

| Mistake | Correct Pattern |
|---------|----------------|
| `Read` 5 files to "understand the codebase" | `ctx_batch_execute` with queries |
| `Read` a file, then decide not to edit it | Should have used `ctx_execute_file` |
| `Bash` for `git diff` with large output | `ctx_execute(language="shell", code="git diff ...")` |
| `Read` a file, edit it 10 tool calls later | `ctx_execute_file` first, `Read` when ready to edit |
