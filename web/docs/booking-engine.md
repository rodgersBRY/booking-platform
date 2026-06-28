# Booking Engine — Reference

## Availability Engine (`src/lib/booking/availability.ts`)

### `getAvailability(params)` → `Slot[]`

| Param | Type | Description |
|---|---|---|
| `barberId` | `string \| "any"` | UUID of a specific barber, or `"any"` to check all active barbers |
| `serviceId` | `string` | UUID of the service (determines slot duration) |
| `date` | `string` | `YYYY-MM-DD` in EAT (Africa/Nairobi, UTC+3) |

**Returns** an array of `Slot` objects sorted by start time:

```ts
interface Slot {
  start: string;   // ISO 8601 with +03:00 offset, e.g. "2026-06-28T09:00:00+03:00"
  end: string;     // ISO 8601 with +03:00 offset
  label: string;   // Display label, e.g. "9:00 AM"
  barberId: string; // The barber who owns this slot
}
```

### Engine rules

- **Timezone**: All date arithmetic is performed in Africa/Nairobi (EAT, UTC+3). Timestamps are stored and queried as `timestamptz` (absolute UTC), then converted for day/weekday logic.
- **Working window**: Sourced from `barber_availability` for the EAT weekday of the requested date (0=Sun … 6=Sat). Multiple rows per barber (split shifts) are each processed independently.
- **Time-off**: `barber_time_off` blocks that overlap the day are subtracted from the working window. Any slot whose `[start, end)` range intersects a time-off block is excluded.
- **Occupied slots**: Bookings with `status IN ('booked', 'arrived', 'in_chair')` that overlap the day are treated as occupied. A candidate slot is kept only if its `[start, start+duration)` range does not overlap any occupied booking.
- **Grid**: Candidate slots start every **15 minutes** on the hour (e.g. 09:00, 09:15, 09:30, …). Slot length = `service.duration_minutes`. No buffer between slots.
- **Lead time (today only)**: Slots starting before `now + 30 minutes` (EAT) are dropped. Slots on future dates have no lead-time filter.
- **`"any"` barber**: The engine iterates over all active barbers. For each 15-minute grid point, the first barber found to be free at that time is assigned to the slot. Each start time appears at most once in the result (no duplicates), with the earliest-found free barber.

---

## API Endpoints

All endpoints require an authenticated staff session (`getCurrentStaff()` via Supabase Auth cookie). A missing or invalid session returns `401 { error: "Unauthorized" }`. Mutating endpoints (POST) also require `role === "owner" | "receptionist"`; wrong role returns `403 { error: "Forbidden" }`.

### `GET /api/barbers`

Returns active barbers.

**Response `200`:**
```json
{
  "barbers": [
    { "id": "uuid", "name": "Tunde" }
  ]
}
```

---

### `GET /api/services`

Returns active services.

**Response `200`:**
```json
{
  "services": [
    { "id": "uuid", "name": "Haircuts & Styling", "durationMinutes": 45, "price": 800 }
  ]
}
```

---

### `GET /api/availability?barber={id|any}&service={id}&date=YYYY-MM-DD`

Returns available slots for a barber/service/date combination.

**Query params:** `barber` (barber UUID or `"any"`), `service` (service UUID), `date` (`YYYY-MM-DD` in EAT).

**Response `200`:**
```json
{
  "date": "2026-06-28",
  "slots": [
    { "start": "2026-06-28T09:00:00+03:00", "end": "2026-06-28T09:45:00+03:00", "label": "9:00 AM", "barberId": "uuid" }
  ]
}
```

---

### `POST /api/bookings`

Creates a booking. Requires `owner` or `receptionist` role.

**Request body:**
```json
{
  "clientId": "uuid (optional if client object provided)",
  "client": { "name": "Jane", "phone": "+254700000001", "acquisitionSource": "walkby" },
  "barberId": "uuid or null",
  "serviceId": "uuid",
  "scheduledStart": "2026-06-28T09:00:00+03:00",
  "channel": "walkin | online | whatsapp | phone"
}
```

