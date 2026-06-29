# Owner Dashboard

Available at `/dashboard` for staff with `role = 'owner'`. Redirects non-owners to their own role home.

## What it shows

### KPI cards (today / this week / this month tabs)

- **New vs Returning** — total visits in the selected window, split by whether the client was created within that same window (new) or before it (returning).
- **Revenue** — sum of `visits.amount_charged` for today and this week.
- **At-risk clients** — active clients whose `last_visit_at` is more than 21 days ago and who have no upcoming `booked` booking.

### Weekly detail panels

- **Per-barber table** — visits and KES revenue per barber this week.
- **Top 3 services** — most-booked services this week with a simple bar.
- **Channel mix** — bookings this week grouped by `channel` (walkin / online / whatsapp / phone).
- **No-show rate** — `no_show` bookings divided by all terminal bookings (no_show + completed + cancelled) this week.

The board polls every 60 seconds.

## API endpoint

```
GET /api/dashboard/stats
```

Auth: `getCurrentStaff()` — returns 401 if not signed in, 403 if role is not `owner`.
Client: `createAdminClient()` (service-role, bypasses RLS).
All date bounds are computed in EAT (Africa/Nairobi, UTC+3).

Response shape:

```ts
{
  kpis: {
    newVsReturning: {
      today:  { new: number; returning: number };
      week:   { new: number; returning: number };
      month:  { new: number; returning: number };
    };
    revenue: { today: number; week: number };
    atRiskClients: number;
  };
  week: {
    perBarber:   { barberId: string; barberName: string; visits: number; revenue: number }[];
    topServices: { serviceId: string; serviceName: string; count: number }[];
    channelMix:  { channel: string; count: number }[];
    noShowRate:  number;  // 0..1
  };
}
```

## Query strategy

1. **One visits query** for the current EAT month with embedded `clients(id, created_at)` and `services(name)`. Today/week/month bucketing is done in JavaScript from this single result set.
2. **Two at-risk queries**: first fetch active clients with `last_visit_at < now-21days`; then subtract those with a future `booked` booking.
3. **Per-barber and top-services** computed from the week slice of the visits already fetched — no extra DB round-trips.
4. **Channel mix**: one additional `bookings` query for the week window, grouped by `channel` in JS.
5. **No-show rate**: two `head: true` count queries (no_shows / terminal bookings this week).

## New vs returning definition

A visit counts as **new** if the visiting client's `clients.created_at` timestamp falls within the same bucket window (today / Mon–Sun week / 1st-of-month to today). All other visits in that window are **returning**.
