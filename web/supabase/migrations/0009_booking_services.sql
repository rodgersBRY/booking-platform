-- Multi-service bookings: a booking (the appointment envelope — time block,
-- barber, double-booking guard) can now carry more than one service.
--
-- `bookings.service_id` is retained as the PRIMARY service (back-compat: every
-- existing read site keeps working, showing the primary). `booking_services`
-- is the full list. Reads migrate onto this table incrementally as multi-service
-- display lands; the time block on `bookings` (scheduled_end = start + sum of
-- service durations) remains the single source for the overlap guard.

create table booking_services (
  id         uuid primary key default gen_random_uuid(),
  booking_id uuid not null references bookings(id) on delete cascade,
  service_id uuid not null references services(id) on delete restrict,
  created_at timestamptz not null default now()
);
create index idx_booking_services_booking on booking_services (booking_id);
-- A service appears at most once per booking.
create unique index uq_booking_services_booking_service
  on booking_services (booking_id, service_id);

alter table booking_services enable row level security;
-- No policies, matching every other table: service-role key only.

-- ── Backfill: mirror each existing booking's primary service ──────────────────
insert into booking_services (booking_id, service_id)
select id, service_id from bookings;
