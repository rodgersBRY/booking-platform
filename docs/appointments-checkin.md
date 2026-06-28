# Appointments and check-in flow

**Zubariq Ventures | Internal Documentation**

---

## Booking lifecycle

Scheduled bookings (created via the public booking page, phone, or WhatsApp) follow this lifecycle:

```
booked → arrived → in_chair → completed
```

| Status      | Meaning                                                      |
| ----------- | ------------------------------------------------------------ |
| `booked`    | Appointment confirmed but client has not yet arrived.        |
| `arrived`   | Receptionist has checked the client in at the desk.          |
| `in_chair`  | Client is seated with a barber; `scheduled_start` = now, `scheduled_end` = now + service duration. |
| `completed` | Service finished; a `visits` row has been created.           |

Walk-in bookings skip `booked` and `arrived` — they are created directly as `in_chair` (or queued via `queue_entries`).

---

## Board `appointments` addition

`GET /api/board` now returns an `appointments` array alongside `chairs`, `queue`, and `stats`.

### Item shape (`Appointment`)

```ts
interface Appointment {
  id: string;
  clientName: string;
  barberId: string | null;
  barberName: string | null;
  serviceName: string | null;
  serviceId: string | null;
  scheduledStart: string;   // ISO 8601 UTC
  status: "booked" | "arrived";
  channel: string;          // "online" | "whatsapp" | "phone" | "walkin"
  isRegular: boolean;       // true when client.total_visits >= 5
}
```

### Query behaviour

- Filters bookings with `status IN ('booked', 'arrived')`.
- Scoped to today in EAT (Africa/Nairobi) using the same `eatTodayBounds()` helper as the rest of the board query.
- Ordered by `scheduled_start` ascending.
- Joins `clients`, `staff`, and `services` via the existing `firstRel<T>()` helper so PostgREST to-one relations are handled safely.

---

## New endpoints

### `POST /api/bookings/[id]/arrive`

Mark a `booked` booking as `arrived`.

**Auth:** owner or receptionist session required.

**Success:** `200 { ok: true }`

**Errors:**
- `404` — booking not found.
- `409` — booking is not currently `booked`.
- `500` — database error.

---

### `POST /api/bookings/[id]/seat`

Seat an `arrived` (or `booked`) booking into the chair immediately.

Sets `status = 'in_chair'`, `scheduled_start = now`, `scheduled_end = now + service.duration_minutes`. This brings the booking into the chairs query window (`scheduled_start <= now <= scheduled_end`) so it appears on the chairs board straight away.

Service duration is read from the booking's `service_id` join. If the join returns no duration, the shortest active service duration is used as a fallback.

**Auth:** owner or receptionist session required.

**Success:** `200 { booking: <updated row> }`

**Errors:**
- `404` — booking not found.
- `409 { error: "barber_busy" }` — Postgres exclusion constraint (`23P01`) fired; the barber already has an overlapping `in_chair` booking.
- `500` — database error.

---

### `POST /api/bookings/[id]/cancel`

Set booking status to `cancelled`.

**Auth:** owner or receptionist session required.

**Success:** `200 { ok: true }`

**Errors:**
- `404` — booking not found.
- `500` — database error.

---

## Console panel

`web/src/components/console/Appointments.tsx` renders a "Today's appointments" panel above the live queue on the receptionist console.

### Per-row actions

| Booking status | Actions shown                       |
| -------------- | ----------------------------------- |
| `booked`       | **Arrived** · **Cancel**            |
| `arrived`      | **Seat now** · **Cancel**           |

- **Arrived** calls `POST /api/bookings/[id]/arrive` and refreshes the board.
- **Seat now** calls `POST /api/bookings/[id]/seat`; on a `409 barber_busy` response it shows "That barber is busy right now." inline without crashing the row.
- **Cancel** calls `POST /api/bookings/[id]/cancel` and refreshes the board.

### Badges

- **Regular** (brass) — shown when `isRegular` is true (5+ visits).
- **Arrived** (blue) — shown when status is `arrived`.
- Channel tag (canvas/navy) — shows the booking channel: Online, WhatsApp, Phone, or Walk-in.

### Empty state

"No appointments booked for today." — shown when the `appointments` array is empty.
