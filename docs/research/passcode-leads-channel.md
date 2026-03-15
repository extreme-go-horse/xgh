# Passcode Leads Channel Report

**Channel:** #passcode-leads (C095RGE3HPY)
**Source:** Slack channel history, complete read on 2026-03-15

---

## 1. CHANNEL OVERVIEW

| Field | Value |
|-------|-------|
| Channel ID | C095RGE3HPY |
| Name | #passcode-leads |
| Created | 2026-02-17 by Andrea Roga |
| Origin | Converted from a conversation between Andrea Roga, Christopher Steinbach, and Nik Shishkin |
| Purpose | Leadership coordination for the Passcode initiative -- staffing, scope, design sign-off, risk management |

### Members (joined dates)

| Person | Joined | Role (inferred) |
|--------|--------|-----------------|
| Andrea Roga | 2026-02-17 (creator) | Lead PO / Product Owner |
| Christopher Steinbach | 2026-02-17 (original conversation) | Engineering (Backend?) |
| Nikita Shishkin | 2026-02-17 (original conversation) | UX Designer |
| Bjorn Schmidt | 2026-03-10 | Engineering Manager |
| Cem Siyok | 2026-03-10 | Technical Lead / Project Coordinator |
| Jan Albers Goettert | 2026-03-10 | Unknown role |
| Carla Sureda | 2026-03-10 | Unknown role |
| Toby Edbrooke | 2026-03-10 | Unknown role |
| Pedro Almeida | 2026-03-12 | iOS Lead |
| Alireza Habibpour | 2026-03-12 | Engineer |

---

## 2. COMPLETE TIMELINE

### Phase 1: Channel Creation and Early Design (Feb 2026)

| Date | Who | What | Category |
|------|-----|------|----------|
| 2026-02-17 13:27 | Andrea Roga | Kicked off acceleration: "we need to accelerate passcode" -- blocked time for review with Valentin (VT = Valentin, management) | **reprioritization** |
| 2026-02-17 16:57 | Nik Shishkin | Shared Mr. Incredible meme (light moment) | -- |
| 2026-02-17 16:58 | Andrea Roga | Reacted to animation | -- |
| 2026-02-18 10:45 | Nik Shishkin | Shared updated Figma designs for Privacy & Security settings with passcode flows | **status-update** |
| 2026-02-18 10:50-11:04 | Andrea / Nik (thread) | Andrea asked Nik to add onboarding (signup) and account recovery flows to designs. Nik pushed back: same component used everywhere, wants logic/copy sign-off before spending hours on all screens. | **scope negotiation** |
| 2026-02-18 15:56 | Nik Shishkin | Shared Figma prototype option for keeping current design while switching to free-text passcode | **status-update** |
| 2026-02-18 18:04 | Christopher Steinbach | Biometric login data: 71.6% of distinct users use biometrics (4.8M out of 6.7M in L28d). 259.8M successful biometric logins in 28 days. | **decision** (data informing scope) |

### Phase 2: Gap (Feb 19 -- Mar 9)

No messages for ~3 weeks. Channel went quiet after initial design review and data gathering.

### Phase 3: Restart and Acceleration (Mar 2026)

