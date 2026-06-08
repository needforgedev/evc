# EVC — Project Plan & Progress Tracker

> Living checklist for the EVC electric-cab platform (Rider + Driver + Admin on a shared backend).
> See [docs/APP_CONCEPT.md](docs/APP_CONCEPT.md) for the full product concept.
>
> **Legend:** `[ ]` todo · `[~]` in progress · `[x]` done · `[!]` blocked
> Mark steps as you go and keep the **Status** line at the top of each phase current.

---

## Progress snapshot — 2026-06-08

**Where we are:** backend is **live** and the platform runs a **real end-to-end ride** across all three apps — book → dispatch → accept → drive → complete → settle. Auth, accounts, **document upload/verification**, and the **full trip loop** are real. **Real phone OTP** (WhatsApp, dev sandbox) now gates Rider + Driver sign-in, with **account recovery on reinstall**.

- ✅ **Monorepo** — pub workspace, melos, shared lint. All three build to APKs: `dev.needforge.evc{rider,driver,admin}`.
- ✅ **Backend live** — schema + RLS + trip-lifecycle RPCs + realtime + analytics views + Storage applied. Creds injected per app via `--dart-define-from-file=.env`.
- ✅ **Auth (real OTP — sandbox)** — Rider & Driver sign in with a **real 6-digit WhatsApp code** (`request-otp`/`verify-otp` edge functions + hashed `otp_codes`, 5-min expiry, 5-try cap; Vonage WhatsApp **sandbox** delivers to one whitelisted number in dev). **Login-vs-register branch** → same number on a new device/reinstall **recovers the same account** (driver vehicle creation made idempotent — no duplicates). Admin = **email/password** (dashboard-provisioned). Sessions persist. *(Production channels — WABA/SMS/Telegram + server-minted sessions — still pending; see OTP section.)*
- ✅ **Documents (real)** — private `driver-docs` Storage bucket + RLS; driver uploads each doc individually (**gated** — no dashboard until all uploaded); Admin views the real files + per-doc Approve/Reject.
- ✅ **Real trips (Milestone A)** — Rider `request_ride` → server prices it + **range-aware dispatch** → Driver realtime **offer → accept → arrived → start → complete**; writes `payments`, bumps **driver earnings**, updates **Admin live-map/Trips/KPIs**. CO₂ per trip + fares from the pricing table.
- ✅ **Rider (real)** — register → book → live status → account + ride history live.
- ✅ **Driver (real)** — register → docs → approval → go online → receive/accept/drive/complete jobs → real earnings; charging + battery/range live.
- ✅ **Admin (real)** — login + role guard; approvals, drivers, trips (cancel), live map, fleet, support, KPIs all live.
- ⏭️ **Next:** **Step 3 — rider tracking polish** (driver card, live driver dot, receipt, rider→driver rating); then Milestone C (promos/surge/wallet) & D (admin pricing/analytics/finance real).

**Still mock / pending:** rider live-tracking polish (driver card / receipt / rating), Admin Pricing/Finance/Analytics screens, real Google Maps + device GPS (the moving dot), **production OTP** (move off the Vonage **sandbox** → real WhatsApp WABA / SMS / Telegram, plus **server-minted sessions** so the app holds no credential — see *OTP / Authentication* section), push notifications, payments capture/payouts, DEWA live data.

> State = Riverpod (plain `Notifier`, no codegen). **Real WhatsApp OTP is live (sandbox)** on Rider + Driver. Sign-in still mints the session client-side via the deterministic phone→account scheme (kept so existing accounts/re-login work); harden to **server-minted sessions** (see *OTP / Authentication → Session minting*) before launch. The legacy `7464` dev code remains only as `EvcConfig.devMockOtp` for offline/mock runs.

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
- [x] Auth: role model (rider/driver/admin) + **real WhatsApp OTP** (Rider & Driver: `request-otp`/`verify-otp` + `otp_codes`, Vonage sandbox) + admin email/password — *production channels (WABA/SMS/Telegram) + server-minted sessions TBD (see "OTP / Authentication" section)*
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
- [x] Phone → **real 6-digit WhatsApp OTP** → **login-vs-register branch**: returning number → straight to Home; new number → collect name → **real `profiles` row + session**. Reinstall/new device → **same account recovered**.
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
- [x] Register (phone → **real WhatsApp OTP** → details) → **real `vehicles` + `driver_details`(pending)**; **login-vs-register branch** (returning number → dashboard) + **idempotent vehicle** (reinstall recovers the same account, no duplicate vehicle)
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

## OTP / Authentication — multi-channel design

> **Status:** **Phase 1 BUILT (dev sandbox).** Rider + Driver now sign in with a **real 6-digit WhatsApp OTP** — `request-otp`/`verify-otp` edge functions, hashed `otp_codes` (5-min expiry, 5-try cap), delivered via the **Vonage WhatsApp sandbox** (one whitelisted recipient in dev). A **login-vs-register branch** recovers the same account on reinstall, and driver vehicle creation is **idempotent**.
> **Still to build (production):** WABA / SMS / Telegram channels, real per-recipient delivery (off the sandbox), **server-minted sessions** (so the app holds no credential), rate-limiting/CAPTCHA. The rest of this section is the production plan.

