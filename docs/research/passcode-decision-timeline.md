# Passcode Introduction -- Decision Timeline & Analysis

> Generated 2026-03-15 from exhaustive read of both Slack channels and all threads.
> Sources: #workgroup-passcode-introduction (C0AH17BFUNL), #workgroup-passcode-introduction-engineering (C0AJA8C73T5)

---

## 1. DECISION TIMELINE (chronological, oldest first)

### 2026-02-20 -- Project Kickoff

| Field | Value |
|---|---|
| Date | 2026-02-20 ~17:41 CET |
| Who | Christopher Steinbach (PM) |
| What | Channel created; next steps assigned: Omar (BE discovery), Alireza+Dima (PIN flow audit), Christopher (PRD), Nik (design open topics) |
| How | Management decree (kick-off meeting) |
| Confidence | LOCKED |
| Thread context | No pushback. Reactions: saluting_face, +1 |

### 2026-02-25 -- Animation approach: in-screen, not navigation

| Field | Value |
|---|---|
| Date | 2026-02-25 14:59 CET |
| Who | Nik Shishkin (designer), confirmed by Dima + Alireza + Kola |
| What | PIN-to-passcode transition will be an **in-screen animation**, not a navigation transition. This is cheaper because it isolates the change within the PIN screen. |
| How | Technical discussion + designer confirmation ("No, totally different. Mine is in-screen animation, there is no transition") |
| Confidence | LOCKED |
| Thread context | Alireza proposed reusing an existing navigation animation from the order flow; Nik rejected it. Dima and Alireza agreed in-screen is more affordable. |

### 2026-02-25 -- MVP mocks target: March 6

| Field | Value |
|---|---|
| Date | 2026-02-25 15:04 CET |
| Who | Dima Titov |
| What | "IMO we shell aim to complete an MVP on mocks by 6th March -- after that we have 1w of 0 mobile capacity" |
| How | Uncontested proposal |
| Confidence | LIKELY |
| Thread context | No objection from anyone. |

### 2026-02-26 -- Passcode update: 6-digit PIN pushback sent to management

| Field | Value |
|---|---|
| Date | 2026-02-26 11:01 CET |
| Who | Christopher Steinbach |
| What | Team pushed back on current proposal, proposed 6-digit numeric PIN as simpler alternative. Management reviewing, answer by Friday EOD. Technical discovery kicked off for both options. |
| How | Management escalation |
| Confidence | OPEN (at the time) |
| Thread context | Discovery ETA: 06.03 |

### 2026-02-27 -- MANAGEMENT DECISION: 4-digit PIN + alphanumeric passcode (not 6-digit PIN)

| Field | Value |
|---|---|
| Date | 2026-02-27 17:27 CET |
| Who | Management (communicated by Christopher Steinbach) |
| What | Go with **4-digit PIN AND alphanumeric passcode** (not 6-digit PIN). One passcode to rule them all -- same passcode for login and in-app sensitive actions. UI entry style (one field vs two fields) still TBD. |
| How | Management decree |
| Confidence | LOCKED |
| Thread context | Omar asked about keeping PIN for in-app security while using passcode for login only. Christopher: "this is not an option for them. They want to keep it simple -- one passcode to rule them all." Team reacted with ack, +1, nicee. |

### 2026-03-02 -- EPICs created with priority tiers

| Field | Value |
|---|---|
| Date | 2026-03-02 19:28 CET |
| Who | Christopher Steinbach |
| What | 5 EPICs created: P0: set+login, in-app flows, monitoring. P1: circumvent PIN entry, biometric protection for data changes. |
| How | PM decision |
| Confidence | LOCKED |
| Thread context | Dima asked about ticket structure (subtasks vs linked issues), deferred to standup with Omar. |

### 2026-03-02 -- Entry points mapped: ~20 flows, ~5 core implementations

| Field | Value |
|---|---|
| Date | 2026-03-02 18:23 CET |
| Who | Dima Titov |
| What | Documented all PIN entry points. Key finding: ~20 flows but only ~5 base implementations, so changes are partially centrally managed. Other teams need acknowledgement + manual regression, but no code changes from them. |
| How | Technical analysis, confirmed in thread |
| Confidence | LOCKED |
| Thread context | Christopher confirmed he would reach out to other POs for acknowledgement. |

### 2026-03-03 -- Auth service analysis: passcodes work with 2 small changes

| Field | Value |
|---|---|
| Date | 2026-03-03 17:40 CET |
| Who | Patrick Fehling (BE) |
| What | Analysis complete: with 2 small changes, accounts can use passcodes of various lengths and wide character range. At certain length, passcode gets truncated due to bcrypt 72-byte limit. Recommends no emojis. Account recovery needs further small changes. |
| How | Technical analysis documented in Confluence |
| Confidence | LOCKED |
| Thread context | This led directly to the Argon2id discovery. |

