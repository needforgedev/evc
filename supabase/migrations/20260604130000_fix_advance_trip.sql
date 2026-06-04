-- Fix: advance_trip compared `status` (trip_status enum) to a CASE that
-- returned text literals → "operator does not exist: trip_status = text".
-- Resolve the expected previous status into a typed enum local first.

create or replace function public.advance_trip(p_trip uuid, p_status trip_status)
returns public.trips
language plpgsql security definer set search_path = public
as $$
declare
  v_trip     public.trips;
  v_expected trip_status;
begin
  if p_status not in ('arrived', 'ongoing') then
    raise exception 'advance_trip only handles arrived/ongoing';
  end if;

  v_expected := case p_status
                  when 'arrived' then 'enroute'::trip_status
                  else 'arrived'::trip_status
                end;

  update public.trips
     set status = p_status
   where id = p_trip
     and driver_id = auth.uid()
     and status = v_expected
   returning * into v_trip;

  if v_trip.id is null then
    raise exception 'Invalid transition';
  end if;

  insert into public.trip_events (trip_id, status, actor_id)
  values (p_trip, p_status, auth.uid());
  return v_trip;
end; $$;

-- Same fix in complete_trip: the payment-status CASE returned text into a
-- payment_status enum column.
create or replace function public.complete_trip(p_trip uuid, p_tip numeric default 0)
returns public.trips
language plpgsql security definer set search_path = public
as $$
declare
  v_trip     public.trips;
  v_vat_rate numeric;
  v_fare     numeric;
  v_pay_status payment_status;
begin
  select vat_rate into v_vat_rate from public.pricing where region = 'dubai';
  select * into v_trip from public.trips
   where id = p_trip and driver_id = auth.uid() and status = 'ongoing';
  if v_trip.id is null then raise exception 'Trip not completable'; end if;

  v_fare := coalesce(v_trip.final_fare, v_trip.fare_estimate);
  v_pay_status := case v_trip.payment_type
                    when 'card' then 'authorized'::payment_status
                    else 'captured'::payment_status
                  end;

  update public.trips
     set status = 'completed', completed_at = now(),
         final_fare = round(v_fare, 2), vat = round(v_fare * v_vat_rate, 2),
         tip = coalesce(p_tip, 0)
   where id = p_trip
   returning * into v_trip;

  insert into public.payments (trip_id, rider_id, amount, vat, tip, type, status)
  values (p_trip, v_trip.rider_id, v_trip.final_fare, v_trip.vat, v_trip.tip,
          v_trip.payment_type, v_pay_status);

  update public.profiles set total_trips = total_trips + 1
   where id in (v_trip.rider_id, v_trip.driver_id);
  update public.driver_locations set is_available = true
   where driver_id = v_trip.driver_id;
  insert into public.trip_events (trip_id, status, actor_id)
  values (p_trip, 'completed', auth.uid());
  return v_trip;
end; $$;