### Built so far (2026-06-08)
- [x] `otp_codes` table (RLS-locked; service-role only) — `phone`, `code_hash`, `channel`, `expires_at`, `attempts`, `consumed` — *`supabase/migrations/20260606120000_otp_codes.sql`*
- [x] `request-otp` edge function — 6-digit crypto code → SHA-256 hash + 5-min expiry → Vonage **WhatsApp sandbox** send (fixed recipient `OTP_SANDBOX_TO` in dev) — *deploy `--no-verify-jwt`*
- [x] `verify-otp` edge function — validate hash/expiry/attempt-cap → `{ verified }` — *deploy `--no-verify-jwt`*
- [x] `EvcOtp` (core) + Rider/Driver onboarding reorder: **phone → OTP → login(existing)/register(new)**
- [x] Idempotent driver vehicle (no duplicate `vehicles` rows on reinstall/re-register)
- [x] Secrets: `VONAGE_API_KEY`, `VONAGE_API_SECRET`, `VONAGE_WA_FROM=14157386102`, `OTP_SANDBOX_TO=918097086954` (`supabase secrets set …`, never in the app)
- **Sandbox caveat:** the sandbox can only message numbers that have joined it → in dev the code is **delivered to the one whitelisted number regardless of the typed phone** (the typed number is still the account identity). Removed by going to a production WhatsApp sender / SMS.
- **Session caveat (dev posture):** verify returns `{verified}` and the **app** then signs into the deterministic phone→account (synthetic email + password) — kept so existing accounts/re-login work. Harden to **server-minted sessions** (below) before launch.

### Goal (production)
- **Phone number = the account identity.** Reinstall / new device / same number → **recovers the same account** (trips, earnings, history). ✅ *(working today via the deterministic phone→account + login/register branch)*
- Real verification across **multiple channels**; retire the deterministic client-side password in favour of **server-minted sessions**.

### Identity model (decision to confirm)
- **Recommended: one phone = one identity** that can be **both rider and driver** (Uber/Careem model). `is_admin()` stays role-based; rider/driver access is ownership-based (`rider_id`/`driver_id`), so a dual-role user works.
- *(Alternative: keep rider & driver strictly separate — needs two numbers or a "become a driver" upgrade. Not recommended.)*

### Channels (UAE-tuned)
- **WhatsApp — primary** (near-universal in UAE, trusted, cheaper than SMS).
- **SMS — fallback** (universal; best OS auto-fill; most expensive; needs TRA Sender-ID).
- **Telegram — free opt-in** (free via bot; lower reach; codeless first-auth — see below).
- Cost order (cheap→pricey): Telegram bot (free) → Telegram Gateway (~¢) → WhatsApp (few ¢) → SMS (most).

### Providers
- **SMS:** **Vonage** (Messages API / SMS API) to start; consider **Unifonic** (Gulf-native, handles TRA Sender-ID + deliverability) for production.
- **WhatsApp:** Vonage as BSP, or **Meta Cloud API** direct — needs a **WhatsApp Business Account (WABA)** + approved **authentication template**.
- **Telegram:** **Telegram Bot API** (free) and/or Telegram Gateway API.

### Architecture — own the OTP (one engine, all channels)
Multi-channel + Telegram needs full control, so **generate / deliver / verify ourselves** and mint a real Supabase session at the end.

**Tables**
- [x] `otp_codes` — `phone`, `code_hash`, `channel`, `expires_at` (~5 min), `attempts`, `consumed`, `created_at`. *(built)*
- [ ] `telegram_links` — `phone` ↔ `chat_id` (set when a user links Telegram).
- [ ] `tg_auth` — short-lived `nonce` rows for the codeless Telegram handshake (`nonce`, `status`, `phone`, expiry).

**Edge Functions**
- [x] `request-otp({ phone })` — 6-digit code → store **hash** + expiry → deliver. *(built — WhatsApp sandbox only; TODO: channel dispatcher SMS/WhatsApp/Telegram, rate-limit cooldown + per-hour cap, optional CAPTCHA)*
- [x] `verify-otp({ phone, code })` — validate hash/expiry/attempts → `{ verified }`. *(built; TODO: **mint Supabase session** server-side and return tokens instead of letting the app sign in)*
- [ ] `telegram-webhook` — receives `/start <nonce>` + contact-share; stores `phone → chat_id`; for codeless first-auth, marks the `tg_auth` nonce verified (or mints the session).

**Session minting (phone = identity, real sessions)**
- After a valid OTP, the server creates/finds the user by **phone** with a **server-only random password**, then `signInWithPassword({ phone, password })` server-side → returns the session. The password never leaves the server and is only used *after* OTP success (not a backdoor).

