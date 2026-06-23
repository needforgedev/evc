-- Charging-session lifecycle · Phase 1: real session spine + (app-)simulated
-- live meter + settle. States: active → completed. Reserve/queue, idle penalty,
-- and the Watanya margin split are Phase 2.
--
-- The session row (kwh, cost, vat) IS the billing record. The simulated meter
-- (no charger hardware) ticks update_charging; when real OCPP exists, only the
-- meter source changes — start/stop/settle/pricing already work.

alter table public.charging_stations
  add column if not exists price_per_kwh numeric(6, 3) not null default 0.70; -- AED/kWh

alter table public.charging_sessions
  add column if not exists status       text not null default 'active', -- active | completed
  add column if not exists cost         numeric(8, 2),
  add column if not exists vat          numeric(8, 2),
  add column if not exists rate_per_kwh numeric(6, 3),
  add column if not exists power_kw     integer,
  add column if not exists target_pct   integer;

-- Open a session: take a stall, put the driver offline + vehicle charging.
create or replace function public.start_charging(p_station uuid, p_target_pct integer default 100)
returns public.charging_sessions
language plpgsql security definer set search_path = public
as $$
declare
  v_uid  uuid := auth.uid();
  v_st   public.charging_stations;
  v_veh  public.vehicles;
  v_sess public.charging_sessions;
begin
  select * into v_st from public.charging_stations where id = p_station;
  if v_st.id is null then raise exception 'Unknown station'; end if;
  if v_st.available_stalls <= 0 then raise exception 'Station full'; end if;

  select v.* into v_veh
  from public.vehicles v
  join public.driver_details d on d.current_vehicle_id = v.id
  where d.driver_id = v_uid;

  insert into public.charging_sessions
    (driver_id, station_id, start_pct, end_pct, kwh, status, rate_per_kwh, power_kw, target_pct)
  values
    (v_uid, p_station, coalesce(v_veh.battery_percent, 20), coalesce(v_veh.battery_percent, 20),
     0, 'active', coalesce(v_st.price_per_kwh, 0.70), coalesce(v_st.power_kw, 60),
     greatest(1, least(100, p_target_pct)))
  returning * into v_sess;

  update public.charging_stations
     set available_stalls = greatest(0, available_stalls - 1) where id = p_station;
  if v_veh.id is not null then
    update public.vehicles set status = 'charging' where id = v_veh.id;
  end if;
  update public.driver_details   set is_online = false    where driver_id = v_uid;
  update public.driver_locations set is_available = false where driver_id = v_uid;
  return v_sess;
end; $$;

-- Live meter tick (simulated): persist kWh + battery %.
create or replace function public.update_charging(p_session uuid, p_kwh numeric, p_pct integer)
returns void
language plpgsql security definer set search_path = public
as $$
begin
  update public.charging_sessions
     set kwh = p_kwh, end_pct = p_pct
   where id = p_session and driver_id = auth.uid() and status = 'active';

  update public.vehicles v set battery_percent = least(100, greatest(0, p_pct))
  from public.driver_details d
  where d.driver_id = auth.uid() and d.current_vehicle_id = v.id;
end; $$;

-- Stop + settle: cost = kWh × rate (+ VAT); free the stall; restore the vehicle.
create or replace function public.stop_charging(p_session uuid)
returns public.charging_sessions
language plpgsql security definer set search_path = public
as $$
declare
  v_sess     public.charging_sessions;
  v_vat_rate numeric;
  v_cost     numeric(8, 2);
  v_vat      numeric(8, 2);
begin
  select * into v_sess from public.charging_sessions
   where id = p_session and driver_id = auth.uid();
  if v_sess.id is null then raise exception 'Session not found'; end if;
  if v_sess.status <> 'active' then return v_sess; end if;

  select vat_rate into v_vat_rate from public.pricing where region = 'dubai';
  v_cost := round(coalesce(v_sess.kwh, 0) * coalesce(v_sess.rate_per_kwh, 0.70), 2);
  v_vat  := round(v_cost * coalesce(v_vat_rate, 0.05), 2);

  update public.charging_sessions
     set ended_at = now(), status = 'completed', cost = v_cost, vat = v_vat
   where id = p_session
   returning * into v_sess;

  if v_sess.station_id is not null then
    update public.charging_stations
       set available_stalls = least(total_stalls, available_stalls + 1)
     where id = v_sess.station_id;
  end if;
  update public.vehicles v set status = 'active'
  from public.driver_details d
  where d.driver_id = auth.uid() and d.current_vehicle_id = v.id;

  return v_sess;
end; $$;

grant execute on function public.start_charging(uuid, integer)        to authenticated;
grant execute on function public.update_charging(uuid, numeric, integer) to authenticated;
grant execute on function public.stop_charging(uuid)                  to authenticated;

-- Realtime (admin live view, later).
alter table public.charging_sessions replica identity full;
alter publication supabase_realtime add table public.charging_sessions;
