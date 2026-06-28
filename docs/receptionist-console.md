# Receptionist Console

The receptionist console is the primary front-desk screen for Fade & Sharp.
It is a tablet-first operational view gated to `owner` and `receptionist` roles.

---

## Layout

```
┌─────────────────────────────────────────────────────────┐
│  Header — shop name · Reception chip · clock · sign out │
├─────────────────────────────────────────────────────────┤
│  Quick stats — Waiting | Served today | No-shows        │
│                                                         │
│  Chairs board  ────────────────────  [Add walk-in]      │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐              │
│  │ Barber A │  │ Barber B │  │ Barber C │              │
│  │  FREE    │  │ IN CHAIR │  │  FREE    │              │
│  └──────────┘  └──────────┘  └──────────┘              │
│                                                         │
│  Queue                                                  │
│  ┌─────────────────────────────────────────────────┐   │
│  │ 12m  James Kariuki  Any barber    [Notify][Seat] │   │
│  │ 5m   Mary Wanjiru   Prefers Dan   [Notified][Seat]│  │
│  └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

---

## Components

| File | Type | Responsibility |
|---|---|---|
| `web/src/app/console/page.tsx` | Server Component | Role gate (`requireRole`), renders layout shell |
| `web/src/components/console/ConsoleHeader.tsx` | Client Component | Shop name, Reception chip, live clock (updates every 10 s), sign-out form |
| `web/src/components/console/ConsoleBoard.tsx` | Client Component | Orchestrates polling, state, and action callbacks; renders all sub-sections |
| `web/src/components/console/ChairsBoard.tsx` | Client Component | One card per barber: free (green) or in-chair (blue) with Done action |
| `web/src/components/console/LiveQueue.tsx` | Client Component | Per-row Seat now / Notify actions; inline 409 error for no free barber |
| `web/src/components/console/QuickStats.tsx` | Client Component | Waiting / served today / no-shows stat cards |
| `web/src/components/console/AddWalkinModal.tsx` | Client Component | `<dialog>` modal: name, phone, service, barber, acquisition source |
| `web/src/lib/api/console.ts` | Client-side helpers | Typed `fetch` wrappers for all console API endpoints |

---

## API Endpoints Consumed

| Endpoint | Method | Purpose |
|---|---|---|
| `/api/board` | GET | Chairs, queue, and stats — polled every 8 s |
| `/api/barbers` | GET | Barber list for Add walk-in dropdown |
| `/api/services` | GET | Service list for Add walk-in dropdown |
| `/api/walkins` | POST | Submit a new walk-in; returns `seated` or `queued` |
| `/api/queue/{id}/seat` | POST | Seat a queued person; 409 = no free barber |
| `/api/queue/{id}/notify` | POST | Mark queued person as notified |
| `/api/bookings/{id}/complete` | POST | Mark an in-chair booking as done |

---

## Polling Behavior

`ConsoleBoard` fetches `/api/board` on mount and then every **8 seconds** via `setInterval`.
The interval is cleared on unmount. After any user action (seat, notify, complete, add walk-in)
the board is re-fetched immediately so the UI reflects the change without waiting for the next poll.

Barbers and services are fetched once on mount (they rarely change).

> **TODO:** swap the 8-second polling for Supabase Realtime channel subscriptions once the
> production environment is set up, so the board updates instantly across multiple devices.

---

## Design Tokens

Defined in `web/src/app/globals.css` as CSS custom properties:

| Token | Value | Usage |
|---|---|---|
| `--navy` | `#1a2540` | Primary text, header background |
| `--brass` | `#b8893a` | Primary action button (Add walk-in), Reception chip |
| `--canvas` | `#f4f5f7` | Page background |
| `--free` / `--free-bg` | green | Free chair, Served today stat, Done button |
| `--waiting` / `--waiting-bg` | amber | Waiting stat, Notify button |
| `--in-chair` / `--in-chair-bg` | blue | In-chair card border, Seat now button |
| `--late` / `--late-bg` | red | No-shows stat, error messages |

---

## Auth

The page calls `requireRole('owner', 'receptionist')` (server-side, `web/src/lib/auth.ts`).
Users who are not signed in are redirected to `/login`; users with a different role are
redirected to their own role home. The role gate is never removed from the page server component.
