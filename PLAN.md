# EVC — Project Plan & Progress Tracker

> Living checklist for the EVC electric-cab platform (Rider + Driver + Admin on a shared backend).
> See [docs/APP_CONCEPT.md](docs/APP_CONCEPT.md) for the full product concept.
>
> **Legend:** `[ ]` todo · `[~]` in progress · `[x]` done · `[!]` blocked
> Mark steps as you go and keep the **Status** line at the top of each phase current.

---

## Progress snapshot — 2026-06-02

**Where we are:** the monorepo + shared packages are in place, and **all three apps have complete, navigable UI mocks** running on hardcoded data (no backend yet). Built ahead of the backend to validate the UX for every role.

- ✅ **Monorepo** — pub workspace (`apps/` + `packages/`), melos, shared lint. All three build to APKs: `dev.needforge.evc{rider,driver,admin}`.
- ✅ **Shared packages** — `core` (12 domain models), `ui_kit` (EVC theme + `Co2Badge`), `maps` (shared `PlaceholderMap`). `realtime` is still a stub.
- ✅ **Rider mock** — onboarding → book → match → live-track → pay → rate → history.
- ✅ **Driver mock** — sign-in → approval → go online → accept request → navigate → complete → earnings + charging map.
- ✅ **Admin mock** — overview KPIs, live ops map, driver approvals, trip intervene, fleet/pricing/finance/support/analytics.
- 🛠️ **Backend authored** — Supabase schema + RLS + trip-lifecycle RPCs + realtime + seed live in `supabase/` (not yet applied to a project). See [supabase/README.md](supabase/README.md).
- ⏭️ **Next:** apply the migrations and wire `packages/core` (Supabase client + repositories) so one `trips` row flows Rider → Driver → Admin.

> State = Riverpod (`Notifier`/`NotifierProvider`, no codegen yet). Data is mock; swapping to Supabase-backed repositories should not change the screens.

---

## Decisions Log (resolve before/early in Phase 0)

These shape everything downstream — record the final call and date.

| # | Decision | Options | Choice | Date |
|---|----------|---------|--------|------|
| 1 | Backend | Firebase/Supabase vs. custom API | **Supabase** (Postgres + Auth + Realtime + Storage + Edge Functions, RLS) | 2026-06-02 |
| 2 | App structure | 3 app shells + shared pkgs vs. single app w/ flavors | **3 separate apps + shared packages** (one Supabase DB = single source of truth) | 2026-06-02 |
| 3 | Fleet model | Company-owned / driver-owned / hybrid | **Hybrid** (support both ownership types) | 2026-06-02 |
| 4 | Maps provider | Google Maps vs. Mapbox/MapLibre | **Google Maps now, behind `packages/maps` abstraction** (swap to MapLibre/OSM later) | 2026-06-02 |
| 5 | State management | Riverpod vs. Bloc | **Riverpod** (with `riverpod_generator` + `freezed`); also serves as DI | 2026-06-02 |
| 6 | Admin form factor | Mobile app / Flutter Web / both | **Mobile app** (Flutter Web dashboard can follow later) | 2026-06-02 |
| 7 | Launch scope | Dubai-only vs. multi-emirate-ready | **Dubai first**, region-aware models for later expansion | 2026-06-02 |

---

## Phase 0 — Foundation & Setup

**Status:** In progress (~60%) · **Goal:** A working monorepo with shared packages, auth, and a backend the apps can talk to.

### 0.1 Repo & tooling
- [x] Decide & record items 1–6 in the Decisions Log
- [x] Restructure repo into monorepo (`apps/`, `packages/`) — `backend/` still TBD
- [x] Set up `melos` (pub workspace) for multi-package management
- [x] Configure shared lint rules (`analysis_options.yaml`) across packages
- [ ] Set up CI (format, analyze, test on PR)
- [ ] Add `.env`/config handling per environment (dev/staging/prod)

