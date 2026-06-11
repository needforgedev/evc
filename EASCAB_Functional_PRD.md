**EASCAB EGYPT**

**Functional Product Requirements**

*The complete functional definition of the EASCAB Egypt super-app — rides, charging, and vehicle sales today; deliveries and instant P2P payments as regulated future modules. Functional scope only: no phasing, timelines, or budgets.*

**Prepared by:** Junaid — CTO, acting Chief Product Architect

**For:** Mohamed Essam — CEO, and the EASCAB build team

**Sources:** Egypt Regional Configuration Brief (May 2026\) · Egypt Features sheet · Build Scope Brief (Apr 2026\)

**Companion:** EASCAB Business Requirements Questionnaire (Q-IDs cross-referenced throughout)

**Status:** v1.0 draft — assumptions marked \[ASSUMPTION\], client decisions marked \[OPEN → Q-ref\]

*Confidential — internal working document*

**SECTION 1**

# **Product definition & principles**

EASCAB Egypt is a **role-aware super-app** operating an integrated EV-mobility ecosystem: ride-hailing on a mixed company-leased (OTR) and driver-owned (O\&O) fleet, public EV charging, and electric-vehicle sales — with deliveries and instant P2P payments as future modules gated on Egyptian regulatory licensing (CBE e-money). One platform, one identity system, one payment rail (FAKKA), one calculation engine (Mathematics Room), three application surfaces.

**Design principles.** (1) The customer never sees fleet contract types — OTR and O\&O vehicles dispatch from one pool and the platform applies the correct economics automatically. (2) Every monetary figure is computed by the Mathematics Room from versioned formulas — nothing is calculated in an app. (3) Every state change is audited immutably. (4) Arabic and English are first-class from day one, with full RTL. (5) All Egypt operational data stays in Egypt (PDPL 2020).

| Regulatory gates carried in this PRD Instant P2P wallet transfers and consumer balance-holding require CBE e-money licensing or a sponsoring PSP; deliveries introduce courier-labour and goods-liability regimes; fractional vehicle ownership is FRA-gated. These appear in this document as defined future modules with their gates named — they are not silent features. → Q-H7, Q-J6 |
| :---- |

**SECTION 2**

# **Actors & roles**

| Actor | KYC | Surface | Definition |
| :---- | :---- | :---- | :---- |
| Customer — Tier 1 | None | Mobile | Rides \+ charging without wallet. Payment method \[OPEN → Q-B10: cash / external card\]. |
| Customer — Tier 2 | Full \+ FAKKA Meeza | Mobile | Full wallet features, Meeza discounts on rides and charging. |
| OTR Captain | Hard (dual: FAKKA \+ EASCAB) | Mobile | Drives EASCAB-leased vehicle on 6-hour shifts. Zero vehicle cost. |
| Pinc Captain | Hard (dual) | Mobile | Verified female OTR captain pool; matched to Pinc requests only. |
| O\&O Owner / PRO | Hard (dual) | Mobile | Driver-owned vehicle. PRO tier adds priority dispatch \+ heatmap. |
| Lessee | Hard \+ asset guarantee | Mobile | OTR captains under lease, enhanced KYC. |
| Sales | Soft | Admin web | Showroom & B2B vehicle-sales pipeline. |
| Customer Service (T1/T2) | Soft | Admin web | Ticket resolution & escalation. Web-only by decision \[OPEN → Q-J2\]. |
| OTR Operator | Hard | Admin web | Shift pool management, vehicle handovers, break-even monitoring. |
| Service / Charging / Sales / CS Ops | Soft | Admin web | HQ oversight roles per the configuration sheet. |
| Regional Admin | Hard | Admin web | Configuration within Global floors/ceilings; approvals; user-role assignment. |

**SECTION 3**

# **Application surfaces**

* **APP-01**  Customer App (iOS/Android): rides, charging, vehicle browsing, wallet (Tier 2), profile, support.

* **APP-02**  Captain App (iOS/Android): shift booking (OTR), trip offers and navigation, earnings, vehicle handover, charging access, heatmap (PRO).

* **APP-03**  Admin Console as a responsive web app / PWA: all operational roles, role-aware modules (Section 12). No native admin app.

* **APP-04**  All surfaces consume the same APIs; the super app is role-aware — interface assignment follows the Human Pool, not a separate binary.

**SECTION 4**

# **Rides**

## **4.1 Trip lifecycle**

Canonical states: requested → matching → offered → accepted → arriving → arrived → in-trip → completed → fare-computed → settled. Terminal branches: cancelled-by-customer, cancelled-by-captain, no-match, disputed. Every transition is audited with actor, device, and timestamp.

