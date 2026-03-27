# validate-project-prefs

Validate that skills read from `config/project.yaml` instead of hardcoding PR workflow values.

## When it runs

- **On demand:** `/xgh-validate-project-prefs`

## What it checks

12 checks in two phases:

### Phase 1 (core)
1. No hardcoded reviewer logins in skill files
2. No hardcoded repo detection (`gh repo view --json`)
3. No inline provider profiles
4. Skills reference `load_pr_pref` or `project.yaml`
5. All 11 preference domains present in project.yaml
6. All 11 loader functions in `lib/preferences.sh`
7. Hook ordering contract (PreToolUse, SessionStart, PostCompact)
8. Cross-domain dependencies (dispatch -> pr)

### Phase 2 (validation)
9. Check keys match known names
10. Severity values are `block` or `warn`
11. Protected branches exist in repo
12. Regex patterns are syntactically valid

## Output

Table with pass/warn/fail status for each check.
