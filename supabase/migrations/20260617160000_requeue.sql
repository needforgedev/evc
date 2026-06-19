-- Punch-list #5 · No-match requeue.
--
-- Dispatch only fired on request + decline/pass, so a trip that found no driver
-- just sat in 'requested' forever — even if a driver came online or freed up a
-- moment later. requeue_waiting_trips() re-attempts matching for recent waiting
-- trips; the app calls it whenever the pool changes (a driver goes online or
-- finishes a trip), so a queued request gets matched as soon as a car appears.
--
-- Bounded to trips requested in the last 3 minutes so abandoned requests aren't
-- matched to a driver with no rider watching.
create or replace function public.requeue_waiting_trips()
returns void
language plpgsql security definer set search_path = public
as $$
declare r record;
begin
  for r in
    select id from public.trips
    where status = 'requested'
      and requested_at > now() - interval '3 minutes'
    order by requested_at   -- oldest first (fairness)
  loop
    perform public.dispatch_trip(r.id);
  end loop;
end; $$;

grant execute on function public.requeue_waiting_trips() to authenticated;
