# trigger

Manage the xgh trigger engine -- list triggers, test them, silence noisy ones, and view firing history.

## When it runs

- **On demand:** `/xgh-trigger`

## Subcommands

| Command | Action |
|---------|--------|
| `list` | Show all registered triggers with status |
| `test <name>` | Test-fire a trigger with a sample event |
| `silence <name>` | Temporarily silence a noisy trigger |
| `history [name]` | Show recent firing history |

## Configuration

Triggers defined in `config/triggers.yaml`. See [Configuration](../configuration.md) for trigger schema.
