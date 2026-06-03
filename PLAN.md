# EVC — Project Plan & Progress Tracker

> Living checklist for the EVC electric-cab platform (Rider + Driver + Admin on a shared backend).
> See [docs/APP_CONCEPT.md](docs/APP_CONCEPT.md) for the full product concept.
>
> **Legend:** `[ ]` todo · `[~]` in progress · `[x]` done · `[!]` blocked
> Mark steps as you go and keep the **Status** line at the top of each phase current.

---

## Progress snapshot — 2026-06-03

**Where we are:** backend is **live** and all three apps have **real authentication + real account data**. Registration and the driver-approval loop work end-to-end **in-app**. **Trips are still mock** — that's the next milestone.

- ✅ **Monorepo** — pub workspace, melos, shared lint. All three build to APKs: `dev.needforge.evc{rider,driver,admin}`.
- ✅ **Backend live** — schema + RLS + trip-lifecycle RPCs + realtime + analytics views applied to the Supabase project. Creds injected per app via `--dart-define-from-file=.env`.
- ✅ **Auth (real)** — dev-OTP scheme (any number + fixed code **7464**, role-scoped synthetic email under the hood → real JWT + RLS) for Rider & Driver; **email/password** for Admin (provisioned in the Supabase dashboard). Sessions persist → no re-login.
- ✅ **Rider (real)** — register (phone → name → 7464) → real `profiles`; Account + ride history read live data.
- ✅ **Driver (real)** — register (phone → details → docs → 7464) → real `profiles`/`vehicles`/`driver_details`(pending)/doc metadata; Account, battery/range, charging toggle and earnings all live; **Go online gated on `active`**.
- ✅ **Admin (real)** — email/password login + role guard; **approval queue, drivers, trips (cancel), live map, fleet, support, overview KPIs** all read/write live data via RLS + RPCs.
- ✅ **Loop closed in-app** — register driver → shows **Pending** in Admin → **Approve** → driver can go online. No SQL needed.
- ⏭️ **Next:** **real trips** — Rider `request_ride` → Driver realtime accept/advance/complete → earnings, history and the live map light up across all three apps.

**Still mock / pending:** trips (book → dispatch → drive → earn), Admin Pricing/Finance/Analytics screens, real Google Maps, real SMS OTP (Twilio), push notifications, document storage bucket.

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
- [~] Wire `core` Supabase client + repositories — *auth + account/admin reads done; **trip repositories next***
- [ ] Set up push notifications (FCM/APNs) plumbing

### 0.4 App shells
- [x] `apps/rider` boots, themed, **real auth + session persistence**
- [x] `apps/driver` boots, themed, **real auth + session persistence**
- [x] `apps/admin` boots, themed, **real auth + session persistence**

**Exit criteria:** All three apps build, share `core`/`ui_kit`, and a user can sign in via the shared backend. ✅

---

## Phase 1 — Rider MVP

**Status:** Auth + account **real** ✅ · booking → trip still mock ⏳ · **Goal:** A rider can book → get matched → track → complete → pay → rate, end to end.

### 1.1 Onboarding
- [x] Phone → name → OTP (7464) → **real `profiles` row + session** (no re-login)
- [~] Saved places (Home / Work / custom) — *mock (saved_places table exists, not wired)*

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
- [x] Ride history — **real** (reads completed `trips`; empty-state for new riders)
- [x] Account screen — **real** name/phone/rating/trips/CO₂ + sign out

**Exit criteria:** A real rider can complete a paid trip on a device against the backend. *(Account real; booking → `request_ride` is the next step.)*

---

## Phase 2 — Driver MVP

**Status:** Registration + account/charging/earnings **real** ✅ · receiving/fulfilling trips still mock ⏳ · **Goal:** Drivers fulfill rides created by the Rider app — closing the loop on the shared backend.

### 2.1 Onboarding & compliance
- [x] Register (phone → details → docs → 7464) → **real `vehicles` + `driver_details`(pending) + doc metadata** (no bucket yet)
- [x] Verification states — **real**: pending until **Admin approves** (`admin_set_driver_status`); **Go online gated on `active`**
- [x] Vehicle profile (EV model/plate/battery/range/ownership) — **real**

### 2.2 Going online & receiving rides
- [x] Online/offline toggle — **real** (`driver_set_online` RPC)
- [~] Location streaming — *default coord sent on go-online; live GPS (geolocator) TBD*
- [ ] Incoming ride request (accept/decline) — *needs real `request_ride` + realtime (mock removed)*

### 2.3 Trip lifecycle
- [ ] Turn-by-turn navigation — *needs real trip + maps*
- [ ] Arrived → Start → Complete flow — *RPCs exist (`advance_trip`/`complete_trip`); not yet wired to UI*
- [~] Contact rider (call/chat) — *UI buttons only*

### 2.4 Earnings
- [x] Earnings dashboard (today/week/month) — **real** (`driver_earnings_view`; zero until trips complete)
- [x] Acceptance rate, rating, charging map + "I'm charging" — **real**

**Exit criteria:** Rider request → Driver accepts → trip completes → both sides settle, fully on the shared backend. *(Accounts real; the request→accept→complete loop is the next step.)*

---

## Phase 3 — Admin MVP

**Status:** **Real** ✅ (login, approvals, trips, fleet, support, KPIs) · Pricing/Finance/Analytics still config ⏳ · **Goal:** Ops can oversee and intervene in both sides of the network.

- [x] Admin auth + RBAC — **real** email/password login + **role guard** (non-admins rejected); admins provisioned in Supabase dashboard; RLS enforces scope
- [x] Driver approval queue — **real** (`profiles`/`driver_details`); approve/reject/suspend/reactivate via `admin_set_driver_status`
- [~] User management — *drivers real; rider management TBD*
- [x] Live ops map — **real** fleet markers (`driver_locations`) + ongoing trips; demand hotspots still illustrative
- [x] Trip inspection + intervention — **real** trips; **cancel** via `cancel_trip` RPC (reassign/refund still stubs)
- [x] Support/dispute view — **real** `support_tickets`
- [x] Overview KPIs — **real** (active trips, active drivers, completed, revenue, pending)

**Exit criteria:** A driver can only operate after Admin approval ✅, and ops can monitor + intervene in live trips *(intervention real; live trips appear once trips are wired)*.

---

## Phase 4 — EV Differentiators

**Status:** Charging + battery/range **real** on driver side ✅ · range-aware dispatch authored, not yet exercised ⏳ · **Goal:** The features that make this an *EV* platform, not just a cab app.

- [x] Driver battery/range — **real** (from `vehicles`, set at registration); manual input / telematics TBD
- [~] Range-aware dispatch — *`dispatch_trip` RPC enforces `range_km >= distance`; not exercised until real trips*
- [x] Charging-station map (DEWA) — **real** stations from `charging_stations` (distance-sorted)
- [x] "I'm charging" driver status — **real** (flips `vehicles.status` → charging + offline)
- [~] Charging-break / range-awareness hint — *static hint*
- [~] Rider "battery-aware assurance" indicator — *mock chip (real once dispatch is wired)*
- [~] "CO₂ saved vs. petrol" badge (rider) + sustainability metric (admin) — *rider mock; per-trip `co2_saved_kg` computed in `request_ride`/views*

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
