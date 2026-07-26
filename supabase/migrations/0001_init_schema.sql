-- 0001_init_schema.sql
-- Initial schema for Field Service Platform
-- Tables: profiles, projects, sites, availability_slots, shifts, assignments

-- ---------------------------------------------------------------------------
-- profiles: one row per auth.users row, extended with app-specific fields
-- ---------------------------------------------------------------------------
create type user_role as enum ('owner', 'worker');

create table profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  role user_role not null default 'worker',
  full_name text not null,
  phone text not null,
  email text,
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- projects: created by the owner
-- ---------------------------------------------------------------------------
create table projects (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references profiles (id) on delete cascade,
  name text not null,
  location text not null,
  start_date date not null,
  end_date date,
  status text not null default 'active', -- active | completed | archived
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- sites: specific work locations belonging to a project
-- ---------------------------------------------------------------------------
create table sites (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references projects (id) on delete cascade,
  name text not null,
  address text not null,
  latitude double precision,
  longitude double precision,
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- availability_slots: worker-declared availability windows
-- ---------------------------------------------------------------------------
create table availability_slots (
  id uuid primary key default gen_random_uuid(),
  worker_id uuid not null references profiles (id) on delete cascade,
  start_at timestamptz not null,
  end_at timestamptz not null,
  created_at timestamptz not null default now(),
  constraint availability_valid_range check (end_at > start_at)
);

-- ---------------------------------------------------------------------------
-- shifts: clock in / clock out records
-- ---------------------------------------------------------------------------
create table shifts (
  id uuid primary key default gen_random_uuid(),
  worker_id uuid not null references profiles (id) on delete cascade,
  site_id uuid not null references sites (id) on delete cascade,
  clock_in_at timestamptz not null default now(),
  clock_out_at timestamptz,
  clock_out_photo_url text,
  status text not null default 'in_progress', -- in_progress | completed
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- assignments: owner assigns a worker to a project/site
-- ---------------------------------------------------------------------------
create table assignments (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references projects (id) on delete cascade,
  site_id uuid not null references sites (id) on delete cascade,
  worker_id uuid not null references profiles (id) on delete cascade,
  assigned_by uuid not null references profiles (id),
  assigned_at timestamptz not null default now(),
  notified_at timestamptz
);

-- ---------------------------------------------------------------------------
-- Row Level Security
-- ---------------------------------------------------------------------------
alter table profiles enable row level security;
alter table projects enable row level security;
alter table sites enable row level security;
alter table availability_slots enable row level security;
alter table shifts enable row level security;
alter table assignments enable row level security;

create or replace function is_owner()
returns boolean
language sql
security definer
stable
as $$
  select exists (
    select 1 from profiles where id = auth.uid() and role = 'owner'
  );
$$;

-- profiles: a worker can see/update their own row; an owner can see everyone
create policy "profiles_select_own_or_owner" on profiles
  for select using (auth.uid() = id or is_owner());
create policy "profiles_update_own" on profiles
  for update using (auth.uid() = id);
create policy "profiles_insert_self" on profiles
  for insert with check (auth.uid() = id);

-- projects: only the owner manages projects
create policy "projects_owner_all" on projects
  for all using (is_owner()) with check (is_owner());
create policy "projects_worker_read_assigned" on projects
  for select using (
    exists (
      select 1 from assignments a
      where a.project_id = projects.id and a.worker_id = auth.uid()
    )
  );

-- sites: owner manages; workers can read sites they're assigned to
create policy "sites_owner_all" on sites
  for all using (is_owner()) with check (is_owner());
create policy "sites_worker_read_assigned" on sites
  for select using (
    exists (
      select 1 from assignments a
      where a.site_id = sites.id and a.worker_id = auth.uid()
    )
  );

-- availability_slots: worker manages their own; owner can read all
create policy "availability_owner_read" on availability_slots
  for select using (is_owner());
create policy "availability_worker_all" on availability_slots
  for all using (auth.uid() = worker_id) with check (auth.uid() = worker_id);

-- shifts: worker manages their own; owner can read all
create policy "shifts_owner_read" on shifts
  for select using (is_owner());
create policy "shifts_worker_all" on shifts
  for all using (auth.uid() = worker_id) with check (auth.uid() = worker_id);

-- assignments: owner manages; worker can read their own assignments
create policy "assignments_owner_all" on assignments
  for all using (is_owner()) with check (is_owner());
create policy "assignments_worker_read_own" on assignments
  for select using (auth.uid() = worker_id);
