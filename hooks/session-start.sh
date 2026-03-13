#!/usr/bin/env bash
# xgh session-start hook
# Outputs JSON: {"result": "...text..."}
# When XGH_BRIEFING=1 is set, appends an instruction for the agent to run
# the xgh:briefing skill at the start of the session.
set -euo pipefail

BASE_MSG="xgh: session-start hook ready"

if [ "${XGH_BRIEFING:-0}" = "1" ]; then
  MSG="${BASE_MSG} — XGH_BRIEFING enabled. Run the xgh:briefing skill now to produce the session briefing."
else
  MSG="${BASE_MSG}"
fi

printf '{"result": "%s"}\n' "$MSG"
exit 0