| Date | Who | What | Category |
|------|-----|------|----------|
| 2026-03-10 18:09 | Andrea Roga | Shared Google Sheets tracker ("Passcode 2026") | **status-update** |
| 2026-03-10 18:13 | Andrea Roga | **Decision: minimum 6 characters for passcodes.** Agreed with management (VT + TP). Users entering 4-digit PIN get error. Nik to handle UX of error message. | **decision** |
| 2026-03-10 18:20 | Nik Shishkin (thread) | Acknowledged with min6 design mockup | **status-update** |
| 2026-03-10 18:32 | Cem Siyok | Asked about max password length and allowed characters | **blocker** |
| 2026-03-10 18:35 | Nik Shishkin (thread) | Thought max was still 20, no news on changes | **status-update** |
| 2026-03-11 11:30 | Andrea Roga | **Passcode logic sign-off (from VT and TP):** Min 6, Max 100 (auth apps can exceed 20), no forced uppercase or special chars. Asked Nik to clarify in Figma. | **decision** |
| 2026-03-11 11:33 | Cem Siyok | **Staffing and risk plan for 15 April deadline.** Needs 3-4 parallel mobile workstreams (4 ideal, 3 minimum). Keyvan + Alan to lead mobile. AliGol as backup for Patrick (parental leave risk). Liza confirmed. Risks: zero buffer, high coordination overhead, Easter during prod testing, perf review cycle overlap, engineers pulled for bugs. Asked Lucas and Andrea for help closing staffing loop. | **staffing, risk, timeline** |
| 2026-03-11 11:34 | Bjorn Schmidt (thread) | Corrected typo: deadline is April 15th, not 25th | **timeline** |
| 2026-03-11 11:36 | Andrea Roga (thread) | Confirmed: 4 mobile engineers needed (including Alan + Keyvan), AliGol as backup, Liza fully staffed. Will discuss in priorities meeting. Asked Cem to check for upcoming vacations. | **staffing** |
| 2026-03-12 17:41 | Andrea Roga | **Scope update from VT meeting:** (1) Onboarding P1 -- confirmed. (2) Selfie for in-app activity -- wants to discuss replacing passcode for in-app verification with selfie to avoid throwaway work. If so, a different engineering group would handle it. | **decision, scope** |
| 2026-03-12 17:51 | Cem Siyok (thread) | Asked about account recovery status | **risk** |
| 2026-03-12 17:53 | Andrea Roga (thread) | **Account recovery remains P0** | **decision** |
| 2026-03-13 14:16 | Cem Siyok | **New risk: Feature team dependencies.** Multiple teams have PIN validation in their flows (transfers, card, Bizum, etc.). Need to clarify ownership: do we make the changes in their code, or do they? Need to inform teams ASAP so they allocate resources. | **risk, escalation** |
| 2026-03-13 14:43 | Bjorn Schmidt (thread) | Transfer, Card, Bizum are with CashExp (Michele). Trades are with Wealth Exp (Felix). Offered to reach out. | **staffing** |
| 2026-03-13 15:12 | Andrea Roga (thread) | Told Bjorn to wait -- there's a meeting later to address this | **decision** |
| 2026-03-13 16:08 | Cem Siyok (thread) | **Comprehensive list of all in-app PIN entry points** (17 total): SEPA Transfer, Payout, Scheduled Transfer, Add to Apple Pay, View Card PIN, Card Spending Limits, Update Spending Limit, Unlock Card, Click to Pay, PSD2 Account Info, PSD2 Payment, Bizum Send, Bizum Request to Pay, Phone Number Change, Payment Links, Junior Add Money, Junior Withdraw Money | **risk** (scope of migration) |
| 2026-03-13 16:12 | Nik Shishkin (thread) | Acknowledged with screenshot | **status-update** |

---

## 3. DECISIONS MADE IN THIS CHANNEL

### D1: Passcode Character Requirements (2026-03-10 / 2026-03-11)
- **Minimum:** 6 characters (agreed with VT and TP management)
- **Maximum:** 100 characters (auth apps can exceed 20)
- **No forced complexity** -- no required uppercase or special characters
- **Rationale:** If user enters 4-digit PIN in passcode field, show error (min 6)
- **Status:** Signed off by management

### D2: Onboarding is P1 (2026-03-12)
- Confirmed in Andrea's meeting with VT
- Onboarding passcode flow is P1 priority (not P0)

### D3: Account Recovery Remains P0 (2026-03-12)
- When Cem asked about changes to account recovery priority, Andrea confirmed it stays P0

### D4: Selfie May Replace Passcode for In-App Activity (2026-03-12)
- Andrea raised the possibility of using selfie verification for in-app critical actions instead of passcode
- Goal: avoid building passcode verification for in-app and then throwing it away when selfie is introduced
- If selfie path is chosen, a different group of engineers would work on it
- **Status:** To be discussed (meeting scheduled for 2026-03-13)

### D5: Staffing Plan for April 15 Deadline (2026-03-11)
- 3-4 parallel mobile workstreams required (4 ideal)
- **Mobile leads:** Keyvan + Alan
- **Remaining engineers:** sourced from CP or onboarding team
- **Backup:** AliGol for Patrick (parental leave risk)
- **Liza:** confirmed and fully staffed
- Andrea to finalize in priorities meeting

### D6: Feature Team Ownership TBD (2026-03-13)
- 17 in-app PIN entry points across multiple feature teams (CashExp, Wealth Exp, etc.)
- Ownership question unresolved: do passcode team make changes or do feature teams?
- Andrea delayed Bjorn's outreach -- meeting planned to decide

---

