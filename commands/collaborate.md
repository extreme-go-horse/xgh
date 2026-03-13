# /xgh collaborate

Run a collaboration workflow through the dispatcher agent.

## Usage

`/xgh collaborate <workflow> [context]`

## Supported Workflow Examples

- `plan-review`
- `parallel-impl`
- `validation`
- `security-review`

## Execution

1. Validate workflow name against configured templates.
2. Call the collaboration dispatcher to assign roles.
3. Return plan, owner assignments, and expected outputs.
4. Curate final outcomes into memory.

This command is the entry point to structured multi-agent workflow execution.
