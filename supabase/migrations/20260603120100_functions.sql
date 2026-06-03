-- EVC — server-authoritative logic as SECURITY DEFINER RPCs.
-- Clients call these via supabase.rpc(...) instead of writing sensitive
-- columns (fare, status, driver assignment) directly.

-- ───────────────────────── Auth: provision profile on signup ──
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  v_role user_role := coalesce((new.raw_user_meta_data ->> 'role')::user_role, 'rider');
begin
  insert into public.profiles (id, role, full_name, phone, email)
  values (
    new.id,
    v_role,
    new.raw_user_meta_data ->> 'full_name',
    new.phone,
    new.email
  );
  insert into public.wallets (user_id) values (new.id);

  -- Drivers start in the approval queue and can't go online until approved.
  if v_role = 'driver' then
    insert into public.driver_details (driver_id, account_status)
    values (new.id, 'pending');
  end if;

  return new;
end; $$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ───────────────────────── Role helpers (no RLS recursion) ────
create or replace function public.auth_role()
returns user_role
language sql stable security definer set search_path = public
as $$ select role from public.profiles where id = auth.uid() $$;

create or replace function public.is_admin()
returns boolean
language sql stable security definer set search_path = public
as $$ select exists (
  select 1 from public.profiles where id = auth.uid() and role = 'admin'
) $$;

-- ───────────────────────── Geo: haversine distance (km) ───────
create or replace function public.haversine_km(
  lat1 double precision, lng1 double precision,
  lat2 double precision, lng2 double precision
) returns double precision
language sql immutable as $$
  select 6371 * 2 * asin(sqrt(
    power(sin(radians(lat2 - lat1) / 2), 2) +
    cos(radians(lat1)) * cos(radians(lat2)) *
    power(sin(radians(lng2 - lng1) / 2), 2)
  ));
$$;

-- ───────────────────────── Rider: request a ride ──────────────
create or replace function public.request_ride(
  p_tier_id      text,
  p_pickup_name  text, p_pickup_address text, p_pickup_lat double precision, p_pickup_lng double precision,
  p_dest_name    text, p_dest_address   text, p_dest_lat   double precision, p_dest_lng   double precision,
  p_payment_type payment_type default 'card',
  p_promo_code   text default null
) returns public.trips
language plpgsql security definer set search_path = public
as $$
declare
  v_rider    uuid := auth.uid();
  v_price    public.pricing;
  v_tier     public.ride_tiers;
  v_dist     double precision;
  v_dur      integer;
  v_fare     numeric(8,2);
  v_trip     public.trips;
begin
  if public.auth_role() <> 'rider' then
    raise exception 'Only riders can request rides';
  end if;

  select * into v_price from public.pricing where region = 'dubai';
  select * into v_tier  from public.ride_tiers where id = p_tier_id and active;
  if v_tier.id is null then raise exception 'Unknown ride tier %', p_tier_id; end if;

  v_dist := public.haversine_km(p_pickup_lat, p_pickup_lng, p_dest_lat, p_dest_lng);
  v_dur  := greatest(1, ceil(v_dist / 0.4));   -- ~24 km/h city average
  v_fare := greatest(
    v_price.min_fare,
    (v_price.base_fare + v_price.per_km * v_dist + v_price.per_min * v_dur) * v_tier.multiplier
  );

  insert into public.trips (
    rider_id, tier_id, status,
    pickup_name, pickup_address, pickup_lat, pickup_lng,
    dest_name, dest_address, dest_lat, dest_lng,
    distance_km, duration_min, fare_estimate, co2_saved_kg,
    payment_type, promo_code, pin
  ) values (
    v_rider, p_tier_id, 'requested',
    p_pickup_name, p_pickup_address, p_pickup_lat, p_pickup_lng,
    p_dest_name, p_dest_address, p_dest_lat, p_dest_lng,
    round(v_dist::numeric, 2), v_dur, round(v_fare, 2), round((v_dist * 0.15)::numeric, 2),
    p_payment_type, p_promo_code, lpad((floor(random() * 10000))::int::text, 4, '0')
  ) returning * into v_trip;

  insert into public.trip_events (trip_id, status, actor_id) values (v_trip.id, 'requested', v_rider);

  -- Try to match a driver immediately (range-aware).
  v_trip := public.dispatch_trip(v_trip.id);
  return v_trip;