### 2026-03-03 -- Argon2id hashing proposed for passwords

| Field | Value |
|---|---|
| Date | 2026-03-04 13:44 CET (posted as reply to analysis) |
| Who | Patrick Fehling |
| What | bcrypt has 72-byte input limit and is legacy. Proposed Argon2id which has no practical input limit (4GB). Available via Spring Boot. |
| How | Technical proposal backed by OWASP cheat sheet |
| Confidence | LIKELY -- RFC written (Mar 9), no visible rejection, but actual implementation deferred ("let's use bcrypt for now" -- Cem, Mar 12) |
| Thread context | No objection to the *idea*, but implementation was deferred. |

### 2026-03-03 -- Credential type detection: mobile cache vs BE call debate begins

| Field | Value |
|---|---|
| Date | 2026-03-03 14:24-14:48 CET |
| Who | Cem, Dima, Patrick, Christopher |
| What | How does the app know if user has PIN or passcode? Options: (a) mobile cache/file system, (b) BE endpoint, (c) JWT. For post-login: process memory. For pre-login: local storage with PIN fallback on unpaired devices. Patrick raised enumeration attack risk. |
| How | Group discussion in thread |
| Confidence | OPEN at the time -- resolved later on Mar 13 |
| Thread context | Patrick's key insight: "We cannot reveal any information about the account on the login screen... Otherwise we risk enumeration attacks for passcode users." Christopher proposed: paired=correct UI, unpaired=PIN first with switch CTA. |

### 2026-03-03 -- Login UI: paired vs unpaired device behavior

| Field | Value |
|---|---|
| Date | 2026-03-03 15:14 CET |
| Who | Christopher Steinbach |
| What | Paired devices: show correct entry UI. Previously paired: show last successful login type. Unpaired: always show 4-digit PIN first, user can switch via CTA. |
| How | Proposal with +1 reactions, no objection |
| Confidence | LOCKED |
| Thread context | Confirmed by Dima: "previously paired device = device has the Pin/Passcode stored in memory" |

### 2026-03-04 -- MANAGEMENT DECISION: Two-entry UI, 4-20 chars, no complexity enforcement, Apple/Google password suggestion P0

| Field | Value |
|---|---|
| Date | 2026-03-04 14:22 CET |
| Who | Management (communicated by Christopher Steinbach) |
| What | 1. Two-entry option (switch between PIN and passcode). 2. Max 20 chars. 3. Min 4 chars. 4. No enforced upper/lower/special chars. 5. Apple/Google password suggestion is P0. |
| How | Management decree |
| Confidence | LOCKED |
| Thread context | **38 replies** -- extensive debate. Patrick questioned 20-char max (Apple uses 20 as default). Cem proposed ASCII regex for allowed chars. Dima: "every rejection of user keyboard symbol input is a poor UX". Kola pushed Google's recommended set. Final resolution by Christopher (Mar 5 17:00): "let's start with this definition first" (ASCII standard chars). Nik asked to add error notification for unsupported chars. Patrick noted min requirements = just a 4-digit PIN, Christopher confirmed this is expected. |

### 2026-03-04 -- Allowed characters: ASCII standard only, no emojis

| Field | Value |
|---|---|
| Date | 2026-03-05 16:52 - 17:00 CET |
| Who | Patrick (extracted Google recommendation), Christopher (final call) |
| What | ASCII-standard characters only. No accents, no emojis. Nik to add error notification for unsupported characters. |
| How | Discussion converged, Christopher confirmed |
| Confidence | LOCKED |
| Thread context | Part of the 38-reply thread on management decision. Kola raised clipboard paste security concern but no resolution on that. |

### 2026-03-04 -- No paste restriction decided

| Field | Value |
|---|---|
| Date | 2026-03-05 16:36-16:40 CET |
| Who | Patrick vs Kola |
| What | Kola suggested restricting paste for clipboard leakage. Patrick asked "Why would we restrict pasting?" No resolution. |
| How | Unresolved discussion |
| Confidence | OPEN |

### 2026-03-04 -- RFC drafted for AR review

| Field | Value |
|---|---|
| Date | 2026-03-04 15:32 CET |
| Who | Cem Siyok |
| What | RFC for Architecture Review with Thomas. Key debate: should PIN and password be stored in separate columns (for rollback) or reuse the existing pin field? |
| How | RFC + internal review + AR |
| Confidence | LOCKED (separate columns won) |
| Thread context | Bjorn had major concerns about co-existing PIN/passcode. Christopher clarified: user has only 1 valid credential at a time. Cem argued separate columns enable rollback. Bjorn: "I am not saying the idea is not good." Omar flagged rollback risk with mobile cache. Patrick proposed GrowthBook FF for mobile preference. |

### 2026-03-04 -- Engineering channel created

