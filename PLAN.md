# EVC — Project Plan & Progress Tracker

> Living checklist for the EVC electric-cab platform (Rider + Driver + Admin on a shared backend).
> See [docs/APP_CONCEPT.md](docs/APP_CONCEPT.md) for the full product concept.
>
> **Legend:** `[ ]` todo · `[~]` in progress · `[x]` done · `[!]` blocked
> Mark steps as you go and keep the **Status** line at the top of each phase current.

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

**Status:** Not started · **Goal:** A working monorepo with shared packages, auth, and a backend the apps can talk to.

### 0.1 Repo & tooling
- [ ] Decide & record items 1–6 in the Decisions Log
- [ ] Restructure repo into monorepo (`apps/`, `packages/`, `backend/`)
- [ ] Set up `melos` (or equivalent) for multi-package management
- [ ] Configure shared lint rules (`analysis_options.yaml`) across packages
- [ ] Set up CI (format, analyze, test on PR)
- [ ] Add `.env`/config handling per environment (dev/staging/prod)

### 0.2 Shared packages
- [ ] `packages/core` — data models (User, Trip, Vehicle, Payment), API client, DI
- [ ] `packages/ui_kit` — theme, colors, typography, base widgets, brand assets
- [ ] `packages/maps` — map + location abstraction over chosen provider
- [ ] `packages/realtime` — websocket/trip-state client scaffold

### 0.3 Backend foundation
- [ ] Stand up backend (per Decision #1) with hosting + environments
- [ ] Define DB schema for core domains (identity, trips, vehicles, payments)
- [ ] Auth service: phone OTP (UAE), sessions, role model (rider/driver/admin)
- [ ] Expose base API + health check; wire `core` API client to it
- [ ] Set up push notifications (FCM/APNs) plumbing

### 0.4 App shells
- [ ] `apps/rider` shell boots, themed, hits auth
- [ ] `apps/driver` shell boots, themed, hits auth
- [ ] `apps/admin` shell boots, themed, hits auth

**Exit criteria:** All three apps build, share `core`/`ui_kit`, and a user can sign in via the shared backend.

---

## Phase 1 — Rider MVP

**Status:** Not started · **Goal:** A rider can book → get matched → track → complete → pay → rate, end to end.

### 1.1 Onboarding
- [ ] Phone OTP login + profile creation
- [ ] Saved places (Home / Work / custom)

### 1.2 Booking flow
- [ ] Pickup selection (GPS / map pin / search)
- [ ] Destination selection
- [ ] Single ride tier (EVC Go) with fare estimate + ETA
- [ ] Confirm & request ride → trip created on backend

### 1.3 Match & track
- [ ] Receive driver assignment (simple/manual dispatch ok for now)
- [ ] Live driver location + ETA on map
- [ ] Driver/vehicle details card (name, photo, plate, model)
- [ ] Trip state updates (enroute → arrived → ongoing → completed)

### 1.4 Payment & post-ride
- [ ] Cash + one card method
- [ ] Fare calculation on completion + receipt (VAT-compliant)
- [ ] Rating + tags
- [ ] Ride history

**Exit criteria:** A real rider can complete a paid trip on a device against the backend.

---

## Phase 2 — Driver MVP

**Status:** Not started · **Goal:** Drivers fulfill rides created by the Rider app — closing the loop on the shared backend.

### 2.1 Onboarding & compliance
- [ ] Document upload (license, RTA permit, Emirates ID, vehicle reg/insurance)
- [ ] Verification status states (pending/approved/rejected) — gated by Admin
- [ ] Vehicle profile (EV model)

### 2.2 Going online & receiving rides
- [ ] Online/offline toggle + availability state
- [ ] Location streaming to backend
- [ ] Incoming ride request card (pickup, distance, fare) + accept/decline w/ countdown

### 2.3 Trip lifecycle
- [ ] Turn-by-turn navigation handoff (maps)
- [ ] Arrived → Start → Complete flow
- [ ] Contact rider (masked call/chat)

### 2.4 Earnings
- [ ] Per-trip earnings + daily summary
- [ ] Online hours, acceptance/cancellation rate, rating
- [ ] Earnings history

**Exit criteria:** Rider request → Driver accepts → trip completes → both sides settle, fully on the shared backend.

---

## Phase 3 — Admin MVP

**Status:** Not started · **Goal:** Ops can oversee and intervene in both sides of the network.

- [ ] Admin auth + role-based access (super-admin/ops/finance/support)
- [ ] Driver approval queue (review docs, approve/reject, activate/deactivate)
- [ ] User management (riders & drivers: view, suspend, history)
- [ ] Live ops map (active drivers + ongoing trips)
- [ ] Trip inspection + manual intervention (reassign, cancel, refund)
- [ ] Basic support/dispute view

**Exit criteria:** A driver can only operate after Admin approval, and ops can monitor + intervene in live trips.

---

## Phase 4 — EV Differentiators

**Status:** Not started · **Goal:** The features that make this an *EV* platform, not just a cab app.

- [ ] Driver battery/range input (manual; telematics later)
- [ ] Range-aware dispatch (only assign reachable trips)
- [ ] Charging-station map (DEWA EV Green Charger integration)
- [ ] "I'm charging" driver status (auto offline → resume)
- [ ] Charging-break suggestions based on range + shift length
- [ ] Rider "battery-aware assurance" indicator
- [ ] "CO₂ saved vs. petrol" badge (rider) + sustainability metric (admin)

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
