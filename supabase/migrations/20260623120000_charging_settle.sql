-- Make charging settle self-contained: stop_charging now takes the final meter
-- reading (kWh + battery %) and writes the session AND the vehicle battery/range
-- directly — so the charge always lands even if the live update_charging ticks
-- were lost. (Previously settle relied on the fire-and-forget ticks having
-- persisted, so a session could settle at 0 kWh and the drive page never climbed.)

drop function if exists public.stop_charging(uuid);

create or replace function public.stop_charging(
  p_session uuid, p_kwh numeric default null, p_pct integer default null
) returns public.charging_sessions
language plpgsql security definer set search_path = public
as $$
declare
  v_sess     public.charging_sessions;
  v_vat_rate numeric;
  v_cost     numeric(8, 2);
  v_vat      numeric(8, 2);
  v_kwh      numeric;
  v_pct      integer;
  v_veh      public.vehicles;
  v_kmpp     numeric;
begin
  select * into v_sess from public.charging_sessions
   where id = p_session and driver_id = auth.uid();
  if v_sess.id is null then raise exception 'Session not found'; end if;
  if v_sess.status <> 'active' then return v_sess; end if;

  -- Trust the passed final reading; fall back to whatever was persisted.
  v_kwh := greatest(0, coalesce(p_kwh, v_sess.kwh, 0));
  v_pct := least(100, greatest(0, coalesce(p_pct, v_sess.end_pct, v_sess.start_pct, 0)));

  select vat_rate into v_vat_rate from public.pricing where region = 'dubai';
  v_cost := round(v_kwh * coalesce(v_sess.rate_per_kwh, 0.70), 2);
  v_vat  := round(v_cost * coalesce(v_vat_rate, 0.05), 2);

  update public.charging_sessions
     set ended_at = now(), status = 'completed',
         kwh = v_kwh, end_pct = v_pct, cost = v_cost, vat = v_vat
   where id = p_session
   returning * into v_sess;

  if v_sess.station_id is not null then
    update public.charging_stations
       set available_stalls = least(total_stalls, available_stalls + 1)
     where id = v_sess.station_id;
  end if;

  -- Apply the final charge to the vehicle (battery + proportional range).
  select v.* into v_veh
  from public.vehicles v
  join public.driver_details d on d.current_vehicle_id = v.id
  where d.driver_id = auth.uid();
  if v_veh.id is not null then
    v_kmpp := case when coalesce(v_veh.battery_percent, 0) > 0
                   then v_veh.range_km::numeric / v_veh.battery_percent
                   else 3.2 end;
    update public.vehicles
       set status = 'active',
           battery_percent = v_pct,
           range_km = greatest(0, round(v_pct * v_kmpp))
     where id = v_veh.id;
  end if;

  return v_sess;
end; $$;

grant execute on function public.stop_charging(uuid, numeric, integer) to authenticated;
