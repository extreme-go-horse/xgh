# Pedro Almeida — Jira Work Profile

> Generated: 2026-03-15 | Source: Jira (PE, PTECH, PQ projects) | Account: pedro.almeida@traderepublic.com

---

## Throughput

| Period | Tickets Completed |
|---|---|
| Last 30 days (since 2026-02-13) | 4 |
| Last 60 days (since 2026-01-14) | 12 |
| Last 90 days (since 2025-12-15) | 13 |

**Monthly breakdown (completed tickets):**

| Month | Count |
|---|---|
| 2025-08 | 13 |
| 2025-09 | 8 |
| 2025-10 | 7 |
| 2025-11 | 3 |
| 2025-12 | 3 |
| 2026-02 | 9 |
| 2026-03 | 3 (month in progress) |

- **Average cycle time:** 38.3 days (across 46 completed tickets)
- **Median throughput:** ~6 tickets/month (excl. outliers)
- **Note:** No story points are tracked (all SP fields are empty). Throughput measured by ticket count only.
- **Note:** January 2026 shows zero completions — likely a holiday/vacation period.

### Fastest turnarounds
| Ticket | Cycle | Summary |
|---|---|---|
| PE-112461 | 0d | Adjust translations for account recovery flow |
| PE-111202 | 0d | Create tracking events |
| PE-124459 | 1d | Login takes a long time on 4.2610 |
| PE-113527 | 1d | Add missing pairDeviceConfirmationScreenViewed event |
| PE-109721 | 1d | Update localization keys in pair device screen |

### Longest cycle times
| Ticket | Cycle | Summary |
|---|---|---|
| PE-63449 | 614d | Login: Next button moves when changing the country code |
| PE-86170 | 326d | Remove tax related fields and migrate to new apis |
| PE-102332 | 112d | Account Closure screen shown instead of chat |
| PE-100948 | 107d | User can not select different area code during account recovery |
| PE-106499 | 68d | Update Amplify FaceLiveness SDK to version 1.4.2 |

> Long-cycle tickets are typically low-priority legacy bugs that sat in backlog before finally being picked up, not active work duration.

---

## Ticket Type Affinity

### Type distribution (most recent 50 tickets)

| Type | Count | % |
|---|---|---|
| Bug | 20 | 40% |
| Task | 12 | 24% |
| Sub-task | 7 | 14% |
| Tech Story | 7 | 14% |
| Discovery | 3 | 6% |
| Story | 1 | 2% |

### Work area distribution (keyword analysis)

| Area | Count | Notes |
|---|---|---|
| iOS | 46 | Primary platform — nearly all tickets are iOS |
| Account Recovery | 7 | Account selector, recovery flows, device pairing |
| Login | 5 | Login screens, hints, phone number entry |
| API / Backend | 5 | API contracts, mapper repositories, BE tasks |
| Android | 4 | Cross-platform when needed (feature flags, GDPR) |
| Passcode | 4 | Currently active — input component, feature flags |
| Profile | 4 | Profile settings, security, view-only mode |
| GDPR / Consent | 3 | Consent screens, usage data, tracker config |
| WAF | 3 | WAF implementation, stale tokens, retry logging |
| Help Center | 3 | Help center flows, entry points |

### Label distribution

| Label | Count |
|---|---|
| iOS | 11 |
| Graduation | 5 |
| account_recovery | 4 |
| Android | 2 |
| passcode | 2 |
| csa_graduation_18 | 1 |
| mobile-core | 1 |

### Project distribution

| Project | Count |
|---|---|
| PE (Platform Engineering) | 38 |
| PTECH (Platform Tech) | 10 |
| PQ (Platform Quality) | 2 |

---

## Strengths & Patterns

### Core strengths
1. **iOS specialist** — 92% of tickets involve iOS work (marked with the apple emoji). Deep familiarity with Swift/iOS SDK patterns.
2. **Login & authentication flows** — Extensive work on login screens, account selectors, device pairing, and account recovery. Understands the full auth lifecycle.
3. **Bug crushing velocity** — 40% of tickets are bugs. Fastest turnarounds are on translation fixes, tracking events, and localization (0-1 day cycle). Comfortable with rapid bug triage and fixes.
4. **Cross-cutting concerns** — Has touched WAF, GDPR consent, help center, and profile settings. Not siloed into a single feature area.
5. **Discovery capability** — Has done RFC/Discovery work (e.g., `[CPF][ProfileReadOnlyView] RFC: View only flag`), showing ability to scope and define work, not just execute.

### Work patterns
- **Burst completions:** Feb 2026 saw 9 tickets closed (mostly login/account recovery bugs in a batch on Feb 10), suggesting focused sprint pushes.
- **Currently active on Passcode:** PTECH-32391 (feature flags setup, QA Passed), PTECH-34246 (passcode input component, In Progress), PTECH-34121 (In Progress) — already onboarded to the passcode initiative.
- **Platform breadth:** Has worked across Graduation, GDPR, WAF, Help Center, and Login — comfortable navigating different areas of the platform codebase.

---

## Status of Current Work

| Ticket | Status | Summary |
|---|---|---|
| PTECH-34246 | In Progress | Passcode input component (iOS) |
| PTECH-34121 | In Progress | Passcode-related task |
| PTECH-32391 | QA Passed | Feature flags setup (iOS + Android) |
| PE-124332 | In Progress | Not all accounts shown in account selector |
| PE-86179 | In Progress | Remove cash account field and migrate to new API |

