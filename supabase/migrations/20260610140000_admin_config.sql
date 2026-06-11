-- Admin config console: version/audit every config change (pricing, ride tiers,
-- promo codes, surge rules). Only ADMIN-initiated changes are logged — system
-- updates (e.g. a rider's promo redemption increment) are skipped via is_admin().

create table if not exists public.config_audit (
  id          uuid primary key default gen_random_uuid(),
  table_name  text not null,
  row_pk      text,
  action      text not null,                 -- INSERT | UPDATE | DELETE
  changed_by  uuid references public.profiles (id),
  old_data    jsonb,
  new_data    jsonb,
  changed_at  timestamptz not null default now()
);
alter table public.config_audit enable row level security;
create policy config_audit_admin on public.config_audit
  for select using (public.is_admin());
create index if not exists idx_config_audit_changed_at
  on public.config_audit (changed_at desc);

create or replace function public.log_config_change()
returns trigger
language plpgsql security definer set search_path = public
as $$
declare
  v_pk  text;
  v_old jsonb;
  v_new jsonb;
begin
  -- Only audit admin-initiated config changes; skip system/service updates.
  if not public.is_admin() then
    return case when tg_op = 'DELETE' then old else new end;
  end if;

  if tg_op = 'DELETE' then
    v_pk := old.id::text; v_old := to_jsonb(old); v_new := null;
  elsif tg_op = 'INSERT' then
    v_pk := new.id::text; v_old := null; v_new := to_jsonb(new);
  else
    v_pk := new.id::text; v_old := to_jsonb(old); v_new := to_jsonb(new);
  end if;

  insert into public.config_audit (table_name, row_pk, action, changed_by, old_data, new_data)
  values (tg_table_name, v_pk, tg_op, auth.uid(), v_old, v_new);

  return case when tg_op = 'DELETE' then old else new end;
end; $$;

drop trigger if exists trg_audit_pricing on public.pricing;
create trigger trg_audit_pricing after insert or update or delete on public.pricing
  for each row execute function public.log_config_change();

drop trigger if exists trg_audit_ride_tiers on public.ride_tiers;
create trigger trg_audit_ride_tiers after insert or update or delete on public.ride_tiers
  for each row execute function public.log_config_change();

drop trigger if exists trg_audit_promo_codes on public.promo_codes;
create trigger trg_audit_promo_codes after insert or update or delete on public.promo_codes
  for each row execute function public.log_config_change();

drop trigger if exists trg_audit_surge_rules on public.surge_rules;
create trigger trg_audit_surge_rules after insert or update or delete on public.surge_rules
  for each row execute function public.log_config_change();