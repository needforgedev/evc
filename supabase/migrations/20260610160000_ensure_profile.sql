-- Self-heal a driver's profile during registration. Fixes the
-- `vehicles_owner_driver_id_fkey` error that occurs when the auth user already
-- exists (e.g. after a data wipe that cleared `profiles` but not `auth.users`):
-- sign-in finds the old auth user, the new-user trigger never fires, so no
-- profile row exists for the vehicle FK to reference.
--
-- SECURITY DEFINER so the role is set by the SERVER (never client-supplied) —
-- a driver can't self-promote to admin.

create or replace function public.ensure_driver_profile(
  p_full_name text,
  p_phone     text,
  p_email     text default null
) returns void
language plpgsql security definer set search_path = public
as $$
begin
  insert into public.profiles (id, role, full_name, phone, email)
  values (auth.uid(), 'driver', p_full_name, p_phone, nullif(p_email, ''))
  on conflict (id) do update set
    full_name = excluded.full_name,
    phone     = excluded.phone,
    email     = coalesce(nullif(excluded.email, ''), public.profiles.email),
    updated_at = now();

  -- Ensure the dependent rows the new-user trigger would normally create.
  insert into public.driver_details (driver_id)
  values (auth.uid()) on conflict (driver_id) do nothing;

  insert into public.wallets (user_id)
  values (auth.uid()) on conflict (user_id) do nothing;
end; $$;

grant execute on function public.ensure_driver_profile(text, text, text) to authenticated;