* **RID-01**  A customer requests a ride with pickup, destination, and optional stops \[ASSUMPTION: multi-stop supported → Q-B8\].

* **RID-02**  The platform returns an upfront fare estimate before request confirmation; the estimate policy (locked upfront fare vs. metered final) is \[OPEN → Q-B6\].

* **RID-03**  Live captain tracking, ETA, captain identity (photo, plate, rating) shown from acceptance onward.

* **RID-04**  In-trip safety: SOS button with priority-tier notification routing, trip-share link, route deviation visibility.

* **RID-05**  Post-trip: mutual rating (customer ↔ captain), itemised receipt in AR/EN, trip history.

* **RID-06**  Cancellation rules and fees per state are \[OPEN → Q-B4\]; fee calculation, like all money, is a Mathematics Room formula.

## **4.2 Matching & dispatch**

* **MAT-01**  OTR and O\&O vehicles dispatch from a single pool; the customer never sees the contract type; the platform applies the correct split automatically.

* **MAT-02**  O\&O PRO captains receive priority dispatch and heatmap access.

* **MAT-03**  Premium fares (RATE 2\) auto-trigger by destination type; the destination taxonomy and trigger list are \[OPEN → Q-B5\].

* **MAT-04**  Pinc: a separate assignment pool, never customer-selectable. Appears only when a verified female OTR captain is nearby AND the requesting profile is female-verified. Always RATE 2\. Gender verification method for both sides is \[OPEN → Q-C1–C2\]; fallback when no Pinc captain is available is \[OPEN → Q-C3\].

* **MAT-05**  Eligibility filter before any offer: KYC valid, documents unexpired, vehicle compliant, captain on-shift (OTR) or online (O\&O). The Compliance Engine removes lapsed entities from pools automatically.

## **4.3 Fare engine (Mathematics Room inputs)**

Fare parameters from the Egypt configuration: **Start-trip base fare** (present in the configuration sheet, absent from the brief — reconciled here as a required parameter), **KM rate**, **Minutes rate**, and a **distance-band multiplier** (\<10km \= 2.5×, \<20km \= 2.0×, \<30km \= 1.5×, \>40km \= 1.0×). RATE 1 (standard) and RATE 2 (premium) are named formulas whose exact expressions are nowhere defined in the source material.

| Defects this PRD inherits and refuses to guess on (1) The 30–40km multiplier band is undefined → Q-A4. (2) RATE 1 / RATE 2 formula expressions are undefined → Q-A2. (3) Whether captain/platform percentages apply to gross or to the post-royalty 95% changes every payout → Q-A1. (4) VAT treatment and merchant-of-record are absent from the entire brief → Q-A7–A8. These are blocking inputs to the Mathematics Room workshop the brief itself mandates. |
| :---- |

### **Revenue splits (as supplied — base ambiguity unresolved → Q-A1)**

| Captain type | Rate tier | Captain | Platform | Notes |
| :---- | :---- | :---- | :---- | :---- |
| OTR Driver | RATE 1 | 35% | 60% | Net platform \= 60% − USD 24/day |
| Pinc (ladies only) | RATE 2 | 35% | 60% | Female captain \+ female customer only |
| Premium | RATE 2 | 35% | 60% | Auto-trigger by destination |
| O\&O Owner | RATE 1 | 75% | 20% | Pure platform commission |
| O\&O PRO | RATE 2 | 70% | 25% | Priority dispatch \+ heatmap |

* **FAR-01**  5% Global royalty is deducted from gross fare first, on every OTR and O\&O trip, hard-coded, remitted to EASCAB Global monthly \[remittance currency and mechanics OPEN → Q-A9\].

* **FAR-02**  Every fare records its formula version and inputs; historical recalculation is always possible.

* **FAR-03**  Minimum fare, rounding rules, and waiting-time charges are \[OPEN → Q-A5, Q-B9\].

**SECTION 5**

# **OTR operations (Own-To-Rent)**

* **OTR-01**  EASCAB operates 50 company-owned vehicles as the anchor OTR pool; lease, maintenance, insurance, and registration are EASCAB obligations; the captain bears zero vehicle cost.

* **OTR-02**  Captains book 6-hour shifts; shift scheduling rules (advance booking, max shifts/day, no-show handling) are \[OPEN → Q-D1, Q-D7\].

* **OTR-03**  Vehicle handover at shift boundaries includes a digital inspection (photos, charge level, damage flags) signed by both outgoing and incoming parties \[ASSUMPTION — process detail → Q-D2\].

* **OTR-04**  USD 24/day per OTR vehicle (USD 1.00/hour × 24h) is collected from the Egypt 60% platform pool — never charged to the captain directly. Components per the brief: Vehicle Growth Fund EGP 547/day (retained, never distributed), maintenance EGP 100, insurance EGP 67, charging EGP 75, OTR operation revenue EGP 474 (at EGP 52.62/USD).

