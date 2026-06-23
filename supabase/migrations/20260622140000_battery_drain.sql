-- Make the battery move with real use: a completed trip drains it by distance,
-- and a charging session refills it — keeping battery % and range_km in sync
-- (range = battery% × the vehicle's km-per-% ratio).

-- complete_trip: same as before + drain the driver's EV by the trip distance.
create or replace function public.complete_trip(p_trip uuid, p_tip numeric default 0)
returns public.trips
language plpgsql security definer set search_path = public
as $$
declare
  v_trip       public.trips;
  v_vat_rate   numeric;
  v_fare       numeric;
  v_pay_status payment_status;
  v_veh        public.vehicles;
  v_kmpp       numeric;
  v_used       integer;
  v_newbat     integer;
begin
  select vat_rate into v_vat_rate from public.pricing where region = 'dubai';
  select * into v_trip from public.trips
   where id = p_trip and driver_id = auth.uid() and status = 'ongoing';
  if v_trip.id is null then raise exception 'Trip not completable'; end if;

  v_fare := coalesce(v_trip.final_fare, v_trip.fare_estimate);
  v_pay_status := case v_trip.payment_type
                    when 'card' then 'authorized'::payment_status
                    else 'captured'::payment_status
                  end;

  update public.trips
     set status = 'completed', completed_at = now(),
         final_fare = round(v_fare, 2), vat = round(v_fare * v_vat_rate, 2),
         tip = coalesce(p_tip, 0)
   where id = p_trip
   returning * into v_trip;

  insert into public.payments (trip_id, rider_id, amount, vat, tip, type, status)
  values (p_trip, v_trip.rider_id, v_trip.final_fare, v_trip.vat, v_trip.tip,
          v_trip.payment_type, v_pay_status);

  update public.profiles set total_trips = total_trips + 1
   where id in (v_trip.rider_id, v_trip.driver_id);
  update public.driver_locations set is_available = true
   where driver_id = v_trip.driver_id;
  insert into public.trip_events (trip_id, status, actor_id)
  values (p_trip, 'completed', auth.uid());

  -- ── Battery drain: % used = trip distance / (km per %) ──
  select v.* into v_veh
  from public.vehicles v
  join public.driver_details d on d.current_vehicle_id = v.id
  where d.driver_id = v_trip.driver_id;
  if v_veh.id is not null then
    v_kmpp := case when coalesce(v_veh.battery_percent, 0) > 0
                   then v_veh.range_km::numeric / v_veh.battery_percent
                   else 3.2 end;
    v_used   := round(coalesce(v_trip.distance_km, 0) / greatest(v_kmpp, 0.5));
    v_newbat := greatest(0, v_veh.battery_percent - v_used);
    update public.vehicles
       set battery_percent = v_newbat,
           range_km        = greatest(0, round(v_newbat * v_kmpp))
     where id = v_veh.id;
  end if;

  return v_trip;
end; $$;

-- update_charging: refill battery AND range (keep the km-per-% ratio).
create or replace function public.update_charging(p_session uuid, p_kwh numeric, p_pct integer)
returns void
language plpgsql security definer set search_path = public
as $$
declare
  v_veh  public.vehicles;
  v_kmpp numeric;
  v_pct  integer := least(100, greatest(0, p_pct));
begin
  update public.charging_sessions
     set kwh = p_kwh, end_pct = p_pct
   where id = p_session and driver_id = auth.uid() and status = 'active';

  select v.* into v_veh
  from public.vehicles v
  join public.driver_details d on d.current_vehicle_id = v.id
  where d.driver_id = auth.uid();
  if v_veh.id is not null then
    v_kmpp := case when coalesce(v_veh.battery_percent, 0) > 0
                   then v_veh.range_km::numeric / v_veh.battery_percent
                   else 3.2 end;
    update public.vehicles
       set battery_percent = v_pct,
           range_km        = greatest(0, round(v_pct * v_kmpp))
     where id = v_veh.id;
  end if;
end; $$;
