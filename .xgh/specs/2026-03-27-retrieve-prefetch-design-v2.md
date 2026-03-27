# Retrieve Prefetch + Briefing Freshness Gate — v2

**Date:** 2026-03-27
**Status:** Revised
**Supersedes:** `2026-03-27-retrieve-prefetch-design.md`
**Revision reason:** Adversarial review (4 rounds, 26 confirmed findings). See `2026-03-27-retrieve-prefetch-adversarial-review.json`.

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
| 4 | In-flight briefing behavior | Proceed immediately with existing data + banner |
| 5 | Staleness threshold | Configurable via `ingest.yaml::briefing_staleness_minutes` (positive integer, default 30) |
| 6 | Running-state TTL | 10 minutes — state=running older than TTL is treated as stale (crashed retrieve recovery) |

---

## Architecture

### New file: `~/.xgh/scripts/check-retrieve-freshness.sh`

Single source of truth for freshness read/decide logic. Called by briefing only.
Retrieve writes state directly (producer); this script reads and decides (consumer).

**Inputs:** reads `~/.xgh/retrieve-state.json` and `~/.xgh/ingest.yaml`

**Exit codes:**
- `0` — fresh (completed this session OR within staleness threshold)
- `1` — stale (no recent completion, or running state exceeded TTL)
- `2` — running (retrieve currently in progress, within TTL)

**Stdout:** on exit 0 or 2, emits `completed_at=<ISO>` (or `completed_at=` if none yet) so
briefing can display the "data as of" banner without re-parsing the state file.

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
```
1. Ensure ~/.xgh/ exists (mkdir -p)
2. If state file missing or corrupted (jq parse fails) → exit 1 (stale)
3. Read state, started_at, completed_at, session_id from state file
4. If state == running:
   - If started_at is older than RUNNING_TTL (10 min) → exit 1 (stale, crashed retrieve)
   - Else → emit "completed_at="; exit 2 (running, within TTL)
5. If state == complete:
   - Read CLAUDE_SESSION_ID env var
   - If CLAUDE_SESSION_ID is non-empty AND matches session_id in state file → emit "completed_at=<value>"; exit 0 (fresh)
   - Read briefing_staleness_minutes from ingest.yaml using yq (fallback: python3 -c); default 30 if key absent or file absent
   - Validate: if value is not a positive integer, use default 30
   - If completed_at is within threshold → emit "completed_at=<value>"; exit 0 (fresh)
   - Else → exit 1 (stale)
6. If state == idle → exit 1 (stale)
```

**Two-session note:** When two sessions run simultaneously, `session_id` in the completed
state will reflect whichever retrieve finished last. A session whose retrieve completed
under a different session_id will fall through to time-based freshness — this is
intentional and safe (the data is still fresh; only the session-match fast-path is missed).

---

### Modified: `hooks/session-start.sh`

**New steps added at the end of the hook:**

```bash
mkdir -p ~/.xgh/

# Read current state with TTL-awareness
state=$(jq -r '.state // "idle"' ~/.xgh/retrieve-state.json 2>/dev/null || echo "idle")
started_at=$(jq -r '.started_at // ""' ~/.xgh/retrieve-state.json 2>/dev/null || echo "")
retrieve_trigger=false

if [ "$state" != "running" ]; then
  # Not running — write running state and trigger
  retrieve_trigger=true
elif [ -n "$started_at" ]; then
  # Running — check TTL (10 min = 600 seconds)
  now_epoch=$(date -u +%s)
  started_epoch=$(date -u -d "$started_at" +%s 2>/dev/null || date -u -jf "%Y-%m-%dT%H:%M:%SZ" "$started_at" +%s 2>/dev/null || echo 0)
  age=$((now_epoch - started_epoch))
  if [ "$age" -gt 600 ]; then
    # Stale running state (crashed retrieve) — override
    retrieve_trigger=true
  fi
fi

if [ "$retrieve_trigger" = "true" ]; then
  # Atomic write via temp file
  tmp=$(mktemp ~/.xgh/retrieve-state.XXXXXX)
  printf '{"state":"running","started_at":"%s","session_id":"%s"}' \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "${CLAUDE_SESSION_ID:-}" > "$tmp"
  mv "$tmp" ~/.xgh/retrieve-state.json
fi
```

Output JSON includes `"retrieveTrigger": <true|false>`.

**Claude reads the JSON output** and, if `retrieveTrigger == true`, calls CronCreate with:
- Prompt: `/xgh-retrieve`
- Schedule: immediate (one-shot; CronCreate `run_once: true`)