| Field | Value |
|---|---|
| Date | 2026-03-04 13:42 CET |
| Who | Dima Titov |
| What | #workgroup-passcode-introduction-engineering created for technical topics |
| How | Dima's initiative |
| Confidence | LOCKED |

### 2026-03-04 -- Mobile ticket structure: Prep + Placement model

| Field | Value |
|---|---|
| Date | 2026-03-04 13:49 CET |
| Who | Dima Titov |
| What | Ticket structure: 2 types -- Prep (foundational work) and Placement (applying change to entry point groups). Detailed breakdown of all P0 work items. |
| How | Proposed for refinement at 15:00, reactions: eyes, raised_hands |
| Confidence | LOCKED |
| Thread context | Alireza and Kola confirmed. |

### 2026-03-05 -- Christopher goes on vacation, Cem takes over

| Field | Value |
|---|---|
| Date | 2026-03-05 20:21 CET |
| Who | Christopher Steinbach |
| What | Vacation handover. Cem takes over: kick off delivery, estimation alignment with Andrea/Bjorn, staffing. Format discussion still open (min 4 vs 8 chars). Lucas mentioned onboarding engineers could support. |
| How | Explicit handover |
| Confidence | LOCKED |

### 2026-03-05 -- Feature flag design RFC published

| Field | Value |
|---|---|
| Date | 2026-03-05 17:56 CET |
| Who | Dima Titov |
| What | RFC for 3 feature flags + deployment order for passcode rollout. |
| How | RFC published, Christopher approved ("makes sense to me, added some comments") |
| Confidence | LOCKED |

### 2026-03-05 -- Credential reset: new endpoints, old PIN reset backward compatible

| Field | Value |
|---|---|
| Date | 2026-03-06 15:42 CET |
| Who | Cem Siyok (after discovery with Omar) |
| What | Old PIN reset endpoints: no behavioral changes, backward compatible, deprecated. New credential reset endpoints: support both PIN and passcode. Newest client versions use new APIs. Gradual rollout. Changing existing API behavior too risky. |
| How | Proposal with checkmark reactions from Patrick and Kola |
| Confidence | LOCKED |

### 2026-03-06 -- Dima's estimates published: 30d/1 engineer/platform

| Field | Value |
|---|---|
| Date | 2026-03-06 18:07 CET |
| Who | Dima Titov (with Kola and Alireza) |
| What | **30 days including testing, per 1 engineer, per platform. 50-60% parallelizable.** Reduction options: trade confirmation -3d, reduce PIN-to-passcode animation -2d. 1 SP = 1 day. |
| How | Estimation session |
| Confidence | LOCKED (as estimates) |
| Thread context | Checkmark reaction from one person. No visible challenge to the numbers. |

### 2026-03-06 -- Epics: keep separate, different ETAs

| Field | Value |
|---|---|
| Date | 2026-03-06 09:21-09:58 CET |
| Who | Bjorn Schmidt, Dima Titov |
| What | Bjorn wanted to merge PTECH-31204 and PTECH-31628. Dima argued they are different deliverables -- "use passcode in flows" must ship before "set passcode" to handle edge case of old app versions. Agreed to keep separate with different ETAs. |
| How | Discussion, agreement |
| Confidence | LOCKED |

### 2026-03-09 -- Cem's revised timeline: staging Apr 8, rollout Apr 14

| Field | Value |
|---|---|
| Date | 2026-03-09 10:31 CET |
| Who | Cem Siyok (responding to Bjorn) |
| What | Christopher's old timeline (rollout Mar 30) is "definitely ambitious." Mobile estimate: 1 week foundational + 2-3 weeks for flows. Need 2 mobile engineers per platform, else 6 weeks with 1. New realistic timeline: staging test done Apr 8, rollout Apr 14. |
| How | Response to Bjorn's request for ETA update |
| Confidence | LOCKED |
| Thread context | Bjorn reacted with "ack". Christopher's timeline was explicitly called unrealistic. |

### 2026-03-09 -- BE work streams kicked off (offline, weekend work)

| Field | Value |
|---|---|
| Date | 2026-03-09 13:50 CET |
| Who | Cem Siyok |
| What | 3 BE work streams: 1. DB migration (Cem), 2. Set passcode endpoint (Patrick), 3. Login endpoint v3 (Omar). |
| How | Proposal + thumbs up |
| Confidence | LOCKED |

### 2026-03-09 -- Change PIN contract RFC published

| Field | Value |
|---|---|
| Date | 2026-03-09 17:15 CET |
| Who | Patrick Fehling |
| What | RFC for changing PIN contract, includes glossary with terminology clarification. Later renamed "passcode" to "password" in the RFC (Mar 10). |
| How | RFC |
| Confidence | LOCKED |

### 2026-03-11 -- DB migration PR opened, varchar(512) chosen

