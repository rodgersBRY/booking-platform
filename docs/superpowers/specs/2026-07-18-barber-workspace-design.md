# Barber Workspace — Design

Date: 2026-07-18
Source requirements: `mobile/.claude/BARBER-APP.md`

## Goal

Add a barber workspace to the existing Baberia Cuts Flutter app. Same app, same design
system. After login the app loads the customer workspace or the barber workspace based on
which account signed in.

The barber workspace is built around managing today's work, not booking services.

## Constraints from the existing codebase

- Mobile is Flutter + GetX, feature-first under `mobile/lib/app/modules/`. Keep that.
- Design system already exists at `mobile/lib/app/theme/` and `mobile/lib/app/widgets/`.
  Reuse it. Do not fork or duplicate components.
- Client accounts authenticate with a Bearer token (`src/lib/clientAuth.ts`).
- Staff authenticate with cookie-based Supabase Auth (`src/lib/auth.ts`), web only.
  A mobile client has no cookie jar, so staff need a token path.
- RLS is on for every table with no policies. All data access goes through the
  service-role client in the Next.js API. That does not change.
- `bookings.staff_id` (not `barber_id`) since migration 0010.
- Multi-service bookings live in `booking_services`; `bookings.service_id` stays as the
  primary service for back-compat.

## Architecture

### Backend

New namespace `/api/v1/staff/*` in `web/src/app/api/v1/staff/`.

New `web/src/lib/staffAuth.ts`, modelled directly on `clientAuth.ts`:

- `getStaffFromRequest(request)` reads `Authorization: Bearer <token>`, resolves the
  Supabase user, loads the `staff` row by `auth_user_id`.
- Returns null for: no token, invalid token, no linked staff row, `status !== 'active'`.
- Route handlers additionally reject roles that are not bookable
  (`isBookableRole` in `src/lib/staff/roles.ts`).

Cookie-based `lib/auth.ts` is untouched and keeps serving the web console. The two auth
paths never call each other, matching the existing comment in `clientAuth.ts`.

### Mobile

New feature folder `mobile/lib/app/modules/barber/`, holding the barber shell, its pages,
and its controllers. Data access goes in `mobile/lib/app/data/repositories/staff_*.dart`
with models in `mobile/lib/app/data/models/`.

`BarberShellPage` mirrors `ShellPage`'s structure and bottom bar, with barber tabs:
Dashboard, Schedule, Customers, Notifications, Profile.

### Auth flow

One login screen, unchanged visually.

1. `AuthRepository.login()` posts to `/v1/account/login`.
2. On an auth failure it retries `/v1/staff/login`.
3. On success it stores the token plus an `accountType` value (`client` or `staff`) in
   `StorageService`.
4. Startup reads `accountType` and calls the matching `/me` endpoint, then routes to
   `ShellPage` or `BarberShellPage`.

A wrong password produces two failed calls before the error surfaces. Acceptable: it keeps
the auto-detect behaviour the requirements ask for without leaking which emails belong to
staff.

### Sync

Pull-to-refresh, refresh on tab focus, and refresh on app resume. No Supabase Realtime in
this scope: it would require writing RLS policies for tables that deliberately have none,
plus exposing the anon key to the mobile client. Realtime is a later slice if the refresh
model proves insufficient.

## Slices

Each slice is a migration (where needed) plus API routes plus Flutter, and lands as its own
commit.

### Slice 1 — Staff auth and shell

- `src/lib/staffAuth.ts`
- `POST /api/v1/staff/login`, `GET /api/v1/staff/me`
- Flutter: `accountType` in `StorageService`, login fallback in `AuthRepository`,
  `StaffModel`, `BarberShellPage` with four placeholder tabs and a working Profile tab
  (name, role, avatar, logout).

### Slice 2 — Dashboard and availability

Migration: `staff.presence` enum (`available`, `busy`, `on_break`, `off_duty`, default
`off_duty`) and `staff.presence_updated_at`. Presence is live status; the existing
`staff_availability` table remains the weekly working-hours schedule and is unrelated.