- Provide either `clientId` or `client.{name, phone}`. If `client.phone` matches an existing client, that record is reused; otherwise a new client is created.
- `scheduledEnd` is computed from `scheduledStart + service.duration_minutes`.
- The booking is inserted with `status: "booked"`.

**Response `201`:**
```json
{ "booking": { ...bookingRow } }
```

**409 — Slot taken (Postgres exclusion constraint `23P01`):**
```json
{
  "error": "slot_taken",
  "message": "That slot is no longer available. Here are the next open slots.",
  "slots": [ ...Slot[] ]
}
```
`slots` contains fresh availability for the same date and barber (or `"any"` if no barber was specified).

---

### `GET /api/board`

Live board state for the receptionist console.

**Response `200`:**
```json
{
  "chairs": [
    {
      "barberId": "uuid",
      "barberName": "Tunde",
      "status": "in_chair",
      "bookingId": "uuid",
      "currentClientName": "Brian",
      "serviceName": "Haircuts & Styling",
      "minutesLeft": 23
    },
    { "barberId": "uuid", "barberName": "James", "status": "free" }
  ],
  "queue": [
    {
      "id": "uuid",
      "clientName": "Aisha",
      "preferredBarberId": "uuid",
      "preferredBarberName": "Mary",
      "choice": "waiting",
      "status": "waiting",
      "waitedMinutes": 12,
      "estimatedWaitMinutes": 18
    }
  ],
  "stats": { "waiting": 1, "servedToday": 4, "noShows": 0 }
}
```

- `chairs`: one entry per active barber. `status: "in_chair"` includes `bookingId` (needed for the Done action), `currentClientName`, `serviceName`, and `minutesLeft` (rounded minutes until `scheduled_end`).
- `queue`: entries with `status IN ('waiting', 'notified')`, ordered by `joined_at`. `estimatedWaitMinutes` = remaining in-chair minutes for the preferred barber (0 if barber is free, null if no preferred barber).
- `stats.servedToday`: visits completed today (EAT). `stats.noShows`: bookings with `status = 'no_show'` today.

---

### `POST /api/walkins`

Seat-or-queue logic for walk-in clients. Requires `owner` or `receptionist` role.

**Request body:**
```json
{
  "name": "Kevin",
  "phone": "+254700000003",
  "preferredBarberId": "uuid (optional)",
  "serviceId": "uuid",
  "acquisitionSource": "walkby (optional)"
}
```

**Seat-or-queue logic:**
1. Client is resolved/created by phone.
2. If `preferredBarberId` is given: check if that barber has no active booking covering now. If free → seat.
3. If no `preferredBarberId`: iterate active barbers and seat with the first free one.
4. If no barber is free → add to `queue_entries` with `status: "waiting"`.

**Response `201` — seated:**
```json
{ "seated": true, "booking": { ...bookingRow, "status": "in_chair" } }
```

**Response `201` — queued:**
```json
{ "seated": false, "queueEntry": { ...queueEntryRow } }
```

---

### `POST /api/queue/{id}/seat`

Seat a queued client now. Requires `owner` or `receptionist` role.

- Tries the preferred barber first; if busy, tries any active barber.
- On success: creates an `in_chair` booking and sets queue entry `status: "served"`.

**Response `200`:**
```json
{ "booking": { ...bookingRow } }
```

**409 — no barber free:**
```json
{ "error": "no_barber_free", "message": "No barber is currently free." }
```

---

### `POST /api/queue/{id}/notify`

Mark a queued client as notified. Requires `owner` or `receptionist` role.

Sets `status: "notified"` and `notified_at: now` on the queue entry. The actual WhatsApp message is sent by n8n after this response (see `// TODO` in the route).

**Response `200`:**
```json
{ "ok": true }
```

---

### `POST /api/bookings/{id}/complete`

Complete a booking and record the visit. Requires `owner` or `receptionist` role.

1. Sets booking `status: "completed"`.
2. Inserts a `visits` row (`amount_charged: 0`; payment is recorded separately).
3. Increments `clients.total_visits` and sets `clients.last_visit_at = now`.

**Response `200`:**
```json
{ "visit": { ...visitRow } }
```

**409 — already completed:**
```json
{ "error": "Booking already completed" }
```
