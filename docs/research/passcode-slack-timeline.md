# Passcode Introduction — Slack Channel Intelligence Report

> Compiled 2026-03-15 from #workgroup-passcode-introduction (C0AH17BFUNL) and #workgroup-passcode-introduction-engineering (C0AJA8C73T5)

---

## Timeline (chronological, oldest first)

| Date | Who | What | Category |
|------|-----|------|----------|
| 2026-02-20 | Christopher Steinbach | Created #workgroup-passcode-introduction channel after kick-off. Next steps: Omar BE discovery, Alireza+Dima check all PIN flows, Chris prepare PRD, Nik work on open design topics | **kickoff** |
| 2026-02-24 | Kola, Lucas | Joined channel. Lucas (from onboarding) mentioned as potential staffing support | staffing |
| 2026-02-25 | Dima Titov | ~20 flows where PIN is involved; most can be changed in batch; effort depends on animation choice. Will recommend cost-efficient animation/transition | **estimate/scope** |
| 2026-02-25 | Patrick Fehling | Asked about UI options in Figma, favours option 1.1 | design |
| 2026-02-26 | Christopher Steinbach | Passcode update: pushed back on current proposal, proposed 6-digit numeric PIN instead. Management reviewing. Discovery kicked off for both options. Discovery ETA: 2026-03-06 | **decision/scope** |
| 2026-02-26 | Alireza | First POC for PIN-to-passcode switch animation in DS gallery | engineering |
| 2026-02-26 | Omar Ansari | Asked who is FE lead for this project | staffing |
| 2026-02-27 | Christopher Steinbach | **Management decision #1**: Go with 4-digit PIN + alphanumeric passcode (NOT 6-digit PIN). Optimise for users who want extra security via password manager. Open question: entry UI (one field or two-view switch) | **decision** |
| 2026-02-27 | Omar Ansari | Created meeting minutes confluence page, asked Dima to add action items | process |
| 2026-03-02 | Dima Titov | Mapped all PIN/Passcode entry points in confluence doc | **scope** |
| 2026-03-02 | Christopher Steinbach | Created 5 EPICs + Kanban board. Label = `passcode` | **ticket slicing** |
| 2026-03-02 | Christopher Steinbach | Shared web designs with Liza. Asked Gaurav about pro trading login impact | scope/dependency |
| 2026-03-02 | Christopher Steinbach | Asked Goran for FinCrime POC | dependency |
| 2026-03-02 | Omar Ansari | Reached out to Gaurav S (FinCrime) about WNM flow, PIN touchpoints, domain events | dependency |
| 2026-03-03 | Christopher Steinbach | Shared first PRD draft | **milestone** |
| 2026-03-03 | Christopher Steinbach | Asked Raghav (IT security) for security review | dependency |
| 2026-03-03 | Christopher Steinbach | Asked Carla (HC) to review help center article for PIN->passcode | scope |
| 2026-03-03 | Christopher Steinbach | Asked Toby (marketing) for copy review + engagement strategy (emails, in-app messages) | scope |
| 2026-03-03 | Christopher Steinbach | Asked Omar+Cem+Patrick+Bjorn to prepare proposal for AR with Thomas by EOW (requested by Valentin & Max) | **milestone** |
| 2026-03-03 | Patrick Fehling | Auth service analysis complete: passcodes of various lengths work with 2 small changes; recommends disallowing emojis | **engineering** |
| 2026-03-04 | Bjorn Schmidt | Scheduled internal AR for next day, will try to get slot with Thomas | milestone |
| 2026-03-04 | Patrick Fehling | Deep-dive on hashing: bcrypt is current (legacy-only recommended); recommends Argon2id | **decision/engineering** |
| 2026-03-04 | Dima Titov | Created #workgroup-passcode-introduction-engineering channel | process |
| 2026-03-04 | Christopher Steinbach | **Management decision #2**: Two entry option (user switches between PIN or passcode). Max length 20 chars. Min length 4 chars. No enforcement of upper/lower/special chars. Apple/Google password suggestion = P0 | **decision** |
| 2026-03-04 | Dima Titov | Asked Alireza+Kola to review ticket composition before refinement at 15:00. Ticket structure: Epics > Tasks (Prep + Placement) > Subtasks per platform | **ticket slicing** |
| 2026-03-05 | Christopher Steinbach | **Vacation handover**: Cem takes over from Chris. Tasks: kick off delivery, prep estimates with Andrea/Bjorn, staffing (onboarding engineers could help). Format discussion open (waiting on Valentin). Management wants 4+ chars capped at 20; proposal is 8+ capped at 64+ | **handover/scope** |
| 2026-03-05 | Dima Titov | Created mobile tasks for P0 tickets. Found that Trading is guarded by biometrics only (no PIN fallback) — investigating | **ticket slicing/finding** |
| 2026-03-05 | Dima Titov | Published RFC on Feature Flagging design (3 flags + deployment order). Feedback requested by Friday noon | **decision/engineering** |
| 2026-03-06 | Cem Siyok | Created epic PTECH-32756, asked Dima+Patrick+Omar+Kola to add tickets | **ticket slicing** |
| 2026-03-06 | Dima Titov + Kola + Alireza | **Mobile estimation complete**: 30 days / 1 engineer / platform. 50-60% parallelizable. Reduction options: skip trade confirmation placement (-3d), reduce PIN-to-passcode animation (-2d). 1 SP = 1 day | **estimate** |
| 2026-03-06 | Cem Siyok | Proposal for handling existing PIN reset: keep backward compatible, deprecate old API, create new credential reset endpoints. New endpoints for gradual rollout | **decision/engineering** |
| 2026-03-06 | Bjorn Schmidt | Proposed merging the two main epics (can't deliver one without the other) | scope |
| 2026-03-09 | Bjorn Schmidt | Asked Cem to update ETA field on PTECH-31628 and PTECH-31204. Shared Chris's old timeline (working backwards from April 1): rollout 30.03, fallback code freeze 24.03, code freeze 17.03, PROD test 13.03, staging test 06.03. Asked: where do we land if we start this week? What if we wait until next Monday (mobile+web OOO this week)? | **milestone/estimate** |
| 2026-03-09 | Cem Siyok | Proposed 3 BE workstreams: (1) auth_account table changes PTECH-32799 (Cem), (2) set passcode endpoint PTECH-32802 (Patrick), (3) new login endpoint PTECH-32797 (Omar) | **assignment/engineering** |
| 2026-03-09 | Patrick Fehling | Published RFC for Change PIN contract + RFC for Argon2 hashing | engineering |
| 2026-03-10 | Alireza | Working on account recovery hotfix, limited availability for passcode | blocker |
| 2026-03-10 | Omar Ansari | Published RFC for v3 login endpoint contract | engineering |
| 2026-03-11 | Cem Siyok | Kickoff message in general channel: defined 5 workstreams for mobile owners to pick. Aggressive timeline, management considers critical. Asked team to proactively flag risks | **kickoff v2/assignment** |
| 2026-03-11 | Patrick Fehling | Asked about kafka topic for PIN change — reuse or new? | engineering |
| 2026-03-11 | Patrick Fehling | Asked about audit log event + "was not me" email for passcode changes | engineering |
| 2026-03-11 | Cem Siyok | Added DB migrations PR to unblock Omar+Patrick | engineering |
| 2026-03-11 | Alireza | Shared Figma prototype demo with Pedro | engineering |
| 2026-03-11 | New joiners | Pedro, Otavio, Madalina, Brenno, Max joined engineering channel | **staffing** |
| 2026-03-12 | Pedro Almeida | Posted consolidated confluence docs list (PRD, 4 RFCs, entry points inventory) | process |
| 2026-03-12 | Cem Siyok | Published RFC for login contract + RFC for change passcode contract. Identified need for 2 new APIs: credential type endpoint + password validation endpoint | **engineering** |
| 2026-03-12 | Pedro Almeida | Set up sync meeting @14:00 for mobile folks to go over Figma flows together (cc Alireza, Patrick, Brenno, Madalina, Otavio) | process |
| 2026-03-12 | Cem Siyok | Called mobile kick-off meeting | milestone |
| 2026-03-12 | Max Oehme | Android: first PR duplicating PIN screen (interfaces only). PR review requests flowing | engineering |
| 2026-03-12 | Alireza | Working on PTECH-32401 (password component) | engineering |
| 2026-03-12 | Yassien | Joined, started reading docs. Asked about FF rollback scenario for users who already switched to passcode | **open question** |
| 2026-03-12 | Patrick Fehling | Posted terminology guide (PIN vs passcode vs password) for new joiners | process |
| 2026-03-12 | Omar Ansari | Asked Patrick about hashing algorithm for login endpoint — should he start with bcrypt? | engineering |
| 2026-03-13 | Alireza | Android password component PR ready for review | engineering |
| 2026-03-13 | Max Oehme | Android: bottomsheet refactoring PR (large), offered live review | engineering |
| 2026-03-13 | Yassien | Starting work on PTECH-32399 (new login endpoints) | engineering |
| 2026-03-13 | Cem Siyok | **Architecture change**: new GET endpoint for credential_type instead of mobile cache. Backend-driven rollout, single source of truth. Will update RFC | **decision/engineering** |
| 2026-03-13 | Yassien | Asked about endpoint DTO: will BE keep `pin` field or change to `passcode`/`password`? | **open question** |
| 2026-03-13 | Liza | Left comments on web designs in Figma for Nik | design |
| 2026-03-12 | Nik Shishkin | Published password font specs. Scaling is logarithmic, depends on screen width | design |
| 2026-03-12 | Nik Shishkin | Proposed adding reveal password button (missing in designs). cc Andrea, Alireza, Pedro | design |

---

## EPICs Created

| ID | Title | Priority |
|----|-------|----------|
| PTECH-31204 | User can set a passcode and login with the complex passcode | P0 |
| PTECH-31628 | New passcode can be used in other in-app flows | P0 |
| PTECH-31631 | Passcode monitoring & alerting | P0 |
| PTECH-31630 | Users cannot circumvent PIN entry | P1 |
| PTECH-31629 | Personal data changes & PIN change are protected by biometrics | P1 |
| PTECH-32756 | (Additional epic created by Cem for delivery tracking) | P0 |

---

## Swimlanes Identified

### Mobile Workstreams (from Cem's kickoff 2026-03-11)

| # | Workstream | Original Owner (Dima's plan) | Current Owner | Estimated Effort | Key Tickets | Status |
|---|-----------|------------------------------|---------------|------------------|-------------|--------|
| 1 | **Foundational work** — new passcode screen + all relevant components | Dima/Alireza | Alireza (Android component), Pedro (iOS input field) | Part of 30d estimate | PTECH-32401 (Android password component) | In progress — PRs open |
| 2 | **New login** — passcode as login method | Dima/Kola | Yassien (Android, PTECH-32399) | Part of 30d estimate | PTECH-32399 | Starting |
| 3 | **Passcode setup from profile** — replacing PIN update flow | Dima/Kola | Unassigned for iOS | Part of 30d estimate | — | Not started |
| 4 | **Passcode verification** — for sensitive actions (money transfers) | Dima/Kola | Unassigned | Part of 30d estimate | — | Not started |
| 5 | **Passcode reset** — account recovery (new + old flows) | Dima/Kola | Unassigned | Part of 30d estimate | — | Not started |

### Backend Workstreams (from Cem 2026-03-09)

| # | Workstream | Owner | Key Ticket | Status |
|---|-----------|-------|------------|--------|
| 1 | Auth account table changes (new columns) | Cem Siyok | PTECH-32799 | DB migration PR merged |
| 2 | Set passcode endpoint (active customers) | Patrick Fehling | PTECH-32802 | In progress |
| 3 | New login endpoint (v3) | Omar Ansari | PTECH-32797 | In progress |

### Additional BE Work Identified Later

- Credential type endpoint (GET credential_type + allowed_credential_types) — Cem
- Password validation endpoint (returns 200 or bad request) — Cem
- Argon2id hashing migration — Patrick (RFC published)

---

## Estimates Found

| Date | Who | What | Estimate |
|------|-----|------|----------|
| 2026-03-06 | Dima + Kola + Alireza | Mobile total (all flows, per platform) | **30 days / 1 engineer / platform** |
| 2026-03-06 | Dima + Kola + Alireza | Parallelization potential | 50-60% |
| 2026-03-06 | Dima + Kola + Alireza | Reduction: skip trade confirmation placement | -3 days |
| 2026-03-06 | Dima + Kola + Alireza | Reduction: reduce PIN-to-passcode animation | -2 days |
| 2026-03-06 | Dima + Kola + Alireza | Story points in tickets (1 SP = 1 day) | See individual tickets |
| 2026-03-09 | Bjorn (relaying Chris's timeline) | Chris's original timeline (working backwards from April 1) | Staging test 06.03, PROD test 13.03, code freeze 17.03, fallback freeze 24.03, rollout 30.03 |

**Note:** Chris's original timeline was acknowledged as unrealistic ("he was aware this does not work in reality"). Bjorn asked for a revised ETA.

---

## Key Decisions

1. **4-digit PIN + alphanumeric passcode** (not 6-digit PIN) — Management, 2026-02-27
2. **Two entry option** — user switches between PIN and passcode views — Management, 2026-03-04
3. **Passcode constraints**: min 4 chars, max 20 chars, no enforcement of upper/lower/special chars — Management, 2026-03-04
4. **Apple/Google password suggestion = P0** — Management, 2026-03-04
5. **No emojis** recommended (Patrick, 2026-03-03)
6. **Backward-compatible PIN reset** + new credential reset endpoints for gradual rollout — Cem+Omar, 2026-03-06
7. **3 feature flags** for rollout (Dima's RFC, 2026-03-05)
8. **Backend-driven credential type** (GET endpoint, not mobile cache) — Cem, 2026-03-13
9. **Argon2id** recommended over bcrypt for new passcode hashing — Patrick, 2026-03-04

---

## Open Questions / Uncertainties

1. **DTO format**: Will BE keep `pin` field or change to `passcode`/`password` with type discriminator? (Yassien, 2026-03-13, unanswered)
2. **FF rollback scenario**: If a user switches to passcode and FF is turned off, what happens? (Yassien, 2026-03-12, unanswered)
3. **Hashing algorithm**: Omar asked if he should start with bcrypt; Patrick recommended Argon2id — final decision unclear
4. **Kafka topic**: Reuse existing `customer.auth.fct.change-pin.v1` or create new? (Patrick, 2026-03-11, unanswered)
5. **Audit log event**: Reuse existing PIN change event or new one for passcode? (Patrick, 2026-03-11, unanswered)
6. **"Was not me" email**: Apply to passcode changes? (Patrick, 2026-03-11, unanswered)
7. **Account recovery flow**: How does user enter it? Button on PIN screen? (Max Oehme, 2026-03-12, unanswered)
8. **Password font scaling**: Logarithmic, screen-width dependent — implementation details TBD (Nik, 2026-03-12)
9. **Reveal password button**: Nik proposed adding it (missing in designs) — awaiting Andrea's feedback (2026-03-12)
10. **Pro Trading login**: Gaurav asked if he or passcode team handles changes — unresolved
11. **FinCrime dependencies**: Omar reached out to Gaurav S — no visible follow-up in channel
12. **Umlauts/special chars**: Patrick asked Chris about allowing umlauts — management said no enforcement, but explicit allow/deny list not confirmed
13. **Passcode min length**: Management said 4, Chris's handover says proposal is 8+ — tension unresolved
14. **Revised ETA**: Bjorn asked for updated timeline on 2026-03-09, no visible answer in channel

---

## People Map

| Person | Role | Joined | Notes |
|--------|------|--------|-------|
| **Christopher Steinbach** | Original PM/Lead | 2026-02-20 | Created channel, PRD, epics. Went on vacation ~2026-03-05, handed over to Cem |
| **Cem Siyok** | BE Lead / Acting PM | 2026-02-20 | Took over from Chris. Drives architecture, RFCs, BE workstreams |
| **Dmitrii (Dima) Titov** | Mobile Lead (original) | 2026-02-20 | Did PIN flow mapping, mobile estimation, ticket slicing, FF RFC |
| **Omar Ansari** | BE Engineer | 2026-02-20 | Working on login endpoint (PTECH-32797), v3 login RFC |
| **Patrick Fehling** | BE Engineer | 2026-02-20 | Auth service analysis, hashing research, change PIN contract, working on PTECH-32802 |
| **Alireza Habibpour** | Android Engineer | 2026-02-20 | Switch animation POC, password component (PTECH-32401), co-estimated with Dima |
| **Kola Emiola** | Mobile Engineer | 2026-02-24 | Co-estimated with Dima, ticket review |
| **Nikita (Nik) Shishkin** | Designer | 2026-02-20 | Figma designs, passcode component specs, password reveal button proposal |
| **Elizaveta (Liza) Shcherbakova** | Web Designer/Engineer | 2026-02-20 | Web designs, Figma comments |
| **Andrea Roga** | Lead PO | 2026-02-20 | Product owner, asked Pedro to fill tracker |
| **Bjorn Schmidt** | Engineering Manager | 2026-03-04 (eng) | Timeline management, ETA tracking, epic merging |
| **Pedro Almeida** | iOS Lead (new) | 2026-03-11 | New mobile lead. Setting up syncs, working on input field, consolidated docs |
| **Brenno Ferrari** | iOS Engineer | 2026-03-11 | Joined for mobile work |
| **Madalina Maletti** | iOS Engineer | 2026-03-11 | Joined for mobile work |
| **Otavio Cordeiro** | iOS Engineer | 2026-03-11 | Joined for mobile work |
| **Max Oehme** | Android Engineer | 2026-03-11 | PIN screen duplication, bottomsheet refactoring PRs |
| **Muhamed Yassien** | Android Engineer | 2026-03-12 | Working on PTECH-32399 (new login endpoints) |
| **Lucas Intveen** | Onboarding team | 2026-02-24 | Mentioned as potential staffing support |
| **Islam Rostom** | Engineer | 2026-02-20 | Joined but no visible contributions in channel |
| **Carla Sureda** | HC/Content | 2026-02-20 | Asked to review help center article |
| **Adnan Waheed** | Engineer | 2026-02-26 | Joined, minimal visible activity |
| **Gaurav Srivastava** | FinCrime | 2026-03-02 | Omar reached out for FinCrime dependencies |
| **Gaurav Swaroop** | Pro Trading | 2026-03-02 | Asked about pro trading login changes |
| **Goran Rukavina** | FinCrime | 2026-03-02 | Chris asked for FinCrime POC |
| **Vitaliy Plastinin** | Unknown | 2026-03-02 | Joined, no visible activity |
| **Victor Kovatsenko** | Unknown | 2026-03-02 | Joined, no visible activity |
| **Odett Nagy** | Unknown | 2026-02-20 | Joined, no visible activity |

---

## De-prioritization and Restart

There is **no evidence of a formal de-prioritization** in the Slack channels. The channel was created 2026-02-20 and work has been continuous since. However:

- **2026-02-26**: Chris pushed back on the passcode proposal, proposed simpler 6-digit PIN instead. Management was reviewing.
- **2026-02-27**: Management decided to proceed with passcode (not 6-digit PIN).
- **2026-03-05**: Chris went on vacation, Cem took over. Chris noted "aggressive timeline" and staffing concerns.
- **2026-03-09**: Bjorn shared Chris's original timeline (working backwards from April 1) and noted "he was aware this does not work in reality." Asked for revised ETA. Mobile and web were OOO that week.
- **2026-03-11**: Cem posted a fresh kickoff message, onboarding new mobile engineers (Pedro, Brenno, Madalina, Otavio, Max, Yassien). This is effectively the **restart** with expanded team.

The de-prioritization Pedro mentioned may have occurred before the channel was created (pre-2026-02-20) or in a different channel. The channel history shows the project was in discovery/planning from Feb 20 to Mar 9, then entered active development on Mar 11 with the expanded team.

---

## Confluence Docs Referenced

1. PRD: https://traderepublic.atlassian.net/wiki/spaces/CPF/pages/4151869442/
2. RFC Passcode Enablement: https://traderepublic.atlassian.net/wiki/spaces/CPF/pages/5076025392/
3. RFC Passcode Rollout (3 flags): https://traderepublic.atlassian.net/wiki/spaces/CPF/pages/5082415166/
4. RFC Login v3 Contract: https://traderepublic.atlassian.net/wiki/spaces/CPF/pages/5103747095/
5. RFC Change PIN Contract: https://traderepublic.atlassian.net/wiki/spaces/CPF/pages/5094998469/
6. RFC Argon2 Hashing: https://traderepublic.atlassian.net/wiki/spaces/CPF/pages/5096669354/
7. Auth Service Capabilities: https://traderepublic.atlassian.net/wiki/spaces/CPF/pages/5072551944/
8. PIN/Passcode Entry Points: https://traderepublic.atlassian.net/wiki/spaces/CPF/pages/5067898932/
9. Meeting Minutes: https://traderepublic.atlassian.net/wiki/spaces/CPF/pages/5055381658/
10. Main RFC: https://traderepublic.atlassian.net/wiki/x/MACOLgE
