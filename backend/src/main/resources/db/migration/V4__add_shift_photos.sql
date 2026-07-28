-- A completed shift can now have up to 3 clock-out photos instead of exactly
-- one, since a worker may want to document more than a single angle of
-- finished work. shift_photos replaces the single clock_out_photo_url column
-- so the photo count isn't hardcoded into the shifts table shape; position
-- (0-2) preserves upload order for display. Existing photos are backfilled
-- as position 0 rather than lost.
create table shift_photos (
    id uuid primary key,
    shift_id uuid not null references shifts (id) on delete cascade,
    photo_url text not null,
    position smallint not null check (position >= 0 and position < 3),
    created_at timestamptz not null default now(),
    unique (shift_id, position)
);

insert into shift_photos (id, shift_id, photo_url, position)
select gen_random_uuid(), id, clock_out_photo_url, 0
from shifts
where clock_out_photo_url is not null;

alter table shifts drop column clock_out_photo_url;
