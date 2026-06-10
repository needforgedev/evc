-- Make promo codes functional: apply a real discount in request_ride, store the
-- discount on the trip, and add a validate_promo() RPC the app uses to preview
-- the discount before booking.

alter table public.trips
  add column if not exists discount numeric(8, 2) not null default 0;

-- Preview a promo for a given gross fare (no redemption side-effect).
create or replace function public.validate_promo(p_code text, p_fare numeric)
returns json
language plpgsql security definer set search_path = public
as $$
declare
  v_promo    public.promo_codes;
  v_discount numeric(8, 2) := 0;
begin
  if p_code is null or length(trim(p_code)) = 0 then
    return json_build_object('valid', false, 'discount', 0, 'reason', 'empty');
  end if;

  select * into v_promo from public.promo_codes
   where upper(code) = upper(trim(p_code))
     and active
     and (valid_from is null or now() >= valid_from)
     and (valid_to   is null or now() <= valid_to)
     and (max_uses   is null or redemptions < max_uses);

  if v_promo.id is null then
    return json_build_object('valid', false, 'discount', 0, 'reason', 'invalid');
  end if;

  if v_promo.discount_type = 'percent' then
    v_discount := p_fare * (v_promo.value / 100.0);
  else
    v_discount := v_promo.value;
  end if;
  if v_promo.max_discount is not null then
    v_discount := least(v_discount, v_promo.max_discount);
  end if;
  v_discount := greatest(0, least(v_discount, p_fare));

  return json_build_object(
    'valid', true,
    'discount', round(v_discount, 2),
    'description', coalesce(v_promo.description, v_promo.code)
  );
end; $$;

grant execute on function public.validate_promo(text, numeric) to authenticated;

-- request_ride now applies the promo discount (and counts the redemption).
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
  v_gross    numeric(8,2);
  v_discount numeric(8,2) := 0;
  v_fare     numeric(8,2);
  v_promo    public.promo_codes;
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
  v_gross := greatest(
    v_price.min_fare,
    (v_price.base_fare + v_price.per_km * v_dist + v_price.per_min * v_dur) * v_tier.multiplier
  );

  -- Apply promo (if any valid).
  if p_promo_code is not null and length(trim(p_promo_code)) > 0 then
    select * into v_promo from public.promo_codes
     where upper(code) = upper(trim(p_promo_code))
       and active
       and (valid_from is null or now() >= valid_from)
       and (valid_to   is null or now() <= valid_to)
       and (max_uses   is null or redemptions < max_uses);
    if v_promo.id is not null then
      if v_promo.discount_type = 'percent' then
        v_discount := v_gross * (v_promo.value / 100.0);
      else
        v_discount := v_promo.value;
      end if;
      if v_promo.max_discount is not null then
        v_discount := least(v_discount, v_promo.max_discount);
      end if;
      v_discount := greatest(0, least(v_discount, v_gross));
      update public.promo_codes set redemptions = redemptions + 1 where id = v_promo.id;
    end if;
  end if;

  v_fare := round(v_gross - v_discount, 2);

  insert into public.trips (
    rider_id, tier_id, status,
    pickup_name, pickup_address, pickup_lat, pickup_lng,
    dest_name, dest_address, dest_lat, dest_lng,
    distance_km, duration_min, fare_estimate, discount, co2_saved_kg,
    payment_type, promo_code, pin
  ) values (
    v_rider, p_tier_id, 'requested',
    p_pickup_name, p_pickup_address, p_pickup_lat, p_pickup_lng,
    p_dest_name, p_dest_address, p_dest_lat, p_dest_lng,
    round(v_dist::numeric, 2), v_dur, v_fare, round(v_discount, 2), round((v_dist * 0.15)::numeric, 2),
    p_payment_type, p_promo_code, lpad((floor(random() * 10000))::int::text, 4, '0')
  ) returning * into v_trip;

  insert into public.trip_events (trip_id, status, actor_id) values (v_trip.id, 'requested', v_rider);

  v_trip := public.dispatch_trip(v_trip.id);
  return v_trip;
end; $$;
