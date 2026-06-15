-- Fix: an EXPIRED document must block the driver regardless of its review
-- status. The first version only counted `review_status = 'approved'` docs, so
-- a freshly-uploaded (pending) expired doc was ignored and the driver could
-- still go online. Now any document whose expiry has passed blocks.

create or replace function public.run_compliance_check()
returns void
language plpgsql security definer set search_path = public
as $$
begin
  -- 1. Tiered alerts for every doc with an expiry (idempotent).
  insert into public.compliance_alerts (driver_id, doc_type, expires_at, days_bucket)
  select dd.driver_id, dd.type, dd.expires_at, b.bucket
  from public.driver_documents dd
  cross join (values (60), (30), (14), (7), (0)) as b(bucket)
  where dd.expires_at is not null
    and (
      (b.bucket = 0 and dd.expires_at < current_date) or
      (b.bucket > 0 and (dd.expires_at - current_date) between 0 and b.bucket)
    )
  on conflict (driver_id, doc_type, expires_at, days_bucket) do nothing;

  -- 2. Block (and force offline) drivers with any expired doc; clear otherwise.
  update public.driver_details d
     set compliance_blocked = sub.has_expired,
         is_online = case when sub.has_expired then false else d.is_online end
  from (
    select dd.driver_id, bool_or(dd.expires_at < current_date) as has_expired
    from public.driver_documents dd
    where dd.expires_at is not null
    group by dd.driver_id
  ) sub
  where d.driver_id = sub.driver_id;

  -- 3. Resolve alerts superseded by a renewal (expiry date changed).
  update public.compliance_alerts a
     set resolved = true
   where not a.resolved
     and not exists (
       select 1 from public.driver_documents dd
       where dd.driver_id = a.driver_id and dd.type = a.doc_type
         and dd.expires_at = a.expires_at
     );
end; $$;

-- Driver cannot go online with ANY expired document.
create or replace function public.driver_set_online(p_online boolean)
returns void
language plpgsql security definer set search_path = public
as $$
begin
  if p_online and exists (
    select 1 from public.driver_documents
    where driver_id = auth.uid()
      and expires_at is not null and expires_at < current_date
  ) then
    raise exception 'compliance_blocked: a required document has expired';
  end if;

  update public.driver_details set is_online = p_online where driver_id = auth.uid();
  insert into public.driver_locations (driver_id, lat, lng, is_available)
  values (auth.uid(), 0, 0, p_online)
  on conflict (driver_id) do update set is_available = p_online, updated_at = now();
end; $$;

-- Dispatch never matches a driver with an expired document.
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
      where dx.driver_id = d.driver_id
        and dx.expires_at is not null and dx.expires_at < current_date
    )
  order by public.haversine_km(l.lat, l.lng, v_trip.pickup_lat, v_trip.pickup_lng)
  limit 1;

  if v_driver is null then return v_trip; end if;

  update public.trips
     set driver_id = v_driver, vehicle_id = v_veh,
         status = 'matched', matched_at = now()
   where id = p_trip
   returning * into v_trip;

  update public.driver_locations set is_available = false where driver_id = v_driver;
  insert into public.trip_events (trip_id, status, actor_id) values (p_trip, 'matched', v_driver);
  return v_trip;
end; $$;

-- Re-evaluate now.
select public.run_compliance_check();
