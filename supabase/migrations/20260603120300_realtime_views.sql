-- EVC — Realtime streams + analytics views.

-- ───────────────────────── Realtime ───────────────────────────
-- Full row payloads on update (so subscribers get changed columns).
alter table public.trips             replica identity full;
alter table public.driver_locations  replica identity full;
alter table public.driver_details    replica identity full;
alter table public.support_tickets   replica identity full;

-- Publish the tables the apps subscribe to:
--   Rider  → its own trip row + assigned driver location
--   Driver → trips where driver_id = me (offers + state)
--   Admin  → all ongoing trips, all driver locations, approval queue
alter publication supabase_realtime add table public.trips;
alter publication supabase_realtime add table public.driver_locations;
alter publication supabase_realtime add table public.trip_events;
alter publication supabase_realtime add table public.driver_details;
alter publication supabase_realtime add table public.support_tickets;

-- ───────────────────────── Analytics views ────────────────────
-- security_invoker = on → each view respects the caller's RLS (admins see all,
-- a driver sees only their own rows).

create view public.active_trips_view with (security_invoker = on) as
select
  t.id, t.status, t.rider_id, t.driver_id,
  rp.full_name as rider_name,
  dp.full_name as driver_name,
  t.tier_id, t.fare_estimate, t.final_fare, t.duration_min,
  t.pickup_name, t.dest_name,
  t.pickup_lat, t.pickup_lng, t.dest_lat, t.dest_lng
from public.trips t
join public.profiles rp on rp.id = t.rider_id
left join public.profiles dp on dp.id = t.driver_id
where t.status in ('matched', 'enroute', 'arrived', 'ongoing');

create view public.driver_earnings_view with (security_invoker = on) as
select
  driver_id,
  date_trunc('day', completed_at)::date as day,
  count(*)                              as trips,
  coalesce(sum(final_fare), 0)          as gross_aed,
  coalesce(sum(tip), 0)                 as tips_aed,
  coalesce(sum(final_fare) * 0.85, 0)   as net_aed   -- after 15% EVC fee
from public.trips
where status = 'completed' and driver_id is not null
group by driver_id, date_trunc('day', completed_at);

create view public.co2_savings_view with (security_invoker = on) as
select
  date_trunc('day', completed_at)::date as day,
  count(*)                               as trips,
  coalesce(sum(co2_saved_kg), 0)         as co2_saved_kg
from public.trips
where status = 'completed'
group by date_trunc('day', completed_at);

create view public.demand_by_hour_view with (security_invoker = on) as
select
  extract(hour from requested_at)::int as hour,
  count(*)                             as requests
from public.trips
group by extract(hour from requested_at)
order by hour;

-- Views are created after the blanket grant in the RLS migration, so grant here.
grant select on
  public.active_trips_view,
  public.driver_earnings_view,
  public.co2_savings_view,
  public.demand_by_hour_view
to authenticated;