# Installer Overhaul: Clean Separation + Verify-and-Fix

**Date:** 2026-03-19
**Status:** Approved (brainstorm complete)
**Scope:** xgh install.sh + lossless-claude install + claude-max-api-proxy alias

---

## Problem

Two installers (xgh and lossless-claude) share overlapping responsibilities with no verification. The delegation from xgh to lossless-claude was started (commit `95de899` removed 589 lines) but never finished. Result: silent failures, orphaned artifacts, broken memory stack that users only discover when `lcm_*` tools are missing from a Claude Code session.

Specific failures on a fresh install (2026-03-19):
- lossless-claude daemon not running → MCP tools unavailable
- `models.env` overwritten with empty values
- `com.xgh.models.plist` has 7 unresolved placeholders
- Orphaned scheduler plists from pre-migration
- cipher MCP server installed manually, not by either installer
- `claude-server` binary missing (naming mismatch with `claude-max-api`)
- No post-install verification in either installer

## Design Principle

**Each installer is self-sufficient and verifies its own domain.** lossless-claude owns the memory stack. xgh owns the workflow layer. Both end with a verify-and-fix step that auto-remediates what it can and prints specific fix commands for what it cannot.

---

## 1. Responsibility Boundaries

### lossless-claude owns (memory stack):

| Concern | Details |
|---|---|
| Backend detection | Auto-detect vllm-mlx / ollama / remote |
| Model selection | Interactive picker for LLM + embedding |
| Qdrant | Install, configure plist/systemd, start, health check |
| cipher.yml | Generate and update |
| cipher MCP | Install `@byterover/cipher`, create `cipher-mcp` wrapper, create `fix-openai-embeddings.js`, register in settings.json |
| claude-max-api-proxy | Install when summarizer=claude-cli, verify health |
| Daemon | Install plist/systemd unit, start, health check |
| lossless-claude MCP | Register in settings.json, verify tools respond |
| Hooks | Register PreCompact + SessionStart in settings.json |
| `lossless-claude doctor` | Verify everything above, auto-fix what's broken |
| `lossless-claude --version` | Print version |
| `lossless-claude status` | One-line summary |

### xgh owns (workflow layer):

