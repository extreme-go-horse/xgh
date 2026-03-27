# Synthesis Template

Use this structure when combining FOR and AGAINST results into a verdict.

## Per-Dimension Table

| Dimension | FOR | AGAINST | Verdict |
|-----------|-----|---------|---------|
| [e.g. Correctness] | [key FOR argument] | [key AGAINST argument] | Go / Conditional / No-go |
| [e.g. Fresh install] | ... | ... | ... |
| [e.g. Concurrency] | ... | ... | ... |
| [e.g. User data safety] | ... | ... | ... |
| [e.g. Maintenance] | ... | ... | ... |

## Overall Verdict

**Go** / **Go with conditions** / **No-go**

### Rationale
[1-2 sentences explaining the deciding factor]

### Conditions (if "Go with conditions")
These are mandatory, not suggestions. Implementation should not proceed without them:
1. [Specific required change]
2. [Specific required change]

### Rejected concerns
The following AGAINST arguments were considered but do not block progress:
- [argument] — [why it doesn't apply or is acceptable]

## Notes for Implementation
[Optional: anything the implementer should keep in mind that didn't rise to the level of a condition]
