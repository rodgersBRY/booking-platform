-- Barbershop platform — initial schema (single-shop)
-- See /Users/mawirab/.claude/plans/synchronous-soaring-naur.md for the design rationale.
--
-- Design notes:
--   * bookings (intent) and visits (what happened) are separate tables.
--   * channel (per booking) is distinct from clients.acquisition_source (per client).
--   * message_log replaces boolean reminder/followup flags.
--   * Double-booking is made structurally impossible via a Postgres exclusion constraint
--     (requires the btree_gist extension to combine `=` on barber_id with `&&` on the time range).
--   * RLS is enabled on every table with NO permissive policies: the app's server API uses the
--     service-role key (which bypasses RLS) and enforces owner/receptionist/barber permissions
--     itself. The anon key therefore cannot read or write anything directly.

create extension if not exists btree_gist;

-- ── Enums ─────────────────────────────────────────────────────────────────────
create type staff_role          as enum ('owner', 'receptionist', 'barber');
create type client_status       as enum ('active', 'inactive', 'blocked');
create type acquisition_source  as enum ('social', 'website', 'referral', 'walkby', 'whatsapp', 'other');
create type booking_channel     as enum ('walkin', 'online', 'whatsapp', 'phone');
create type booking_status      as enum ('booked', 'arrived', 'in_chair', 'completed', 'late', 'no_show', 'cancelled');
create type queue_choice        as enum ('waiting', 'switched', 'notify');
create type queue_status        as enum ('waiting', 'notified', 'in_chair', 'served', 'left');
create type payment_method      as enum ('cash', 'mpesa', 'card');
create type loyalty_txn_type    as enum ('earn', 'redeem', 'referral_bonus', 'adjust');
create type message_type        as enum ('reminder_24h', 'reminder_2h', 'review_request', 'reengagement', 'queue_notify', 'owner_alert');
create type message_status      as enum ('sent', 'failed');

-- ── updated_at trigger helper ─────────────────────────────────────────────────
create or replace function set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- ── staff (owner / receptionist / barber) ─────────────────────────────────────
create table staff (
  id               uuid primary key default gen_random_uuid(),
  name             text not null,
  role             staff_role not null,
  phone            text,
  email            text,
  telegram_chat_id text,
  password_hash    text,
  status           client_status not null default 'active',
  created_at       timestamptz not null default now()
);

-- ── services ──────────────────────────────────────────────────────────────────
create table services (
  id               uuid primary key default gen_random_uuid(),
  name             text not null,
  category         text,
  description      text,
  duration_minutes int  not null check (duration_minutes > 0),
  price            numeric(10,2) not null default 0,
  active           boolean not null default true,
  created_at       timestamptz not null default now()
);

-- ── clients ───────────────────────────────────────────────────────────────────
create table clients (
  id                   uuid primary key default gen_random_uuid(),
  name                 text not null,
  phone                text not null unique,          -- identity key
  email                text,
  preferred_barber_id  uuid references staff(id) on delete set null,
  acquisition_source   acquisition_source,
  referred_by_client_id uuid references clients(id) on delete set null,
  loyalty_points       int not null default 0,
  total_visits         int not null default 0,
  last_visit_at        timestamptz,
  status               client_status not null default 'active',
  created_at           timestamptz not null default now()
);
create index idx_clients_last_visit_at on clients (last_visit_at);
create index idx_clients_preferred_barber on clients (preferred_barber_id);

-- ── barber availability (recurring weekly hours) ──────────────────────────────
create table barber_availability (
  id         uuid primary key default gen_random_uuid(),
  barber_id  uuid not null references staff(id) on delete cascade,
  weekday    smallint not null check (weekday between 0 and 6),  -- 0 = Sunday
  start_time time not null,
  end_time   time not null,
  check (end_time > start_time)
);
create index idx_barber_availability_barber on barber_availability (barber_id);

-- ── barber time off (one-off blocks) ──────────────────────────────────────────
create table barber_time_off (
  id        uuid primary key default gen_random_uuid(),
  barber_id uuid not null references staff(id) on delete cascade,
  start_at  timestamptz not null,
  end_at    timestamptz not null,
  reason    text,
  check (end_at > start_at)
);
create index idx_barber_time_off_barber on barber_time_off (barber_id);