---

## Recommendation for Passcode Swimlane

### Best fit: **1. Foundational** (passcode input component, validation rules, duplicate PIN screen)

**Rationale:**
- Pedro is **already actively building the passcode input component** (PTECH-34246) and has completed the feature flags setup (PTECH-32391). He has momentum and context on the foundational layer.
- His profile shows strength in **UI component work on iOS** — building screens, adjusting layouts, handling keyboard interactions (see PE-123997, PE-124003). This maps directly to the input component and duplicate PIN screen.
- His **bug-fixing speed** (40% of tickets are bugs, many resolved in 1-4 days) means he can iterate quickly on validation edge cases.

### Secondary fit: **2. Login placement** (integrate new login flow)

**Rationale:**
- Deep history with login flows (PE-123875, PE-124142, PE-124459, PE-63449). He understands the existing login architecture intimately.
- Has worked on login hints, account selectors, and phone number confirmation — all adjacent to where passcode would integrate into login.

### Avoid: **5. Verification** and **6. Observability**

- His ticket history shows minimal backend/infrastructure work. Verification (PSD2, transfers) and observability (logging pipelines, breadcrumbs) lean more backend/infra and would underutilize his iOS UI strengths.

---

## Appendix: All Completed Tickets (sorted by resolution date)

| Ticket | Type | Resolved | Created | Labels | Summary |
|---|---|---|---|---|---|
| PE-123637 | Tech Story | 2026-03-05 | 2026-01-22 | account_recovery | Update help center flow destinations |
| PE-124471 | Bug | 2026-03-05 | 2026-02-27 | - | Adjust selfie intro screen and add help center |
| PE-124469 | Bug | 2026-03-05 | 2026-02-27 | iOS | Remove subtitle in phone number confirmation dialog |
| PE-124459 | Bug | 2026-02-26 | 2026-02-25 | - | Login takes a long time on 4.2610 |
| PE-124220 | Bug | 2026-02-10 | 2026-02-06 | account_recovery | Fix account selector dismiss behavior |
| PE-124214 | Bug | 2026-02-10 | 2026-02-06 | - | Phone number confirmation not shown from Account selector |
| PE-124142 | Bug | 2026-02-10 | 2026-02-03 | - | Update login hints after any type of login |
| PE-123997 | Bug | 2026-02-10 | 2026-01-29 | - | Fix keyboard not reopening after dismissing bottom sheet |
| PE-123875 | Bug | 2026-02-10 | 2026-01-27 | - | [Login Screens] Adjust frontend for iOS |
| PE-123874 | Bug | 2026-02-10 | 2026-01-27 | - | [Account List] List is cleared after phone number change |
| PE-123673 | Task | 2026-02-05 | 2026-01-22 | - | Fix logged in bottom sheet icon |
| PE-123635 | Tech Story | 2026-02-05 | 2026-01-22 | - | Create new help center flow entry points |
| PE-120399 | Sub-task | 2025-12-15 | 2025-11-26 | Graduation | [P1] Omit editable features from "view-only" mode |
| PE-121330 | Task | 2025-12-11 | 2025-12-08 | - | iOS Add logs to failed WAF retries |
| PE-119348 | Task | 2025-12-02 | 2025-11-12 | Graduation | Create Mapper Repository for accountPairs topic |
| PE-119343 | Task | 2025-11-27 | 2025-11-12 | Graduation | Implement profileAccessType in relationship APIs |
| PE-119114 | Discovery | 2025-11-13 | 2025-11-10 | Graduation | [CPF][ProfileReadOnlyView] RFC: View only flag |
| PE-116457 | Bug | 2025-11-11 | 2025-10-15 | - | iOS Fix stale WAF tokens |
| PE-116089 | Sub-task | 2025-10-27 | 2025-10-12 | - | Add new Usage Data Consents screen |
| PE-116088 | Sub-task | 2025-10-27 | 2025-10-12 | - | Implement new GDPR consent config screen |
| PE-113154 | Tech Story | 2025-10-10 | 2025-09-10 | - | Implement WAF in the mobile app |
| PE-86170 | Tech Story | 2025-10-06 | 2024-11-14 | - | Remove tax related fields and migrate to new APIs |
| PE-63449 | Bug | 2025-10-14 | 2024-02-08 | mobile-core | Login: Next button moves when changing country code |
| PE-114140 | Bug | 2025-10-01 | - | - | (early Oct resolution) |
| PE-106499 | Bug | 2025-09-09 | 2025-07-03 | - | Update Amplify FaceLiveness SDK to version 1.4.2 |
| PE-112461 | Sub-task | 2025-09-09 | 2025-09-09 | - | Adjust translations for account recovery flow |
| PE-111202 | Task | 2025-09-03 | 2025-09-03 | - | Create tracking events |
| PE-113527 | Sub-task | 2025-09-10 | 2025-09-09 | - | Add missing pairDeviceConfirmationScreenViewed event |
| PE-109721 | Sub-task | 2025-08-27 | 2025-08-26 | - | Update localization keys in pair device screen |
| PE-100948 | Bug | 2025-08-20 | 2025-05-05 | - | User can not select different area code during account recovery |
| PE-102332 | Bug | 2025-08-20 | 2025-04-30 | - | Account Closure screen shown instead of chat |

> Additional older tickets omitted for brevity. Full data available in Jira.
