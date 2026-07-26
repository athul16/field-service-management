-- 0002_grant_authenticated_table_privileges.sql
-- 0001_init_schema.sql enabled RLS and added policies for every table, but
-- never issued the underlying GRANTs. This project's default privileges for
-- new tables are revoked for anon/authenticated (a project-level hardening
-- default), so without explicit GRANTs every PostgREST request from the app
-- fails with "permission denied for table X" before RLS is ever evaluated.

grant select, insert, update, delete on public.profiles to authenticated;
grant select, insert, update, delete on public.projects to authenticated;
grant select, insert, update, delete on public.sites to authenticated;
grant select, insert, update, delete on public.availability_slots to authenticated;
grant select, insert, update, delete on public.shifts to authenticated;
grant select, insert, update, delete on public.assignments to authenticated;
