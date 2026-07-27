-- V1__migrate_from_supabase.sql
-- Transforms the existing Supabase-created schema (public.profiles/projects/
-- sites/availability_slots/shifts/assignments) into one this backend owns
-- outright, with Postgres RLS/auth.users/GoTrue removed from the picture.
-- This is an ALTER migration against a live, non-empty database, not a
-- fresh CREATE — Flyway is baselined at version 0 (see application.yml)
-- so this is genuinely the first migration it ever applies here.
--
-- Verified against the live database before writing this (via pg_dump and
-- targeted queries) rather than assumed from the old supabase/migrations/
-- files, since the live schema had drifted from them: extra indexes
-- (assignments/shifts/sites/projects/availability_slots FK columns,
-- shifts_one_open_per_worker_idx, availability_slots_unique_window_idx)
-- and an extra check constraint (shifts_completed_requires_clock_out) exist
-- that were never captured in any supabase/migrations/*.sql file. All of
-- that is good and kept as-is here — only the auth/RLS coupling is removed.
--
-- Left alone deliberately: Supabase's own platform event triggers
-- (ensure_rls, pgrst_ddl_watch, etc.) and the `rls_auto_enable` function
-- behind them — they're Supabase-managed infrastructure, not ours, and
-- harmless here since this backend connects as the `postgres` role, which
-- bypasses RLS by default regardless of whether it's enabled.

-- profiles.id no longer needs to reference auth.users — this backend
-- issues its own ids and JWTs, GoTrue is out of the picture entirely.
alter table public.profiles drop constraint profiles_id_fkey;

-- Login now looks up strictly by phone (no auth.users to disambiguate
-- identity), so this needs to be a real uniqueness guarantee, not just a
-- convention. No existing duplicates as of this migration (verified).
alter table public.profiles add constraint profiles_phone_key unique (phone);

-- profiles.role was a Postgres enum type (user_role). Convert to a plain
-- varchar + check constraint: portable across database engines, and maps
-- directly to a Java enum via @Enumerated(EnumType.STRING) without any
-- Postgres-specific type on the JPA side.
alter table public.profiles alter column role drop default;
alter table public.profiles
  alter column role type varchar(20) using role::text;
alter table public.profiles alter column role set default 'worker';
alter table public.profiles
  add constraint profiles_role_check check (role in ('owner', 'worker'));
drop type public.user_role;

-- Drop every RLS policy — authorization moves into the Java service layer
-- from here on (see backend security config / service-layer ownership
-- checks). Disabling RLS is not strictly required for this backend's own
-- connection (table owner bypasses RLS regardless), but leaving policies
-- in place that reference a now-deleted auth model would be misleading to
-- anyone reading the schema later.
drop policy assignments_owner_all on public.assignments;
drop policy assignments_worker_read_own on public.assignments;
drop policy availability_owner_read on public.availability_slots;
drop policy availability_worker_all on public.availability_slots;
drop policy profiles_update_own on public.profiles;
drop policy profiles_insert_self on public.profiles;
drop policy profiles_select_own_or_owner on public.profiles;
drop policy projects_worker_read_assigned on public.projects;
drop policy projects_owner_all on public.projects;
drop policy shifts_owner_read on public.shifts;
drop policy shifts_worker_all on public.shifts;
drop policy sites_worker_read_assigned on public.sites;
drop policy sites_owner_all on public.sites;

alter table public.assignments disable row level security;
alter table public.availability_slots disable row level security;
alter table public.profiles disable row level security;
alter table public.projects disable row level security;
alter table public.shifts disable row level security;
alter table public.sites disable row level security;

-- is_owner() only existed to power the RLS policies just dropped.
-- set_employee_pin() wrote directly to auth.users.encrypted_password to
-- make Supabase's GoTrue password-grant login work — this backend
-- verifies PINs with Spring Security's BCryptPasswordEncoder directly
-- against profiles.pin_hash instead, so neither function is needed.
drop function public.is_owner();
drop function public.set_employee_pin(uuid, text);
