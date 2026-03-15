# Passcode Tracker — Swimlane Breakdown

> For Andrea's Google tracker sheet. Data from Jira + Slack as of 2026-03-15.
> **Note:** Zero story points in Jira. Dima's verbal estimate: 30d/1 engineer/platform total, 1 SP = 1 day.

## Epic 1: PTECH-31204 — User can set and login with complex pass code (P0)

| Swimlane | Tickets | iOS Owner | Android Owner | Est (days) | Status | Due (stale) |
|----------|---------|-----------|---------------|------------|--------|-------------|
| **Foundational — components** | | | | | | |
| Feature flags setup | PTECH-32391 | Pedro | Pedro | 1 | QA Passed | Mar 17 |
| Passcode input component | PTECH-32401 | TBD | Alireza (in progress) | 3 | In Progress | Mar 19 |
| On-device validation rules | PTECH-32405 | TBD | Dima (assigned) | 2 | To Do | Mar 20 |
| Duplicate PIN screen (dual-mode) | PTECH-32410 | TBD | Max (Android PRs open) | 3 | To Do | Mar 25 |
| Persist user's code type in memory | PTECH-32408 | TBD | Dima (assigned) | 2 | To Do | Mar 25 |
| **Placement — Login** | | | | | | |
| Update API to accept passcode | PTECH-32399 | TBD | Yassien (starting) | 3 | To Do | Mar 19 |
| Placement: Login | PTECH-32413 | TBD | Dima (assigned) | 3 | To Do | Mar 25 |
| **Placement — Change PIN/Passcode** | | | | | | |
| Placement: Change PIN/Passcode | PTECH-32414 | TBD | Dima (assigned) | 3 | To Do | Mar 25 |
| **Placement — Account Recovery** | | | | | | |
| Placement: Account Recovery | PTECH-32415 | TBD | Dima (assigned) | 2 | To Do | Mar 25 |
| **Placement — Onboarding** | | | | | | |
| ~~Placement: Onboarding~~ | PTECH-32416 | — | — | 2 | **P1 (deferred)** | — |
| **Observability** | | | | | | |
| Tracking — mode switch CTA tap | PTECH-32426 | TBD | Dima (assigned) | 1 | To Do | Mar 24 |
| Non-fatal logging + breadcrumbs | PTECH-32427 | TBD | Dima (assigned) | 1 | To Do | Apr 1 |
| **Other** | | | | | | |
| Passcode notifications | PTECH-31211 | TBD | TBD | 1 | To Do | — |
| Validate passcode when set | PTECH-31214 | TBD | TBD | 1 | To Do | — |
| Set new passcode in profile | PTECH-31207 | TBD | TBD | 2 | To Do | — |
| Login with passcode (all platforms) | PTECH-31209 | TBD | TBD | 2 | To Do | — |
| ~~Set passcode during onboarding~~ | PTECH-31215 | — | — | 2 | **P1 (deferred)** | — |
| Set passcode in account recovery | PTECH-31213 | TBD | TBD | 2 | Backlog | — |

## Epic 2: PTECH-31628 — Passcode can be used in other app flows (P0)

| Swimlane | Tickets | iOS Owner | Android Owner | Est (days) | Status | Due (stale) |
|----------|---------|-----------|---------------|------------|--------|-------------|
| Placement: Transfers | PTECH-32418 | TBD | Dima (assigned) | 3 | To Do | Apr 1 |
| Placement: Card | PTECH-32420 | TBD | Dima (assigned) | 2 | To Do | Apr 1 |
| Placement: Bizum | PTECH-32422 | TBD | Dima (assigned) | 1 | To Do | Apr 1 |
| Placement: PSD2 | PTECH-32423 | TBD | Dima (assigned) | 2 | To Do | Apr 1 |
| Placement: Trade confirmation | PTECH-32424 | TBD | Dima (assigned) | 2 | To Do | Apr 1 |
| Biometric fallback (generic) | PTECH-31216 | TBD | TBD | 3 | Backlog | — |

## Epic 3: PTECH-31630 — Users cannot circumvent PIN entry (P1)

| Swimlane | Tickets | iOS Owner | Android Owner | Est (days) | Status | Due (stale) |
|----------|---------|-----------|---------------|------------|--------|-------------|
| Prevent BE-direct PIN bypass (JWT) | PTECH-31220 | TBD | TBD | ? | Backlog | — |

## Backend Workstreams (not in tracker — Cem owns)

| Workstream | Owner | Ticket | Status |
|-----------|-------|--------|--------|
| DB migration (auth_account table) | Cem | PTECH-32799 | Done (merged) |
| Set passcode endpoint | Patrick | PTECH-32802 | In Progress |
| New login endpoint v3 | Omar | PTECH-32797 | In Progress |
| Credential type endpoint | Cem | — | Proposed, no ticket |
| Password validation endpoint | Cem | — | Proposed, no ticket |
| Argon2id hashing | Patrick | — | RFC published |

## Summary

| Metric | Value |
|--------|-------|
| Total mobile tickets | 25 |
| Story points in Jira | **0 (none entered)** |
| Verbal estimate (Dima) | 30d / 1 engineer / platform |
| iOS owner assigned | 1 (Pedro — FF setup, QA passed) |
| Android owners assigned | 3 (Alireza, Max, Yassien) |
| Tickets still assigned to Dima | 15 |
| Tickets unassigned | 6 |
| Due dates | All stale (based on Chris's Apr 1 timeline) |

## Actions for Pedro

1. Re-estimate each ticket with iOS team (Brenno, Madalina, Otávio)
2. Assign iOS owners per ticket
3. Reassign Dima's tickets to actual implementers
4. Update due dates to mid-April timeline
5. Add story points to Jira
6. Fill Andrea's Google tracker with per-swimlane totals