| Concern | Details |
|---|---|
| Prerequisites | Check node + python3 exist (warn if missing) |
| lossless-claude | npm install + `lossless-claude install` + `lossless-claude doctor` |
| Skills & plugin | Registration, cache, marketplace |
| Context tree | Create `.xgh/context-tree/` |
| Hooks | xgh-specific hooks (session-start, prompt-submit, etc.) |
| Settings merge | xgh permissions + hook entries (preserves lossless-claude's) |
| Ingest pipeline | Directories, lib files, ingest.yaml |
| CLAUDE.local.md | Inject instructions |
| Optional plugins | superpowers, context-mode |
| MCP detection | Snapshot connected MCPs to connectors.json |
| Post-install validation | Full-stack verify (delegates memory stack to `lossless-claude doctor`) |

### Eliminated from xgh:

| Artifact | Action |
|---|---|
| `~/.xgh/models.env` | Stop creating. Delete on migration. |
| `com.xgh.models.plist` | Delete from repo. |
| `~/.xgh/schedulers/` directory | Stop creating. Delete on migration. |
| Homebrew install in xgh | Let lossless-claude's setup.sh handle it. |

---

## 2. `lossless-claude doctor`

Single command that answers: "Is my memory stack working? If not, why, and can you fix it?"

### Always-run checks:

| # | Check | Auto-fix | Failure message |
|---|---|---|---|
| 1 | Binary in PATH | — | `npm install -g @ipedro/lossless-claude` |
| 2 | `--version` responds | — | Binary corrupted — reinstall |
| 3 | `config.json` exists | Re-create with defaults | `Run: lossless-claude install` |
| 4 | `cipher.yml` exists with valid config | — | `Run: lossless-claude install` |
| 5 | Daemon running (`:3737/health`) | Restart via launchd/systemd | `Daemon not running — restarting...` |
| 6 | Daemon service registered (plist/unit exists + loaded) | Re-create + load | `Service not registered — fixing...` |
| 7 | `settings.json`: PreCompact + SessionStart hooks | Add entries | `Hooks missing — fixing...` |
| 8 | `settings.json`: lossless-claude MCP entry | Add entry | `MCP entry missing — fixing...` |
| 9 | `cipher` binary exists | `npm install -g @byterover/cipher` | `cipher not found — installing...` |
| 10 | `cipher-mcp` wrapper exists at `~/.local/bin/cipher-mcp` | Re-create from template | `Wrapper missing — creating...` |
| 11 | `fix-openai-embeddings.js` exists at `~/.local/lib/` | Re-create from template | `SDK fix missing — creating...` |
| 12 | `settings.json`: cipher MCP entry with correct env vars | Add/update entry | `cipher MCP missing — fixing...` |
| 13 | lossless-claude MCP handshake → 5 tools | Restart daemon, retry | `MCP not responding — restarting...` |
| 14 | cipher MCP handshake responds | — | `cipher MCP not responding — check Qdrant` |
| 15 | `lcm_store` → `lcm_search` round-trip | — | `Check daemon logs: ~/.lossless-claude/daemon.log` |

**Implementation notes:**
- Checks 13-14 (MCP handshake): Spawn the MCP server process via stdio, send JSON-RPC `initialize` + `tools/list`, count tools, kill process. Same approach as `echo '{"jsonrpc":"2.0",...}' | lossless-claude mcp`.
- Check 15 (round-trip): POST to daemon's `/store` endpoint with a test payload (`__lcm_doctor_probe`), then POST to `/search` for that string, verify it appears. No cleanup needed — the test payload is tiny and tagged with `__doctor` for identification.

### Conditional on backend:

| Check | vllm-mlx | ollama | remote |
|---|---|---|---|
| Qdrant local (`:6333/healthz`) | ✅ auto-start | ✅ auto-start | ✅ auto-start |
| vllm-mlx listening (`:11435`) | ✅ warn + start cmd | — | — |
| Ollama listening (`:11434`) | — | ✅ auto-start via brew/systemd | — |
| Remote URL reachable | — | — | ✅ curl check |
| Embedding endpoint (`/v1/models`) | ✅ local | ✅ local | ✅ remote |
| LLM endpoint (`/v1/models`) | ✅ local | ✅ local | ✅ remote |

### Conditional on summarizer provider:

| Check | claude-cli | anthropic | openai |
|---|---|---|---|
| `claude` binary in PATH | ✅ | — | — |
| `claude auth status` → logged in | ✅ warn | — | — |
| `claude-max-api` / `claude-server` in PATH | ✅ auto-install | — | — |
| claude-max-api reachable (`:3456/health`) | ✅ restart daemon | — | — |
| `ANTHROPIC_API_KEY` env var set | — | ✅ warn | — |
| Custom endpoint reachable | — | — | ✅ curl check |

### Output format:

```
lossless-claude doctor

  ── Stack ──────────────────────────────
  Backend:     vllm-mlx
  Summarizer:  claude-cli
  Config:      ~/.lossless-claude/config.json

  ── Infrastructure ─────────────────────
  ✅ Qdrant: localhost:6333 (healthy)
  ✅ vllm-mlx: localhost:11435 (responding, 2 models loaded)
  ✅ Embedding: mlx-community/nomicai-modernbert-embed-base-8bit ✓
  ✅ LLM: mlx-community/Llama-3.2-3B-Instruct-4bit ✓

  ── Daemon ─────────────────────────────
  ✅ Daemon: localhost:3737 (up, pid 56123)
  ✅ Service: com.lossless-claude.daemon (loaded)

  ── MCP Servers ────────────────────────
  ✅ lossless-claude: 5/5 tools
  ✅ cipher: 7/7 tools

  ── Settings ───────────────────────────
  ✅ Hooks: PreCompact ✓  SessionStart ✓
  ✅ MCP entries: lossless-claude ✓  cipher ✓

  ── Summarizer ─────────────────────────
  ✅ Claude CLI: authenticated (pedro@example.com)
  ✅ claude-max-api: localhost:3456 (healthy)

  ── Memory ─────────────────────────────
  ✅ Round-trip: store→search OK (12ms)

  All checks passed (19/19).
```

### Behavior:

- **Auto-fixable failure**: Fix → re-check → print `⚠️ [thing] — fixed`
- **Not auto-fixable**: Print `❌ [thing]` + specific fix command + log path
- **Exit code**: 0 if all pass or only warnings. Non-zero if any ❌ remains.
- **Idempotency**: All auto-fixes must be idempotent. Settings.json mutations use `hasHookCommand()`-style dedup. File writes use "create if missing" guards. Service restarts use "check health first" guards.

### Rollback:

No explicit rollback. If doctor fails after auto-fix attempts, the system is in a partially-fixed state — but doctor can be re-run safely (idempotent). This is acceptable because each check is independent and self-healing.

### Linux Qdrant note:

lossless-claude's `setup.sh` already handles Qdrant on Linux (downloads binary to `~/.qdrant/bin/`, creates systemd unit `lossless-claude-qdrant.service`). Doctor should check this unit on Linux instead of brew services.

---

## 3. `lossless-claude install` Changes

### New commands:

| Command | Purpose |
|---|---|
| `lossless-claude --version` | Print version from package.json |
| `lossless-claude doctor` | Verify-and-fix (Section 2) |
| `lossless-claude status` | One-liner: `daemon: up · qdrant: up · last compact: 2m ago` |

### Install flow changes:

1. **setup.sh** — unchanged (backend, models, Qdrant, cipher.yml)
2. **NEW: Install cipher** — `npm install -g @byterover/cipher` if not present
3. **NEW: Create cipher-mcp wrapper** — write `~/.local/bin/cipher-mcp` from template
4. **NEW: Create fix-openai-embeddings.js** — write `~/.local/lib/fix-openai-embeddings.js` from template
5. **NEW: Register cipher MCP** in settings.json with env vars derived from cipher.yml + backend config
6. **config.json** — create if missing, pick summarizer (unchanged)
7. **settings.json** — merge hooks + MCP entries for BOTH lossless-claude AND cipher
8. **Daemon service** — install plist/systemd, start
9. **Health-wait** — poll `localhost:3737/health` for up to 10s after daemon start. Same for Qdrant (`:6333/healthz`).
10. **NEW: Install claude-max-api-proxy** — when summarizer=claude-cli: `npm install -g claude-max-api-proxy`
11. **NEW: End with `lossless-claude doctor`** — full verification. Installer succeeds only if doctor passes.

### Template source locations:

The cipher-mcp wrapper and OpenAI SDK fix live as templates inside the lossless-claude package:

| Template | Source in lossless-claude repo | Destination |
|---|---|---|
| `cipher-mcp` wrapper | `src/installer/templates/cipher-mcp.js` | `~/.local/bin/cipher-mcp` |
| `fix-openai-embeddings.js` | `src/installer/templates/fix-openai-embeddings.js` | `~/.local/lib/fix-openai-embeddings.js` |

These are copied during `lossless-claude install` and re-created by `lossless-claude doctor` if missing.

### cipher MCP env vars (derived from config):

The cipher MCP settings.json entry needs these env vars, all derivable from cipher.yml + backend:

```json
{
  "type": "stdio",
  "command": "~/.local/bin/cipher-mcp",
  "env": {
    "MCP_SERVER_MODE": "aggregator",
    "VECTOR_STORE_TYPE": "qdrant",
    "VECTOR_STORE_URL": "http://localhost:6333",
    "EMBEDDING_PROVIDER": "<from cipher.yml embedding.type>",
    "EMBEDDING_MODEL": "<from cipher.yml embedding.model>",
    "EMBEDDING_BASE_URL": "<from cipher.yml embedding.baseURL>",
    "EMBEDDING_DIMENSIONS": "<from cipher.yml embedding.dimensions>",
    "EMBEDDING_API_KEY": "placeholder",
    "LLM_PROVIDER": "<from cipher.yml llm.provider>",
    "LLM_MODEL": "<from cipher.yml llm.model>",
    "LLM_BASE_URL": "<from cipher.yml llm.baseURL>",
    "LLM_API_KEY": "placeholder",
    "CIPHER_LOG_LEVEL": "info",
    "SEARCH_MEMORY_TYPE": "both",
    "USE_WORKSPACE_MEMORY": "true"
  }
}
```

### claude-max-api-proxy (separate repo):

Add `"claude-server"` alias to `bin` field in package.json so lossless-claude's proxy-manager works without code changes. No changes needed in lossless-claude's proxy-manager.js.

```json
{
  "bin": {
    "claude-max-api": "./src/server.js",
    "claude-server": "./src/server.js"
  }
}
```

---

## 4. `xgh install.sh` Changes

### Remove:

| Code block | What | Why |
|---|---|---|
| `cat > "$HOME/.xgh/models.env"` block | `models.env` creation | Eliminated — cipher.yml is source of truth |
| `sed ... com.xgh.models.plist` block | models plist copy + sed | Dead code — unresolved placeholders, never registered |
| `mkdir -p "$HOME/.xgh/schedulers"` | schedulers directory | No longer needed |

Note: Line numbers are omitted intentionally — they shift between commits. Match by content.

### Add:

| What | Where | Purpose |
|---|---|---|
| `rm -rf ~/.xgh/schedulers/` | Migration block | Clean orphaned plists |
| `rm -f ~/.xgh/models.env` | Migration block | Clean dead config |
| `.lossless-claude/` to `.gitignore` | Gitignore patterns | Prevent committing per-project lcm.db |
| `lossless-claude doctor` after install | After lossless-claude install call | Verify memory stack |
| Post-install validation | Before done banner | Full-stack verify (Section 5) |

### Modify:

| What | Change |
|---|---|
| lossless-claude install failure | Run `lossless-claude doctor` to diagnose. Print specific failure. |
| Dependencies section | Remove brew install. Keep node + python3 checks. |
| Ingest setup section | Remove schedulers mkdir and plist copy. |

### Settings merge contract:

Both installers write to `~/.claude/settings.json` independently. The contract: **each installer only adds its own entries and never removes others.** lossless-claude's `mergeClaudeSettings()` uses `hasHookCommand()` to avoid duplicates while preserving everything else. xgh's python deep-merge similarly only appends. Either installer can run independently or in sequence with the same result.

### Revised flow:

```
 1. Check node + python3 exist (warn if missing)
 2. Install/update lossless-claude → lossless-claude install → lossless-claude doctor
 3. Fetch xgh pack
 4. Legacy cleanup (cipher MCP entries + orphaned schedulers + models.env)
 5. Hooks (copy files, choose scope)
 6. Settings merge (deep-merge xgh hooks + permissions, preserving lossless-claude's)
 7. Plugin registration
 8. Context tree
 9. .gitignore (add .lossless-claude/)
10. CLAUDE.local.md
11. Optional plugins (superpowers, context-mode)
12. MCP detection
13. Ingest pipeline (dirs + lib files, no schedulers)
14. Post-install validation (Section 5)
15. Done banner
```

### Repo file deletions:

| File | Reason |
|---|---|
| `scripts/schedulers/com.xgh.models.plist` | Dead — unresolved placeholders, never registered |

---

## 5. xgh Post-Install Validation

Runs at end of install.sh. Validates full stack.

### Checks:

| # | Check | Auto-fix | Failure |
|---|---|---|---|
| 1 | `lossless-claude doctor` passes | Delegates to lossless-claude | `Memory stack unhealthy — see above` |
| 2 | Plugin in `installed_plugins.json` | Re-run `register_plugin` | `Re-registering...` |
| 3 | Skills in cache dir | Re-copy from pack | `Re-copying...` |
| 4 | xgh hooks in settings.json | Re-run settings merge | `Re-merging...` |
| 5 | lossless-claude hooks in settings.json | `lossless-claude doctor` handles | — |
| 6 | `_manifest.json` exists | Re-create | `Re-creating...` |
| 7 | `.lossless-claude/` in `.gitignore` | Append | `Adding...` |
| 8 | `ingest.yaml` exists | Copy template | `Creating...` |
| 9 | Claude CLI authenticated | — | `Run: claude` |

### Output:

```
  ━━━ Post-install validation 🔍

  ✅ Memory stack (lossless-claude doctor: 19/19)
  ✅ Plugin: xgh@ipedro v1.2.0
  ✅ Skills: 23 skills in cache
  ✅ Hooks: xgh (5) + lossless-claude (2)
  ✅ Context tree: .xgh/context-tree/_manifest.json
  ✅ Gitignore: .lossless-claude/ ✓
  ✅ Ingest config: ~/.xgh/ingest.yaml
  ⚠️ Claude CLI: not authenticated — run `claude` to log in

  9/9 passed, 0 failed, 1 warning
```

### Behavior:

- Auto-fixable: fix → re-check → `⚠️ fixed`
- Not fixable: `❌` + specific command
- Exit code: 0 if pass/warn, non-zero if ❌ remains

---

## 6. Migration & Cleanup

Runs early in install.sh for existing users.

### Migration block:

| Artifact | Detection | Action | Message |
|---|---|---|---|
| `~/.xgh/schedulers/` | Dir exists | `rm -rf` | `Removed orphaned schedulers` |
| `~/.xgh/models.env` | File exists | `rm -f` | `Removed legacy models.env` |
| `~/.xgh/lib/ingest-schedule.sh` | File exists | Already handled | Keep as-is |
| Cipher in `.mcp.json` | Already handled | Keep as-is | — |
| Old skill copies | Already handled | Keep as-is | — |

### Repo deletions (this PR):

- `scripts/schedulers/com.xgh.models.plist`

### New `.gitignore` entries:

- `.lossless-claude/`

---

## Dependency Graph

```
xgh install.sh
  ├── node + python3 (prerequisites, warn if missing)
  ├── lossless-claude install
  │     ├── setup.sh
  │     │     ├── _ensure_brew (Homebrew, if needed)
  │     │     ├── Backend (vllm-mlx | ollama | remote)
  │     │     ├── Qdrant (install + start + health wait)
  │     │     ├── Model picker (LLM + embedding)
  │     │     └── cipher.yml (generate/update)
  │     ├── cipher
  │     │     ├── npm install -g @byterover/cipher
  │     │     ├── ~/.local/bin/cipher-mcp (wrapper)
  │     │     ├── ~/.local/lib/fix-openai-embeddings.js
  │     │     └── settings.json cipher MCP entry
  │     ├── claude-max-api-proxy (when summarizer=claude-cli)
  │     │     └── npm install -g claude-max-api-proxy
  │     ├── config.json (summarizer picker)
  │     ├── settings.json (hooks + MCP: lossless-claude + cipher)
  │     ├── daemon service (launchd/systemd + health wait)
  │     └── lossless-claude doctor (full verification)
  ├── xgh pack (git clone/pull)
  ├── Legacy cleanup (schedulers, models.env, cipher MCP)
  ├── Hooks (5 xgh hook files, scope choice)
  ├── Settings merge (xgh hooks + permissions, preserves lossless-claude)
  ├── Plugin registration (cache, installed_plugins.json, marketplace)
  ├── Context tree (_manifest.json)
  ├── .gitignore (.lossless-claude/, existing patterns)
  ├── CLAUDE.local.md (inject instructions)
  ├── Optional plugins (superpowers, context-mode)
  ├── MCP detection (connectors.json)
  ├── Ingest pipeline (dirs + lib files, no schedulers)
  └── Post-install validation (lossless-claude doctor + xgh checks)
```

---

## Implementation Scope

### Repos affected:

1. **lossless-claude** — doctor command, install changes (cipher, claude-max-api, health-wait, --version, status)
2. **xgh** — install.sh cleanup, migration block, post-install validation, delete models.plist
3. **claude-max-api-proxy** — add `claude-server` bin alias

### Estimated changes:

- lossless-claude: ~400-500 lines new (doctor, cipher setup, health-wait), ~50 lines modified
- xgh install.sh: ~80 lines removed, ~120 lines new (migration, validation)
- claude-max-api-proxy: 1 line in package.json