## 4. ESCALATIONS AND RISKS

### R1: Zero Development Buffer (2026-03-11)
- **Severity:** High
- **Detail:** Any slip in any workstream directly impacts the April 15 deadline
- **Raised by:** Cem Siyok

### R2: Easter + Perf Review Collision (2026-03-11)
- **Severity:** Medium
- **Detail:** Easter falls during prod testing phase; performance review cycle starts simultaneously
- **Raised by:** Cem Siyok

### R3: Patrick Parental Leave (2026-03-11)
- **Severity:** Medium
- **Detail:** Patrick could go on parental leave at any point
- **Mitigation:** AliGol designated as backup
- **Raised by:** Cem Siyok

### R4: Engineers Pulled for Bugs/CRs (2026-03-11)
- **Severity:** Medium
- **Detail:** Multiple open projects mean mobile engineers could be reassigned at any time
- **Raised by:** Cem Siyok

### R5: Feature Team Dependencies (2026-03-13)
- **Severity:** High
- **Detail:** 17 in-app entry points across multiple feature teams (CashExp, Wealth Exp) need migration
- **Ownership:** Unresolved -- affects whether passcode team absorbs the work or feature teams do
- **Raised by:** Cem Siyok

### R6: Selfie vs. Passcode Throwaway Work Risk (2026-03-12)
- **Severity:** Medium-High
- **Detail:** If selfie verification replaces passcode for in-app activity, all passcode in-app work would be wasted
- **Raised by:** Andrea Roga

---

## 5. PEOPLE AND ROLES

| Person | Slack ID | Role |
|--------|----------|------|
| **Andrea Roga** | U05NEJJLGJ0 | Lead Product Owner -- drives scope, priority, management alignment (VT/TP) |
| **Cem Siyok** | U03ME8T65RU | Technical Lead / Project Coordinator -- staffing plans, risk identification, technical scope |
| **Bjorn Schmidt** | U01CNBDDV3M | Engineering Manager -- cross-team coordination (CashExp, Wealth Exp) |
| **Nikita Shishkin** | U089MKQ1RPH | UX Designer -- Figma designs, passcode flows, UI decisions |
| **Christopher Steinbach** | U019VCLG2SW | Engineer (likely Backend) -- data analysis, biometric login metrics |
| **Pedro Almeida** | U08L9EYLV1T | iOS Lead -- joined 2026-03-12 |
| **Alireza Habibpour** | U04L03E8VN2 | Engineer -- joined 2026-03-12 |
| **Jan Albers Goettert** | U02L3B53X16 | Unknown -- joined 2026-03-10 |
| **Carla Sureda** | U0A09P4EY90 | Unknown -- joined 2026-03-10 |
| **Toby Edbrooke** | U0A99S4FZ5K | Unknown -- joined 2026-03-10 |

### Referenced but not in channel
| Person | Slack ID | Context |
|--------|----------|---------|
| Keyvan | U03ELEFN6N6 | Mobile lead for passcode workstream |
| Alan | U03Q3M0AH7Z | Mobile lead for passcode workstream |
| AliGol | U05UQ979GFL | Backup for Patrick (parental leave) |
| Liza | U05QLFAF928 | Confirmed staffed on project |
| Lucas | U09SV36MLSZ | Asked to help close staffing loop |
| Patrick | -- | At risk of parental leave |
| Michele | -- | CashExp lead (Transfer, Card, Bizum) |
| Felix | -- | Wealth Exp lead (Trades) |
| VT (Valentin) | -- | Management -- signs off on scope/priority |
| TP | -- | Management -- signs off on scope/priority |

---

## Key Observations

1. **The 3-week gap (Feb 19 -- Mar 9)** aligns with the hypothesis that the project was paused and restarted. The channel was created Feb 17 for initial design work, then went quiet until the March restart.

2. **The selfie discussion (D4) is the biggest open question.** If management decides selfie replaces passcode for in-app verification, the scope of the passcode project shrinks significantly but a new selfie workstream emerges.

3. **Pedro joined late (Mar 12)** -- two days after the major staffing/risk/scope discussions. The staffing plan (D5) references Keyvan and Alan as mobile leads but does not mention Pedro, suggesting his iOS lead role may have been assigned after these discussions.

4. **Feature team dependencies (R5) are the newest and potentially largest risk.** 17 entry points across at least 2 other engineering groups is a significant coordination burden that was not in the original scope.
