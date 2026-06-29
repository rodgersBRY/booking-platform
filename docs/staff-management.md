# Staff Management

Owner-only section of the dashboard for viewing, adding, deactivating, and resetting passwords for staff members.

## What the page does

`/dashboard/staff` renders a table of all staff rows ordered by creation date. Owners can:

- **Add a staff member** — opens a modal that collects name, role (barber or receptionist), email, phone (optional), and a temporary password. A Supabase Auth user is created first; if that succeeds the `staff` row is inserted and linked via `auth_user_id`. On any insert failure the auth user is rolled back.
- **Deactivate / Reactivate** — toggles a non-owner staff member's `status` between `active` and `inactive`. Inactive staff cannot log in (see inactive-staff gate below).
- **Reset password** — sets a new temporary password on the linked Supabase Auth user via the admin API.

The board polls every 15 seconds so the list stays fresh without a full page reload.

## API Endpoints

### `GET /api/staff`

Returns all staff rows ordered by `created_at`.

- **Auth:** requires active owner session
- **Response:** `{ staff: StaffListItem[] }`

### `POST /api/staff`

Creates a new staff member (role must be `barber` or `receptionist`).

- **Auth:** requires active owner session
- **Body:** `{ name, role, email, phone?, password }`
- **Response 201:** `{ staff: StaffListItem }`
- **Response 409:** email already registered in Supabase Auth

### `PATCH /api/staff/[id]`

Two actions dispatched via `action` field in the body:

| `action`        | Body fields        | Effect                                                                 |
| --------------- | ------------------ | ---------------------------------------------------------------------- |
| `setStatus`     | `status`           | Updates `staff.status`; blocked for owner rows and the caller's own id |
| `resetPassword` | `password`         | Calls `auth.admin.updateUser` with the new password                    |

## Auth user lifecycle

1. **Create** — `POST /api/staff` calls `auth.admin.createUser` with `email_confirm: true`, then inserts the `staff` row with `auth_user_id` linking the two.
2. **Active use** — `getCurrentStaff` looks up the staff row by `auth_user_id` and checks `status === "active"` before returning it.
3. **Deactivate** — sets `status` to `inactive` on the `staff` row. The Supabase Auth user is preserved, keeping the audit trail and booking history intact. The inactive-staff gate blocks future logins without deleting any data.
4. **Reactivate** — sets `status` back to `active`; the existing auth user is reused immediately.

## Inactive-staff gate

In `web/src/lib/auth.ts`, `getCurrentStaff` returns `null` for any staff row where `status !== "active"`. This means:

- Inactive staff are redirected to `/login` by `requireStaff` and `requireRole`.
- No session invalidation is needed — the check happens on every request.