**LLM contract note:** The CronCreate call depends on Claude reading and acting on
`retrieveTrigger`. If Claude ignores it, the TTL (10 min) ensures the next session-start
will retry. This is the recovery path for silent-drop.

---

### Modified: `skills/retrieve/retrieve.md`

**Step 0 addition (before guard checks):** capture start time and write state atomically:
```bash
mkdir -p ~/.xgh/
STARTED_AT=$(date -u +%Y-%m-%dT%H:%M:%SZ)
tmp=$(mktemp ~/.xgh/retrieve-state.XXXXXX)
printf '{"state":"running","started_at":"%s","session_id":"%s"}' \
  "$STARTED_AT" "${CLAUDE_SESSION_ID:-}" > "$tmp"
mv "$tmp" ~/.xgh/retrieve-state.json
```

**Step 10 addition (after log completion):** write complete state atomically:
```bash
tmp=$(mktemp ~/.xgh/retrieve-state.XXXXXX)
printf '{"state":"complete","started_at":"%s","completed_at":"%s","session_id":"%s"}' \
  "$STARTED_AT" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "${CLAUDE_SESSION_ID:-}" > "$tmp"
mv "$tmp" ~/.xgh/retrieve-state.json
```

---

### Modified: `skills/briefing/briefing.md`

Replace the existing **Scheduler nudge** section with a **Freshness Gate** section:

```
## Freshness Gate

Before gathering any data, run:
  freshness_output=$(bash ~/.xgh/scripts/check-retrieve-freshness.sh)
  EXIT=$?
  completed_at=$(echo "$freshness_output" | grep '^completed_at=' | cut -d= -f2)

EXIT=0 (fresh):
  Proceed with briefing normally.

EXIT=2 (running):
  Proceed with briefing using existing inbox data.
  Prepend to output:
    ⚡ Retrieve in progress — data as of ${completed_at:-"session start"}

EXIT=1 (stale):
  Write state=running to state file before triggering:
    mkdir -p ~/.xgh/
    tmp=$(mktemp ~/.xgh/retrieve-state.XXXXXX)
    printf '{"state":"running","started_at":"%s","session_id":"%s"}' \
      "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "${CLAUDE_SESSION_ID:-}" > "$tmp"
    mv "$tmp" ~/.xgh/retrieve-state.json
  Call CronCreate with prompt /xgh-retrieve (one-shot, immediate).
  If CronCreate fails: proceed with existing data, prepend "⚠ data may be stale (retrieve trigger failed)"
  If CronCreate succeeds: proceed with existing data, prepend:
    ⚡ Retrieve triggered — data as of ${completed_at:-"no prior retrieve"}
  (Briefing does NOT block waiting for the retrieve to complete.)
```

---

### Modified: `ingest.yaml` schema

```yaml
# How many minutes before briefing considers inbox data stale.
# Must be a positive integer. Values ≤ 0 are treated as default.
# Default: 30
briefing_staleness_minutes: 30
```

---

## Data Flow

```
SessionStart hook (bash)
  │
  ├─ mkdir -p ~/.xgh/
  ├─ Read state file; check state + TTL
  │     state != running OR running > 10min → write running (atomic mv); retrieveTrigger:true
  │     state == running AND within TTL     → skip; retrieveTrigger:false
  │
  └─ Output JSON: { ..., retrieveTrigger: true/false }

Claude reads session-start output
  │
  └─ retrieveTrigger == true → CronCreate /xgh-retrieve (one-shot)
     [LLM contract — TTL is the recovery path if ignored]

Retrieve skill runs (background)
  │
  ├─ Step 0: STARTED_AT=$(date); write { state:running, started_at, session_id } (atomic)
  ├─ ... (10 existing steps) ...
  └─ Step 10: write { state:complete, started_at:$STARTED_AT, completed_at, session_id } (atomic)

User calls /xgh-briefing
  │
  └─ check-retrieve-freshness.sh (stdout: completed_at=...)
        ├─ EXIT 0 (fresh)    → proceed normally
        ├─ EXIT 2 (running)  → proceed + "⚡ in-progress" banner
        └─ EXIT 1 (stale)    → write running + CronCreate + proceed + banner
                               (CronCreate fail → ⚠ stale warning banner)
```

---

## Error Handling

