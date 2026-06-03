-- EVC — core schema (identity, fleet, trips, pricing, payments, charging, support).
-- One Postgres database shared by the Rider, Driver and Admin apps. A single
-- `trips` row is created by Rider, fulfilled by Driver, monitored by Admin.

-- ───────────────────────── Extensions ─────────────────────────
create extension if not exists pgcrypto;       -- gen_random_uuid()

-- ───────────────────────── Enums ──────────────────────────────
create type user_role            as enum ('rider', 'driver', 'admin');
create type admin_scope          as enum ('super_admin', 'ops', 'finance', 'support');
create type ownership_type       as enum ('company', 'driver');
create type vehicle_status       as enum ('active', 'charging', 'maintenance', 'offline');
create type driver_account_status as enum ('pending', 'active', 'suspended');
create type doc_type             as enum ('license', 'rta_permit', 'emirates_id', 'vehicle_registration', 'insurance');
create type doc_review_status    as enum ('pending', 'approved', 'rejected');
-- Canonical trip lifecycle — collapses the mock TripStage / JobStage / AdminTripStatus.
create type trip_status          as enum ('requested', 'matched', 'enroute', 'arrived', 'ongoing', 'completed', 'canceled');
create type place_kind           as enum ('home', 'work', 'recent', 'search', 'pin');
create type payment_type         as enum ('cash', 'card', 'apple_pay', 'wallet');
create type payment_status       as enum ('pending', 'authorized', 'captured', 'failed', 'refunded');
create type promo_discount       as enum ('percent', 'flat');
create type ticket_type          as enum ('lost_item', 'safety', 'fare', 'general');
create type ticket_status        as enum ('open', 'pending', 'resolved');

-- ───────────────────────── Shared helpers ─────────────────────
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end; $$;

-- ───────────────────────── Identity ───────────────────────────
create table public.profiles (
  id          uuid primary key references auth.users (id) on delete cascade,
  role        user_role   not null default 'rider',
  admin_scope admin_scope,                       -- only for role = 'admin'
  full_name   text,
  phone       text,
  email       text,
  photo_url   text,
  rating      numeric(3, 2) default 5.00,
  total_trips integer     not null default 0,
  is_suspended boolean    not null default false,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);
create trigger trg_profiles_updated before update on public.profiles
  for each row execute function public.set_updated_at();

create table public.saved_places (
  id        uuid primary key default gen_random_uuid(),
  rider_id  uuid not null references public.profiles (id) on delete cascade,
  kind      place_kind not null default 'pin',
  name      text not null,
  address   text,
  lat       double precision,
  lng       double precision,
  created_at timestamptz not null default now()
);
create index idx_saved_places_rider on public.saved_places (rider_id);

-- ───────────────────────── Fleet & drivers ────────────────────
create table public.vehicles (
  id              uuid primary key default gen_random_uuid(),
  plate           text not null unique,
  model           text not null,
  ownership       ownership_type not null,
  owner_driver_id uuid references public.profiles (id) on delete set null, -- null = company-owned
  battery_percent integer not null default 100,
  range_km        integer not null default 0,
  status          vehicle_status not null default 'offline',
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);
create trigger trg_vehicles_updated before update on public.vehicles
  for each row execute function public.set_updated_at();
create index idx_vehicles_status on public.vehicles (status);

create table public.driver_details (
  driver_id          uuid primary key references public.profiles (id) on delete cascade,
  account_status     driver_account_status not null default 'pending',
  current_vehicle_id uuid references public.vehicles (id) on delete set null,
  is_online          boolean not null default false,
  acceptance_rate    numeric(4, 1) not null default 100.0,
  owner_label        text not null default 'Driver-owned',
  applied_at         timestamptz not null default now(),
  approved_by        uuid references public.profiles (id),
  updated_at         timestamptz not null default now()
);
create trigger trg_driver_details_updated before update on public.driver_details
  for each row execute function public.set_updated_at();

