# Provider Examples

These are reference examples of what `/xgh-track` generates when you add a data source. They show the `provider.yaml` format for each access mode.

**Do NOT copy these manually.** Run `/xgh-track` instead — it auto-detects your tools, reads their documentation, and generates correct configs.

## Access Modes

| Mode | How it works | Generated files | Example |
|------|-------------|----------------|---------|
| `cli` | Calls a CLI binary (gh, jira-cli, etc.) | `provider.yaml` + `fetch.sh` | `github-cli.yaml` |
| `api` | Calls REST/OpenAPI endpoints with curl | `provider.yaml` + `fetch.sh` | `linear-api.yaml` |
| `mcp` | Uses MCP server tools via Claude session | `provider.yaml` only | `slack-mcp.yaml` |

## Where configs live

Generated providers are saved to `~/.xgh/user_providers/<service>-<mode>/`. This directory is **never touched** by plugin installs or updates — it's your data.

## Regeneration

If a CLI or API changes, regenerate with:
```
/xgh-track --regenerate <provider-name>
```
This re-reads the tool's documentation and updates the fetch script while preserving your config.