* **OTR-05**  FX mechanics for the USD-denominated collection — rate source, capture timing, who bears intra-period movement — are \[OPEN → Q-A10\]. Behaviour when a vehicle's daily pool contribution is below USD 24 is \[OPEN → Q-D3\].

* **OTR-06**  OTR Operators monitor per-vehicle break-even in the Admin Console; threshold actions (alerts, reallocation, retirement) are \[OPEN → Q-D4\].

**SECTION 6**

# **O\&O operations (Owner-Operated)**

* **ONO-01**  Drivers operate their own or bank-financed vehicles under an Operate Contract; maintenance, insurance, and registration are the driver's obligations, verified by the Compliance Engine on a recurring cadence \[cadence OPEN → Q-E3\].

* **ONO-02**  Vehicle eligibility criteria — EV-only or mixed, age, model whitelist — are \[OPEN → Q-E1\].

* **ONO-03**  PRO tier qualification (and disqualification) criteria are \[OPEN → Q-E2\].

* **ONO-04**  Document expiry triggers tiered alerts (60/30/14/7 days) and automatic pool removal on lapse.

**SECTION 7**

# **Charging**

The charging network serves the OTR fleet and any public EV owner through the same app. Stations run dual metering — grid meter (Watanya supply cost) and PV meter (solar, near-zero cost, tracked for attribution) — with a configurable per-station end-customer rate. Watanya receives 30% of net charging margin, paid in EGP. OCPP is the station protocol.

* **CHG-01**  Session lifecycle: discover station → reserve/queue → plug-in → authorise → charging (live kWh \+ cost) → complete → grace period → idle penalty if still connected → settle.

* **CHG-02**  Digital queue when all points are occupied: real-time position, push notification on availability; hold-time and skip rules \[OPEN → Q-F6\].

* **CHG-03**  Idle penalty after a 10-minute grace period post-full-charge, with a visible countdown before it starts; the penalty rate and cap are \[OPEN → Q-F5\].

* **CHG-04**  Cross-sell: on session start the platform offers a ride (“Your car will be ready in 47 minutes — need a ride while you wait?”).

* **CHG-05**  FAKKA Meeza holders receive a configurable session discount vs. external cards — the same parameter governs rides and charging.

* **CHG-06**  Public EV users can register for charging-only access; their onboarding tier is \[OPEN → Q-F7\].

* **CHG-07**  Charging margin computation (charge rate − blended grid/PV cost, Watanya 30% of net) is a Mathematics Room formula; PV attribution rules are \[OPEN → Q-F8\]; Watanya settlement cadence and reconciliation are \[OPEN → Q-F9\].

* **CHG-08**  Hardware ownership, installation responsibility, and the OCPP version/vendor matrix are \[OPEN → Q-F1–F3\].

**SECTION 8**

# **Vehicle sales**

* **SAL-01**  Showroom and B2B sales pipeline for NAMMI 06, Mage EV, and eπ 007 under Finance-by-Supply, 12% gross margin, surveillance kit included in COGS.

* **SAL-02**  Pipeline stages: lead → qualified → test drive → offer → contract → delivery → after-sales; managed by the Sales pool in the Admin Console.

* **SAL-03**  Customer-app vehicle browsing/enquiry surface \[ASSUMPTION — confirm → Q-G2\].

* **SAL-04**  Financing, trade-ins, warranty and after-sales scope are \[OPEN → Q-G1, Q-G4\]. The surveillance kit's function and its privacy disclosure to buyers are \[OPEN → Q-G3\] — selling a tracking device inside a consumer vehicle without explicit disclosure is a PDPL exposure.

**SECTION 9**

# **Payments & money movement**

* **PAY-01**  FAKKA is the sole payment rail; the Financial Transaction engine is the only component permitted to instruct it; every instruction is idempotent; no instruction is ever lost or duplicated.

* **PAY-02**  Collections: ride fares, charging sessions, idle penalties, vehicle-sale payments. Disbursements: captain earnings, owner payouts, Watanya share, Global royalty.

* **PAY-03**  Payout schedules and approval thresholds (which amounts require Admin approval) are \[OPEN → Q-H4, Q-K1\].

* **PAY-04**  Refunds, failed-payment retry, and chargeback handling are \[OPEN → Q-H5–H6\].

* **PAY-05**  VAT: computed by the Mathematics Room on every taxable transaction once treatment is confirmed \[OPEN → Q-A7\]; Egyptian e-invoicing (ETA portal) integration is \[OPEN → Q-A8\].