create table public.driver_documents (
  id            uuid primary key default gen_random_uuid(),
  driver_id     uuid not null references public.profiles (id) on delete cascade,
  type          doc_type not null,
  storage_path  text not null,                   -- object key in the 'driver-docs' bucket
  review_status doc_review_status not null default 'pending',
  reviewed_by   uuid references public.profiles (id),
  created_at    timestamptz not null default now(),
  unique (driver_id, type)
);
create index idx_driver_documents_driver on public.driver_documents (driver_id);

-- ───────────────────────── Pricing & promos ───────────────────
create table public.ride_tiers (
  id           text primary key,                 -- 'go' | 'comfort' | 'xl' | 'premium'
  name         text not null,
  blurb        text,
  seats        integer not null default 4,
  multiplier   numeric(4, 2) not null default 1.0,
  icon         text,
  sort_order   integer not null default 0,
  active       boolean not null default true
);

create table public.pricing (
  id         uuid primary key default gen_random_uuid(),
  region     text not null default 'dubai',
  currency   text not null default 'AED',
  base_fare  numeric(8, 2) not null,
  per_km     numeric(8, 2) not null,
  per_min    numeric(8, 2) not null,
  min_fare   numeric(8, 2) not null,
  vat_rate   numeric(4, 3) not null default 0.05,
  updated_at timestamptz not null default now(),
  unique (region)
);

create table public.zones (
  id      uuid primary key default gen_random_uuid(),
  name    text not null,
  region  text not null default 'dubai',
  geojson jsonb
);

create table public.surge_rules (
  id          uuid primary key default gen_random_uuid(),
  zone_id     uuid references public.zones (id) on delete cascade,
  multiplier  numeric(4, 2) not null default 1.0,
  starts_at   time,
  ends_at     time,
  active      boolean not null default true
);

create table public.promo_codes (
  id            uuid primary key default gen_random_uuid(),
  code          text not null unique,
  description   text,
  discount_type promo_discount not null,
  value         numeric(8, 2) not null,
  max_discount  numeric(8, 2),
  max_uses      integer,
  redemptions   integer not null default 0,
  active        boolean not null default true,
  valid_from    timestamptz,
  valid_to      timestamptz
);

-- ───────────────────────── Trips (the heart) ──────────────────
create table public.trips (
  id              uuid primary key default gen_random_uuid(),
  rider_id        uuid not null references public.profiles (id) on delete restrict,
  driver_id       uuid references public.profiles (id) on delete set null,
  vehicle_id      uuid references public.vehicles (id) on delete set null,
  tier_id         text not null references public.ride_tiers (id),
  status          trip_status not null default 'requested',

  pickup_name     text,
  pickup_address  text,
  pickup_lat      double precision not null,
  pickup_lng      double precision not null,
  dest_name       text,
  dest_address    text,
  dest_lat        double precision not null,
  dest_lng        double precision not null,

  distance_km     numeric(8, 2),
  duration_min    integer,
  fare_estimate   numeric(8, 2),
  final_fare      numeric(8, 2),
  vat             numeric(8, 2),
  tip             numeric(8, 2) not null default 0,
  co2_saved_kg    numeric(6, 2),

  payment_type    payment_type not null default 'card',
  promo_code      text,
  pin             text,                            -- 4-digit verification PIN

  requested_at    timestamptz not null default now(),
  matched_at      timestamptz,
  completed_at    timestamptz,
  canceled_reason text,
  updated_at      timestamptz not null default now()
);
create trigger trg_trips_updated before update on public.trips
  for each row execute function public.set_updated_at();
create index idx_trips_rider  on public.trips (rider_id);
create index idx_trips_driver on public.trips (driver_id);
create index idx_trips_status on public.trips (status);

-- Append-only audit / state-machine log (also feeds analytics).
create table public.trip_events (
  id         uuid primary key default gen_random_uuid(),
  trip_id    uuid not null references public.trips (id) on delete cascade,
  status     trip_status not null,
  actor_id   uuid references public.profiles (id),
  note       text,
  created_at timestamptz not null default now()
);
create index idx_trip_events_trip on public.trip_events (trip_id);

-- ───────────────────────── Geo / realtime ─────────────────────
create table public.driver_locations (
  driver_id    uuid primary key references public.profiles (id) on delete cascade,
  lat          double precision not null,
  lng          double precision not null,
  heading      numeric(5, 1),
  is_available boolean not null default false,
  updated_at   timestamptz not null default now()
);

