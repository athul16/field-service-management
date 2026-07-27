-- Lets an owner confirm a completed shift after reviewing its clock-out photo.
-- confirmed_by is stored for audit purposes but deliberately not exposed via ShiftResponse
-- (matches the existing convention on assignments: assigned_by is stored, never returned).
alter table shifts add column confirmed_at timestamptz;
alter table shifts add column confirmed_by uuid references profiles (id);
