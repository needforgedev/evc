# EVC — Project Plan & Progress Tracker

> Living checklist for the EVC electric-cab platform (Rider + Driver + Admin on a shared backend).
> See [docs/APP_CONCEPT.md](docs/APP_CONCEPT.md) for the full product concept.
>
> **Legend:** `[ ]` todo · `[~]` in progress · `[x]` done · `[!]` blocked
> Mark steps as you go and keep the **Status** line at the top of each phase current.

---

## Progress snapshot — 2026-06-04

**Where we are:** backend is **live** and the platform runs a **real end-to-end ride** across all three apps — book → dispatch → accept → drive → complete → settle. Auth, accounts, **document upload/verification**, and the **full trip loop** are real.

- ✅ **Monorepo** — pub workspace, melos, shared lint. All three build to APKs: `dev.needforge.evc{rider,driver,admin}`.
- ✅ **Backend live** — schema + RLS + trip-lifecycle RPCs + realtime + analytics views + Storage applied. Creds injected per app via `--dart-define-from-file=.env`.
- ✅ **Auth (real)** — dev-OTP (any number + fixed **7464**, role-scoped synthetic email → real JWT/RLS) for Rider & Driver; **email/password** for Admin (dashboard-provisioned). Sessions persist → no re-login.
- ✅ **Documents (real)** — private `driver-docs` Storage bucket + RLS; driver uploads each doc individually (**gated** — no dashboard until all uploaded); Admin views the real files + per-doc Approve/Reject.
- ✅ **Real trips (Milestone A)** — Rider `request_ride` → server prices it + **range-aware dispatch** → Driver realtime **offer → accept → arrived → start → complete**; writes `payments`, bumps **driver earnings**, updates **Admin live-map/Trips/KPIs**. CO₂ per trip + fares from the pricing table.
- ✅ **Rider (real)** — register → book → live status → account + ride history live.
- ✅ **Driver (real)** — register → docs → approval → go online → receive/accept/drive/complete jobs → real earnings; charging + battery/range live.
- ✅ **Admin (real)** — login + role guard; approvals, drivers, trips (cancel), live map, fleet, support, KPIs all live.
- ⏭️ **Next:** **Step 3 — rider tracking polish** (driver card, live driver dot, receipt, rider→driver rating); then Milestone C (promos/surge/wallet) & D (admin pricing/analytics/finance real).

**Still mock / pending:** rider live-tracking polish (driver card / receipt / rating), Admin Pricing/Finance/Analytics screens, real Google Maps + device GPS (the moving dot), real SMS OTP (Twilio), push notifications, payments capture/payouts, DEWA live data.

> State = Riverpod (plain `Notifier`, no codegen). Dev OTP **7464** is a dev backdoor (`EvcConfig.devMockOtp`) — replace with real SMS OTP before launch.

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

**Status:** Mostly done (~85%) · **Goal:** A working monorepo with shared packages, auth, and a backend the apps can talk to.

### 0.1 Repo & tooling
- [x] Decide & record items 1–6 in the Decisions Log
- [x] Restructure repo into monorepo (`apps/`, `packages/`, `supabase/`)
- [x] Set up `melos` (pub workspace) for multi-package management
- [x] Configure shared lint rules (`analysis_options.yaml`) across packages
- [ ] Set up CI (format, analyze, test on PR)
- [x] Config handling — per-app `.env` via `--dart-define-from-file` (`EvcConfig`); staging/prod profiles TBD

### 0.2 Shared packages
- [x] `packages/core` — domain models + Supabase client (`EvcSupabase`) + dev-OTP auth (`EvcDevAuth`) + Rider/Driver registration
- [x] `packages/ui_kit` — theme, colors, typography, base widgets, `Co2Badge`
- [~] `packages/maps` — shared `PlaceholderMap` (mock); **real Google Maps + provider interface TBD**
- [~] `packages/realtime` — placeholder; apps use the Supabase client directly for now

### 0.3 Backend foundation  *(applied to the live Supabase project)*
- [x] Stand up Supabase project — schema + functions + seed applied
- [x] Define DB schema for core domains (identity, trips, vehicles, payments) + RLS — *`supabase/migrations/`*
- [x] Trip-lifecycle RPCs + range-aware dispatch + realtime publication + analytics views
- [x] Auth: role model (rider/driver/admin) + dev-OTP (7464) + admin email/password — *real SMS OTP (Twilio) still TBD*
- [x] Wire `core` Supabase client + repositories — auth, account/admin reads, **`EvcTrips`** (request/stream/accept/advance/complete) + Storage
- [ ] Set up push notifications (FCM/APNs) plumbing

### 0.4 App shells
- [x] `apps/rider` boots, themed, **real auth + session persistence**
- [x] `apps/driver` boots, themed, **real auth + session persistence**
- [x] `apps/admin` boots, themed, **real auth + session persistence**

**Exit criteria:** All three apps build, share `core`/`ui_kit`, and a user can sign in via the shared backend. ✅

---

## Phase 1 — Rider MVP

**Status:** Booking → trip **real** ✅ · tracking UI polish pending ⏳ · **Goal:** A rider can book → get matched → track → complete → pay → rate, end to end.

### 1.1 Onboarding
- [x] Phone → name → OTP (7464) → **real `profiles` row + session** (no re-login)
- [~] Saved places (Home / Work / custom) — *mock (saved_places table exists, not wired)*

