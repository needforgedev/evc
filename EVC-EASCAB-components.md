# EVC ↔ EASCAB — Component Scorecard

> **What this is.** A component-by-component scorecard of the **EASCAB 20 components** against
> what is **actually built in EVC today** — judged on **function only**, *not* architecture.
> (So "Supabase monolith vs 20 Docker containers / Kubernetes" is **not** counted as a gap; we
> only ask: *does the component's job exist in EVC?*)
>
> **Companion docs:** [PLAN.md](PLAN.md) (feature tracker) · [EVC-EASCAB.md](EVC-EASCAB.md)
> (full comparison) · [plan(migration).md](plan%28migration%29.md) (migration guide).
>
> **Sources:** *EASCAB Build Scope Brief (Apr 2026)* — the 20 **components** (architecture lens) ·
> ***EASCAB Egypt Functional PRD v1.0* (Junaid, CTO)** — the **functional** requirements (feature
> lens). This doc now scores EVC **both ways**: § "Scorecard" = component lens; § "Functional PRD
> coverage" = feature lens against the PRD's requirement IDs.
>
> **Date:** 2026-06-10.

**Legend:** ✅ done (function works) · 🟡 partial (some of it real) · ⬜ not started

---

## Scorecard — all 20 components

| # | EASCAB component | EVC | Done in EVC | Missing |
|---|---|:--:|---|---|
| 0 | Registry (OS kernel) | ⬜ | — (Supabase *is* the managed runtime) | K8s/etcd/component registry/four-eyes governance — *pure infra* |
| 1 | Authentication | 🟡 | Phone-OTP identity (WhatsApp), roles rider/driver/admin, JWT sessions, RLS, **reinstall account recovery** | biometrics, TOTP, device binding, on-device face recognition |
| 2 | Audit Engine | 🟡 | `trip_events` (status change + actor + time), doc-review trail (`reviewed_by`) | platform-wide **immutable append-only** log |
| 3 | Regional Config | 🟡 | `pricing` + `ride_tiers` (rates served from DB, not hardcoded) | currency/tax/phone/language/region still hardcoded; no global↔regional tiers |
| 4 | Notification | 🟡 | WhatsApp OTP delivery (edge fn) | push (FCM/APNs), in-app, SMS fallback, SOS priority |
| 5 | API Puzzle (gateway) | ⬜ | — (edge fn calls Vonage directly) | single mediated external-call gateway |
| 6 | FAKKA / payments | 🟡 | `payments` recorded (amount/VAT/tip/**discount**), method selector | real gateway **capture**, instruction queue, idempotency |
| 7 | **Marketplace (match/dispatch)** | ✅ | `request_ride` → `dispatch_trip` (**range- + tier-aware**, nearest) → offer → accept/decline → full trip lifecycle, realtime | universal multi-use-case (CS / charging-slot), batched optimization |
| 8 | Asset Pool | 🟡 | `vehicles` (model/plate/battery/range/status/**tier**/ownership), `charging_stations` (DEWA), charging status | doc-expiry, maintenance state, soft-delete, utilization |
| 9 | Human Pool | 🟡 | driver + rider profiles, onboarding, **docs (KYC-lite)** + admin approval, ratings (+ tags), acceptance rate, online/offline | tiered/dual KYC, nightly **grade** engine, specialized pools (CS / ops / Pinc) |
| 10 | Contract | ⬜ | — | lease / driver / partner agreement lifecycle |
| 11 | Financial Tx | 🟡 | payments on completion, **driver earnings** (flat 85%), CO₂ | revenue **splits / royalty**, SOAs, atomic multi-party, capture |
| 12 | Report Template | 🟡 | admin **KPIs**, live map, analytics views (earnings / CO₂ / demand) | Superset, SOAs, investor / partner reports |
| 13 | Mathematics Room | 🟡 | real fare `(base + km + min) × multiplier`, VAT, **promo discount**, CO₂ (+ client mirror `EvcPricing`) | **versioned / replayable formula library**, single calc service |
| 14 | AI Engine | ⬜ | — | forecasting / NLP / vision |
| 15 | Compliance | 🟡 | manual doc approve / reject | expiry tracking, **tiered 60/30/14/7-day alerts**, auto-remove |
| 16 | Config Wizard | ⬜ | — | guided <30-min regional setup |
| 17 | Feature Builder | ⬜ | — | the capstone (assemble features by config) |
| 18 | Update Intelligence | ⬜ | — | Renovate + AI risk scoring |
| 19 | Language Engine | ⬜ | — | i18n, **Arabic + RTL** |

---

## Tally

- ✅ **Done: 1** — #7 Marketplace (the ride match / dispatch engine, fully working).
- 🟡 **Partial: 10** — #1 Auth, #2 Audit, #3 Regional Config, #4 Notification, #6 Payments,
  #8 Asset Pool, #9 Human Pool, #11 Financial Tx, #12 Report, #13 Mathematics Room, #15 Compliance.
- ⬜ **Not started: 9** — #0 Registry, #5 API Puzzle, #10 Contract, #14 AI, #16 Config Wizard,
  #17 Feature Builder, #18 Update Intelligence, #19 Language *(and #0 is infra-only)*.

---

## Functional PRD coverage (vs *EASCAB Egypt Functional PRD v1.0*)

The PRD defines a **role-aware super-app** = **Rides + Charging + Vehicle Sales** today, with
**wallet / P2P + deliveries + fractional ownership** as regulator-gated future modules — over one
identity, one payment rail (**FAKKA**), one calc engine (**Mathematics Room**), and three surfaces
(Customer app, Captain app, Admin **web** console). **EVC has built — partially — the *Rides*
module, plus charging *discovery* and payment *recording*; the other modules are unbuilt.**

Mapped against the PRD's requirement areas:

| PRD area (req IDs) | EVC | Built in EVC | Missing vs PRD |
|---|:--:|---|---|
| **Actors & roles** (§2) | 🟡 | rider / driver / admin (generic) | Customer **T1/T2** (wallet KYC tiers); **OTR / Pinc / O&O / PRO / Lessee** captain pools; HQ/ops pools; Regional Admin |
| **Rides — lifecycle** (RID-01…06) | 🟡 | request + **upfront estimate** + tracking + **mutual rating** + itemised receipt + history; audited via `trip_events` | multi-stop; **SOS / trip-share / route-deviation**; captain **photo**; **Arabic** receipt; cancellation **fees** |
| **Rides — matching/dispatch** (MAT-01…05) | 🟡 | single-pool nearest + **range- + tier-aware** dispatch | OTR/O&O auto-**split**; **PRO priority + heatmap**; **Pinc** female pool; **destination-triggered premium**; doc-expiry eligibility filter |
| **Rides — fare engine** (FAR-01…03) | 🟡 | `(base + km + min) × tier-mult`, VAT, **promo discount**, min-fare | **distance-band multiplier** (2.5/2.0/1.5×); **RATE 1 / RATE 2** formulas; **5% global royalty**; **versioned/replayable** formulas; waiting-time |
| **OTR operations** (OTR-01…06) | ⬜ | — | 50-vehicle lease pool; **6-h shifts**; handover inspection; **USD-24/day** algorithm; break-even monitoring |
| **O&O operations** (ONO-01…04) | 🟡 | driver-owned vehicles (`ownership`) | Operate Contract; compliance cadence; **PRO** rules; **doc-expiry alerts + auto-removal** |
| **Charging** (CHG-01…08) | 🟡 | station **discovery map** (DEWA) + "I'm charging" status | **session lifecycle**; dual metering (grid/PV); **OCPP**; queue; **idle penalty**; **cross-sell ride**; Meeza discount; Watanya 30% |
| **Vehicle sales** (SAL-01…04) | ⬜ | — | showroom / B2B pipeline; in-app vehicle browsing; Finance-by-Supply |
| **Payments & money** (PAY-01…06) | 🟡 | `payments` recorded (amount / VAT / tip / **discount**), method selector | **FAKKA** capture; payouts/disbursements; refunds/chargebacks; e-invoicing (ETA); **P2P wallet** (CBE-gated) |
| **KYC & compliance** (KYC-01…04) | 🟡 | driver doc upload + **manual admin approval** (audited) | tiered levels (none / soft / **hard-dual** / asset-guarantee); FAKKA financial KYC; **PDPL** residency; Pinc gender data |
| **Admin Console** (ADM-01…10) | 🟡 | approval queue + **doc review**; live map; trips; support; KPIs; **config console — edit rates / tiers / promos / surge, versioned + audited (`config_audit`)** | config **four-eyes + Global floors/ceilings**; **payout approvals**; station mgmt; sales pipeline; **audit viewer**; fraud workflows — *form factor: EVC admin is **native mobile**, PRD wants **web/PWA*** |
| **Cross-cutting** (XCT-01…07) | 🟡 | phone+OTP + JWT sessions, trip audit, support tickets | **Arabic + RTL**; push / in-app / **SMS** + SOS priority; **TOTP (admin)** + device binding; offline resilience; accessibility; Egypt data residency |

**Module rollup**
- 🟡 **Partially built:** Rides · Charging *(discovery only)* · O&O *(ownership only)* · Payments
  *(recording only)* · KYC *(driver docs)* · Admin *(approvals + ops)* · Cross-cutting *(auth + audit)*.
- ⬜ **Not started:** OTR leasing · Vehicle Sales · wallet / P2P · full Charging module.

> **Two things to keep straight:**
> 1. EVC's **tier** (go/comfort/xl/premium) is *not* the PRD's **captain-type** model
>    (OTR / O&O / Pinc / PRO) nor its **RATE 1 / RATE 2** fare model — it's a parallel
>    rider-selected class.
> 2. The PRD's biggest gaps are **business decisions, not EVC code**: the `[OPEN — Q]` cluster
>    (RATE formulas Q-A2, split base Q-A1, distance-multiplier gap Q-A4, VAT treatment Q-A7–A8,
>    USD-24/day FX Q-A10) are blocking inputs to the **Mathematics Room workshop** the brief
>    mandates *before* those fare/economics requirements can be built at all.

### Recent work ↔ PRD sync log

Every EVC change is tracked here against the PRD requirement it serves
(✅ aligned · ⚠️ diverges / partial · 🔵 needs a PRD decision · ➕ extra, no PRD req).
**Convention going forward:** each new build names its PRD req ID(s) here.

| EVC change | PRD req(s) | Sync |
|---|---|---|
| Real WhatsApp OTP + reinstall recovery | XCT-04 | ✅ aligned *(device-binding / TOTP still missing)* |
| Live tracking — driver card + dot + PIN + Call | RID-03 | ⚠️ partial — plate/rating/vehicle ✅; captain **photo** ❌; ETA = estimate; dot = placeholder until real map |
| Itemised VAT receipt | RID-05 | ⚠️ **English only** — PRD wants **AR/EN** |
| Ratings — stars + tags + tip | RID-05 | ✅ aligned (mutual rating; tip = gratuity) |
| Upfront fare estimate | RID-02 | 🔵 estimate-policy **[OPEN Q-B6]** — EVC chose *locked ≈ final*; needs confirm |
| Promo-code discounts | FAR / CHG-05 (discount) | ⚠️ inline, **not** a versioned Math-Room formula (FAR-02); promo codes aren't an explicit PRD fare req |
| Driver **tier** + tier-aware dispatch | MAT / FAR | ⚠️ **DIVERGES** — EVC go/comfort/xl/premium ≠ PRD **RATE 1/2 + OTR/O&O/Pinc/PRO**; reconcile (region-specific?) |
| Admin **config console** + `config_audit` | ADM-03 · #2 Audit | ⚠️ versioned + audited ✅; **four-eyes + Global floors/ceilings** ❌ |
| Saved places | — | ➕ EVC UX extra (not a PRD req) |

> **Decisions needed to fully sync** (PRD author = Junaid):
> - **Fare/tier model:** keep EVC service tiers (go/comfort/xl/premium) for Dubai while Egypt uses
>   **RATE 1/2 + captain types** (region-specific — likely *yes*), or unify the model?
> - **Q-B6:** upfront fare = **locked** (EVC today) or metered-final?
> - **Q-A7:** VAT treatment (EVC = 5% UAE; Egypt TBD).
> - **ADM-03:** add **four-eyes approval + Global floors/ceilings** to the config console?
> - **RID-05 / XCT-03:** Arabic receipt + **RTL** (the localization milestone).

---

## Pure-architecture differences (NOT missing features)

These EVC↔EASCAB gaps are **structural / infra**, not absent functionality. EVC delivers the same
user-facing outcome a *different way* — a **modular monolith on managed Supabase** instead of 20
self-hosted microservices. Per the Implementation Plan's own *"modular monolith first"* stance,
these are **deliberate choices, not deficits**: read them as "N/A for a monolith," not "to-do."

### Components that are pure architecture (#0, #5, #18)

| # | EASCAB component | What it really is | EVC equivalent |
|---|---|---|---|
| 0 | Registry | Kubernetes + etcd orchestration, component registry, Deployment Manager, four-eyes governance | **Managed Supabase** is the runtime — no orchestration layer to build |
| 5 | API Puzzle Engine | Kong as the single gateway mediating *all* external calls (rate-limit, anti-cascade) | Edge functions call externals (Vonage) directly; Supabase is the implicit gateway |
| 18 | Update Intelligence | Renovate + AI risk-scoring + sequential multi-region deploy with rollback | Manual `pub` / `melos` dependency management |

### Cross-cutting architectural attributes (span *every* component)

- **Microservice split** — 20 components, each in its own **encrypted Docker container**, talking
  only via defined interfaces → EVC: one **modular monolith** (shared `packages/` + one Postgres
  schema with RLS).
- **Self-hosted stack** (Kubernetes · etcd · FastAPI · Postgres · Redis · Kong · Celery) → EVC:
  **Supabase** (managed Postgres + Auth + Realtime + Storage + Edge Functions).
- **Instance-per-region + data residency** (no raw data crosses borders) + **Global↔Regional admin**
  hierarchy → EVC: single project, single admin scope today.
- **Container encryption** as the IP-protection mechanism → EVC: standard repo.
- **"Universal template"** abstraction (one Marketplace / Asset / Human / Contract / Report engine
  instantiated per use-case via config) → EVC: purpose-built ride-hailing implementations.

> **Net:** of the 20, the **architecture-only** components are exactly **#0, #5, #18**. Everything
> else on the scorecard is a **functional** capability (present, partial, or missing) — those are
> the real build items; the architecture-only ones are infra/ops decisions, not product features.

---

## Read on it

EVC has effectively built **the ride-hailing spine** of EASCAB:

- **Marketplace (#7) is the one fully-done component.**
- The components a ride **touches** — **Auth (#1), Human Pool (#9), Asset Pool (#8), Financial Tx
  (#11), Mathematics Room (#13), Report (#12), Regional-Config rates (#3)** — are each **partially
  real**.
- What's **untouched** is the **platform/OS layer** (#0 Registry, #16 Config Wizard, #17 Feature
  Builder, #18 Update Intelligence, #5 API Puzzle) and the **non-ride domains** (#10 Contract /
  leasing, #14 AI, full #15 Compliance, #19 Language).

**Recently advanced** (this iteration): **Mathematics Room (#13)** gained real promo-discount math ·
**Marketplace (#7)** gained tier-aware dispatch · **Human/Asset Pool (#8/#9)** gained the driver
service tier · **Regional Config (#3) + Audit (#2)** gained the **admin config console**
(editable rates/tiers/promos/surge with a `config_audit` trail). *(See the PRD sync log above for
how each maps to PRD requirement IDs.)*

> Caveat: EVC is the **ride-hailing slice**, so naturally the ride components score highest. The
> EASCAB-grade versions (versioned formula library, universal templates, multi-region config,
> KYC grades, revenue splits) remain the larger build — see [EVC-EASCAB.md](EVC-EASCAB.md) and
> [plan(migration).md](plan%28migration%29.md). EASCAB itself is on hold while EVC features are the focus.
