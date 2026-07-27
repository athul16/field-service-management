-- 0004_employee_pin_login.sql
-- Replaces self-service registration + phone/OTP login with an
-- owner-provisioned model: the owner (via the future owner_dashboard,
-- using the service_role key server-side) creates the employee's
-- auth.users row directly and sets an initial PIN for them to log in
-- with. There is no more in-app "create an account" flow and no more
-- Twilio/OTP dependency for employee login.
--
-- Why a PIN needs to touch both `profiles.pin_hash` and
-- `auth.users.encrypted_password`:
--   - `profiles.pin_hash` is the domain-visible record of "this worker
--     has a PIN" that the owner dashboard manages (set/reset), per the
--     product requirement to store the PIN in our own schema.
--   - Only Supabase Auth (GoTrue) can issue a real session/JWT that
--     `auth.uid()` and RLS recognize. GoTrue's password check is just
--     `crypt(password, encrypted_password) = encrypted_password` using
--     the same pgcrypto bcrypt format, so writing that column directly
--     from a trusted SECURITY DEFINER function is a supported pattern
--     for custom-credential flows that don't go through GoTrue's own
--     password-set APIs. The mobile app logs in with
--     `supabase.auth.signInWithPassword(phone: ..., password: pin)`.
--   - `auth.users` is never exposed to PostgREST/the client directly —
--     the only way to reach it is through this function.

create extension if not exists pgcrypto;

alter table profiles add column pin_hash text;

-- Owner-only: set or reset a worker's PIN. Call this from the owner
-- dashboard's authenticated session (not the service_role key) so
-- `is_owner()` correctly scopes it to owners.
create or replace function set_employee_pin(p_worker_id uuid, p_pin text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_hash text;
begin
  if not is_owner() then
    raise exception 'Only an owner can set a worker''s PIN.';
  end if;
  if p_pin !~ '^[0-9]{4,6}$' then
    raise exception 'PIN must be 4 to 6 digits.';
  end if;

  v_hash := crypt(p_pin, gen_salt('bf'));

  update profiles set pin_hash = v_hash where id = p_worker_id and role = 'worker';
  if not found then
    raise exception 'No worker found with that id.';
  end if;

  update auth.users set encrypted_password = v_hash where id = p_worker_id;
end;
$$;

grant execute on function set_employee_pin(uuid, text) to authenticated;

-- Column-level lockdown: no client (worker or owner) can read or write
-- pin_hash directly — only set_employee_pin() can touch it. Table-wide
-- grants from 0002 are replaced with explicit column lists.
revoke select on public.profiles from authenticated;
grant select (id, role, full_name, phone, email, created_at) on public.profiles to authenticated;

revoke update on public.profiles from authenticated;
grant update (full_name, email) on public.profiles to authenticated;
