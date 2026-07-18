-- Client-facing notification feed. Written at the same points bookings
-- change status (create/cancel/complete) so the insert doubles as the
-- future hook point for push notifications — same event, same place.
--
-- Only event-driven types are populated for now: booking_confirmed,
-- booking_cancelled, booking_completed. Reminders need a scheduled job
-- (none exists yet for this feed) and promotions/new_service/loyalty_reward
-- need systems that don't exist yet either — the type check allows them so
-- the column doesn't need another migration when those land.

create table notifications (
  id         uuid primary key default gen_random_uuid(),
  client_id  uuid not null references clients(id) on delete cascade,
  type       text not null check (type in (
               'booking_confirmed',
               'booking_cancelled',
               'booking_completed',
               'appointment_reminder',
               'promotion',
               'new_service',
               'loyalty_reward'
             )),
  title      text not null,
  body       text not null,
  booking_id uuid references bookings(id) on delete set null,
  read       boolean not null default false,
  created_at timestamptz not null default now()
);
create index idx_notifications_client_created
  on notifications (client_id, created_at desc);

alter table notifications enable row level security;
-- No policies, matching every other table: service-role key only.
