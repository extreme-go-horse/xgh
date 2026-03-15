# Brenno Ferrari -- Jira Work Profile

> Generated: 2026-03-15 | Source: traderepublic.atlassian.net | 50 tickets analyzed

---

## Throughput

| Window | Tickets Completed |
|--------|------------------|
| Last 30 days | 11 |
| Last 60 days | 11 |
| Last 90 days | 15 |
| All time (visible) | 50 |

- **Average cycle time:** 20.8 days (skewed by long-lived Tasks)
- **Median cycle time:** 9 days (better indicator of typical work)
- **Story points:** Not used (customfield_10016 empty across all tickets)

## Cycle Time by Ticket Type

| Type | Avg Cycle | Count |
|------|-----------|-------|
| Bug | 7.0 days | 8 |
| Sub-task | 11.4 days | 28 |
| Engineering Incident | 10.0 days | 1 |
| Story | 36.3 days | 7 |
| Task | 66.5 days | 6 |

Bugs and sub-tasks move fastest. Stories and tasks carry longer lead times (likely due to discovery/review phases, not active dev time).

## Ticket Type Distribution (all 50)

| Type | Count | % |
|------|-------|---|
| Sub-task | 30 | 60% |
| Bug | 15 | 30% |
| Task | 3 | 6% |
| Epic | 1 | 2% |
| Story | 1 | 2% |

## Domain & Component Affinity

### Labels (ranked)
| Label | Count |
|-------|-------|
| **iOS** | 27 |
| **account_recovery** | 25 |
| new_onboarding_ui | 4 |
| junior_onboarding | 3 |
| Goal-4 | 15 (completed) |

### Components
- **iOS: 31 tickets** (dominant platform)
- Android: 1, Backend: 1 (negligible)

### Parent Epics (top)
| Epic | Tickets |
|------|---------|
| PE-121469: KYC for account recovery incl. unknown numbers | 7 |
| PE-124475: Document Type Screen | 5 |
| PTECH-24594: KYC UI & flow changes | 5 |
| PE-124484: KYC Intro Screen | 4 |
| PE-124483: KYC UI V2 change requests | 3 |
| PE-124474: Issuing Country Screen | 3 |

## Strengths & Patterns

1. **iOS specialist** -- 62% of all tickets are iOS-labeled, 31/50 have iOS component. Nearly all ticket summaries carry the apple emoji prefix.
2. **KYC & Account Recovery domain expert** -- Half of all tickets relate to account_recovery. Deep involvement in KYC V2 UI redesign (document type, issuing country, intro screens, camera/scanning flows).
3. **Fast bug fixer** -- 7-day average cycle on bugs, with several same-day fixes. Comfortable with quick UI polish (checkmarks, copy, localization, masks).
4. **UI-focused** -- Work centers on screens, flows, copy, localization, and visual polish. No backend/infra tickets.
5. **Consistent output** -- 11 tickets completed in the last 30 days shows steady cadence.
6. **Onboarding familiarity** -- Some tickets in `new_onboarding_ui` and `junior_onboarding` areas.

## Recommendation for Passcode Swimlane

**Best fit: Swimlane 4 -- Account Recovery Placement (reset flows)**

Rationale:
- Brenno's dominant domain is **account_recovery** (25 of 50 tickets). They already own the KYC-for-recovery flow end-to-end on iOS.
- Account recovery is where passcode reset will live. Brenno has the screen-level familiarity (intro, document type, issuing country, upload, polling) needed to integrate a new passcode reset step into the existing recovery journey.
- Their fast bug-fix cycle (7 days avg) will be valuable for the iterative QA rounds typical of security-sensitive flows.

**Second choice: Swimlane 1 -- Foundational (passcode input component, validation, duplicate PIN screen)**
- Their UI component skill (building KYC screens from scratch in V2) transfers well to building the core passcode input component.
- However, this swimlane may benefit more from someone with cross-platform or design-system experience, whereas Brenno is iOS-only.

**Not recommended:**
- Swimlane 5 (Verification) -- requires deep integration across many product surfaces (transfers, cards, PSD2), which is outside Brenno's observed scope.
- Swimlane 6 (Observability) -- no evidence of logging/tracking work in their history.
- Swimlane 2 (Login placement) -- less alignment with their account_recovery expertise.
