-- Clock-out photos move off the local disk (single-instance, no backup) and into the
-- database itself, so they ride along with the existing Postgres backups and the
-- clock-out-then-insert-photo step stays in one transaction (no orphaned files if either
-- half fails). photo_url is dropped — the URL is now derived from the row's own id
-- (/photos/{id}) rather than stored, since there's no longer a real filesystem path to record.
-- Existing rows are disposable dev/test data (confirmed with the user) — truncated rather
-- than migrated, same reasoning as every prior schema change on test-only data.
truncate table shift_photos;

alter table shift_photos drop column photo_url;
alter table shift_photos add column data bytea not null;
alter table shift_photos add column content_type text not null;
