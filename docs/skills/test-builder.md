# test-builder

Generate and run tailored test suites from architectural analysis.

## When it runs

- **On demand:** `/xgh-test-builder init` or `/xgh-test-builder run`

## Subcommands

| Command | Action |
|---------|--------|
| `init` | Analyze architecture and generate test suite |
| `run [flow-name]` | Execute generated tests |

## What it does (init phase)

1. Resolves active project
2. Reads architectural analysis
3. Identifies testable boundaries
4. Generates test scripts tailored to the codebase
5. Writes tests to `tests/`