### 0.2 Shared packages
- [~] `packages/core` — domain models done (Place, RideTier, Trip, DriverProfile, RideRequest, FleetVehicle, AdminTrip, …); **Supabase client + DI still TBD**
- [x] `packages/ui_kit` — theme, colors, typography, base widgets, `Co2Badge`
- [~] `packages/maps` — shared `PlaceholderMap` (mock); **real Google Maps + provider interface TBD**
- [~] `packages/realtime` — placeholder only; client scaffold TBD

### 0.3 Backend foundation  *(schema authored in `supabase/`; not yet applied to a live project)*
- [~] Stand up Supabase project — *migrations + functions + seed written; run `supabase db reset` to apply*
- [x] Define DB schema for core domains (identity, trips, vehicles, payments) + RLS — *`supabase/migrations/`*
- [x] Trip-lifecycle RPCs + range-aware dispatch + realtime publication + analytics views
- [~] Auth: phone OTP (UAE), role model — *`handle_new_user` trigger + role model done; Twilio provider config pending*
- [ ] Wire `core` Supabase client + repositories; health check
- [ ] Set up push notifications (FCM/APNs) plumbing

### 0.4 App shells
- [~] `apps/rider` shell boots & themed (full UI mock); **real auth TBD**
- [~] `apps/driver` shell boots & themed (full UI mock); **real auth TBD**
- [~] `apps/admin` shell boots & themed (full UI mock); **real auth TBD**

**Exit criteria:** All three apps build, share `core`/`ui_kit` ✅ — and a user can sign in via the shared backend ⏳.

---

## Phase 1 — Rider MVP

**Status:** UI mock complete ✅ · backend integration pending ⏳ · **Goal:** A rider can book → get matched → track → complete → pay → rate, end to end.

### 1.1 Onboarding
- [~] Phone OTP login + profile creation — *mock (any code works)*
- [~] Saved places (Home / Work / custom) — *mock*

### 1.2 Booking flow
- [~] Pickup selection (GPS / map pin / search) — *mock search list*
- [~] Destination selection — *mock*
- [~] Ride tiers + fare estimate + ETA + CO₂ badge — *mock (4 tiers: Go/Comfort/XL/Premium)*
- [ ] Confirm & request ride → **trip created on backend** *(UI confirms; no DB write yet)*

### 1.3 Match & track
- [~] Receive driver assignment — *simulated via timers*
- [~] Live driver location + ETA on map — *animated car on PlaceholderMap (mock)*
- [x] Driver/vehicle details card (name, rating, plate, model) — *mock data*
- [~] Trip state updates (enroute → arrived → ongoing → completed) — *client-side state machine*

### 1.4 Payment & post-ride
- [~] Cash + card + Apple Pay + wallet selector — *mock*
- [~] Fare calculation on completion + receipt (VAT-compliant) — *computed client-side*
- [x] Rating + tags + tip — *mock submit*
- [x] Ride history — *mock list*

**Exit criteria:** A real rider can complete a paid trip on a device against the backend. *(UI done; needs Supabase.)*

---

## Phase 2 — Driver MVP

**Status:** UI mock complete ✅ · backend integration pending ⏳ · **Goal:** Drivers fulfill rides created by the Rider app — closing the loop on the shared backend.

### 2.1 Onboarding & compliance
- [~] Document checklist (license, RTA permit, Emirates ID, vehicle reg/insurance) — *mock approval screen, all "verified"*
- [~] Verification status states (pending/approved/rejected) — *gated in Admin approvals (mock)*
- [~] Vehicle profile (EV model) — *mock*

### 2.2 Going online & receiving rides
- [x] Online/offline toggle + availability state — *mock*
- [ ] Location streaming to backend
- [x] Incoming ride request card (pickup, distance, fare, rating) + accept/decline w/ countdown — *mock*