- `GET /api/v1/staff/day` — port of `/api/me/day` with appointment counts, completed and
  remaining, today's working hours from `staff_availability`, and multi-service names from
  `booking_services`.
- `PATCH /api/v1/staff/presence`

Flutter: `AvailabilityCard`, `DailySummaryCard`, `NextAppointmentCard`,
`AppointmentTimelineCard`, presence bottom sheet, pull-to-refresh, dashboard empty state.

### Slice 3 — Schedule and appointment detail

Migration:

- `clients.customer_notes` — preferences, visible to the barber.
- `clients.staff_notes` — private staff notes.
- `booking_channel` enum gains `mobile_app`, `reception`, `barber`. Existing `online`,
  `walkin`, `whatsapp`, `phone` values are kept and continue to display.

Endpoints:

- `GET /api/v1/staff/schedule?range=today|tomorrow|week`
- `GET /api/v1/staff/bookings/[id]`
- `PATCH /api/v1/staff/bookings/[id]` — notes only
- `POST /api/v1/staff/bookings/[id]/start` — `arrived` to `in_chair`
- `POST /api/v1/staff/bookings/[id]/complete` — `in_chair` to `completed`, optional
  service notes into `bookings.notes`

Every one of these verifies `booking.staff_id === staff.id` and returns 403 otherwise. A
barber cannot read or touch another barber's bookings.

Flutter: tabbed schedule (Today / Tomorrow / Week), status-coloured cards
(blue confirmed, orange checked in, purple in progress, green completed, red cancelled),
appointment detail page, primary action button, notes editing.

### Slice 4 — Create booking

- `GET /api/v1/staff/clients/search?q=` — name or phone
- `POST /api/v1/staff/clients` — name and phone only
- `GET /api/v1/staff/services` — filtered to the staff member's role via `service_roles`
- `GET /api/v1/staff/availability?date=` — this staff member's free slots
- `POST /api/v1/staff/bookings` — reuses `src/lib/booking/createBooking.ts` so the existing
  overlap guard applies; `channel` is set to `barber`, `created_by_staff_id` to the caller,
  `staff_id` forced to the caller.

Flutter: Customer, Service, Date, Time, Review, Confirm. Reuses
`BookingProgressIndicator`. Entry point is a FAB on the Schedule tab.

### Slice 5 — My customers

- `GET /api/v1/staff/clients` — distinct clients this staff member has served, from
  `visits`, with visit count and last visit date; supports search.
- `GET /api/v1/staff/clients/[id]` — profile, visit timeline, both note fields. Only
  returns a client this staff member has actually served.

Flutter: searchable customer list, customer profile with visit timeline and notes.

### Slice 6 — Notifications

Migration: `staff_notifications` (`id`, `staff_id`, `type`, `title`, `body`, `booking_id`,
`read_at`, `created_at`).

Rows are written server-side by the existing handlers when a client checks in, cancels,
reschedules, or a booking is created for that staff member.

- `GET /api/v1/staff/notifications`
- `POST /api/v1/staff/notifications/read`

Flutter: timeline list, unread highlighting, unread count badge on the tab.

## Permissions

A barber may create bookings for themselves, edit and reschedule their own bookings, view
history for customers they have served, add notes, and start and complete their own
appointments.

A barber may not edit another barber's bookings, assign another barber, modify pricing,
change service definitions, view shop analytics, manage the walk-in queue, or manage staff.
No endpoint in this scope exposes any of those.

## Testing

- Backend: unit tests for `staffAuth.ts` resolution and rejection cases, and for the
  ownership check applied to booking routes. Follow the existing pattern in
  `src/lib/staff/availability.test.ts`.
- Mobile: widget tests for the new barber cards and a controller test for the login
  fallback path.
- Each slice ships with its tests. A slice is not done until `npm run build` and
  `flutter analyze` are both clean.

## Error handling

API errors follow the shape the mobile app already parses: `{ error, message }` with an
appropriate status. The Flutter repositories map `DioException` to a result object the same
way `AuthRepository` does today, so controllers never see raw Dio errors.

Barber-facing failure states: an expired token routes back to login; a failed refresh keeps
the last loaded data on screen and shows a retry affordance rather than blanking the page.