end; $$;

-- ───────────────────────── Dispatch: range-aware matching ─────
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

  -- Nearest online+available driver whose EV has the range to finish the trip.
  select d.driver_id, d.current_vehicle_id
    into v_driver, v_veh
  from public.driver_details d
  join public.vehicles v        on v.id = d.current_vehicle_id
  join public.driver_locations l on l.driver_id = d.driver_id
  where d.account_status = 'active'
    and d.is_online
    and l.is_available
    and v.status = 'active'
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

-- ───────────────────────── Driver: accept / decline ───────────
create or replace function public.accept_ride(p_trip uuid)
returns public.trips
language plpgsql security definer set search_path = public
as $$
declare v_trip public.trips;
begin
  update public.trips
     set status = 'enroute'
   where id = p_trip and driver_id = auth.uid() and status = 'matched'
   returning * into v_trip;
  if v_trip.id is null then raise exception 'Trip not assigned to you or not matchable'; end if;
  insert into public.trip_events (trip_id, status, actor_id) values (p_trip, 'enroute', auth.uid());
  return v_trip;
end; $$;

create or replace function public.decline_ride(p_trip uuid)
returns public.trips
language plpgsql security definer set search_path = public
as $$
declare v_driver uuid := auth.uid();
begin
  update public.trips set driver_id = null, vehicle_id = null, status = 'requested', matched_at = null
   where id = p_trip and driver_id = v_driver and status = 'matched';
  update public.driver_locations set is_available = true where driver_id = v_driver;
  return public.dispatch_trip(p_trip, v_driver);  -- re-match, excluding decliner
end; $$;

-- ───────────────────────── Driver: advance / complete ─────────
create or replace function public.advance_trip(p_trip uuid, p_status trip_status)
returns public.trips
language plpgsql security definer set search_path = public
as $$
declare v_trip public.trips;
begin
  if p_status not in ('arrived', 'ongoing') then
    raise exception 'advance_trip only handles arrived/ongoing';
  end if;
  update public.trips set status = p_status
   where id = p_trip and driver_id = auth.uid()
     and status = case p_status when 'arrived' then 'enroute' else 'arrived' end
   returning * into v_trip;
  if v_trip.id is null then raise exception 'Invalid transition'; end if;
  insert into public.trip_events (trip_id, status, actor_id) values (p_trip, p_status, auth.uid());
  return v_trip;
end; $$;

create or replace function public.complete_trip(p_trip uuid, p_tip numeric default 0)
returns public.trips
language plpgsql security definer set search_path = public
as $$
declare
  v_trip public.trips;
  v_vat_rate numeric;
  v_fare numeric;
begin
  select vat_rate into v_vat_rate from public.pricing where region = 'dubai';
  select * into v_trip from public.trips where id = p_trip and driver_id = auth.uid() and status = 'ongoing';
  if v_trip.id is null then raise exception 'Trip not completable'; end if;

  v_fare := coalesce(v_trip.final_fare, v_trip.fare_estimate);

  update public.trips
     set status = 'completed', completed_at = now(),
         final_fare = round(v_fare, 2), vat = round(v_fare * v_vat_rate, 2), tip = coalesce(p_tip, 0)
   where id = p_trip
   returning * into v_trip;

  insert into public.payments (trip_id, rider_id, amount, vat, tip, type, status)
  values (p_trip, v_trip.rider_id, v_trip.final_fare, v_trip.vat, v_trip.tip, v_trip.payment_type,
          case v_trip.payment_type when 'card' then 'authorized' else 'captured' end);

  update public.profiles set total_trips = total_trips + 1
   where id in (v_trip.rider_id, v_trip.driver_id);
  update public.driver_locations set is_available = true where driver_id = v_trip.driver_id;
  insert into public.trip_events (trip_id, status, actor_id) values (p_trip, 'completed', auth.uid());
  return v_trip;
