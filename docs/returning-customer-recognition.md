# Returning-customer Recognition

Lets the receptionist recognize a returning customer in the walk-in flow so a regular is entered once
and recognized on every later visit — with their preferred barber and history surfaced. The data layer
already dedupes by phone; this adds the recognition UI on top.

## The two flows (from the Add-walk-in modal)

### New client (first-ever visit)
1. Receptionist taps **Add walk-in**, types phone/name → **no match**.
2. Taps **+ New customer**, fills the full form: name, phone, preferred barber (or "any"), service, and
   "How did you hear about us?" (acquisition source).
3. Submit → seated now (if a barber is free) or queued.

**Recorded:** a new `clients` row (`name`, `phone` identity, `acquisition_source` = first-touch,
`preferred_barber_id`, `loyalty_points 0`, `total_visits 0`, `last_visit_at null`); a `bookings` row
(`in_chair`, `channel walkin`) or a `queue_entries` row. On completion → a `visits` row, `total_visits → 1`,
`last_visit_at = now`.

### Returning client (a regular)
1. Receptionist taps **Add walk-in**, types phone or name → **match appears**: name, phone, preferred
   barber, "N visits · last seen …", plus a **Regular** badge at `total_visits ≥ 5`.
2. Taps the match → name/phone/preferred barber pre-fill; confirms the service.
3. Submit → the **existing client is reused** (the request carries `clientId`).

**Recorded:** no new client row; a new `bookings`/`queue_entries` row. `acquisition_source` is unchanged
(first-touch). On completion → a `visits` row, `total_visits += 1`, `last_visit_at = now`.

## API
### `GET /api/clients/search?q=`
Staff-session guarded (owner/receptionist). Returns up to ~8 matches where phone `ILIKE q%` OR name
`ILIKE %q%` (min 2 chars). Shape:
```
{ clients: ClientSearchResult[] }
ClientSearchResult = {
  id, name, phone,
  preferredBarberId: string | null,
  preferredBarberName: string | null,
  totalVisits: number,
  lastVisitAt: string | null,
  isRegular: boolean        // total_visits >= 5
}
```

### `POST /api/walkins` (extended)
Now accepts an optional **`clientId`**. When present, that existing client is used directly (no name
required, no creation). Otherwise the existing find-or-create-by-phone behavior is unchanged. Seat-or-queue
logic is unchanged.

### `GET /api/board` (extended)
`QueueItem` now includes `isRegular` (`total_visits >= 5`) so the Regular badge can show on queue rows too.

## The "Regular" rule
A client is a **Regular** when `total_visits >= 5`. Surfaced as a badge on search matches, the selected
client, and queue rows.

## Files
- `web/src/app/api/clients/search/route.ts` — search endpoint.
- `web/src/app/api/walkins/route.ts` — `clientId` extension.
- `web/src/app/api/board/route.ts`, `web/src/lib/booking/types.ts` — `isRegular` on `QueueItem`.
- `web/src/lib/api/console.ts` — `searchClients()` helper + `ClientSearchResult` type.
- `web/src/components/console/AddWalkinModal.tsx` — debounced search, match list, returning/new paths.
- `web/src/components/console/LiveQueue.tsx` — Regular badge on queue rows.
