-- De-bias provider references: a booking / queue entry / visit is assigned to a
-- STAFF member — who may be a barber, beautician, or masseuse — not specifically
-- a barber. `role = 'barber'` remains a valid staff_role; only the "assigned
-- provider" columns and the availability/time-off tables are renamed.
--
-- Postgres cascades a column rename into every dependent object automatically,
-- so the bookings_no_overlap exclusion constraint and all indexes keep working
-- against the new column name with no drop/recreate needed. Index *names* are
-- renamed separately below purely so they don't lie.

alter table bookings      rename column barber_id to staff_id;
alter table queue_entries rename column barber_id to staff_id;
alter table visits        rename column barber_id to staff_id;
alter table clients       rename column preferred_barber_id to preferred_staff_id;

alter table barber_availability rename column barber_id to staff_id;
alter table barber_time_off     rename column barber_id to staff_id;

alter table barber_availability rename to staff_availability;
alter table barber_time_off     rename to staff_time_off;

alter index idx_clients_preferred_barber   rename to idx_clients_preferred_staff;
alter index idx_barber_availability_barber rename to idx_staff_availability_staff;
alter index idx_barber_time_off_barber     rename to idx_staff_time_off_staff;
alter index idx_bookings_barber_start      rename to idx_bookings_staff_start;
alter index idx_queue_barber_status        rename to idx_queue_staff_status;
alter index idx_visits_barber              rename to idx_visits_staff;
