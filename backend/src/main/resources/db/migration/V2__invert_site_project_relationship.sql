-- Invert Site/Project: a Site is now the independent, permanent entity (physical location,
-- company name, address), and a Project belongs to exactly one Site (many projects can happen
-- at the same site over time). Previously it was the reverse (sites.project_id).
--
-- Existing sites/projects/assignments/shifts are disposable dev/test data created while
-- testing the dashboard under the old model, so we truncate rather than attempt a backfill
-- (backfilling would require guessing a "company name" and picking one site per project
-- arbitrarily where a project had more than one).
truncate table shifts, assignments, sites, projects cascade;

alter table sites add column company_name text not null default '';
alter table sites alter column company_name drop default;

alter table projects add column site_id uuid references sites (id) on delete cascade;
alter table projects alter column site_id set not null;

alter table sites drop constraint sites_project_id_fkey;
alter table sites drop column project_id;

alter table projects drop column location;

update projects set status = 'active' where status not in ('active', 'closed');
alter table projects add constraint projects_status_check check (status in ('active', 'closed'));
alter table projects alter column status set default 'active';
