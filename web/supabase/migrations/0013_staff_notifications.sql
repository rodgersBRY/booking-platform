-- Staff-facing notification feed, the STAFF parallel to the client
-- `notifications` table (0011_notifications.sql). Deliberately a separate
-- table and a separate writer (createStaffNotification.ts) rather than
-- reusing the client one — same client/staff separation this codebase
-- already keeps everywhere else (see clientAuth.ts vs staffAuth.ts, which
-- never resolve each other's sessions).
--
-- Rows are written server-side by the existing booking-lifecycle handlers
-- when a client checks in, cancels, reschedules, or a booking is created
-- for a staff member — same event-driven hook points as the client feed.
--
-- read_at is a timestamp, not a boolean like the client table's `read`
-- column: unread is `read_at IS NULL`. That's an intentional, independent
-- design choice for this new table (it doubles as "when did they see it"),
-- not an inconsistency with 0011 to reconcile.

create table staff_notifications (
  id         uuid primary key default gen_random_uuid(),
  staff_id   uuid not null references staff(id) on delete cascade,
  type       text not null check (type in (
               'booking_created', 'booking_cancelled',
               'booking_rescheduled', 'customer_checked_in'
             )),
  title      text not null,
  body       text not null,
  booking_id uuid references bookings(id) on delete set null,
  read_at    timestamptz,
  created_at timestamptz not null default now()
);
create index idx_staff_notifications_staff_created
  on staff_notifications (staff_id, created_at desc);

alter table staff_notifications enable row level security;
-- No policies, matching every other table: service-role key only.
