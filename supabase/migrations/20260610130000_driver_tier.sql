-- Give each vehicle a service tier and make dispatch match the rider's
-- requested tier to a driver whose vehicle serves that tier.

alter table public.vehicles
  add column if not exists tier text not null default 'go'
    references public.ride_tiers (id);

-- dispatch_trip now also requires the matched vehicle's tier == the trip's tier.
create or replace function public.dispatch_trip(p_trip uuid, p_exclude uuid default null)
returns public.trips
language plpgsql security definer set search_path = public
as $$
declare
  v_trip   public.trips;
  v_driver uuid;
  v_veh    uuid;
begin
  select * into v_trip from public.trips where id = p_trip;
  if v_trip.status <> 'requested' then return v_trip; end if;

  -- Nearest online+available driver whose EV serves the requested tier and has
  -- the range to finish the trip.
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
  order by public.haversine_km(l.lat, l.lng, v_trip.pickup_lat, v_trip.pickup_lng)
  limit 1;

  if v_driver is null then
    return v_trip;                              -- stays 'requested'; retry later
  end if;

  update public.trips
     set driver_id = v_driver, vehicle_id = v_veh,
         status = 'matched', matched_at = now()
   where id = p_trip
   returning * into v_trip;

  update public.driver_locations set is_available = false where driver_id = v_driver;
  insert into public.trip_events (trip_id, status, actor_id) values (p_trip, 'matched', v_driver);
  return v_trip;
end; $$;
