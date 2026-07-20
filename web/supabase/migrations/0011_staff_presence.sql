-- Staff presence: LIVE status a staff member sets for themselves right now
-- ('available', 'busy', 'on_break', 'off_duty'), surfaced on the barber
-- dashboard and everywhere else that needs to know if they can be handed a
-- walk-in this second.
--
-- This is unrelated to `staff_availability` (renamed from barber_availability
-- in 0010): that table is the recurring WEEKLY WORKING-HOURS schedule (e.g.
-- "Tuesdays 09:00-19:00"). Presence is not derived from it and does not write
-- to it — a barber can be within their working hours and still be `on_break`
-- or `off_duty`, or outside their working hours and still `available` for a
-- late walk-in. Do not conflate the two.

create type staff_presence as enum ('available', 'busy', 'on_break', 'off_duty');

alter table staff
  add column if not exists presence staff_presence not null default 'off_duty',
  add column if not exists presence_updated_at timestamptz;