### 1.2 Booking flow
- [~] Pickup selection — *mock "current location" with real coords; no device GPS yet*
- [~] Destination selection — *mock place list, now with real lat/lng*
- [~] Ride tiers + fare estimate + ETA + CO₂ badge — *mock estimate display (server prices the real fare)*
- [x] Confirm & request ride → **real `trips` row** via `request_ride` (priced + auto-dispatched)

### 1.3 Match & track
- [x] Receive driver assignment — **real** (range-aware `dispatch_trip`)
- [~] Live driver location + ETA on map — *status is real; the moving dot needs device GPS (Step 3 / external)*
- [~] Driver/vehicle details card — *Step 3 (rider tracking polish)*
- [x] Trip state updates (matched → enroute → arrived → ongoing → completed) — **real** (Realtime stream)

### 1.4 Payment & post-ride
- [~] Cash + card + Apple Pay + wallet selector — *passed to `request_ride`; no gateway capture*
- [~] Fare calculation on completion + receipt (VAT-compliant) — *server computes fare+VAT; rider receipt UI = Step 3*
- [~] Rating + tags + tip — *`rate_trip` RPC wired on driver side; rider rating UI = Step 3*
- [x] Ride history — **real** (reads completed `trips`)
- [x] Account screen — **real** name/phone/rating/trips/CO₂ + sign out

**Exit criteria:** A real rider can complete a paid trip on a device against the backend. ✅ *(Loop works; rider tracking/receipt/rating polish = Step 3.)*

---

## Phase 2 — Driver MVP

**Status:** **Real end-to-end** ✅ — drivers receive, accept and fulfil real rides · **Goal:** Drivers fulfill rides created by the Rider app — closing the loop on the shared backend.

### 2.1 Onboarding & compliance
- [x] Register (phone → details → 7464) → **real `vehicles` + `driver_details`(pending)**
- [x] **Document upload** — each doc uploaded individually to the `driver-docs` Storage bucket; **gated** (no dashboard until all uploaded)
- [x] Verification states — **real**: pending until Admin approves docs + account; **Go online gated on `active`**
- [x] Vehicle profile (EV model/plate/battery/range/ownership) — **real**

### 2.2 Going online & receiving rides
- [x] Online/offline toggle — **real** (`driver_set_online` RPC)
- [~] Location streaming — *default coord sent on go-online; live GPS (geolocator) TBD*
- [x] Incoming ride request (accept/decline + 15s countdown) — **real** (Realtime `driverJobStream` → `accept_ride`/`decline_ride`)

### 2.3 Trip lifecycle
- [~] Turn-by-turn navigation — *map + route shown; real nav handoff TBD (maps)*
- [x] Arrived → Start → Complete flow — **real** (`advance_trip`/`complete_trip`; writes `payments`)
- [~] Contact rider (call/chat) — *UI buttons only*

### 2.4 Earnings
- [x] Earnings dashboard (today/week/month) — **real** (`driver_earnings_view`; updates as trips complete)
- [x] Acceptance rate, rating, charging map + "I'm charging" — **real**

**Exit criteria:** Rider request → Driver accepts → trip completes → both sides settle, fully on the shared backend. ✅

---

## Phase 3 — Admin MVP

**Status:** **Real** ✅ (login, approvals, trips, fleet, support, KPIs) · Pricing/Finance/Analytics still config ⏳ · **Goal:** Ops can oversee and intervene in both sides of the network.

- [x] Admin auth + RBAC — **real** email/password login + **role guard** (non-admins rejected); admins provisioned in Supabase dashboard; RLS enforces scope
- [x] Driver approval queue — **real**; **view uploaded documents** (signed URLs) + per-doc Approve/Reject; account approve/suspend via `admin_set_driver_status`
- [~] User management — *drivers real; rider management TBD*
- [x] Live ops map — **real** fleet markers (`driver_locations`) + **real ongoing trips** as they happen; demand hotspots still illustrative
- [x] Trip inspection + intervention — **real** trips (live); **cancel** via `cancel_trip` RPC (reassign/refund still stubs)
- [x] Support/dispute view — **real** `support_tickets`
- [x] Overview KPIs — **real** (active trips, active drivers, completed, **revenue from completed trips**, pending)

**Exit criteria:** A driver can only operate after Admin approval ✅, and ops can monitor + intervene in **live trips** ✅.

---

## Phase 4 — EV Differentiators

**Status:** Charging + battery/range **real**; **range-aware dispatch live** ✅ · **Goal:** The features that make this an *EV* platform, not just a cab app.

- [x] Driver battery/range — **real** (from `vehicles`, set at registration); manual input / telematics TBD
- [x] Range-aware dispatch — **real & exercised** (`dispatch_trip` only matches a driver whose `range_km ≥ trip distance`)
- [x] Charging-station map (DEWA) — **real** stations from `charging_stations` (distance-sorted)
- [x] "I'm charging" driver status — **real** (flips `vehicles.status` → charging + offline)
- [~] Charging-break / range-awareness hint — *static hint*
- [~] Rider "battery-aware assurance" indicator — *Step 3 (rider tracking) will show the matched driver's real range*
- [x] "CO₂ saved vs. petrol" — **real** per-trip `co2_saved_kg` (computed in `request_ride`); shown in ride history + powers `co2_savings_view`

**Exit criteria:** No rider is ever matched to a car that can't complete the trip ✅; charging is a first-class flow for drivers ✅.

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
