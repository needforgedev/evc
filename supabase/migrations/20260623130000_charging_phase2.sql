-- Charging Phase 2a · idle penalty + grace (CHG-03) and the Watanya margin
-- split (CHG-07). Both compute at settle; no new tables.
--   • Idle fee  = idle minutes × per-station idle rate (after a grace period).
--   • Margin    = energy revenue − blended supply cost; Watanya gets 30% of it.

alter table public.charging_stations
  add column if not exists grid_cost_per_kwh numeric(6, 3) not null default 0.40, -- blended grid/PV supply cost
  add column if not exists idle_fee_per_min  numeric(6, 2) not null default 1.00; -- AED/min after grace

alter table public.charging_sessions
  add column if not exists idle_min         integer not null default 0,
  add column if not exists idle_fee         numeric(8, 2) not null default 0,
  add column if not exists margin           numeric(8, 2),
  add column if not exists watanya_share    numeric(8, 2),
  add column if not exists idle_fee_per_min numeric(6, 2),
  add column if not exists grid_cost_per_kwh numeric(6, 3);

-- start: also capture the station's idle rate + supply cost onto the session.
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
    (driver_id, station_id, start_pct, end_pct, kwh, status,
     rate_per_kwh, power_kw, target_pct, idle_fee_per_min, grid_cost_per_kwh)
  values
    (v_uid, p_station, coalesce(v_veh.battery_percent, 20), coalesce(v_veh.battery_percent, 20),
     0, 'active', coalesce(v_st.price_per_kwh, 0.70), coalesce(v_st.power_kw, 60),
     greatest(1, least(100, p_target_pct)),
     coalesce(v_st.idle_fee_per_min, 1.00), coalesce(v_st.grid_cost_per_kwh, 0.40))
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

-- stop + settle: final reading + idle minutes → cost (energy + idle) + VAT, plus
-- the Watanya margin split. Writes the vehicle battery/range.
drop function if exists public.stop_charging(uuid, numeric, integer);

create or replace function public.stop_charging(
  p_session uuid, p_kwh numeric default null, p_pct integer default null,
  p_idle_min integer default 0
) returns public.charging_sessions
language plpgsql security definer set search_path = public
as $$
declare
  v_sess     public.charging_sessions;
  v_vat_rate numeric;
  v_kwh      numeric;
  v_pct      integer;
  v_idle_min integer;
  v_energy   numeric(8, 2);
  v_idle     numeric(8, 2);
  v_cost     numeric(8, 2);
  v_vat      numeric(8, 2);
  v_supply   numeric(8, 2);
  v_margin   numeric(8, 2);
  v_watanya  numeric(8, 2);
  v_veh      public.vehicles;
  v_kmpp     numeric;
begin
  select * into v_sess from public.charging_sessions
   where id = p_session and driver_id = auth.uid();
  if v_sess.id is null then raise exception 'Session not found'; end if;
  if v_sess.status <> 'active' then return v_sess; end if;

  v_kwh      := greatest(0, coalesce(p_kwh, v_sess.kwh, 0));
  v_pct      := least(100, greatest(0, coalesce(p_pct, v_sess.end_pct, v_sess.start_pct, 0)));
  v_idle_min := greatest(0, coalesce(p_idle_min, 0));

  select vat_rate into v_vat_rate from public.pricing where region = 'dubai';

  v_energy  := round(v_kwh * coalesce(v_sess.rate_per_kwh, 0.70), 2);
  v_idle    := round(v_idle_min * coalesce(v_sess.idle_fee_per_min, 1.00), 2);
  v_cost    := v_energy + v_idle;
  v_vat     := round(v_cost * coalesce(v_vat_rate, 0.05), 2);
  v_supply  := round(v_kwh * coalesce(v_sess.grid_cost_per_kwh, 0.40), 2);
  v_margin  := round(v_energy - v_supply, 2);
  v_watanya := round(greatest(0, v_margin) * 0.30, 2); -- Watanya 30% of net margin

  update public.charging_sessions
     set ended_at = now(), status = 'completed',
         kwh = v_kwh, end_pct = v_pct, idle_min = v_idle_min, idle_fee = v_idle,
         cost = v_cost, vat = v_vat, margin = v_margin, watanya_share = v_watanya
   where id = p_session
   returning * into v_sess;

  if v_sess.station_id is not null then
    update public.charging_stations
       set available_stalls = least(total_stalls, available_stalls + 1)
     where id = v_sess.station_id;
  end if;

  select v.* into v_veh
  from public.vehicles v
  join public.driver_details d on d.current_vehicle_id = v.id
  where d.driver_id = auth.uid();
  if v_veh.id is not null then
    v_kmpp := case when coalesce(v_veh.battery_percent, 0) > 0
                   then v_veh.range_km::numeric / v_veh.battery_percent
                   else 3.2 end;
    update public.vehicles
       set status = 'active', battery_percent = v_pct,
           range_km = greatest(0, round(v_pct * v_kmpp))
     where id = v_veh.id;
  end if;

  return v_sess;
end; $$;

grant execute on function public.start_charging(uuid, integer)                  to authenticated;
grant execute on function public.stop_charging(uuid, numeric, integer, integer) to authenticated;
