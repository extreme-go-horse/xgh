# Retrieve Prefetch + Briefing Freshness Gate

**Date:** 2026-03-27
**Status:** Draft
**Branch:** feat/phase-2-validate-observe

---

## Problem

Today, `/xgh-briefing` gathers data live from providers every time it runs. There is no
background retrieval — the user always waits for a full fetch. If the scheduler is not
active, briefing silently shows stale inbox data with only a passive nudge.

**Goal:** On session start, kick off a background retrieve so briefing data is already
fresh (or in-flight) when the user asks for it. If briefing detects stale data, it should
re-trigger a retrieve rather than silently showing old data.

---

## Decisions

| # | Decision | Choice |
|---|----------|--------|
| 1 | Staleness model | Hybrid — fresh if completed this session OR within `briefing_staleness_minutes` |
| 2 | Session-start trigger mechanism | `session-start.sh` outputs `retrieveTrigger: true`; Claude calls CronCreate |
| 3 | State signaling | State file at `~/.xgh/retrieve-state.json` |
| 4 | In-flight briefing behavior | Proceed immediately with existing data + "⚡ retrieve in progress" banner |
| 5 | Staleness threshold | Configurable via `ingest.yaml::briefing_staleness_minutes`, default 30 |

---

## Architecture

### New file: `~/.xgh/scripts/check-retrieve-freshness.sh`

Single source of truth for freshness logic. Called by briefing and retrieve.

**Inputs:** reads `~/.xgh/retrieve-state.json` and `~/.xgh/ingest.yaml`

**Exit codes:**
- `0` — fresh (completed this session OR within staleness threshold)
- `1` — stale (no recent completion)
- `2` — running (retrieve currently in progress)

**State file schema:**
```json
{
  "state": "idle | running | complete",
  "started_at": "2026-03-27T10:00:00Z",
  "completed_at": "2026-03-27T10:02:30Z",
  "session_id": "abc123"
}
```

**Freshness logic:**
1. If state file missing or corrupted → exit 1 (stale)
2. If `state == running` → exit 2
3. If `state == complete`:
   - Read `session_id` from state file; compare to `$CLAUDE_SESSION_ID`
   - If match → exit 0 (fresh, completed this session)
   - If no `CLAUDE_SESSION_ID` available → fall back to time-only check
   - Read `briefing_staleness_minutes` from `ingest.yaml` (default 30)
   - If `completed_at` is within threshold → exit 0 (fresh)
   - Else → exit 1 (stale)
4. If `state == idle` → exit 1 (stale)

---

### Modified: `hooks/session-start.sh`

**New steps added at the end of the hook:**

1. Check current state file:
   ```bash
   state=$(jq -r '.state // "idle"' ~/.xgh/retrieve-state.json 2>/dev/null || echo "idle")
   ```
2. If `state != running`: write initial state:
   ```bash
   echo "{\"state\":\"running\",\"started_at\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"session_id\":\"${CLAUDE_SESSION_ID:-}\"}" \
     > ~/.xgh/retrieve-state.json
   ```
3. Add `retrieveTrigger: true` to the hook's JSON output (only if state was not already running)
4. If `state == running`: add `retrieveTrigger: false` (duplicate guard — retrieve already in progress)

**Claude reads the JSON output** and, if `retrieveTrigger == true`, calls CronCreate with:
- Prompt: `/xgh-retrieve`
- Schedule: immediate (one-shot)

---

### Modified: `skills/retrieve/retrieve.md`

**Step 0 addition (before guard checks):** write state `running` (idempotent):
```bash
echo "{\"state\":\"running\",\"started_at\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"session_id\":\"${CLAUDE_SESSION_ID:-}\"}" \
  > ~/.xgh/retrieve-state.json
```

**Step 10 addition (after log completion):** update state to `complete`:
```bash
echo "{\"state\":\"complete\",\"started_at\":\"$STARTED_AT\",\"completed_at\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"session_id\":\"${CLAUDE_SESSION_ID:-}\"}" \
  > ~/.xgh/retrieve-state.json
```

---

### Modified: `skills/briefing/briefing.md`

Replace the existing **Scheduler nudge** section with a **Freshness Gate** section:

```
## Freshness Gate

Before gathering any data, run:
  bash ~/.xgh/scripts/check-retrieve-freshness.sh
  EXIT=$?

EXIT=0 (fresh):
  Proceed with briefing normally.

EXIT=2 (running):
  Proceed with briefing using existing inbox data.
  Prepend to output:
    ⚡ Retrieve in progress — data as of <completed_at or "session start">

EXIT=1 (stale):
  Call CronCreate with prompt /xgh-retrieve (one-shot, immediate).
  Proceed with briefing using existing inbox data.
  Prepend to output:
    ⚡ Retrieve triggered — data as of <completed_at or "no prior retrieve">
  (Briefing does NOT block waiting for the retrieve to complete.)
```

