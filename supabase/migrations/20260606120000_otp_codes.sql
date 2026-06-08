-- EVC — OTP store for the real (WhatsApp/SMS) verification flow.
-- One active code per phone. Codes are stored HASHED. Only the Edge Functions
-- (service role) touch this table — RLS is on with NO policies, so clients
-- (anon/authenticated) have no access.

create table if not exists public.otp_codes (
  phone      text primary key,
  code_hash  text not null,
  channel    text not null default 'whatsapp',
  expires_at timestamptz not null,
  attempts   integer not null default 0,
  consumed   boolean not null default false,
  created_at timestamptz not null default now()
);

alter table public.otp_codes enable row level security;
-- (no policies → only the service role, used by the edge functions, can access)
