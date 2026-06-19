-- Punch-list #4 (Phase 1) · Round-robin with timeout-vs-decline semantics.
--
-- decline  = hard no  → declined_by (never re-offered this trip).      [from #4]
-- timeout  = soft pass → passed_by  (skipped this round, eligible again next).
--
-- The request circulates A→B→C…; when everyone eligible has declined or passed,
-- the passed_by set is cleared to start another round (so timed-out drivers get
-- another chance) — capped at 2 full rounds, after which the trip stays
-- 'requested' and the rider's no-driver handling takes over.

alter table public.trips
  add column if not exists passed_by      uuid[]  not null default '{}',
  add column if not exists dispatch_rounds integer not null default 1;

-- dispatch_trip: eligibility (tier · range · compliance · radius) minus the
-- declined set and the current round's passed set; loops into the next round
-- (clearing passed_by) up to the 2-round cap.
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

  loop
    select d.driver_id, d.current_vehicle_id
      into v_driver, v_veh
    from public.driver_details d
    join public.vehicles v         on v.id = d.current_vehicle_id
    join public.driver_locations l on l.driver_id = d.driver_id
    where d.account_status = 'active'
      and d.is_online
      and l.is_available
      and v.status = 'active'
      and v.tier = v_trip.tier_id
      and v.range_km >= v_trip.distance_km
      and (p_exclude is null or d.driver_id <> p_exclude)
      and d.driver_id <> all (coalesce(v_trip.declined_by, '{}'::uuid[]))
      and d.driver_id <> all (coalesce(v_trip.passed_by,   '{}'::uuid[]))
      and public.haversine_km(l.lat, l.lng, v_trip.pickup_lat, v_trip.pickup_lng) <= v_radius
      and not exists (
        select 1 from public.driver_documents dx
        where dx.driver_id = d.driver_id
          and dx.expires_at is not null and dx.expires_at < current_date
      )
    order by public.haversine_km(l.lat, l.lng, v_trip.pickup_lat, v_trip.pickup_lng)
    limit 1;

    if v_driver is not null then
      update public.trips
         set driver_id = v_driver, vehicle_id = v_veh,
             status = 'matched', matched_at = now()
       where id = p_trip
       returning * into v_trip;
      update public.driver_locations set is_available = false where driver_id = v_driver;
      insert into public.trip_events (trip_id, status, actor_id) values (p_trip, 'matched', v_driver);
      return v_trip;
    end if;

    -- No eligible driver this round.
    exit when v_trip.dispatch_rounds >= 2;                          -- 2-round cap
    exit when coalesce(array_length(v_trip.passed_by, 1), 0) = 0;   -- nobody to retry

    -- Next round: the drivers who only timed out become eligible again.
    update public.trips
       set dispatch_rounds = dispatch_rounds + 1, passed_by = '{}'::uuid[]
     where id = p_trip
     returning * into v_trip;
  end loop;

  return v_trip;  -- stays 'requested'
end; $$;

-- pass_ride: the 30s timeout (soft). Records the driver in passed_by, frees
-- them, and re-dispatches. NOT a hard decline — they can be re-offered next round.
create or replace function public.pass_ride(p_trip uuid)
returns public.trips
language plpgsql security definer set search_path = public
as $$
declare v_driver uuid := auth.uid();
begin
  update public.trips
     set driver_id = null, vehicle_id = null, status = 'requested', matched_at = null,
         passed_by = array_append(passed_by, v_driver)
   where id = p_trip and driver_id = v_driver and status = 'matched';

  update public.driver_locations set is_available = true where driver_id = v_driver;
  return public.dispatch_trip(p_trip);
end; $$;

grant execute on function public.pass_ride(uuid) to authenticated;
