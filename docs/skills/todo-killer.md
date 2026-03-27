# todo-killer

Systematically resolve TODO, FIXME, HACK, and other comment markers in the codebase.

## When it runs

- **On demand:** `/xgh-todo-killer`

## Arguments

- `--mode scan|fix|both` -- `scan` harvests signals, `fix` resolves them, `both` (default) does both
- `--filter TODO|FIXME|HACK|DEPRECATED|NOTE|all` -- default: `all`
- `--glob <pattern>` -- scope to specific files (e.g., `"Sources/**/*.swift"`)
- `--priority high|medium|low|all` -- default: `all`
- `--dry-run` -- show what would be fixed

## What it does

1. **Scan phase**: Harvests all comment markers matching the filter
2. **Triage**: Assigns priority based on context and age
3. **Fix phase**: Resolves each TODO with appropriate code changes