| Field | Value |
|---|---|
| Date | 2026-03-11 11:10 CET |
| Who | Cem Siyok |
| What | DB migration adding new columns to auth_account table. Patrick wanted `text` type, Cem wanted `varchar(255)`. Compromised at `varchar(512)`. Run against 5M+ records on dev, fast enough. |
| How | PR review discussion, compromise |
| Confidence | LOCKED |
| Thread context | 29-reply thread. Omar confirmed migration safe. Patrick raised concern about future varchar size changes causing table locks. |

### 2026-03-11 -- Cem's welcome message: 5 workstreams, mobile owners pick flows

| Field | Value |
|---|---|
| Date | 2026-03-11 17:08 CET |
| Who | Cem Siyok |
| What | Welcome to expanded team. 5 workstreams: foundational, new login, passcode setup from profile, passcode verification, passcode reset. Mobile owners to pick one each. |
| How | @here announcement |
| Confidence | LOCKED |
| Thread context | Max asked about timeline, Cem shared Google Sheets tracker. Bjorn wants to use Jira tracker instead. |

### 2026-03-11 -- Terminology: "Passcode" is the umbrella, "password" is the alphanumeric variant

| Field | Value |
|---|---|
| Date | 2026-03-11 17:37 CET (in general channel) + 2026-03-10 (in eng channel) |
| Who | Nik Shishkin (designer), confirmed by Patrick |
| What | Passcode = umbrella term (either 4-digit PIN or alphanumeric password). Password = the alphanumeric variant specifically. In code: use "password" for the alphanumeric component. |
| How | Designer recommendation, team realized terminology confusion had existed for weeks |
| Confidence | LOCKED |
| Thread context | Patrick: "Yes we only realized this week that the alphanumeric part is called password." Madalina flagged RFC still had old definition. Patrick confirmed he would update RFC to remove "passcode" in favor of "password" (except glossary). |

### 2026-03-11 -- Timeline/audit log: replace "PIN" with "Passcode" in existing events

| Field | Value |
|---|---|
| Date | 2026-03-11 14:03-18:29 CET |
| Who | Patrick (raised), Cem + Nik (decided) |
| What | Existing timeline event and "was not me" email: just localize, replace "PIN" with "Passcode". No logic change. Tickets created: PTECH-33920 (email), PTECH-33923 (activity log). |
| How | Thread discussion, Jira tickets created |
| Confidence | LOCKED |
| Thread context | Patrick flagged email was missing from Figma (found it later). Nik: "just Passcode, because Passcode is either a 4-digit PIN or a password." Patrick questioned whether product/management understood this terminology. |

### 2026-03-12 -- Hashing algorithm: use bcrypt for now (Argon2id deferred)

| Field | Value |
|---|---|
| Date | 2026-03-12 12:09 CET |
| Who | Cem Siyok |
| What | Omar asked whether to start with bcrypt. Cem: "Let's use bcrypt for now." Argon2id RFC exists but migration deferred. |
| How | Quick decision in thread |
| Confidence | LOCKED (for now, Argon2id likely later) |

### 2026-03-12 -- New login RFC and Change passcode RFC shared with mobile

| Field | Value |
|---|---|
| Date | 2026-03-12 13:23 CET |
| Who | Cem Siyok |
| What | Login v3 RFC + Change PIN contract RFC shared. Bjorn questioned the need for a separate validate endpoint. Cem: FE only checks min/max, BE handles all validation rules for flexibility. |
| How | RFC sharing |
| Confidence | LOCKED |
| Thread context | Patrick listed extensive validation rules from PRD (sequential numbers, repeated chars, common passwords, keyboard patterns, birthdate, name, email prefix, low entropy, must have lower+upper+special). This is a LOT more scope than originally discussed. |

### 2026-03-12 -- TWO new endpoints discovered as needed (credential type + password validation)

| Field | Value |
|---|---|
| Date | 2026-03-12 13:22 CET |
| Who | Cem Siyok |
| What | 1. Authenticated endpoint returning current credentialType. 2. Authenticated endpoint for validating new password against rules. These were NOT in the original scope. |
| How | Cem flagged to Patrick and Omar |
| Confidence | LOCKED |
| Thread context | Patrick pushed back on #1 ("I thought we agreed to handle this on the mobile side only"). Cem insisted: "we can't rely on the mobile cache for PIN change use case." They had a call to resolve. Ultimately resolved on Mar 13. |

### 2026-03-12 -- Patrick's terminology guide: PIN / Password / Passcode

| Field | Value |
|---|---|
| Date | 2026-03-12 14:30 CET |
| Who | Patrick Fehling |
| What | Shared image defining the three fundamental terms. PIN = 4-digit. Password = alphanumeric. Passcode = umbrella term for both. Backend uses "credentials" for passcode. |
| How | Posted with image, 3x raised_hands, +1 |
| Confidence | LOCKED |

### 2026-03-12 -- Password reveal button added to designs

