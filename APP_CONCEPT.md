# EVC — Electric Vehicle Cab Platform (Dubai)

> A green ride-hailing platform for Dubai built entirely around electric vehicles.
> One shared backend powering three apps: **Rider**, **Driver**, and **Admin**.

---

## 1. The Idea in One Line

EVC is Dubai's all-electric ride-hailing service — riders book zero-emission cabs, drivers
earn on a fleet of EVs with charging-aware scheduling, and operators run the whole network
from a single control panel. Think "Uber, but 100% electric and tuned for the UAE."

## 2. Why This, Why Dubai, Why Now

- **Government tailwind:** Dubai's RTA targets a large share of taxis to be electric/hybrid,
  and the UAE has a Net Zero 2050 commitment. A purpose-built EV fleet aligns with policy and
  earns goodwill (and potentially incentives).
- **Differentiation:** Riders increasingly want a sustainable option; "guaranteed EV, no
  petrol cars" is a clear brand promise that Careem/Uber don't make.
- **Charging is the hard part — and the moat:** EV ride-hailing lives or dies on charging
  logistics. Building charging-awareness into dispatch from day one is the defensible edge.
- **Premium positioning:** Quiet, clean, modern EVs (Tesla, BYD, etc.) support a slightly
  premium, comfort-forward brand in a city that values it.

## 3. The Three Apps (shared backend)

| App | Primary users | Core job |
|-----|---------------|----------|
| **EVC Rider** | Passengers | Book, track, pay, rate rides |
| **EVC Driver** | Drivers/partners | Accept rides, navigate, track earnings, manage charging |
| **EVC Admin** | Operators / ops team | Oversee fleet, users, pricing, support, analytics |

All three talk to the same backend (single source of truth: users, trips, vehicles, payments,
pricing). A trip created by the Rider app is the same record the Driver app fulfills and the
Admin app monitors.

---

## 4. EVC Rider App

**Goal:** Book an EV cab in under 30 seconds and trust it will arrive.

### Key features
- **Onboarding & auth:** Phone OTP (UAE numbers), optional email, profile, saved places
  (Home / Work / custom).
- **Booking flow:**
  - Set pickup (GPS / map pin / search) and destination.
  - Ride tiers: **EVC Go** (compact EV), **EVC Comfort** (mid-size), **EVC XL** (SUV/van),
    optionally **EVC Green Premium** (Tesla/luxury EV).
  - Upfront fare estimate, ETA, and a small **"CO₂ saved vs. petrol"** badge (brand hook).
  - Schedule-ahead booking (e.g., airport runs).
- **Live tracking:** Driver location, vehicle make/model + plate, driver name/photo/rating,
  live ETA. **Battery-aware assurance** — never assigned a car that can't complete the trip.
- **Payments:** Card, Apple/Google Pay, cash (common in UAE), in-app wallet, promo codes.
  Multi-currency display but AED settlement.
- **Safety:** Share trip / live location, SOS button, masked calling/chat with driver,
  trip PIN verification.
- **Post-ride:** Rating + tags, tip, receipt (VAT-compliant), lost-item report.
- **Extras:** Ride history, favorites, referral program, support chat, language toggle
  (English + Arabic, RTL support).

## 5. EVC Driver App

**Goal:** Maximize earnings while managing the realities of an EV (range, charging, shifts).

### Key features
- **Onboarding & compliance:** Document upload (license, RTA permit, Emirates ID, vehicle
  reg/insurance), verification status, training checklist. Driver can't go online until
  approved by Admin.
- **Go online / offline** toggle with availability state.
- **Ride requests:** Incoming request card with pickup, distance, fare, rider rating;
  accept/decline with countdown. Turn-by-turn navigation (Google Maps / Mapbox handoff).
- **Trip lifecycle:** Arrived → Start → Complete, with in-app navigation and rider contact.
- **EV-specific:**
  - **Battery/range input** (manual or telematics if integrated) so dispatch only sends
    reachable rides.
  - **Charging station map** + "I'm charging" status (auto goes offline, resumes after).
  - Charging-break suggestions based on remaining range and shift length.
- **Earnings dashboard:** Today / week / month, per-trip breakdown, tips, incentives/bonuses,
  payout history, instant-cashout (if supported).
- **Daily view:** Completed rides, online hours, acceptance/cancellation rate, ratings.
- **Heatmap / demand zones:** Where rides are hot right now (and where chargers are nearby).
- **Support & disputes:** Report issues, contest fares, contact ops.

## 6. EVC Admin App / Dashboard

**Goal:** Run the network — visibility and control over both sides.

### Key features
- **Live ops map:** All active drivers, ongoing trips, demand hotspots, charging status of fleet.
- **User management:** Riders (suspend, refund, view history) and drivers (approve/reject docs,
  activate/deactivate, performance).
- **Fleet & vehicle management:** Vehicle registry, EV model, battery/range profile,
  maintenance + charging status.
- **Trip management:** Search/inspect any trip, intervene (reassign, cancel, refund), monitor
  live for SLA/safety.
- **Pricing & promotions:** Base fares, per-km/per-min, surge rules by zone/time, promo codes,
  driver incentive campaigns.
- **Finance:** Revenue, driver payouts, commission, VAT reporting, reconciliation.
- **Support / dispute console:** Ticket queue, lost items, safety reports.
- **Analytics:** Demand patterns, supply gaps, CO₂ saved (sustainability reporting),
  charging utilization, cohort retention.
- **Roles & permissions:** Super-admin, ops, finance, support — scoped access.

---

## 7. Shared Backend (conceptual)

Single backend exposing one API consumed by all three apps, with role-based access.

**Core domains/services:**
- **Identity & auth** — users, roles (rider/driver/admin), OTP, sessions, KYC/document store.
- **Trips/dispatch** — request lifecycle, matching engine (EV-range & charging aware),
  state machine (requested → matched → enroute → ongoing → completed/canceled).