---

### Modified: `ingest.yaml` schema

Add optional key under the top-level config:
```yaml
# How many minutes before briefing considers inbox data stale (default: 30)
briefing_staleness_minutes: 30
```

---

## Data Flow

```
SessionStart hook (bash)
  │
  ├─ Check retrieve-state.json
  │     state != running → write { state: running, session_id, started_at }
  │     state == running → skip (duplicate guard)
  │
  └─ Output JSON: { ..., retrieveTrigger: true/false }

Claude reads session-start output
  │
  └─ retrieveTrigger == true → CronCreate /xgh-retrieve (one-shot, immediate)

Retrieve skill runs (background)
  │
  ├─ Step 0: confirm state=running in state file
  ├─ ... (10 existing steps) ...
  └─ Step 10: write { state: complete, completed_at, session_id }

User calls /xgh-briefing
  │
  └─ check-retrieve-freshness.sh
        ├─ EXIT 0 (fresh)  → proceed normally
        ├─ EXIT 2 (running) → proceed + "⚡ in-progress" banner
        └─ EXIT 1 (stale)  → CronCreate retrieve + proceed + "⚡ triggered" banner
```

---

## Error Handling

| Scenario | Behavior |
|----------|----------|
| State file missing | Treated as stale; fresh write on next session-start |
| State file corrupted (bad JSON) | Treated as stale; overwritten on next write |
| `CLAUDE_SESSION_ID` unavailable | Fall back to time-only freshness check |
| `briefing_staleness_minutes` missing from ingest.yaml | Default to 30 minutes |
| CronCreate fails in session-start | Log warning; session continues normally |
| CronCreate fails in briefing (stale path) | Log warning; proceed with existing data; omit banner |
| Retrieve stuck (never writes `complete`) | State file stays `running`; briefing shows in-progress banner indefinitely — resolved on next session-start which resets state |
| Two sessions open simultaneously | Second session overwrites state file with running; both retrieves run; last writer wins for completed_at — acceptable edge case |

---

## Tests

All tests live in `tests/test-retrieve-prefetch.sh`. No live MCP calls — structural and
behavioral assertions only.

| # | Description | Assertion |
|---|-------------|-----------|
| 1 | `check-retrieve-freshness.sh` exists and is executable | file exists, chmod +x |
| 2 | Freshness script exits 0 when state=complete and session_id matches | mock state file, set CLAUDE_SESSION_ID |
| 3 | Freshness script exits 0 when completed_at within threshold | mock state file with recent timestamp |
| 4 | Freshness script exits 1 when completed_at beyond threshold | mock state file with old timestamp |
| 5 | Freshness script exits 1 when state=idle | mock state file |
| 6 | Freshness script exits 1 when state file missing | no state file present |
| 7 | Freshness script exits 2 when state=running | mock state file |
| 8 | Freshness script reads threshold from ingest.yaml | mock ingest.yaml with custom value |
| 9 | Freshness script defaults to 30 min when key absent | ingest.yaml without the key |
| 10 | Freshness script falls back to time-only when session_id absent | state file has no session_id field |
| 11 | `session-start.sh` contains retrieveTrigger output logic | grep for retrieveTrigger |
| 12 | `session-start.sh` contains duplicate guard (state check before write) | grep for state != running guard |
| 13 | `retrieve/retrieve.md` updates state to running at Step 0 | grep for retrieve-state.json + running |
| 14 | `retrieve/retrieve.md` updates state to complete at Step 10 | grep for retrieve-state.json + complete |
| 15 | `briefing/briefing.md` contains Freshness Gate section | grep for "Freshness Gate" |
| 16 | `briefing/briefing.md` calls check-retrieve-freshness.sh | grep for script name |
| 17 | `briefing/briefing.md` handles EXIT=2 with in-progress banner | grep for "in progress" |
| 18 | `briefing/briefing.md` handles EXIT=1 by calling CronCreate | grep for CronCreate in stale path |
| 19 | `briefing/briefing.md` does NOT block waiting when stale | absence of poll/wait loop in stale path |
| 20 | `ingest.yaml` schema documented with briefing_staleness_minutes | grep in retrieve skill or config skill |

---

## Out of Scope

- Blocking wait for retrieve completion (decided: non-blocking with banner)
- Multiple concurrent session coordination beyond duplicate guard
- Retrieve progress streaming to briefing
- Per-provider freshness tracking (whole-retrieve granularity only)
