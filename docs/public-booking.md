# Public Booking Page (online channel)

An unauthenticated, mobile-first booking flow at **`/book`** for the website "Book Now" channel. It
writes through the **same guarded booking-create path** as the staff console (no logic drift) and tags
the booking `channel = 'online'`.

## The flow (`/book`)
Mobile 4-step stepper (`web/src/app/book/page.tsx` + `web/src/components/book/BookingFlow.tsx`):
1. **Service** — from `GET /api/public/services` (shows duration + price).
2. **Barber** — from `GET /api/public/barbers`, or **Any barber**.
3. **Date + time** — next ~14 days; slots from `GET /api/public/availability` (30-min lead already
   enforced for today by the engine).
4. **Your details** — name + phone (acquisition source defaults to `website`) → confirm.

On submit → `POST /api/public/bookings`. Success → confirmation screen (barber, service, date/time).
On `409` → "Sorry, that time was just taken" + refreshed slots to re-pick.

## Public endpoints (`web/src/app/api/public/...`) — no staff session
| Endpoint | Returns |
|---|---|
| `GET /api/public/services` | `{ services: {id,name,durationMinutes,price}[] }` |
| `GET /api/public/barbers` | `{ barbers: {id,name}[] }` |
| `GET /api/public/availability?barber={id\|any}&service={id}&date=YYYY-MM-DD` | `{ date, slots }` |
| `POST /api/public/bookings` | `201 { booking }` or `409 { error:'slot_taken', slots }` |

`POST /api/public/bookings` requires `client.{name,phone}`, `serviceId`, `scheduledStart`, and a
**concrete `barberId`** (the slot's barber — for "Any barber" the availability slot already carries the
chosen barber). It forces `channel='online'`, `createdByStaffId=null`. `// TODO: rate-limit / captcha`.

## Shared guarded path (`web/src/lib/booking/createBooking.ts`)
The client-resolve + service-duration + guarded-insert + 409 logic was extracted from the staff
`POST /api/bookings` into `createBooking()`. Both the staff route (passing `createdByStaffId = staff.id`)
and the public route call it, so there is **one** booking-create path. Double-booking is still prevented
by the Postgres exclusion constraint (`23P01` → `slot_taken`). The staff route's auth (owner/receptionist)
and status codes are unchanged.

## Reachability
`web/src/proxy.ts` lists `/book` in `PUBLIC_PATHS`; all `/api/` routes already bypass the auth redirect
(each enforces its own auth), so the public endpoints are reachable while staff endpoints stay guarded.

## Security
All DB access is server-side via the service-role admin client. Public endpoints expose only service/
barber names, availability, and the created booking — no staff-only data.