### 2.3 Trip lifecycle
- [~] Turn-by-turn navigation — *map + animated car (mock; no real nav handoff)*
- [x] Arrived → Start → Complete flow — *mock*
- [~] Contact rider (call/chat) — *UI buttons only*

### 2.4 Earnings
- [x] Per-trip earnings + daily summary — *mock*
- [x] Online hours, acceptance rate, rating — *mock*
- [x] Earnings history (today/week/month) + cash out — *mock*

**Exit criteria:** Rider request → Driver accepts → trip completes → both sides settle, fully on the shared backend. *(UI done; needs Supabase.)*

---

## Phase 3 — Admin MVP

**Status:** UI mock complete ✅ · backend + real RBAC pending ⏳ · **Goal:** Ops can oversee and intervene in both sides of the network.

- [~] Admin auth + role-based access — *mock email/password; roles listed, not enforced*
- [x] Driver approval queue (review docs, approve/reject, suspend/reactivate) — *mock, live via Riverpod*
- [~] User management — *drivers done (mock); rider management TBD*
- [x] Live ops map (active drivers + ongoing trips + demand hotspots) — *mock*
- [x] Trip inspection + manual intervention (reassign, cancel, refund) — *mock; cancel updates state*
- [x] Basic support/dispute view — *mock ticket queue*

**Exit criteria:** A driver can only operate after Admin approval, and ops can monitor + intervene in live trips. *(UI done; needs Supabase + RLS to be real.)*

---

## Phase 4 — EV Differentiators

**Status:** Partially represented in mock UI ✅ · real logic pending ⏳ · **Goal:** The features that make this an *EV* platform, not just a cab app.

- [~] Driver battery/range display — *shown (mock); manual input / telematics TBD*
- [ ] Range-aware dispatch (only assign reachable trips) — *needs backend dispatch*
- [~] Charging-station map (DEWA EV Green Charger) — *mock stations on map; real DEWA data TBD*
- [x] "I'm charging" driver status (auto offline → resume) — *mock*
- [~] Charging-break / range-awareness hint — *static hint (mock)*
- [x] Rider "battery-aware assurance" indicator — *mock chip on driver card*
- [x] "CO₂ saved vs. petrol" badge (rider) + sustainability metric (admin) — *mock*

**Exit criteria:** No rider is ever matched to a car that can't complete the trip; charging is a first-class flow for drivers.

---

## Phase 5 — Scale & Polish

**Status:** Not started · **Goal:** Production-grade growth, monetization, and localization.

### 5.1 Pricing & growth
- [ ] Surge pricing by zone/time
- [ ] Promo codes + referral program
- [ ] Driver incentive campaigns
- [ ] Multiple ride tiers (Comfort / XL / Premium)
- [ ] Scheduled / advance bookings

### 5.2 Payments & finance
- [ ] In-app wallet
- [ ] Apple Pay / Google Pay
- [ ] Driver payouts + reconciliation
- [ ] Finance dashboard + VAT reporting (admin)

### 5.3 Safety & trust
- [ ] SOS button + trip/location sharing
- [ ] Trip PIN verification
- [ ] Lost-item reporting
- [ ] Ratings moderation

### 5.4 Localization & analytics
- [ ] Arabic + full RTL support
- [ ] Demand/supply analytics + charging utilization (admin)
- [ ] Retention/cohort dashboards

### 5.5 Launch readiness
- [ ] RTA licensing/compliance validated
- [ ] App Store + Play Store listings (all three apps)
- [ ] Crash reporting + analytics + monitoring
- [ ] Load/performance testing of dispatch + realtime
- [ ] Security review / pen test

**Exit criteria:** Publicly launchable in Dubai with monetization, localization, safety, and compliance in place.

---

## Backlog / Ideas (not yet scheduled)

- [ ] Loyalty / subscription tier for frequent riders
- [ ] Corporate accounts / business billing
- [ ] Telematics integration for real-time battery data
- [ ] Multi-emirate / GCC expansion
- [ ] Driver community / training hub
