# Architecture — System vs. Tool

The platform is two cooperating halves with a clean boundary, so neither becomes a tangled source
of truth.

> **Principle:** the **system** (web app) owns the data and everything humans do in the shop
> (state + screens). The **tool** (n8n) owns everything that happens automatically around that data
> (events + messages). They meet at the web app's **API/webhooks** — n8n never holds canonical data.

## Responsibilities

### System — custom web app (Next.js + Supabase)

- Database (source of truth): clients, staff/barbers, services, bookings, queue, visits, loyalty, messages.
- Front-desk console: check-in / walk-in capture, the live queue.
- Booking & availability engine; per-barber calendars; 15-min grace; slot release.
- Owner dashboard & reports; barber views; public online booking page.
- An API the automation calls, and webhooks it emits.

### Tool — n8n automation

- Inbound WhatsApp booking conversation → calls the web app API.
- Reminders (24h / 2h), post-visit review request, re-engagement nudges.
- Owner & barber notifications; delivery of the daily/weekly/monthly digests.

## Integration boundary

```
Customer WhatsApp ─► n8n ─► Web App API ─► DB
In-shop staff ─► Web App UI ─► DB
Web App ─ webhook (booking.created / visit.completed / client.went_quiet) ─► n8n ─► WhatsApp out
```

- n8n authenticates to the API with a shared secret (`AUTOMATION_API_KEY`), stored as an n8n credential.
- The web app emits one webhook per event type to n8n Webhook trigger nodes.
- During the pilot, n8n may still read/write Airtable; once the web app DB is the source of truth, the
  workflows are refactored to call the API instead.

## Channels

Four intake channels converge on one database, each tagged on the booking: `walkin`, `online`,
`whatsapp`, `phone`. This is distinct from `clients.acquisition_source` (how a client first found the
shop), which drives marketing-attribution reports.

See the full blueprint at `~/.claude/plans/synchronous-soaring-naur.md`.
