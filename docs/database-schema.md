# Database Schema

Single-shop Postgres schema for the web app. Source of truth:
[`web/supabase/migrations/0001_init.sql`](../web/supabase/migrations/0001_init.sql).

## Design principles

- **`bookings` (intent) vs `visits` (what happened) are separate.** No-show / cancellation rate comes
  from `bookings`; revenue comes from `visits`. A booking becomes a visit on completion.
- **`channel` (per booking) ≠ `acquisition_source` (per client).** Operational intake vs. marketing source.
- **`message_log` replaces boolean reminder/followup flags** — prevents double-sends, feeds "messages
  sent" reporting; the automation writes a row instead of flipping a checkbox.
- **`loyalty_transactions` is a signed ledger**; `clients.loyalty_points` is the cached balance.

## Tables

| Table                  | Purpose                              | Key columns                                                                                                                        |
| ---------------------- | ------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------- |
| `staff`                | Owner / receptionist / barber        | `role`, `telegram_chat_id`, `status`                                                                                               |
| `services`             | Service menu                         | `name`, `duration_minutes`, `price`, `active`                                                                                      |
| `clients`              | Customer records                     | `phone` (unique identity), `preferred_barber_id`, `acquisition_source`, `referred_by_client_id`, `loyalty_points`, `last_visit_at` |
| `barber_availability`  | Recurring weekly hours               | `barber_id`, `weekday`, `start_time`, `end_time`                                                                                   |
| `barber_time_off`      | One-off blocks                       | `barber_id`, `start_at`, `end_at`                                                                                                  |
| `bookings`             | Intent / the schedule (all channels) | `barber_id` (null = any), `service_id`, `scheduled_start/end`, `channel`, `status`                                                 |
| `queue_entries`        | Live walk-in / wait queue            | `barber_id` (preferred), `choice`, `status`, `estimated_wait_minutes`                                                              |
| `visits`               | What happened + money                | `amount_charged`, `payment_method`, `loyalty_points_earned`                                                                        |
| `loyalty_transactions` | Signed points ledger                 | `type`, `points`, `visit_id`                                                                                                       |
| `message_log`          | Every automated message sent         | `type`, `booking_id`, `status`, `sent_at`                                                                                          |

## Enums

`staff_role`, `client_status`, `acquisition_source`, `booking_channel`, `booking_status`,
`queue_choice`, `queue_status`, `payment_method`, `loyalty_txn_type`, `message_type`, `message_status`.

## The double-booking guard (key invariant)

Cross-channel double-booking is made **structurally impossible** in the database, not in app code:

```sql
create extension if not exists btree_gist;

alter table bookings add constraint bookings_no_overlap
  exclude using gist (
    barber_id with =,
    tstzrange(scheduled_start, scheduled_end, '[)') with &&
  )
  where (barber_id is not null and status in ('booked', 'arrived', 'in_chair'));
```

No two **active** bookings (booked / arrived / in_chair) for the same barber may overlap. Booking
creation runs in a transaction; on constraint violation the API returns "slot just taken" + fresh
availability. Statuses `completed / cancelled / late / no_show` free the time.

## Row-Level Security

RLS is **enabled on every table with no policies**. The anon/public key is therefore denied all
access; the trusted server API uses the **service-role** key (which bypasses RLS) and enforces
owner / receptionist / barber permissions itself. See [`docs/architecture.md`](architecture.md).

## Applying it

Run the migration via the Supabase SQL Editor or `supabase db push`. See [`web/README.md`](../web/README.md).
