-- Rider-initiated tip on a completed trip.
-- Riders have no direct UPDATE on `trips`, so this SECURITY DEFINER RPC verifies
-- the caller owns the (completed) trip, then records the tip on both `trips`
-- (which `driver_earnings_view` sums) and the trip's `payments` row (receipt).

create or replace function public.add_tip(p_trip uuid, p_amount numeric)
returns void
language plpgsql security definer set search_path = public
as $$
begin
  if p_amount is null or p_amount < 0 then
    raise exception 'Invalid tip amount';
  end if;

  if not exists (
    select 1 from public.trips
    where id = p_trip and rider_id = auth.uid() and status = 'completed'
  ) then
    raise exception 'Trip not tippable';
  end if;

  update public.trips set tip = p_amount where id = p_trip;
  update public.payments set tip = p_amount where trip_id = p_trip;
end; $$;

grant execute on function public.add_tip(uuid, numeric) to authenticated;