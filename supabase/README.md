# EVC Backend (Supabase)

One Postgres database shared by the Rider, Driver and Admin apps. A single
`trips` row is **created by Rider → fulfilled by Driver → monitored by Admin**,
with Row-Level Security scoping what each role can see and do.

## Layout

```
supabase/
├── migrations/
│   ├── 20260603120000_schema.sql          # extensions, enums, all tables, indexes
│   ├── 20260603120100_functions.sql       # auth trigger, helpers, trip-lifecycle RPCs, dispatch
│   ├── 20260603120200_rls.sql             # RLS enabled + per-role policies
│   └── 20260603120300_realtime_views.sql  # realtime publication + analytics views
├── functions/
│   └── finalize-payment/                   # example edge function (card capture)
├── seed.sql                                # pricing, tiers, zones, promos, DEWA stations
└── README.md
```

## Apply it

**Prerequisites:** [Supabase CLI](https://supabase.com/docs/guides/cli) + Docker.

```bash
# from the repo root
supabase init          # creates config.toml (keeps these migrations/functions)
supabase start         # local Postgres + Auth + Realtime + Storage in Docker
supabase db reset      # runs all migrations + seed.sql
```

Deploy to a hosted project:

```bash
supabase link --project-ref <your-ref>
supabase db push                       # migrations
supabase functions deploy finalize-payment
supabase secrets set PAYMENT_GATEWAY_KEY=...   # for the edge function
```

## Auth setup

- **Riders / Drivers** → Phone OTP. Enable the **Phone** provider (Twilio) in
  Auth settings for UAE numbers.
- **Admins** → email + password.
- A new user's `role` comes from sign-up metadata
  (`{ data: { role: 'rider' | 'driver' | 'admin' } }`). The `handle_new_user`
  trigger then creates the `profiles` row (and a `driver_details` row in the
  pending approval queue for drivers).

Create a test user, e.g.:

```bash
# admin
curl -X POST "$SUPABASE_URL/auth/v1/signup" -H "apikey: $ANON" \
  -H "Content-Type: application/json" \
  -d '{"email":"ops@evc.ae","password":"secret123","data":{"role":"admin","full_name":"Ops"}}'
```

## What the apps call

**RPCs** (via `supabase.rpc(...)`) — all sensitive writes go through these:

| RPC | Who | Does |
|---|---|---|
| `request_ride(...)` | Rider | Creates the trip, prices it, auto-dispatches |
| `accept_ride(trip)` / `decline_ride(trip)` | Driver | Take or pass an offer |
| `advance_trip(trip, status)` | Driver | enroute → arrived → ongoing |
| `complete_trip(trip, tip)` | Driver | Finalize fare + write payment |
| `cancel_trip(trip, reason)` | Rider/Admin | Cancel |
| `rate_trip(trip, ratee, stars, …)` | Both | Post-ride rating |
| `driver_set_online(bool)` / `driver_update_location(…)` | Driver | Availability + GPS |
| `admin_set_driver_status(driver, status)` | Admin | Approve / suspend / reactivate |
| `admin_reassign_trip(trip, driver)` | Admin | Intervene |

**Realtime channels** (map to Riverpod `StreamProvider`):

- Rider → `trips` row where `id = <activeTrip>` + `driver_locations` of the assigned driver.
- Driver → `trips` where `driver_id = me`.
- Admin → `trips` where `status in (active)`, all `driver_locations`, `driver_details where account_status = 'pending'`.

**Views** (admin dashboards): `active_trips_view`, `driver_earnings_view`,
`co2_savings_view`, `demand_by_hour_view` (all `security_invoker`, so RLS still
applies per caller).

## Wiring the Flutter apps

Put the project URL + anon key into `packages/core` (env/config), add
`supabase_flutter`, and replace the mock controllers
(`bookingController`, `jobController`, `adminController`) with repositories that
call the RPCs and subscribe to the channels above. The screens consume the same
`evc_core` models, so the UI shouldn't change.

## Not yet done (intentional TODOs)

- Payouts cron (scheduled function) and a double-entry ledger.
- Promo redemption application inside `request_ride` (validated but not yet deducted).
- Column-level locking on `profiles`/`trips` updates (today guarded by routing all writes through RPCs).
- Swap haversine for **PostGIS** if dispatch needs true road-distance / geofencing.
- Storage buckets: create `driver-docs` (private), `avatars`, `vehicle-photos` with RLS.