### The unified OTP (code) flow
```
1. App    → enter +971 number → pick channel → request-otp(phone, channel)
2. Server → make 6-digit code, store hash + 5-min expiry, deliver via channel
3. User   → receives code, types it (iOS auto-fills SMS)
4. App    → verify-otp(phone, code)
5. Server → check hash/expiry/attempts → mint Supabase session → tokens
6. App    → setSession → profile exists? → Home  (LOGIN)
                         → no profile?    → collect name / driver details (REGISTER)
```
- The **login-vs-register branch** (step 6) fixes reinstall/duplicate: existing phone → straight to app; new phone → onboarding.

### Telegram specifics (the `/start` constraint)
- A bot **cannot message a cold user** — the user must `/start` + **share contact** once, which links `phone → chat_id`.
- **Codeless first-auth (recommended):** the contact-share **is** the verification (Telegram-verified number) — no typed code. Flow: app makes a `nonce` + subscribes (Realtime) → opens `t.me/EvcBot?start=<nonce>` → user taps **Start** → **Share my number** → webhook stores the link + marks the nonce verified → app's Realtime fires → logged in. ~3 taps, no code.
- **One-time:** after linking, returning users get a DM'd code or a one-tap "Log in" button — **no `/start` again** → lands in the same account.
- **Cold-start without Telegram:** first verification via WhatsApp/SMS, then offer "Connect Telegram for free codes" later.
- Treat Telegram as a **delivery channel for the phone's code**, never a separate identity.
- *Consistency choice:* **Model A** — Telegram codeless + typed code on WhatsApp/SMS (smoothest) · **Model B** — typed code everywhere (uniform, +1 tap on Telegram first run).

### WhatsApp: sandbox vs production (handling new/unknown numbers)
- **Sandbox** (`/messages/sandbox`) **requires whitelisting** each recipient (they send a `join` keyword) — **test only**; cannot reach new drivers.
- **Production = no whitelist:** with an approved **WABA** + an **authentication template** (`Your EVC code is {{1}}`), you can send to **any** number with no prior opt-in (auth templates may *initiate* contact; the 24-h window only restricts free-form messages).
- **Setup (has lead time):** Facebook Business Manager + business verification → link WABA in Vonage → register a business sender number → submit auth template for approval → live.
- **Until WABA is ready:** use **SMS** (cold-OK, no whitelist) or **Telegram** for new drivers in dev.

### Vonage usage notes
- The Messages API curl (`POST https://api.nexmo.com/v1/messages`) is the **send** half → becomes a `fetch` inside `request-otp`. Verification is ours (`otp_codes` + `verify-otp`).
- Secret → `supabase secrets set VONAGE_SECRET=…` (never in the app). Auth: `Basic base64(key:secret)` for SMS; WhatsApp needs a Vonage **Application + JWT**.
- **UAE:** register an alphanumeric **Sender ID** (e.g. "EVC") with the TRA; normalize numbers to **E.164**.
- *(Alternative for SMS only: Vonage **Verify API** does code-gen+send+check for you, but it's a separate verification system — our own `otp_codes` keeps all channels on one engine, so prefer Messages API as pure delivery.)*

### Dev / test path (replaces the 7464 backdoor)
- Use **Supabase test phone numbers** (preset codes) for QA — real flow, no SMS cost, no arbitrary-number backdoor.
- For cold-start testing of new drivers now: **SMS (Vonage, cold-OK)** or **Telegram bot (free)**.

### Interim fixes — DONE (2026-06-08)
- [x] After OTP sign-in, **check if the account exists** → if yes, skip onboarding (login); if no, collect details. *(Rider: profile has a name; Driver: has a vehicle.)*
- [x] Driver: vehicle creation **idempotent** (skip if `current_vehicle_id` set) — kills duplicate-vehicle rows on reinstall.

### Migration note
- Switching from the synthetic-email scheme to **phone-native** auth invalidates the current dev accounts (email-based). **Wipe dev data** (existing reset query) before going phone-native.

### Decisions to lock before building
1. Identity: one phone = rider+driver (recommended) vs separate?
2. Telegram consistency: **Model A** (codeless Telegram) vs **Model B** (code everywhere)?
3. SMS provider: Vonage now vs **Unifonic** for UAE production?
4. WhatsApp route: Vonage BSP vs Meta Cloud API direct?
5. Timing: build now vs just before launch (Supabase test numbers avoid SMS cost during dev)?
6. Accounts in hand: Vonage / WABA / Telegram bot — or budget setup + TRA/Meta approvals (lead time)?

---

## Backlog / Ideas (not yet scheduled)

- [ ] Loyalty / subscription tier for frequent riders
- [ ] Corporate accounts / business billing
- [ ] Telematics integration for real-time battery data
- [ ] Multi-emirate / GCC expansion
- [ ] Driver community / training hub
