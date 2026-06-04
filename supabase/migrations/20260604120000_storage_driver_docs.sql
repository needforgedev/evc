-- EVC — driver documents storage bucket + access policies.
-- Files are stored under `<driver_uid>/<doc_type>.<ext>`; a driver can manage
-- only their own folder, admins can read everything.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'driver-docs', 'driver-docs', false, 10485760,
  array['image/jpeg', 'image/png', 'image/webp', 'application/pdf']
)
on conflict (id) do nothing;

-- A driver can upload into their own folder (first path segment = their uid).
create policy "driver upload own docs"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'driver-docs'
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "driver update own docs"
on storage.objects for update to authenticated
using (
  bucket_id = 'driver-docs'
  and (storage.foldername(name))[1] = auth.uid()::text
);

-- A driver reads their own files; admins read all (for review).
create policy "driver or admin read docs"
on storage.objects for select to authenticated
using (
  bucket_id = 'driver-docs'
  and ((storage.foldername(name))[1] = auth.uid()::text or public.is_admin())
);