end; $$;

create or replace function public.cancel_trip(p_trip uuid, p_reason text default null)
returns public.trips
language plpgsql security definer set search_path = public
as $$
declare v_trip public.trips;
begin
  select * into v_trip from public.trips where id = p_trip;
  if not (v_trip.rider_id = auth.uid() or public.is_admin()) then
    raise exception 'Not allowed to cancel this trip';
  end if;
  if v_trip.status in ('completed', 'canceled') then
    raise exception 'Trip already finalized';
  end if;
  update public.trips set status = 'canceled', canceled_reason = p_reason
   where id = p_trip returning * into v_trip;
  if v_trip.driver_id is not null then
    update public.driver_locations set is_available = true where driver_id = v_trip.driver_id;
  end if;
  insert into public.trip_events (trip_id, status, actor_id) values (p_trip, 'canceled', auth.uid());
  return v_trip;
end; $$;

-- ───────────────────────── Post-ride rating ───────────────────
create or replace function public.rate_trip(
  p_trip uuid, p_ratee uuid, p_stars int, p_tags text[] default '{}', p_comment text default null
) returns void
language plpgsql security definer set search_path = public
as $$
begin
  insert into public.ratings (trip_id, rater_id, ratee_id, stars, tags, comment)
  values (p_trip, auth.uid(), p_ratee, p_stars, coalesce(p_tags, '{}'), p_comment)
  on conflict (trip_id, rater_id) do update
    set stars = excluded.stars, tags = excluded.tags, comment = excluded.comment;

  update public.profiles p
     set rating = round((select avg(stars) from public.ratings where ratee_id = p_ratee), 2)
   where p.id = p_ratee;
end; $$;

-- ───────────────────────── Driver availability / location ─────
create or replace function public.driver_set_online(p_online boolean)
returns void
language plpgsql security definer set search_path = public
as $$
begin
  update public.driver_details set is_online = p_online where driver_id = auth.uid();
  insert into public.driver_locations (driver_id, lat, lng, is_available)
  values (auth.uid(), 0, 0, p_online)
  on conflict (driver_id) do update set is_available = p_online, updated_at = now();
end; $$;

create or replace function public.driver_update_location(
  p_lat double precision, p_lng double precision, p_heading numeric default null
) returns void
language plpgsql security definer set search_path = public
as $$
begin
  insert into public.driver_locations (driver_id, lat, lng, heading, is_available)
  values (auth.uid(), p_lat, p_lng, p_heading, true)
  on conflict (driver_id) do update
    set lat = excluded.lat, lng = excluded.lng, heading = excluded.heading, updated_at = now();
end; $$;

-- ───────────────────────── Admin actions ──────────────────────
create or replace function public.admin_set_driver_status(p_driver uuid, p_status driver_account_status)
returns void
language plpgsql security definer set search_path = public
as $$
begin
  if not public.is_admin() then raise exception 'Admin only'; end if;
  update public.driver_details
     set account_status = p_status, approved_by = auth.uid()
   where driver_id = p_driver;
end; $$;

create or replace function public.admin_reassign_trip(p_trip uuid, p_driver uuid)
returns public.trips
language plpgsql security definer set search_path = public
as $$
declare v_trip public.trips;
begin
  if not public.is_admin() then raise exception 'Admin only'; end if;
  update public.trips
     set driver_id = p_driver,
         vehicle_id = (select current_vehicle_id from public.driver_details where driver_id = p_driver),
         status = 'matched', matched_at = now()
   where id = p_trip returning * into v_trip;
  insert into public.trip_events (trip_id, status, actor_id, note)
  values (p_trip, 'matched', auth.uid(), 'reassigned by ops');
  return v_trip;
end; $$;

-- Allow authenticated users to call the RPCs (RLS still guards the tables).
grant execute on all functions in schema public to authenticated;