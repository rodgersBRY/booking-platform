# Barbershop Platform — Web App

The system-of-record for the barbershop platform (Next.js + Supabase). The n8n automation
workflows are the messaging layer and talk to this app's API. See the architecture blueprint at
`~/.claude/plans/synchronous-soaring-naur.md`.

## Stack

- **Next.js** (App Router, TypeScript) — receptionist console, owner dashboard, barber views, public booking page, and the API.
- **Supabase** — Postgres (source of truth), Auth (owner/receptionist/barber), Realtime (live queue board).

## Setup

1. **Install deps** (already done if scaffolded):

   ```bash
   npm install
   ```

2. **Create a Supabase project** at https://supabase.com, then copy the example env:

   ```bash
   cp .env.local.example .env.local
   ```

   Fill in `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`
   (from Project Settings → API) and a random `AUTOMATION_API_KEY`.

3. **Apply the schema.** Run `supabase/migrations/0001_init.sql` against your database — either via
   the Supabase SQL Editor (paste and run) or the Supabase CLI:

   ```bash
   supabase db push      # if using the Supabase CLI with a linked project
   ```

4. **Run the dev server:**
   ```bash
   npm run dev
   ```

## Project structure

```
supabase/migrations/   SQL schema (source of truth for the DB)
src/lib/supabase/      admin (service-role), server (RLS, cookies), client (browser) helpers
src/lib/db/types.ts    TypeScript row/enum types mirroring the schema
src/app/               routes, API handlers, UI
```

## Security model

- RLS is **on** for every table with **no policies** — the anon key can't touch data.
- The trusted server API uses the **service-role** client and enforces owner/receptionist/barber
  permissions itself (see the Roles & permissions section of the blueprint).
- The n8n automation authenticates to the API with `AUTOMATION_API_KEY`.

## Status

| Feature                  | Status                                                       |
| ------------------------ | ------------------------------------------------------------ |
| DB schema (init)         | ✅ Done — `0001_init.sql`                                    |
| Auth + role-based access | ✅ Done — `0002_auth.sql`, `src/proxy.ts`, `src/lib/auth.ts` |
| Seed data                | ✅ Done — `0003_seed.sql` (3 barbers, 6 services, 3 clients) |
| Booking / availability engine | ✅ Done — `src/lib/booking/availability.ts`, `src/lib/booking/types.ts` |
| Console API endpoints    | ✅ Done — `GET /api/barbers`, `GET /api/services`, `GET /api/availability`, `POST /api/bookings`, `GET /api/board`, `POST /api/walkins`, `POST /api/queue/{id}/seat`, `POST /api/queue/{id}/notify`, `POST /api/bookings/{id}/complete` |
| Owner dashboard          | 🔲 Stub only                                                 |
| Receptionist console     | 🔲 Stub only                                                 |
| Barber "My day" view     | 🔲 Stub only                                                 |
| Public booking page      | 🔲 Not started                                               |
| 15-min grace job         | ✅ Done — GET /api/cron/grace (header-auth)                  |

See `docs/auth.md` for the auth model, role→route map, and first-owner-user setup steps.

---

> Note: this project's `AGENTS.md` warns that the installed Next.js may differ from common
> conventions — consult `node_modules/next/dist/docs/` before writing route/component code.
