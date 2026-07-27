-- 0003_create_shift_photos_bucket.sql
-- ClockService.clockOut() uploads to a 'shift-photos' bucket and calls
-- getPublicUrl() on it, but no migration ever created that bucket or its
-- storage.objects RLS policies. Storage RLS is on by default (same class of
-- bug as 0002's missing table GRANTs), so every upload was failing with
-- "new row violates row-level security policy" before this migration,
-- surfaced in the app as the generic "Could not clock out" message.

insert into storage.buckets (id, name, public)
values ('shift-photos', 'shift-photos', true)
on conflict (id) do nothing;

-- Workers may only upload into their own folder: shift-photos/<worker_id>/...
create policy "Workers can upload their own shift photos"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'shift-photos'
  and (storage.foldername(name))[1] = auth.uid()::text
);

-- Bucket is public, so reads (incl. the owner dashboard) go through the
-- public URL and don't need a storage.objects SELECT policy.
