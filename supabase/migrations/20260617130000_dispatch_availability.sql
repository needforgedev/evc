-- No-availability handling (dispatch trio #1 + #3).
--
-- #3  Give dispatch a max pickup radius so "no cars in your area" is real
--     (today the nearest driver matches at ANY distance).
-- #1  nearby_tiers(): per-tier availability + pickup ETA, so the booking screen
--     can show "3 min away" / grey out empty tiers before the rider commits.

-- Configurable service radius (km). One source of truth for both functions.
alter table public.pricing
  add column if not exists dispatch_radius_km numeric not null default 10;

-- ── #3 · dispatch_trip now also enforces the pickup radius ──────────────
create or replace function public.dispatch_trip(p_trip uuid, p_exclude uuid default null)
returns public.trips
language plpgsql security definer set search_path = public
as $$
declare
  v_trip   public.trips;
  v_driver uuid;
  v_veh    uuid;
  v_radius numeric;
begin
  select * into v_trip from public.trips where id = p_trip;
  if v_trip.status <> 'requested' then return v_trip; end if;

  select coalesce(dispatch_radius_km, 10) into v_radius
    from public.pricing where region = 'dubai';
  v_radius := coalesce(v_radius, 10);

  -- Nearest online+available driver whose EV serves the requested tier, has the
  -- range to finish the trip, is compliant, and is WITHIN the service radius.
  select d.driver_id, d.current_vehicle_id
    into v_driver, v_veh
  from public.driver_details d
  join public.vehicles v        on v.id = d.current_vehicle_id
  join public.driver_locations l on l.driver_id = d.driver_id
  where d.account_status = 'active'
    and d.is_online
    and l.is_available
    and v.status = 'active'
    and v.tier = v_trip.tier_id
    and v.range_km >= v_trip.distance_km
    and (p_exclude is null or d.driver_id <> p_exclude)
    and public.haversine_km(l.lat, l.lng, v_trip.pickup_lat, v_trip.pickup_lng) <= v_radius
    and not exists (
      select 1 from public.driver_documents dx
      where dx.driver_id = d.driver_id
        and dx.expires_at is not null and dx.expires_at < current_date
    )
  order by public.haversine_km(l.lat, l.lng, v_trip.pickup_lat, v_trip.pickup_lng)
  limit 1;

  if v_driver is null then return v_trip; end if;  -- stays 'requested'

  update public.trips
     set driver_id = v_driver, vehicle_id = v_veh,
         status = 'matched', matched_at = now()
   where id = p_trip
   returning * into v_trip;

  update public.driver_locations set is_available = false where driver_id = v_driver;
  insert into public.trip_events (trip_id, status, actor_id) values (p_trip, 'matched', v_driver);
  return v_trip;
end; $$;

-- ── #1 · per-tier availability + pickup ETA for a given pickup + trip distance ─
-- Returns one row per active tier: how many eligible drivers are within radius,
-- the nearest one's distance, and a pickup ETA (~24 km/h). Uses the SAME
-- eligibility rules as dispatch_trip so the preview matches reality.
create or replace function public.nearby_tiers(
  p_lat double precision, p_lng double precision, p_dist_km double precision
)
returns table(tier_id text, drivers integer, nearest_km double precision, eta_min integer)
language sql security definer set search_path = public
as $$
  with cfg as (
    select coalesce((select dispatch_radius_km from public.pricing where region = 'dubai'), 10) as radius
  )
  select t.id as tier_id,
         count(e.driver_id)::int as drivers,
         min(e.km) as nearest_km,
         case when min(e.km) is null then null
              else greatest(1, ceil(min(e.km) / 0.4))::int end as eta_min
  from public.ride_tiers t
  left join lateral (
    select d.driver_id,
           public.haversine_km(l.lat, l.lng, p_lat, p_lng) as km
    from public.driver_details d
    join public.vehicles v         on v.id = d.current_vehicle_id
    join public.driver_locations l on l.driver_id = d.driver_id
    cross join cfg
    where d.account_status = 'active'
      and d.is_online
      and l.is_available
      and v.status = 'active'
      and v.tier = t.id
      and v.range_km >= p_dist_km
      and public.haversine_km(l.lat, l.lng, p_lat, p_lng) <= cfg.radius
      and not exists (
        select 1 from public.driver_documents dx
        where dx.driver_id = d.driver_id
          and dx.expires_at is not null and dx.expires_at < current_date
      )
  ) e on true
  where t.active
  group by t.id;
$$;

grant execute on function public.nearby_tiers(double precision, double precision, double precision)
  to authenticated;