-- ── bookings (intent / the schedule; every channel writes here) ───────────────
create table bookings (
  id                  uuid primary key default gen_random_uuid(),
  client_id           uuid not null references clients(id) on delete restrict,
  barber_id           uuid references staff(id) on delete set null,   -- null = any barber
  service_id          uuid not null references services(id) on delete restrict,
  scheduled_start     timestamptz not null,
  scheduled_end       timestamptz not null,
  channel             booking_channel not null,
  status              booking_status not null default 'booked',
  created_by_staff_id uuid references staff(id) on delete set null,
  notes               text,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now(),
  check (scheduled_end > scheduled_start)
);
create index idx_bookings_barber_start on bookings (barber_id, scheduled_start);
create index idx_bookings_client on bookings (client_id);
create index idx_bookings_status on bookings (status);
-- Structural double-booking guard: no two ACTIVE bookings for the same barber may overlap.
alter table bookings add constraint bookings_no_overlap
  exclude using gist (
    barber_id with =,
    tstzrange(scheduled_start, scheduled_end, '[)') with &&
  )
  where (barber_id is not null and status in ('booked', 'arrived', 'in_chair'));

create trigger trg_bookings_updated_at
  before update on bookings
  for each row execute function set_updated_at();

-- ── queue entries (live walk-in / wait queue) ─────────────────────────────────
create table queue_entries (
  id                     uuid primary key default gen_random_uuid(),
  client_id              uuid not null references clients(id) on delete cascade,
  barber_id              uuid references staff(id) on delete set null,  -- preferred barber
  booking_id             uuid references bookings(id) on delete set null,
  joined_at              timestamptz not null default now(),
  estimated_wait_minutes int,
  choice                 queue_choice not null default 'waiting',
  status                 queue_status not null default 'waiting',
  notified_at            timestamptz
);
create index idx_queue_barber_status on queue_entries (barber_id, status);

-- ── visits (what actually happened; revenue lives here) ───────────────────────
create table visits (
  id                   uuid primary key default gen_random_uuid(),
  booking_id           uuid references bookings(id) on delete set null,  -- null = pure walk-in
  client_id            uuid not null references clients(id) on delete restrict,
  barber_id            uuid references staff(id) on delete set null,
  service_id           uuid references services(id) on delete set null,
  completed_at         timestamptz not null default now(),
  amount_charged       numeric(10,2) not null default 0,
  payment_method       payment_method,
  loyalty_points_earned int not null default 0,
  review_requested     boolean not null default false,
  created_at           timestamptz not null default now()
);
create index idx_visits_client on visits (client_id);
create index idx_visits_barber on visits (barber_id);
create index idx_visits_completed_at on visits (completed_at);

-- ── loyalty ledger (signed points; clients.loyalty_points is the cached balance) ─
create table loyalty_transactions (
  id         uuid primary key default gen_random_uuid(),
  client_id  uuid not null references clients(id) on delete cascade,
  visit_id   uuid references visits(id) on delete set null,
  type       loyalty_txn_type not null,
  points     int not null,                 -- signed: earn positive, redeem negative
  reason     text,
  created_at timestamptz not null default now()
);
create index idx_loyalty_client on loyalty_transactions (client_id);

-- ── message log (every automated message the tool sends) ──────────────────────
create table message_log (
  id         uuid primary key default gen_random_uuid(),
  client_id  uuid references clients(id) on delete set null,
  staff_id   uuid references staff(id) on delete set null,
  type       message_type not null,
  booking_id uuid references bookings(id) on delete set null,
  channel    text,
  status     message_status not null default 'sent',
  sent_at    timestamptz not null default now()
);
create index idx_message_log_booking on message_log (booking_id);
create index idx_message_log_type_sent on message_log (type, sent_at);

-- ── Row-Level Security: lock everything; server uses the service-role key ──────
alter table staff                enable row level security;
alter table services             enable row level security;
alter table clients              enable row level security;
alter table barber_availability  enable row level security;
alter table barber_time_off      enable row level security;
alter table bookings             enable row level security;
alter table queue_entries        enable row level security;
alter table visits               enable row level security;
alter table loyalty_transactions enable row level security;
alter table message_log          enable row level security;
-- No policies are defined intentionally: with RLS on and no policy, the anon/public key is denied
-- all access, while the service-role key (used only by the trusted server API) bypasses RLS.
-- Owner/receptionist/barber permissions are enforced in the API layer per the blueprint.
