-- seed.sql
-- Test data for exercising the employee app end-to-end before the owner
-- dashboard exists. This is NOT a schema migration — do not number it or
-- put it in migrations/. Run manually in the Supabase SQL editor.
--
-- Prerequisites (do these first, through the running app):
--   1. Using Supabase's "Test Phone Numbers and OTPs" (Authentication ->
--      Providers -> Phone), register at least two test workers through the
--      employee_app "Create an account" flow. Registration always creates
--      a profile with role = 'worker' (see AuthService.verifyOtpAndCreateProfile),
--      so every account starts as a worker regardless of who it's for.
--   2. Note the phone numbers you used for each test account below.
--
-- This script then:
--   - promotes one of those profiles to role = 'owner'
--   - creates one project + one site under that owner
--   - assigns the other test worker to that site
--
-- Edit the two phone numbers below to match the test accounts you created,
-- then run the whole script.

do $$
declare
  v_owner_phone text := '+15005550001';   -- << replace with your test owner's phone
  v_worker_phone text := '+15005550002';  -- << replace with your test worker's phone
  v_owner_id uuid;
  v_worker_id uuid;
  v_project_id uuid;
  v_site_id uuid;
begin
  select id into v_owner_id from profiles where phone = v_owner_phone;
  select id into v_worker_id from profiles where phone = v_worker_phone;

  if v_owner_id is null then
    raise exception 'No profile found with phone %. Register this test account through the app first.', v_owner_phone;
  end if;
  if v_worker_id is null then
    raise exception 'No profile found with phone %. Register this test account through the app first.', v_worker_phone;
  end if;

  update profiles set role = 'owner' where id = v_owner_id;

  insert into projects (owner_id, name, location, start_date, status)
  values (v_owner_id, 'Riverside Apartments Refit', 'Pune, MH', current_date, 'active')
  returning id into v_project_id;

  insert into sites (project_id, name, address)
  values (v_project_id, 'Block C', 'Riverside Apartments, Block C, Pune, MH')
  returning id into v_site_id;

  insert into assignments (project_id, site_id, worker_id, assigned_by)
  values (v_project_id, v_site_id, v_worker_id, v_owner_id);

  raise notice 'Seed complete: project %, site %, worker % assigned.', v_project_id, v_site_id, v_worker_id;
end $$;