| Field | Value |
|---|---|
| Date | 2026-03-12 19:31 CET |
| Who | Nik Shishkin (designer) |
| What | Adding reveal password button to designs (was missing). Andrea tagged for feedback. |
| How | Designer initiative, reactions: +1 (3), pepelove (2) |
| Confidence | LOCKED |

### 2026-03-12 -- Account recovery entry point added to Figma

| Field | Value |
|---|---|
| Date | 2026-03-12 15:12 CET |
| Who | Nik Shishkin |
| What | Added recovery entry point in Passcodes Figma page after Max asked how users get into Account Recovery flow. |
| How | Designer added after question |
| Confidence | LOCKED |

### 2026-03-13 -- GET /api/v1/auth/account/credentials endpoint decided

| Field | Value |
|---|---|
| Date | 2026-03-13 13:26 CET |
| Who | Cem Siyok |
| What | New endpoint `GET api/v1/auth/account/credentials` returning `credentialType` (PIN or PASSWORD) and `allowedCredentialTypes`. Used ONLY for change passcode flow (not login). For login and other in-app flows: mobile cache + switch option. For web: local storage keyed by last digits of phone number. |
| How | Proposal with +1 reactions (3), discussed in 7-reply thread |
| Confidence | LOCKED |
| Thread context | Yassien suggested FE caching too (performance concern). Alireza suggested BE caching + FE fallback for offline. Cem clarified: endpoint only for change passcode from profile. Login uses mobile cache. Liza confirmed web approach: local storage with partial phone number. |

### 2026-03-13 -- Rollback UX: user falls back to old PIN (no graceful UX)

| Field | Value |
|---|---|
| Date | 2026-03-13 09:44-09:59 CET |
| Who | Alireza, Bjorn, Yassien |
| What | If FF is turned off, users who set passwords revert to their old PIN. If they forgot it, account recovery. Bjorn: "This is a hot potato... users might not expect their old PIN to still work or they might have forgotten it." |
| How | Thread discussion |
| Confidence | LOCKED (acknowledged as a risk, no better solution proposed) |
| Thread context | Yassien suggested BE-driven FF so rollout halt can keep FF ON for already-migrated users. Got +1 but no formal decision. |

### 2026-03-13 -- Yassien identifies need for BE RFC on remaining endpoint DTOs

| Field | Value |
|---|---|
| Date | 2026-03-13 21:00-22:35 CET |
| Who | Muhamed Yassien |
| What | Existing endpoints use `SetPinRequestApiModel(pin: String, deviceKey: String)`. Need RFC for how remaining endpoints will handle the pin/password distinction. Self-answered: existing RFCs suggest similar pattern changes. "Will need a BE RFC for the remaining endpoints next week." |
| How | Self-identified need |
| Confidence | OPEN (need acknowledged, RFC not yet written) |

---

## 2. WORK IN PROGRESS MAP (as of Mar 13, latest messages)

### Backend

