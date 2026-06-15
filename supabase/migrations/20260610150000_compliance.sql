-- Compliance engine: document expiry tracking, tiered 60/30/14/7-day alerts,
-- and automatic removal from the dispatch pool when a required doc lapses.
-- (PRD: ONO-04 / MAT-05 / KYC-04 · Compliance Engine #15.)

-- ── schema ──
alter table public.driver_documents
  add column if not exists expires_at date;

alter table public.driver_details
  add column if not exists compliance_blocked boolean not null default false;

create table if not exists public.compliance_alerts (
  id          uuid primary key default gen_random_uuid(),
  driver_id   uuid not null references public.profiles (id) on delete cascade,
  doc_type    doc_type not null,
  expires_at  date not null,
  days_bucket int not null,                 -- 60 / 30 / 14 / 7 / 0 (= expired)
  resolved    boolean not null default false,
  created_at  timestamptz not null default now(),
  unique (driver_id, doc_type, expires_at, days_bucket)
);
alter table public.compliance_alerts enable row level security;
create policy compliance_alerts_select on public.compliance_alerts for select
  using (driver_id = auth.uid() or public.is_admin());
create index if not exists idx_compliance_alerts_driver
  on public.compliance_alerts (driver_id) where not resolved;

-- ── daily job: generate tiered alerts + block/unblock + resolve renewals ──
create or replace function public.run_compliance_check()
returns void
language plpgsql security definer set search_path = public
as $$
begin
  -- 1. Fire tiered alerts (idempotent — one row per doc · expiry · bucket).
  insert into public.compliance_alerts (driver_id, doc_type, expires_at, days_bucket)
  select dd.driver_id, dd.type, dd.expires_at, b.bucket
  from public.driver_documents dd
  cross join (values (60), (30), (14), (7), (0)) as b(bucket)
  where dd.review_status = 'approved' and dd.expires_at is not null
    and (
      (b.bucket = 0 and dd.expires_at < current_date) or
      (b.bucket > 0 and (dd.expires_at - current_date) between 0 and b.bucket)
    )
  on conflict (driver_id, doc_type, expires_at, days_bucket) do nothing;

  -- 2. Block (and force offline) drivers with an expired approved doc; clear
  --    the block for drivers whose docs are all valid again.
  update public.driver_details d
     set compliance_blocked = sub.has_expired,
         is_online = case when sub.has_expired then false else d.is_online end
  from (
    select dd.driver_id, bool_or(dd.expires_at < current_date) as has_expired
    from public.driver_documents dd
    where dd.review_status = 'approved' and dd.expires_at is not null
    group by dd.driver_id
  ) sub
  where d.driver_id = sub.driver_id;

  -- 3. Resolve alerts superseded by a renewal (new approved expiry date).
  update public.compliance_alerts a
     set resolved = true
   where not a.resolved
     and not exists (
       select 1 from public.driver_documents dd
       where dd.driver_id = a.driver_id and dd.type = a.doc_type
         and dd.expires_at = a.expires_at and dd.review_status = 'approved'
     );
end; $$;

grant execute on function public.run_compliance_check() to authenticated;

-- ── real-time enforcement (cron-independent: no gap at midnight) ──

-- Driver cannot go online with an expired approved document.
create or replace function public.driver_set_online(p_online boolean)
returns void
language plpgsql security definer set search_path = public
as $$
begin
  if p_online and exists (
    select 1 from public.driver_documents
    where driver_id = auth.uid() and review_status = 'approved'
      and expires_at is not null and expires_at < current_date
  ) then
    raise exception 'compliance_blocked: a required document has expired';
  end if;

  update public.driver_details set is_online = p_online where driver_id = auth.uid();
  insert into public.driver_locations (driver_id, lat, lng, is_available)
  values (auth.uid(), 0, 0, p_online)
  on conflict (driver_id) do update set is_available = p_online, updated_at = now();
end; $$;

-- Dispatch never matches a driver with an expired approved document.
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
    and not exists (
      select 1 from public.driver_documents dx
      where dx.driver_id = d.driver_id and dx.review_status = 'approved'
        and dx.expires_at is not null and dx.expires_at < current_date
    )
  order by public.haversine_km(l.lat, l.lng, v_trip.pickup_lat, v_trip.pickup_lng)
  limit 1;

  if v_driver is null then
    return v_trip;
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

-- ── schedule the daily job (00:05) — needs the pg_cron extension ──
-- Enforcement above works without it; the cron only fires proactive alerts.
do $$
begin
  execute 'create extension if not exists pg_cron';
  perform cron.schedule('compliance-daily', '5 0 * * *',
      'select public.run_compliance_check();');
exception when others then
  raise notice 'pg_cron unavailable — enable it in Supabase Dashboard → Database → Extensions, then run: select cron.schedule(''compliance-daily'', ''5 0 * * *'', ''select public.run_compliance_check();''); Real-time enforcement is active regardless.';
end $$;

-- Seed once now.
select public.run_compliance_check();