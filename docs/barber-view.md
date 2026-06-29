# Barber "My Day" View

## What it shows

A barber (or owner previewing their own day) visits `/me` to see:

- **Next client card** — the next upcoming appointment (status `booked` or `arrived`), or a "You're clear" message when none remain.
- **Queue waiting badge** — how many walk-in queue clients are waiting specifically for this barber.
- **Today's schedule** — all appointments for today (statuses: `booked`, `arrived`, `in_chair`, `late`) sorted by scheduled time, each with an action button.

## Action buttons

| Status   | Button       | Effect                                                       |
| -------- | ------------ | ------------------------------------------------------------ |
| booked   | Mark arrived | Calls `POST /api/bookings/{id}/arrive`                       |
| arrived  | Start        | Calls `POST /api/bookings/{id}/seat`                         |
| in_chair | Complete     | Opens payment modal → `POST /api/bookings/{id}/complete`     |
| late     | —            | No action                                                    |

## API endpoint

`GET /api/me/day` — requires an authenticated session with role `barber` or `owner`. Returns:

```json
{
  "barberId": "uuid",
  "nextClient": { "bookingId": "...", "clientName": "...", "serviceName": "...", "scheduledStart": "...", "status": "booked|arrived" } | null,
  "schedule": [ { "bookingId": "...", "clientName": "...", "serviceName": "...", "scheduledStart": "...", "status": "booked|arrived|in_chair|late" } ],
  "queueWaitingCount": 2
}
```

## PII enforcement

The endpoint selects only `id, scheduled_start, status, clients(name), services(name)` — phone and email are never fetched or returned to the client.

## Polling

`MyDayBoard` polls every 10 seconds. Future improvement: swap for Supabase Realtime.

## Role-based action authorization

Barbers can call `arrive`, `seat`, and `complete` on bookings where `booking.barber_id === staff.id`. Owners and receptionists can act on any booking.
