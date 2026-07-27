-- seed.sql
-- Test data for exercising the employee app end-to-end before the owner
-- dashboard exists. This is NOT a schema migration — do not number it or
-- put it in migrations/. Run manually in the Supabase SQL editor.
--
-- Prerequisites (do these first, in the Supabase Dashboard):
--   1. employee_app has no self-registration (see 0004_employee_pin_login.sql
--      — login is phone + PIN, provisioned by the owner). So the only way to
--      create a test account right now is: Authentication -> Users -> Add
--      user. For each of the two test accounts below, set the phone number
--      and a password (the password IS the PIN), and check "Auto Confirm
--      User" so the phone counts as verified.
--   2. Note the phone number + PIN you used for each account below — the
--      dashboard creates the auth.users row, but not a profiles row; this
--      script creates profiles (and mirrors the PIN into pin_hash) for both.
--
-- This script then:
--   - creates a profiles row for each (one 'owner', one 'worker')
--   - creates one project + one site under that owner
--   - assigns the worker to that site
--
-- Edit the phone numbers/PINs below to match the test accounts you created,
-- then run the whole script.

do $$
declare
  v_owner_phone text := '9000000001';   -- << replace with your test owner's phone (local format, no country code)
  v_owner_pin text := '123456';         -- << must match the password you set for them
  v_worker_phone text := '9000000002';  -- << replace with your test worker's phone (local format, no country code)
  v_worker_pin text := '654321';        -- << must match the password you set for them
  v_owner_id uuid;
  v_worker_id uuid;
  v_project_id uuid;
  v_site_id uuid;
begin
  select id into v_owner_id from auth.users where phone = v_owner_phone;
  select id into v_worker_id from auth.users where phone = v_worker_phone;

  if v_owner_id is null then
    raise exception 'No auth user with phone %. Create it first via Dashboard > Authentication > Users > Add user.', v_owner_phone;
  end if;
  if v_worker_id is null then
    raise exception 'No auth user with phone %. Create it first via Dashboard > Authentication > Users > Add user.', v_worker_phone;
  end if;

  insert into profiles (id, role, full_name, phone, pin_hash)
  values (v_owner_id, 'owner', 'Test Owner', v_owner_phone, crypt(v_owner_pin, gen_salt('bf')))
  on conflict (id) do update set role = 'owner', pin_hash = excluded.pin_hash;

  insert into profiles (id, role, full_name, phone, pin_hash)
  values (v_worker_id, 'worker', 'Test Worker', v_worker_phone, crypt(v_worker_pin, gen_salt('bf')))
  on conflict (id) do update set pin_hash = excluded.pin_hash;

  insert into projects (owner_id, name, location, start_date, status)
  values (v_owner_id, 'Riverside Apartments Refit', 'Pune, MH', current_date, 'active')
  returning id into v_project_id;

  insert into sites (project_id, name, address)
  values (v_project_id, 'Block C', 'Riverside Apartments, Block C, Pune, MH')
  returning id into v_site_id;

  insert into assignments (project_id, site_id, worker_id, assigned_by)
  values (v_project_id, v_site_id, v_worker_id, v_owner_id);

  raise notice 'Seed complete: owner %, worker %, project %, site %.', v_owner_id, v_worker_id, v_project_id, v_site_id;
end $$;
