# Otavio Cordeiro -- Jira Work Profile

> Generated 2026-03-15 from 50 resolved tickets (assignee: 712020:ccfeed86-194f-474d-8fc0-d71c82b7e95b)

---

## Throughput

| Window | Tickets Resolved |
|--------|-----------------|
| Last 30 days (Feb 13 -- Mar 15) | 21 |
| Last 60 days (Jan 14 -- Mar 15) | 22 |
| Last 90 days (Dec 15 -- Mar 15) | 22 |
| Oct -- Dec 2025 | 22 |

**Monthly breakdown:**

| Month | Resolved |
|-------|----------|
| 2025-09 | 2 |
| 2025-10 | 5 |
| 2025-11 | 7 |
| 2025-12 | 10 |
| 2026-03 | 20 |

Note: The spike in March 2026 (20 tickets) suggests a bulk resolution event -- possibly closing out long-running Device Intelligence subtasks and AFCFLO items that had been "Ready For QA" for months.

**Cycle time (created to resolved):**

| Type | Avg | Median | Count |
|------|-----|--------|-------|
| Task | 42d | 19d | 27 |
| Sub-task | 28d | 36d | 4 |
| Subtask | 199d | 264d | 8 |
| Bug | 373d | 404d | 5 |

The **median Task cycle of 19 days** is the most meaningful metric -- many older Subtask/Bug items appear to have languished in QA or backlog before bulk-resolution.

**Story points:** No story points recorded on any ticket (customfield_10016 = null across the board). The team likely does not use SP-based estimation.

---

## Ticket Type Affinity

### Primary domain: iOS Device Intelligence (15 tickets)

Otavio is the sole owner of the **Device Intelligence** module on iOS (PTECH-6491 epic). He built it end-to-end:
- Created the module structure (`DeviceIntelligence Module`, `CoreMotionService`, `DeviceIntelligenceManager`, `NetworkService`, `LogService`, `TrackerService`, `FeatureFlag`)
- Added data collection (screen-based, motion, battery separation, on-demand)
- Integrated GrowthBook for session-based configuration
- Migrated from WebSocket to HTTP transport
- Added App-Originated Call Detection (investigation + implementation)

### Secondary domain: Anti-Financial-Crime Flows (AFCFLO) -- 12 tickets

- Transfer list / rejected transfer handling
- Push notification routing to transfer details
- Account details display + native share sheet
- Screen-sharing detection events + risk-assessment routing
- Source of Funds (SoF) survey flows for crypto
- Crypto risk assessment integration
- SoF rejection + quick path UI (Rejection Page, Review Screen, Extend contracts)

### Tertiary: Bug fixes / misc (5 tickets)

- KYC font size fix (same-day turnaround)
- Upload size validation bug
- Loading view transition bug
- Back button navigation fix
- Flaky test fix

---

## Strengths & Patterns

### Where Otavio is fastest
- **Greenfield module creation:** Built the entire Device Intelligence module (7 tasks) in 11 days each
- **Same-day bug fixes:** PE-124584 (KYC font) resolved in <1 day; PTECH-6530 (back button) in 2 days
- **Focused feature work:** When given a well-scoped Task, median 19-day cycle time
- **Module architecture:** Consistently creates clean service layers (Manager, NetworkService, LogService, TrackerService patterns)

### Where tickets take longer
- **Cross-team subtasks (AFCFLO):** 250+ day cycle times suggest these sit in shared backlogs with external dependencies
- **Bugs with low urgency:** Old bugs (upload limit, loading transition) went 400-700+ days before resolution

### Technical profile
- **Platform:** 100% iOS (all 50 tickets carry the iOS label or apple emoji prefix)
- **Seniority signals:** Owns entire modules end-to-end, writes RFCs (PTECH-6292), investigates before implementing (PTECH-9845 -> PTECH-9846), authors proposals (AFCFLO-2527)
- **Security/fraud focus:** Device intelligence, call detection, screen-sharing detection, risk assessment routing -- all anti-fraud infrastructure

---

## Recommendation for Passcode Swimlane

### Best fit: **5. Verification -- sensitive actions (transfers, cards, PSD2, etc.)**

**Rationale:**

1. **Domain overlap:** Otavio already owns the anti-fraud infrastructure layer on iOS (device intelligence, call detection, screen-sharing detection). Verification flows for sensitive actions (transfers, cards, PSD2) are the natural consumer of this infrastructure.

2. **Proven pattern:** His AFCFLO work already touches the transfer flow, risk assessment routing, and SEPA/Bizum/Crypto confirmation paths -- exactly the surfaces where passcode verification gates will be inserted.

3. **Architecture skills:** Verification placement requires inserting passcode checks into multiple existing flows without breaking them. His modular approach (Manager + Service + Flag pattern) is ideal for creating a reusable verification coordinator.

4. **Speed on focused tasks:** Verification subtasks are well-scoped ("add passcode check before transfer confirmation") which matches his sweet spot of 11-19 day median cycle time for Tasks.

### Second-best fit: **6. Observability -- tracking, logging, breadcrumbs**

His Device Intelligence work is essentially observability infrastructure (event collection, logging services, network transport). If the Verification lane is already staffed, he could own the passcode observability layer including attempt tracking, failure logging, and security breadcrumbs.

### Avoid assigning: **1. Foundational** or **2. Login placement**

These require UI component design from scratch (input field, animation, validation UX) which is not where Otavio's history shows strength -- his work is more infrastructure/integration-oriented than UI-forward.
