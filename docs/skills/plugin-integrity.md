# plugin-integrity

Check that every command has a matching skill directory and vice versa.

## When it runs

- **On demand:** `/xgh-plugin-integrity`

## What it does

1. Scans `commands/` for all `.md` files
2. Scans `skills/` for all skill directories
3. Reports:
   - Commands without a matching skill directory
   - Skills without a matching command wrapper
