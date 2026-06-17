-- Make driver accept robust + clearly-messaged.
--
-- The old accept_ride did a single UPDATE ... WHERE status='matched' and raised
-- a generic "Trip not assigned to you or not matchable" when 0 rows changed —
-- which fires on a normal race (the 15s offer auto-decline running as the driver
-- taps Accept) and leaks a raw error. This version distinguishes the cases and
-- is idempotent for a double-tap (already enroute to me → succeed).
create or replace function public.accept_ride(p_trip uuid)
returns public.trips
language plpgsql security definer set search_path = public
as $$
declare v_trip public.trips;
begin
  select * into v_trip from public.trips where id = p_trip;

  if v_trip.id is null then
    raise exception 'Ride request not found';
  end if;

  if v_trip.driver_id is distinct from auth.uid() then
    raise exception 'This ride is no longer assigned to you';
  end if;

  if v_trip.status = 'enroute' then
    return v_trip;  -- already accepted by me (double-tap / retry) — succeed
  end if;

  if v_trip.status <> 'matched' then
    raise exception 'This ride request has expired';
  end if;

  update public.trips set status = 'enroute'
   where id = p_trip and driver_id = auth.uid() and status = 'matched'
   returning * into v_trip;

  insert into public.trip_events (trip_id, status, actor_id)
    values (p_trip, 'enroute', auth.uid());
  return v_trip;
end; $$;