* **PAY-06**  FUTURE / GATED: instant P2P transfers and stored customer balances — defined here as a module boundary only; activation requires CBE e-money licensing or a sponsoring PSP \[→ Q-H7\].

**SECTION 10**

# **KYC & compliance framework**

| Level | Applies to | Content |
| :---- | :---- | :---- |
| None (Tier 1\) | Customers without wallet | Phone verification only. |
| Soft | Sales, CS, HQ ops pools | Identity document \+ role assignment by Regional Admin. |
| Hard (dual) | All captains, OTR operators | FAKKA financial KYC \+ EASCAB operational KYC (licence, background, vehicle docs). |
| Hard \+ asset guarantee | Lessees | Enhanced KYC including asset guarantee for leased vehicles. |
| Tiered (Tier 2\) | Wallet customers | Full KYC \+ FAKKA Meeza card issuance. |

* **KYC-01**  All KYC approvals are human decisions executed in the Admin Console with full audit; auto-approval is not permitted.

* **KYC-02**  Document types per pool, background-check provider, and approval SLAs are \[OPEN → Q-I1, Q-K2\].

* **KYC-03**  Gender data for Pinc is sensitive personal data under PDPL; its lawful basis, collection, and storage are \[OPEN → Q-C1, Q-I4\].

* **KYC-04**  PDPL: consent capture, retention schedules, subject-access handling, and strict Egypt data residency (ETIT hosting; no raw data crosses to Global/UAE — aggregates only).

**SECTION 11**

# **Admin Console (web app / PWA)**

One role-aware console, modules visible per Human Pool role:

* **ADM-01**  KYC queue: review, approve/reject with reason, request-more-info; SLA timers; full audit.

* **ADM-02**  Payout approvals: pending-disbursement queue with thresholds and a four-eyes rule on high-value items \[matrix OPEN → Q-K1\].

* **ADM-03**  Configuration console: rates, multipliers, discounts, penalty parameters — editable within Global floors/ceilings, every change versioned, audited, and four-eyes approved.

* **ADM-04**  Fleet management: vehicle registry, status, documents, maintenance scheduling, handover records, break-even dashboards.

* **ADM-05**  Station management: charger status (OCPP), meter readings, per-station rates, queue monitoring, fault tickets.

* **ADM-06**  CS console: omnichannel tickets (messages/calls), escalation tiers, canned responses, trip/session context panel.

* **ADM-07**  Sales pipeline module for the Sales pool (Section 8).

* **ADM-08**  Dashboards & reports: Superset-fed operational KPIs, driver SOAs, station performance, consolidated summaries upward to Global (aggregates only).

* **ADM-09**  Audit viewer: read-only, filterable, immutable record of who did what, when, from which device.

* **ADM-10**  Fraud & incident workflows: GPS-spoof flags, account takeover response, trip-anomaly review \[playbook OPEN → Q-K4\].

**SECTION 12**

# **Cross-cutting requirements**

* **XCT-01**  Audit: every significant action appended immutably before the action is acknowledged.

* **XCT-02**  Notifications: push, in-app, SMS fallback through one engine; safety notifications (SOS) are priority-tiered and immediate.

* **XCT-03**  Language: Arabic and English at launch, full RTL, per-user preference; all strings, invoices, notifications, and legal documents in both; translations DB-stored and admin-editable.

* **XCT-04**  Security: phone+OTP baseline, device binding, JWT sessions, TOTP for admin roles; any vehicle-device face recognition processes on-device only, with no biometric data transmitted, and is licence-gated before build.

* **XCT-05**  Offline resilience: captain app queues trip events through connectivity gaps; charging sessions tolerate app disconnects (station-side authority).

* **XCT-06**  Accessibility: WCAG-aligned mobile/web surfaces; Arabic numerals/locale formatting throughout.

* **XCT-07**  Hosting: EASCAB Egypt instance on ETIT under SLA \[terms OPEN → Q-J3\]; all operational data resident in Egypt.

**SECTION 13**

# **Customer service model**

CS is web-only by current decision: agents work in the Admin Console; the consumer app is unaffected. Whether consumers can raise tickets inside the super app is an explicitly open configuration decision \[→ Q-J2\].

**SECTION 14**

# **Assumptions & open-decision register**

Every \[OPEN → Q-x\] marker in this document resolves through the companion **Business Requirements Questionnaire**. The highest-consequence cluster — split base (Q-A1), RATE formulas (Q-A2), multiplier gap (Q-A4), VAT and merchant-of-record (Q-A7–A8), and USD 24/day FX mechanics (Q-A10) — are blocking inputs to the Mathematics Room workshop that the configuration brief itself requires before development begins. The architecture open item AD-18 (encrypted containers) is addressed factually in Q-J1 and must be resolved at CEO–CTO level, not absorbed silently into the architecture record.