| Person | Working on | Last activity | Blockers | PRs |
|---|---|---|---|---|
| **Cem Siyok** | DB migration (PTECH-32799), new auth entity attributes, credential type endpoint design | Mar 13 | None visible | [tr-backend-auth #4154](https://github.com/traderepublic/tr-backend-auth/pull/4154) -- merged |
| **Patrick Fehling** | Set passcode endpoint (PTECH-32802), Change PIN contract RFC | Mar 13 | Was about to add auth entity attributes but Cem beat him to it | None visible |
| **Omar Ansari** | Login endpoint v3 (PTECH-32797), hashing implementation | Mar 12 | Using bcrypt for now (Argon2id deferred) | None visible |

### Android

| Person | Working on | Last activity | Blockers | PRs |
|---|---|---|---|---|
| **Max Oehme** | Duplicating PIN screen, bottom sheet refactoring | Mar 13 | None | [#27323](https://github.com/traderepublic/tr-android/pull/27323) (interfaces), [#27337](https://github.com/traderepublic/tr-android/pull/27337) (duplication + unit tests), [#27342](https://github.com/traderepublic/tr-android/pull/27342) (bottom sheet) |
| **Alireza Habibpour** | Password input component (PTECH-32401), POC animation | Mar 13 | Design specs only finalized Mar 12 | [#27333](https://github.com/traderepublic/tr-android/pull/27333) (password component) |
| **Muhamed Yassien** | New login endpoints ticket (PTECH-32399), reading docs | Mar 13 | OOO Mar 23-30 | None yet (just started Mar 12) |

### iOS

| Person | Working on | Last activity | Blockers | PRs |
|---|---|---|---|---|
| **Pedro Almeida** | Input field component, organized Confluence docs, Figma sync | Mar 13 | Just joined Mar 11, ramping up | None visible |
| **Brenno Ferrari** | (Joined Mar 11) | Mar 11 | Ramping up | None visible |
| **Madalina Maletti** | Reading RFCs, flagging terminology issues | Mar 13 | Ramping up | None visible |
| **Otavio Cordeiro** | (Joined Mar 11) | Mar 11 | Ramping up | None visible |

### Web

| Person | Working on | Last activity | Blockers | PRs |
|---|---|---|---|---|
| **Elizaveta Shcherbakova (Liza)** | Web designs, added web tickets with estimates to epic | Mar 13 | Waiting on Nik for web password font specs (promised EOD Mar 13) | None visible |

### Design

| Person | Working on | Last activity | Blockers | PRs |
|---|---|---|---|---|
| **Nik Shishkin** | Password font specs, reveal button design, web specs, account recovery entry point | Mar 13 | None | N/A |

### Product/Management

| Person | Working on | Last activity | Blockers |
|---|---|---|---|
| **Cem Siyok** (acting PM/tech lead) | Coordination, RFC updates, BE work | Mar 13 | None |
| **Bjorn Schmidt** (engineering manager) | Jira tracker, epic management, RFC review | Mar 13 | Wants to move away from spreadsheet trackers |
| **Christopher Steinbach** (original PM) | On vacation since Mar 6 | Mar 6 | OOO |

---

## 3. PENDING / UNRESOLVED ITEMS

### 3.1 Questions without answers

1. **Kafka topic for passcode change** (Patrick, Mar 11): "Do we use the same [change-pin] topic or a new one?" -- **No response from anyone.**

2. **Paste restriction for passcode field** (Kola, Mar 5): Raised clipboard leakage concern. Patrick asked "Why would we restrict pasting?" -- **Never resolved.**

3. **Pro Trading designs**: Nik notified their designer but "still waiting for estimates" (Feb 27). Gaurav Swaroop looked at designs Mar 5 but ownership of implementation unclear. Christopher asked Gaurav to "push the designs for web" before his OOO. -- **Status unknown.**

4. **IT Security review**: Christopher notified Raghav (Mar 3) about the feature. "We will raise a ticket as usual once we have the RFCs defined." -- **No follow-up visible.**

5. **FinCrime dependencies**: Omar reached out to Gaurav Srivastava (Mar 2). Gaurav said he and Vitaliy "can try to support as much as possible." -- **No further interaction visible.**

6. **Marketing/engagement strategy**: Christopher asked Toby (Mar 3) for copy review + engagement strategy. Toby asked clarifying questions. Christopher answered. -- **No deliverable visible.**

7. **HC article**: Carla Sureda to check existing HC articles and prepare proposal by mid-March. "I will check next week" (Mar 3). -- **No follow-up visible, deadline likely passed.**

8. **Password validation rules scope**: Patrick listed extensive rules from PRD (Mar 12) including sequential numbers, keyboard patterns, birth date, name, email prefix, low entropy, etc. Cem said he would "create a dedicated ticket and update the RFC." -- **Ticket not visibly created yet.**

9. **BE RFC for remaining endpoint DTOs** (Yassien, Mar 13): Self-identified need, planned for next week. -- **Not yet started.**

10. **Jira tracker vs Google Sheets**: Bjorn wants to use Jira Plans tracker (Mar 12). -- **No resolution on which is the source of truth.**

### 3.2 Proposals without explicit agreement

1. **BE-driven feature flag** (Yassien, Mar 13): Suggested BE-driven FF so rollout halt can keep FF ON for already-migrated users. Got +1 but no formal decision or action item.

2. **Argon2id migration**: Patrick wrote RFC (Mar 9), well-researched. Cem said "let's use bcrypt for now" (Mar 12). Migration timing unclear -- is it in scope or deferred to post-launch?

### 3.3 Conflicting opinions never fully settled

1. **Mobile cache vs BE endpoint for credential type**: Patrick initially thought they agreed on mobile-only. Cem insisted on BE endpoint for change passcode flow. They had a call (Mar 12). Cem's proposal won on Mar 13 but with compromise: endpoint only for change passcode, not login.

2. **varchar(512) vs text**: Patrick wanted `text`, Cem wanted bounded `varchar`. Compromised at 512 but Patrick's concern about future table locks if we ever need to change the size was acknowledged but not mitigated.

---

## 4. ESTIMATE RELIABILITY ANALYSIS

### 4.1 The estimates

| Field | Value |
|---|---|
| When made | 2026-03-06 18:07 CET |
| By whom | Dima Titov, with Kola (Android) and Alireza (Android) |
| Scope | All P0 work: foundational + all placements |
| Headline | **30 days / 1 engineer / platform** (including testing) |
| Parallelism | 50-60% can be parallelized |
| Reduction options | Trade confirmation: -3d; Reduce animation: -2d |
| Assumption | 1 SP = 1 day |

### 4.2 Cem's derived timeline (Mar 9)

- With 2 engineers per platform: 1 week foundational + 2-3 weeks for flows
- With 1 engineer: 6 weeks
- Staging test: **Apr 8** | Rollout start: **Apr 14**

### 4.3 Scope included in the estimate

Based on the ticket breakdown Dima posted (Mar 4):
- Feature flag setup
- New endpoint registration
- Passcode input component (UI)
- Passcode validation rules
- Persist user code type in memory
- Duplicate PIN screen
- Login placement
- Change PIN/Passcode placement
- Account Recovery placement
- Onboarding placement
- All sensitive flow placements (transfers, cards, Bizum, PSD2, trade confirmation)
- Monitoring & tracking

### 4.4 Scope ADDED since the estimate

| Item | When added | By whom | Impact |
|---|---|---|---|
| **GET /api/v1/auth/account/credentials endpoint** (new) | Mar 12-13 | Cem | New BE endpoint + mobile integration. Not in original scope. |
| **Password validation endpoint** (new) | Mar 12 | Cem | New BE endpoint for validating password against rules before setting. Not in original scope. |
| **Extensive password validation rules** | Mar 12 | Patrick (from PRD) | Sequential numbers, keyboard patterns, birth date, name, email prefix, low entropy, common passwords -- significant BE work. Unclear if this was in the 30d estimate. |
| **Password reveal button** | Mar 12 | Nik | UI component addition. Small but not zero. |
| **Account recovery entry point in Figma** | Mar 12 | Nik | Was missing from designs, added after Max asked. |
| **Terminology cleanup / RFC updates** | Mar 11-12 | Patrick | Rework across all docs and code naming. |
| **Localization tickets** (PTECH-33920, PTECH-33923) | Mar 11 | Patrick | Email + activity log text changes. |

### 4.5 Scope REMOVED since the estimate

| Item | When removed | By whom | Impact |
|---|---|---|---|
| **Onboarding flow** | Recent (per Pedro's context) | Andrea (PO) | Marked P1 (deferred). This was listed in Dima's ticket breakdown as "Placement: Onboarding." Saves some work but exact days unclear. |

### 4.6 Stated assumptions

1. **1 SP = 1 day** -- explicitly stated
2. **50-60% parallelizable** -- meaning with 2 engineers you do NOT cut time in half, more like 40-50% reduction
3. **2 engineers per platform required** for the 3-4 week timeline
4. Estimate was done by Dima + Kola + Alireza (iOS was NOT represented -- Dima is iOS lead but estimate was done with Android engineers)

### 4.7 Concerns raised about estimates

- **Christopher's old timeline was explicitly called unrealistic** by Cem (Mar 9): "this timeline is definitely ambitious"
- **Cem's revised timeline (Apr 14 rollout) still assumed 2 engineers per platform** -- which we now have (Pedro+Brenno for iOS, though Madalina and Otavio are also there)
- **No visible challenge to the 30d number itself** -- it was presented and accepted

### 4.8 Actual velocity since Mar 11 (when expanded team started)

**Days elapsed**: Mar 11 to Mar 15 = 4 working days (assuming Mar 15 is current)

**What's been done (visible from Slack)**:

*Backend:*
- DB migration written, reviewed, tested on dev with 5M rows, merged (Cem)
- Auth entity attributes added (Cem)
- Login v3 RFC written (Omar)
- Change PIN contract RFC written (Patrick)
- Argon2id RFC written (Patrick)
- Credential type endpoint designed and agreed (Cem)
- Login endpoint implementation started (Omar)
- Set passcode endpoint implementation started (Patrick)

*Android:*
- PIN screen duplicated (interfaces PR merged, logic PR merged) (Max) -- 3 PRs
- Password component PR submitted (Alireza)
- Yassien started reading docs and picked up login endpoints ticket (Mar 13)

*iOS:*
- Pedro started input field component
- Team ramping up (joined Mar 11)

*Web:*
- Liza added web tickets with estimates to epic
- Waiting on design specs

*Design:*
- Password font specs finalized (Nik, Mar 12)
- Reveal button designed (Nik, Mar 12)
- Account recovery entry point added (Nik, Mar 12)

### 4.9 Assessment

**The 30d estimate is likely undercooked for the following reasons:**

1. **It was made before several scope additions**: credential type endpoint, password validation endpoint, extensive validation rules, and password reveal button were all added after the estimate.

2. **iOS was not represented in the estimation session**: Dima led it but only Kola and Alireza (both Android) participated. iOS may have different complexities.

3. **The estimate does not appear to account for**: RFC writing time, cross-team coordination overhead, design iteration cycles (font specs weren't finalized until Mar 12, a week after the estimate), terminology confusion and rework.

4. **Actual throughput so far is hard to measure** because the first 4 days were heavily front-loaded with setup, RFCs, and ramp-up. The "productive" coding window is really just starting.

5. **The 50-60% parallelization claim means** with 2 engineers you'd need ~15-18 working days. From Mar 11 to Apr 14 is 24 working days. That gives ~6 days of buffer, which is thin considering:
   - Yassien is OOO Mar 23-30
   - Design specs are still being finalized
   - New endpoints keep being discovered
   - The validation rules are extensive and not yet ticketed

6. **However, the team is bigger than estimated for**: Dima estimated for 2 engineers/platform. iOS now has Pedro + Brenno + Madalina + Otavio (4 people), Android has Max + Alireza + Yassien (3 people). This could compensate if coordination overhead doesn't eat the gains.

**Bottom line**: The Apr 14 rollout date is achievable but tight. The estimate is directionally correct but did not account for the scope creep that has already happened. Pedro should add 5-7 days of buffer when filling Andrea's tracker, putting realistic rollout at **Apr 21-24** unless scope is cut further.

---

## 5. SCOPE CREEP TRACKER

### Items NOT in original scope but added

| # | Item | When added | Added by | Status | Impact |
|---|---|---|---|---|---|
| 1 | **GET /api/v1/auth/account/credentials** -- new endpoint returning credential type + allowed types | Mar 12-13 | Cem Siyok | Designed, agreed | BE: ~2-3d. Mobile: integration ~1d |
| 2 | **Password validation endpoint** -- validates new password against rules before setting | Mar 12 | Cem Siyok | Proposed, not yet ticketed | BE: ~2-3d (depends on rule complexity). Mobile: integration ~1d |
| 3 | **Extensive password validation rules** -- sequential numbers, keyboard patterns, birth date, name, email prefix, common passwords, low entropy | Mar 12 (surfaced from PRD) | Patrick (from PRD) | Not yet ticketed | BE: ~3-5d. This is significant -- needs a dictionary, pattern matching, PII access |
| 4 | **Argon2id hashing migration** | Mar 4 (proposed), deferred Mar 12 | Patrick Fehling | RFC written, deferred to "later" | BE: ~2-3d when done. Not blocking launch. |
| 5 | **Password reveal button** | Mar 12 | Nik Shishkin | Designed | Mobile: ~0.5-1d per platform |
| 6 | **Localization: email + activity log** | Mar 11 | Patrick | Tickets created (PTECH-33920, PTECH-33923) | ~1d total |
| 7 | **Terminology rework across all RFCs and code** | Mar 10-12 | Patrick, Cem | Ongoing | ~0.5d (already done for docs, code still in progress) |
| 8 | **Account recovery Figma entry point** (was missing) | Mar 12 | Nik (after Max asked) | Done in design | Design-side only, but indicates design wasn't complete |
| 9 | **Web font specs for password** | Mar 13 | Liza requested, Nik delivering | In progress | Blocks web implementation |
| 10 | **BE RFC for remaining endpoint DTOs** | Mar 13 | Yassien | Not yet started, planned next week | Unknown -- could surface more endpoint changes |

### Items REMOVED from scope

| # | Item | When removed | Removed by | Savings |
|---|---|---|---|---|
| 1 | **Onboarding flow** (Placement: Onboarding) | Recent | Andrea (PO) -- marked P1 | ~2-3d per platform (estimate) |

### Net scope change

**Added**: ~10-15 engineering days (across all platforms/BE)
**Removed**: ~2-3 days per platform
**Net**: Approximately **+7-12 days of work** beyond original estimate, partially offset by having more engineers than planned.

---

## Appendix: Key People

| Name | Role | Status |
|---|---|---|
| Christopher Steinbach | Original PM | OOO since Mar 6 (vacation) |
| Cem Siyok | Acting PM / BE tech lead | Active, took over from Christopher |
| Bjorn Schmidt | Engineering Manager | Active, owns Jira tracking |
| Andrea Roga | Product Owner | Active, marked onboarding P1 |
| Dima Titov | Mobile lead (iOS), original estimator | OOO ~Mar 7-10 (vacation mentioned), may be back |
| Patrick Fehling | Backend engineer | Active |
| Omar Ansari | Backend engineer | Active |
| Nik Shishkin | Designer | Active |
| Alireza Habibpour | Android engineer | Active |
| Kola Emiola | Android engineer | Active (less visible recently) |
| Max Oehme | Android engineer | Active, joined Mar 11 |
| Muhamed Yassien | Android engineer | Active, joined Mar 12, OOO Mar 23-30 |
| Pedro Almeida | iOS lead | Active, joined Mar 11 |
| Brenno Ferrari | iOS engineer | Joined Mar 11, ramping up |
| Madalina Maletti | iOS engineer | Joined Mar 11, ramping up |
| Otavio Cordeiro | iOS engineer | Joined Mar 11, ramping up |
| Elizaveta Shcherbakova (Liza) | Web engineer | Active |
| Carla Sureda | HC/Content | Awaiting delivery (mid-March deadline) |
| Toby Edbrooke | Marketing | Awaiting engagement strategy |
| Lucas Intveen | Onboarding team lead | Offered engineers to support |
