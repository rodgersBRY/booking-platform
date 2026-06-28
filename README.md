# Barbershop Platform

A customer-capture, booking, and insights platform for barbershops & salons — built walk-in-first,
with a custom web app as the system of record and an n8n automation layer for all outbound messaging.

## The two halves

| Part                      | What it is                                                                                                            | Where                                                     |
| ------------------------- | --------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------- |
| **Web app (the system)**  | Source of truth + front-desk console, owner dashboard, barber views, public booking, and the API. Next.js + Supabase. | [`web/`](web/)                                            |
| **Automation (the tool)** | n8n workflows: WhatsApp booking, reminders, post-visit follow-up, re-engagement, owner/barber alerts.                 | [`CLAUDE.md`](CLAUDE.md) (build guide) + the n8n instance |

> **Principle:** the system owns the data and everything humans do in the shop; the tool owns
> everything that happens automatically around that data. They meet at the web app's API/webhooks —
> n8n never holds canonical data. Full rationale in the architecture blueprint
> (`~/.claude/plans/synchronous-soaring-naur.md`).

## Intake channels (all converge on one database)

Walk-in (receptionist console) · phone-to-barber (logged at the desk) · WhatsApp (n8n → API) ·
online (website Book Now → API). Every booking is tagged by `channel`; every client by
`acquisition_source`.

## Documentation

- [`docs/architecture.md`](docs/architecture.md) — system vs. tool boundary, integration model.
- [`docs/database-schema.md`](docs/database-schema.md) — tables, constraints, the double-booking guard, RLS.
- [`docs/auth.md`](docs/auth.md) — auth model, roles, route protection, first-owner setup.
- [`docs/booking-engine.md`](docs/booking-engine.md) — availability engine + console API endpoints.
- [`docs/ui-design.md`](docs/ui-design.md) — UI philosophy, role-based screens, design language.
- [`web/README.md`](web/README.md) — web app setup and run instructions.

## Status

- ✅ n8n workflows 1–4 built (inbound handler, reminders, follow-up, re-engagement).
- ✅ Web app scaffolded (Next.js 16 + Supabase) with the full Postgres schema.
- ✅ Auth + role-based access (owner / receptionist / barber) with route protection.
- ✅ Booking/availability engine + console API endpoints + seed data.
- ⏳ Next: receptionist console UI; then owner dashboard, barber view, public booking.

Each implemented feature is documented under [`docs/`](docs/).