-- ───────────────────────── Payments & finance ─────────────────
create table public.payment_methods (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.profiles (id) on delete cascade,
  type       payment_type not null,
  label      text not null,
  detail     text,                                -- e.g. '•••• 4242'
  is_default boolean not null default false,
  created_at timestamptz not null default now()
);
create index idx_payment_methods_user on public.payment_methods (user_id);

create table public.payments (
  id          uuid primary key default gen_random_uuid(),
  trip_id     uuid not null references public.trips (id) on delete cascade,
  rider_id    uuid not null references public.profiles (id) on delete restrict,
  amount      numeric(8, 2) not null,
  vat         numeric(8, 2) not null default 0,
  tip         numeric(8, 2) not null default 0,
  type        payment_type not null,
  status      payment_status not null default 'pending',
  gateway_ref text,
  created_at  timestamptz not null default now()
);
create index idx_payments_trip on public.payments (trip_id);

create table public.wallets (
  user_id    uuid primary key references public.profiles (id) on delete cascade,
  balance    numeric(10, 2) not null default 0,
  currency   text not null default 'AED',
  updated_at timestamptz not null default now()
);

create table public.wallet_transactions (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.profiles (id) on delete cascade,
  amount     numeric(10, 2) not null,             -- signed
  reason     text,
  trip_id    uuid references public.trips (id) on delete set null,
  created_at timestamptz not null default now()
);

create table public.payouts (
  id         uuid primary key default gen_random_uuid(),
  driver_id  uuid not null references public.profiles (id) on delete cascade,
  period     text not null,                       -- e.g. '2026-W23'
  amount     numeric(10, 2) not null,
  status     text not null default 'scheduled',
  run_at     timestamptz,
  created_at timestamptz not null default now()
);
create index idx_payouts_driver on public.payouts (driver_id);

-- ───────────────────────── EV / charging ──────────────────────
create table public.charging_stations (
  id               uuid primary key default gen_random_uuid(),
  name             text not null,
  network          text not null default 'DEWA EV Green Charger',
  lat              double precision not null,
  lng              double precision not null,
  total_stalls     integer not null default 1,
  available_stalls integer not null default 0,
  power_kw         integer not null default 0,
  updated_at       timestamptz not null default now()
);

create table public.charging_sessions (
  id         uuid primary key default gen_random_uuid(),
  driver_id  uuid not null references public.profiles (id) on delete cascade,
  station_id uuid references public.charging_stations (id) on delete set null,
  started_at timestamptz not null default now(),
  ended_at   timestamptz,
  kwh        numeric(6, 2),
  start_pct  integer,
  end_pct    integer
);
create index idx_charging_sessions_driver on public.charging_sessions (driver_id);

-- ───────────────────────── Engagement & support ───────────────
create table public.ratings (
  id         uuid primary key default gen_random_uuid(),
  trip_id    uuid not null references public.trips (id) on delete cascade,
  rater_id   uuid not null references public.profiles (id) on delete cascade,
  ratee_id   uuid not null references public.profiles (id) on delete cascade,
  stars      integer not null check (stars between 1 and 5),
  tags       text[] not null default '{}',
  comment    text,
  created_at timestamptz not null default now(),
  unique (trip_id, rater_id)
);
create index idx_ratings_ratee on public.ratings (ratee_id);

create table public.support_tickets (
  id          uuid primary key default gen_random_uuid(),
  type        ticket_type not null,
  opened_by   uuid not null references public.profiles (id) on delete cascade,
  trip_id     uuid references public.trips (id) on delete set null,
  subject     text not null,
  body        text,
  status      ticket_status not null default 'open',
  assigned_to uuid references public.profiles (id),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);
create trigger trg_tickets_updated before update on public.support_tickets
  for each row execute function public.set_updated_at();
create index idx_tickets_status on public.support_tickets (status);

create table public.notifications (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.profiles (id) on delete cascade,
  title      text not null,
  body       text,
  read       boolean not null default false,
  created_at timestamptz not null default now()
);
create index idx_notifications_user on public.notifications (user_id);