- **Geo/real-time** — driver location streaming, ETA, geofencing/zones, charging-station data.
- **Pricing** — fare calc, surge, promos, estimates.
- **Payments & wallet** — gateway integration (UAE-friendly, e.g. cards + Apple/Google Pay +
  cash reconciliation), payouts, ledger, VAT.
- **Fleet** — vehicles, battery/range profiles, maintenance, charging sessions.
- **Notifications** — push (FCM/APNs), SMS, in-app.
- **Analytics/reporting** — events pipeline feeding Admin dashboards.

**Real-time transport:** WebSockets / Firebase / a streaming layer for live location and trip
state across apps.

## 8. Suggested Tech Approach (Flutter monorepo)

Since all three are Flutter apps sharing logic, a **monorepo with a shared package** keeps the
codebase DRY:

```
evc/                      # repo root (this one)
├── apps/
│   ├── rider/            # Flutter app — flavor: rider
│   ├── driver/           # Flutter app — flavor: driver
│   └── admin/            # Flutter app (or Flutter Web for desktop dashboard)
├── packages/
│   ├── core/             # models, API client, auth, config, DI
│   ├── ui_kit/           # shared design system / widgets / theme
│   ├── maps/             # map + location abstraction
│   └── realtime/         # websocket/trip-state client
└── backend/              # (or separate repo) API, dispatch, db
```

- **Could also be one app with build flavors** (`--flavor rider|driver|admin`) if you want a
  single binary base — but three separate app shells around shared packages is cleaner for
  store listings and permissions.
- **State management:** Riverpod or Bloc (pick one, use everywhere).
- **Maps:** Google Maps Platform (strong UAE coverage) or Mapbox.
- **Backend options:**
  - *Fast path:* **Firebase/Supabase** (auth, realtime DB, functions) to validate quickly.
  - *Scalable path:* Custom API (Node/NestJS, Go, or Dart Frog/serverpod) + Postgres + Redis +
    a realtime layer. Recommended once dispatch logic gets complex.
- **Admin** is a strong candidate for **Flutter Web** so ops can run it on a big screen.

## 9. Dubai / UAE-Specific Considerations

- **Regulatory:** RTA licensing for ride-hailing & driver permits; this gates launch. Worth
  validating early — it shapes the driver onboarding flow.
- **Bilingual:** English + Arabic with full **RTL** support from day one.
- **Payments:** Cash is still common; support it alongside cards/wallets. VAT (5%) on receipts.
- **Charging network:** DEWA EV Green Charger network — integrate station locations into both
  Rider assurance and Driver charging map.
- **Geography:** Dense urban + long highway/airport runs (DXB, Abu Dhabi corridor) make
  range/charging awareness genuinely important, not cosmetic.

## 10. Phased Roadmap (suggested)

**Phase 0 — Foundation (this repo):** Monorepo + shared `core`/`ui_kit`, auth, backend choice,
data models, single map integration.

**Phase 1 — Rider MVP:** Book → match → track → complete → pay → rate. Hardcoded/simple
dispatch. One ride tier.

**Phase 2 — Driver MVP:** Go online, receive/accept rides, navigate, complete, basic earnings.
Now Rider↔Driver works end-to-end on the shared backend.

**Phase 3 — Admin MVP:** Driver approval, live trip view, basic user management, manual
intervention.

**Phase 4 — EV differentiators:** Range-aware dispatch, charging map + status, CO₂ badge,
charging-break logic.

**Phase 5 — Scale & polish:** Surge pricing, promos, incentives, analytics, safety suite,
scheduled rides, multi-tier, Arabic/RTL, finance/VAT reporting.

## 11. Decisions (resolved)

1. **Backend → Supabase.** Postgres + Auth + Realtime + Storage + Edge Functions, with
   Row-Level Security (RLS) enforcing per-role access. One database is the single source of
   truth for all three apps.
2. **App structure → Three separate apps + shared packages.** `apps/rider`, `apps/driver`,
   `apps/admin` are independently built and store-listed Flutter apps, each a thin shell over
   shared `packages/` (models, Supabase client, auth, UI kit). They do *not* copy data between
   each other — every app reads/writes the *same* Supabase rows (e.g. a single `trips` row is
   created by Rider, fulfilled by Driver, monitored by Admin), with RLS scoping what each role
   can see and do.
3. **Fleet model → Hybrid.** Support both company-owned EVs and driver-owned EVs. Onboarding,
   vehicle registry, and charging flows must handle both; economics/payout rules differ per
   ownership type.
4. **Maps → Google Maps now, behind a `packages/maps` abstraction (open path kept open).**
   Start on Google Maps Platform for best-in-UAE routing/ETA/places data (the things that make
   or break fares and arrival times). All map use goes through our own `packages/maps`
   interface, so we can later swap to **MapLibre/OpenStreetMap** (fully open source) or split
   rendering (open) from routing/geocoding (Google) for cost — without changing app code.
5. **Launch scope → Dubai first, then expand.** Build for Dubai; keep data models
   region-aware (zones, pricing, currency) so multi-emirate/GCC expansion is incremental, not
   a rewrite.
6. **Admin form factor → Mobile app.** The Admin app is a Flutter mobile app like the other
   two (a Flutter Web dashboard can be added later from the same shared packages if ops need a
   big-screen view).
7. **State management → Riverpod** (with `riverpod_generator` + `freezed`). Chosen for its
   stream ergonomics (Supabase Realtime subscriptions map cleanly to `StreamProvider`),
   low boilerplate across three apps, and built-in compile-safe DI (providers in
   `packages/core` are consumed by all three apps). Used consistently everywhere — no mixing.

