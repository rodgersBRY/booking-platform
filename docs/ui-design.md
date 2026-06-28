# UI Design

Goal: **simple and easy to adopt** for non-technical staff. For an all-day operational tool, clarity
beats flair — the design thesis is operational clarity.

## Principles

1. **Role-based home screens.** Each person logs in and lands on exactly their one job:
   - Receptionist → the console (queue + check-in). The hero surface, used all day.
   - Owner → the dashboard (north-star numbers first).
   - Barber → their day (their queue, their next client).
   - Customer → the public booking page (4 taps, mobile-first).
2. **The receptionist console is designed like a POS, not an admin panel** — big touch targets (tablet
   at the desk), live queue front-and-center, walk-in capture in ~2 taps, status shown by **color**.
3. **Plain language.** Verbs people control ("Add walk-in", "Seat now", "Notify when free"), sentence
   case, no system jargon.
4. **One consistent shell** everywhere so the product feels learnable.

## Component system

**shadcn/ui** (Radix + Tailwind, already configured). Accessible, consistent, fast to build, themeable
per shop. Next.js App Router + Server Components by default; `'use client'` only where interactive
(e.g. the realtime queue board).

## Visual language

Grounded in the barbershop's world — a modern barber counter:

- **Ink (primary):** deep barber-navy / charcoal.
- **Brass (accent):** warm brass for the primary action and brand — used sparingly.
- **Canvas:** calm light gray for all-day comfort; white cards.
- **Status colors (loud, unmistakable):** green = free/done, amber = waiting/notified, blue = in chair,
  red = late.
- **Signature element:** a live "chairs" board showing each barber's station — not a generic stat row.

## Screen inventory

- **Receptionist console** — chairs board, live queue with per-card actions, day's quick stats.
- **Owner dashboard** — new-vs-returning, revenue, at-risk count up front; drill-down below.
- **Barber view** — phone-sized: next client, own queue, mark done.
- **Public booking** — mobile, 4 steps: service → barber → time → confirm.

A mockup of the receptionist console was reviewed during design; the real screens wear the navy + brass
theme on a tablet with larger touch targets.
