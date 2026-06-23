-- Charging Phase 2b · reserve/queue (CHG-02) + admin station rate (ADM-05).
--
-- charging_queue holds one row per driver-intent at a station:
--   reserved = holds a free stall (10-min expiry) · queued = waiting for one.
-- A freed stall (leave / stop / expiry) promotes the oldest queued driver.

create table if not exists public.charging_queue (
  id          uuid primary key default gen_random_uuid(),
  station_id  uuid not null references public.charging_stations (id) on delete cascade,
  driver_id   uuid not null references public.profiles (id) on delete cascade,
  status      text not null default 'queued', -- queued | reserved
  created_at  timestamptz not null default now(),
  reserved_at timestamptz,
  expires_at  timestamptz,
  unique (station_id, driver_id)
);

alter table public.charging_queue enable row level security;
-- Readable by any signed-in user (so a driver can compute their live position);
-- writable only for own rows (or admin).
create policy charging_queue_select on public.charging_queue
  for select using (true);
create policy charging_queue_insert on public.charging_queue
  for insert with check (driver_id = auth.uid());
create policy charging_queue_update on public.charging_queue
  for update using (driver_id = auth.uid() or public.is_admin());
create policy charging_queue_delete on public.charging_queue
  for delete using (driver_id = auth.uid() or public.is_admin());

alter table public.charging_queue     replica identity full;
alter table public.charging_stations  replica identity full;
alter publication supabase_realtime add table public.charging_queue;
alter publication supabase_realtime add table public.charging_stations;

-- ── internal helpers ───────────────────────────────────────────
-- Release stalls held by reservations that have expired.
create or replace function public._expire_reservations(p_station uuid)
returns void language plpgsql security definer set search_path = public as $$
declare r record;
begin
  for r in select id from public.charging_queue
           where station_id = p_station and status = 'reserved' and expires_at < now()
  loop
    delete from public.charging_queue where id = r.id;
    update public.charging_stations
       set available_stalls = least(total_stalls, available_stalls + 1)
     where id = p_station;
  end loop;
end; $$;

-- Give a freed stall to the oldest queued driver.
create or replace function public._promote_queue(p_station uuid)
returns void language plpgsql security definer set search_path = public as $$
declare v_st public.charging_stations; v_next public.charging_queue;
begin
  perform public._expire_reservations(p_station);
  select * into v_st from public.charging_stations where id = p_station for update;
  if v_st.available_stalls <= 0 then return; end if;
  select * into v_next from public.charging_queue
   where station_id = p_station and status = 'queued'
   order by created_at limit 1;
  if v_next.id is null then return; end if;
  update public.charging_stations set available_stalls = available_stalls - 1 where id = p_station;
  update public.charging_queue
     set status = 'reserved', reserved_at = now(), expires_at = now() + interval '10 minutes'
   where id = v_next.id;
end; $$;

-- ── driver: reserve (if free) or queue ─────────────────────────
create or replace function public.join_charging_queue(p_station uuid)
returns public.charging_queue
language plpgsql security definer set search_path = public as $$
declare v_uid uuid := auth.uid(); v_st public.charging_stations; v_q public.charging_queue;
begin
  perform public._expire_reservations(p_station);
  select * into v_st from public.charging_stations where id = p_station for update;
  if v_st.id is null then raise exception 'Unknown station'; end if;

  delete from public.charging_queue where station_id = p_station and driver_id = v_uid; -- idempotent

  if v_st.available_stalls > 0 then
    update public.charging_stations set available_stalls = available_stalls - 1 where id = p_station;
    insert into public.charging_queue (station_id, driver_id, status, reserved_at, expires_at)
      values (p_station, v_uid, 'reserved', now(), now() + interval '10 minutes')
      returning * into v_q;
  else
    insert into public.charging_queue (station_id, driver_id, status)
      values (p_station, v_uid, 'queued') returning * into v_q;
  end if;
  return v_q;
end; $$;

create or replace function public.leave_charging_queue(p_station uuid)
returns void language plpgsql security definer set search_path = public as $$
declare v_uid uuid := auth.uid(); v_q public.charging_queue;
begin
  select * into v_q from public.charging_queue where station_id = p_station and driver_id = v_uid;
  if v_q.id is null then return; end if;
  delete from public.charging_queue where id = v_q.id;
  if v_q.status = 'reserved' then
    update public.charging_stations
       set available_stalls = least(total_stalls, available_stalls + 1) where id = p_station;
    perform public._promote_queue(p_station);
  end if;
end; $$;

-- ── start_charging: consume a reservation if present ───────────
create or replace function public.start_charging(p_station uuid, p_target_pct integer default 100)
returns public.charging_sessions
language plpgsql security definer set search_path = public
as $$
declare
  v_uid  uuid := auth.uid();
  v_st   public.charging_stations;
  v_veh  public.vehicles;
  v_sess public.charging_sessions;
  v_resv public.charging_queue;
begin
  perform public._expire_reservations(p_station);
  select * into v_st from public.charging_stations where id = p_station for update;
  if v_st.id is null then raise exception 'Unknown station'; end if;

  select * into v_resv from public.charging_queue
   where station_id = p_station and driver_id = v_uid and status = 'reserved';
  if v_resv.id is not null then
    delete from public.charging_queue where id = v_resv.id; -- stall already held by the reservation
  elsif v_st.available_stalls <= 0 then
    raise exception 'Station full — join the queue';
  else
    update public.charging_stations set available_stalls = available_stalls - 1 where id = p_station;
  end if;

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

  if v_veh.id is not null then
    update public.vehicles set status = 'charging' where id = v_veh.id;
  end if;
  update public.driver_details   set is_online = false    where driver_id = v_uid;
  update public.driver_locations set is_available = false where driver_id = v_uid;
  return v_sess;
end; $$;

-- ── stop_charging: free the stall + promote the queue ──────────
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
  v_watanya := round(greatest(0, v_margin) * 0.30, 2);

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
    perform public._promote_queue(v_sess.station_id);
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

-- ── admin: set the customer charge rate (ADM-05) ───────────────
create or replace function public.admin_set_station_rate(p_station uuid, p_rate numeric)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_admin() then raise exception 'Admins only'; end if;
  update public.charging_stations set price_per_kwh = greatest(0, p_rate) where id = p_station;
end; $$;

grant execute on function public.join_charging_queue(uuid)        to authenticated;
grant execute on function public.leave_charging_queue(uuid)       to authenticated;
grant execute on function public.admin_set_station_rate(uuid, numeric) to authenticated;