| Scenario | Behavior |
|----------|----------|
| State file missing | Treated as stale; write on next session-start or briefing trigger |
| State file corrupted (bad JSON) | Treated as stale; overwritten on next atomic write |
| `CLAUDE_SESSION_ID` absent or empty | Fall back to time-only freshness check |
| `briefing_staleness_minutes` missing key | Default to 30 minutes |
| `briefing_staleness_minutes` value ≤ 0 or non-integer | Default to 30 minutes |
| `ingest.yaml` file missing entirely | Default to 30 minutes |
| CronCreate fails in session-start | Log warning; session continues; TTL ensures retry on next session |
| CronCreate fails in briefing (stale path) | Show "⚠ data may be stale" banner; proceed with existing data |
| Retrieve stuck / crashed (state=running) | TTL=10min: after expiry, freshness script exits 1 and session-start overwrites; self-healing |
| Two sessions open simultaneously | Both may fire CronCreate (narrow TOCTOU window); both retrieves run; last writer wins for session_id — cosmetic, not a correctness failure |
| `~/.xgh/` directory missing | `mkdir -p` in every write path ensures it exists |

---

## Tests

All tests live in `tests/test-retrieve-prefetch.sh`. No live MCP calls — structural and
behavioral assertions only. Tests 2-10 run the actual `check-retrieve-freshness.sh`
against mock state files to verify decision logic.

| # | Description | Assertion |
|---|-------------|-----------|
| 1 | `check-retrieve-freshness.sh` exists and is executable | file exists, chmod +x |
| 2 | Freshness script exits 0 when state=complete and session_id matches (non-empty) | mock state file, set CLAUDE_SESSION_ID to matching non-empty value |
| 3 | Freshness script exits 0 when completed_at within threshold | mock state file with recent timestamp |
| 4 | Freshness script exits 1 when completed_at beyond threshold | mock state file with old timestamp |
| 5 | Freshness script exits 1 when state=idle | mock state file |
| 6 | Freshness script exits 1 when state file missing | no state file present |
| 7 | Freshness script exits 2 when state=running within TTL | mock state file with recent started_at |
| 8 | Freshness script reads threshold from ingest.yaml (yq) | mock ingest.yaml with custom value |
| 9 | Freshness script defaults to 30 min when key absent | ingest.yaml without the key |
| 10a | Freshness script falls back to time-only when CLAUDE_SESSION_ID env var is absent | unset env var, state=complete |
| 10b | Freshness script falls back to time-only when state file has no session_id field | state file with no session_id key |
| 11 | Freshness script exits 1 when state=running and started_at exceeds TTL (10 min) | mock state file with old started_at |
| 12 | Freshness script emits completed_at= to stdout on exit 0 | parse stdout for completed_at= line |
| 13 | Freshness script emits completed_at= to stdout on exit 2 | parse stdout for completed_at= line |
| 14 | Freshness script defaults to 30 when briefing_staleness_minutes ≤ 0 | mock ingest.yaml with 0 |
| 15 | Freshness script handles missing ingest.yaml (defaults to 30) | no ingest.yaml present |
| 16 | `session-start.sh` contains TTL check for running state | grep for TTL / 600 logic |
| 17 | `session-start.sh` uses atomic write (mktemp + mv) | grep for mktemp and mv |
| 18 | `session-start.sh` contains retrieveTrigger output logic | grep for retrieveTrigger |
| 19 | `retrieve/retrieve.md` assigns STARTED_AT at Step 0 | grep for STARTED_AT= |
| 20 | `retrieve/retrieve.md` uses $STARTED_AT in Step 10 | grep for $STARTED_AT in Step 10 |
| 21 | `retrieve/retrieve.md` uses atomic write (mktemp + mv) | grep for mktemp and mv |
| 22 | `briefing/briefing.md` contains Freshness Gate section | grep for "Freshness Gate" |
| 23 | `briefing/briefing.md` calls check-retrieve-freshness.sh and captures stdout | grep for freshness_output or completed_at= parse |
| 24 | `briefing/briefing.md` writes state=running before CronCreate in stale path | grep for state=running write in EXIT=1 block |
| 25 | `briefing/briefing.md` shows fallback banner on CronCreate failure | grep for "data may be stale" |
| 26 | `ingest.yaml` schema documents briefing_staleness_minutes with positive-integer constraint | grep for "positive integer" near briefing_staleness_minutes |

---

## Out of Scope

- Blocking wait for retrieve completion (decided: non-blocking with banner)
- Full mutex/flock for concurrent session-start (narrow window; TTL is sufficient recovery)
- Retrieve progress streaming to briefing
- Per-provider freshness tracking (whole-retrieve granularity only)
- CLAUDE_SESSION_ID propagation enforcement into CronCreate child (environment-dependent; conservative fallback handles it)
