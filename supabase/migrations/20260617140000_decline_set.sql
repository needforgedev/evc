-- Punch-list #4 · Persistent per-trip declined-set.
--
-- Before: decline_ride re-dispatched excluding only the *immediate* decliner
-- (single p_exclude), so a small driver pool could ping-pong A→B→A — a driver
-- who already declined a trip could be re-offered it.
--
-- Now: every decline (manual or 30s auto-decline) is recorded on the trip's
-- declined_by set, and dispatch_trip excludes everyone in it — so a trip is
-- never re-offered to a driver who already passed on it.

alter table public.trips
  add column if not exists declined_by uuid[] not null default '{}';

-- dispatch_trip: same eligibility as before (tier · range · compliance · radius)
-- plus "never a driver who already declined this trip".
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
    and d.driver_id <> all (coalesce(v_trip.declined_by, '{}'::uuid[]))
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

-- decline_ride: record the decliner in declined_by, free them, and re-dispatch
-- (the declined-set is now enforced inside dispatch_trip).
create or replace function public.decline_ride(p_trip uuid)
returns public.trips
language plpgsql security definer set search_path = public
as $$
declare v_driver uuid := auth.uid();
begin
  update public.trips
     set driver_id = null, vehicle_id = null, status = 'requested', matched_at = null,
         declined_by = array_append(declined_by, v_driver)
   where id = p_trip and driver_id = v_driver and status = 'matched';

  update public.driver_locations set is_available = true where driver_id = v_driver;
  return public.dispatch_trip(p_trip);
end; $$;
