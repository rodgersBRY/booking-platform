# 15-Minute Grace Job

## What it does

The grace job flips bookings from `booked` → `late` once 15 minutes have passed since their `scheduled_start` time without the client checking in. This frees the slot for walk-ins and gives staff a clear signal that the client is not coming.

Only rows with `status = 'booked'` are affected. Bookings already in `arrived`, `in_chair`, `completed`, or `cancelled` are untouched, making the update fully idempotent.

## Endpoint

```
GET /api/cron/grace
```

**Authentication:** pass the shared secret in the `x-automation-key` header.

```
x-automation-key: <AUTOMATION_API_KEY>
```

**Response (200):**

```json
{ "updated": 3, "cutoff": "2026-06-29T07:45:00.000Z" }
```

`updated` is the count of bookings flipped in this run. `cutoff` is the UTC timestamp used as the threshold.

## Wiring in n8n

1. Add a **Schedule Trigger** node — set to run every 5 minutes.
2. Add an **HTTP Request** node:
   - **Method:** GET
   - **URL:** `https://your-domain.com/api/cron/grace`
   - **Headers:** `x-automation-key` → `{{ $env.AUTOMATION_API_KEY }}`
3. Optionally add an **IF** node after it to alert on `updated > 0` or on HTTP errors.

## No timezone conversion needed

`scheduled_start` is stored in UTC. The cutoff is computed as `Date.now() - 15 minutes` in UTC. No EAT (+3h) offset is applied — adding one would introduce a 3-hour bug by comparing an EAT cutoff against UTC timestamps.

## Idempotency

Running the job multiple times in the same window is safe. The `WHERE status = 'booked'` clause means a row that has already been flipped to `late` (or any other terminal status) will not be touched again.
