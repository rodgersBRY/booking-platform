-- Barber-visible client notes, plus the channel values the mobile barber app
-- writes when it creates or handles a booking.
--
-- customer_notes: client PREFERENCES the client has shared (e.g. "prefers
-- skin fade") — visible to any staff member serving them, shown on the
-- client's own booking-detail screen inside the barber app.
-- staff_notes: PRIVATE staff-only notes about the client relationship (e.g.
-- "usually books every three weeks") — never shown to the client. Editable
-- by any staff member serving that client, same as customer_notes.
--
-- booking_channel gains mobile_app / reception / barber so bookings made
-- from the new mobile flows can be tagged distinctly from the existing four
-- values (walkin, online, whatsapp, phone), which are untouched and keep
-- working exactly as before.
--
-- Each new enum value is its own statement: Postgres cannot use a
-- newly-added enum value in the same transaction that added it, and
-- Supabase runs each migration file as its own transaction (see
-- 0005_staff_roles.sql for the same constraint). None of these three new
-- values are referenced anywhere else in this file.

alter table clients add column if not exists customer_notes text;
alter table clients add column if not exists staff_notes text;

alter type booking_channel add value if not exists 'mobile_app';
alter type booking_channel add value if not exists 'reception';
alter type booking_channel add value if not exists 'barber';
