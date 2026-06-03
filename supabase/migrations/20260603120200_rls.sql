-- EVC — Row-Level Security. One policy set scopes what rider / driver / admin
-- can see and do. Sensitive writes (trip status, fare, dispatch) go only
-- through the SECURITY DEFINER RPCs, so most tables have no client UPDATE policy.

-- Base privileges (RLS still gates every row).
grant usage on schema public to anon, authenticated;
grant select, insert, update, delete on all tables in schema public to authenticated;
grant select on
  public.ride_tiers, public.pricing, public.charging_stations, public.zones to anon;

-- Enable RLS everywhere.
alter table public.profiles           enable row level security;
alter table public.saved_places       enable row level security;
alter table public.vehicles           enable row level security;
alter table public.driver_details     enable row level security;
alter table public.driver_documents   enable row level security;
alter table public.ride_tiers         enable row level security;
alter table public.pricing            enable row level security;
alter table public.zones              enable row level security;
alter table public.surge_rules        enable row level security;
alter table public.promo_codes        enable row level security;
alter table public.trips              enable row level security;
alter table public.trip_events        enable row level security;
alter table public.driver_locations   enable row level security;
alter table public.payment_methods    enable row level security;
alter table public.payments           enable row level security;
alter table public.wallets            enable row level security;
alter table public.wallet_transactions enable row level security;
alter table public.payouts            enable row level security;
alter table public.charging_stations  enable row level security;
alter table public.charging_sessions  enable row level security;
alter table public.ratings            enable row level security;
alter table public.support_tickets    enable row level security;
alter table public.notifications      enable row level security;

-- ───────────────────────── profiles ───────────────────────────
-- Self, admins, and the counterparty on a shared trip can read a profile.
create policy profiles_select on public.profiles for select using (
  id = auth.uid()
  or public.is_admin()
  or exists (
    select 1 from public.trips t
    where (t.rider_id = auth.uid() and t.driver_id = profiles.id)
       or (t.driver_id = auth.uid() and t.rider_id = profiles.id)
  )
);
create policy profiles_update_self on public.profiles for update
  using (id = auth.uid() or public.is_admin())
  with check (id = auth.uid() or public.is_admin());

-- ───────────────────────── saved_places ───────────────────────
create policy saved_places_owner on public.saved_places for all
  using (rider_id = auth.uid() or public.is_admin())
  with check (rider_id = auth.uid());

-- ───────────────────────── vehicles ───────────────────────────
create policy vehicles_select on public.vehicles for select using (true);
create policy vehicles_write on public.vehicles for all
  using (owner_driver_id = auth.uid() or public.is_admin())
  with check (owner_driver_id = auth.uid() or public.is_admin());

-- ───────────────────────── driver_details ─────────────────────
create policy driver_details_select on public.driver_details for select
  using (driver_id = auth.uid() or public.is_admin());
create policy driver_details_update on public.driver_details for update
  using (driver_id = auth.uid() or public.is_admin())
  with check (driver_id = auth.uid() or public.is_admin());

-- ───────────────────────── driver_documents ───────────────────
create policy driver_documents_select on public.driver_documents for select
  using (driver_id = auth.uid() or public.is_admin());
create policy driver_documents_insert on public.driver_documents for insert
  with check (driver_id = auth.uid());
create policy driver_documents_admin_update on public.driver_documents for update
  using (public.is_admin()) with check (public.is_admin());

-- ───────────────────────── config tables (read-all, admin-write) ─
create policy ride_tiers_read on public.ride_tiers for select using (true);
create policy ride_tiers_admin on public.ride_tiers for all
  using (public.is_admin()) with check (public.is_admin());

create policy pricing_read on public.pricing for select using (true);
create policy pricing_admin on public.pricing for all
  using (public.is_admin()) with check (public.is_admin());

create policy zones_read on public.zones for select using (true);
create policy zones_admin on public.zones for all
  using (public.is_admin()) with check (public.is_admin());

create policy surge_read on public.surge_rules for select using (true);
create policy surge_admin on public.surge_rules for all
  using (public.is_admin()) with check (public.is_admin());

create policy promos_read on public.promo_codes for select using (active or public.is_admin());
create policy promos_admin on public.promo_codes for all
  using (public.is_admin()) with check (public.is_admin());

create policy stations_read on public.charging_stations for select using (true);
create policy stations_admin on public.charging_stations for all
  using (public.is_admin()) with check (public.is_admin());

-- ───────────────────────── trips ──────────────────────────────
-- Read only your own trips (as rider or driver) or everything as admin.
-- All writes happen through the RPCs (request_ride / accept_ride / … ).
create policy trips_select on public.trips for select using (
  rider_id = auth.uid() or driver_id = auth.uid() or public.is_admin()
);

-- ───────────────────────── trip_events ────────────────────────
create policy trip_events_select on public.trip_events for select using (
  public.is_admin() or exists (
    select 1 from public.trips t
    where t.id = trip_events.trip_id
      and (t.rider_id = auth.uid() or t.driver_id = auth.uid())
  )
);

-- ───────────────────────── driver_locations ───────────────────
-- Admin sees all; a driver sees their own; a rider sees their assigned
-- driver only while the trip is active.
create policy driver_locations_select on public.driver_locations for select using (
  public.is_admin()
  or driver_id = auth.uid()
  or exists (
    select 1 from public.trips t
    where t.driver_id = driver_locations.driver_id
      and t.rider_id = auth.uid()
      and t.status in ('matched', 'enroute', 'arrived', 'ongoing')
  )
);

-- ───────────────────────── payment_methods ────────────────────
create policy payment_methods_owner on public.payment_methods for all
  using (user_id = auth.uid() or public.is_admin())
  with check (user_id = auth.uid());

-- ───────────────────────── payments ───────────────────────────
create policy payments_select on public.payments for select using (
  rider_id = auth.uid()
  or public.is_admin()
  or exists (select 1 from public.trips t where t.id = payments.trip_id and t.driver_id = auth.uid())
);

-- ───────────────────────── wallets / ledger ───────────────────
create policy wallets_owner on public.wallets for select
  using (user_id = auth.uid() or public.is_admin());
create policy wallet_tx_owner on public.wallet_transactions for select
  using (user_id = auth.uid() or public.is_admin());

-- ───────────────────────── payouts ────────────────────────────
create policy payouts_select on public.payouts for select
  using (driver_id = auth.uid() or public.is_admin());

-- ───────────────────────── charging_sessions ──────────────────
create policy charging_sessions_owner on public.charging_sessions for all
  using (driver_id = auth.uid() or public.is_admin())
  with check (driver_id = auth.uid());

-- ───────────────────────── ratings ────────────────────────────
create policy ratings_select on public.ratings for select using (
  rater_id = auth.uid() or ratee_id = auth.uid() or public.is_admin()
);

-- ───────────────────────── support_tickets ────────────────────
create policy tickets_select on public.support_tickets for select
  using (opened_by = auth.uid() or public.is_admin());
create policy tickets_insert on public.support_tickets for insert
  with check (opened_by = auth.uid());
create policy tickets_admin_update on public.support_tickets for update
  using (public.is_admin()) with check (public.is_admin());

-- ───────────────────────── notifications ──────────────────────
create policy notifications_owner on public.notifications for select
  using (user_id = auth.uid());
create policy notifications_read on public.notifications for update
  using (user_id = auth.uid()) with check (user_id = auth.uid());