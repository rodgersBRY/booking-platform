# Barbershop AI Receptionist — Build Guide

**Zubariq Ventures | Internal Documentation**
_Prototype: Telegram → Production: WhatsApp Business API_

---

## Overview

This document is a step-by-step build guide for the Barbershop AI Receptionist workflow. The system acts as a virtual receptionist — handling bookings, sending reminders, following up for reviews, and re-engaging inactive clients automatically.

The prototype is built using **Telegram** for speed and zero API approval friction. Once validated, the communication layer swaps to **WhatsApp Business API** for production. Everything else stays the same.

---

## System Architecture

The system is **4 separate n8n workflows** sharing one Airtable base as a common data layer.

| Workflow                   | Trigger Type        | Purpose                                                             |
| -------------------------- | ------------------- | ------------------------------------------------------------------- |
| 1. Inbound Message Handler | Webhook (real-time) | Receives messages, understands intent, manages booking conversation |
| 2. Reminder Workflow       | Scheduled           | Sends 24hr and 2hr appointment reminders                            |
| 3. Post-Visit Follow-Up    | Scheduled           | Sends review request after appointment                              |
| 4. Re-engagement Workflow  | Scheduled           | Nudges clients who haven't booked in 21+ days                       |

---

## Tools & Accounts Required

### Prototype Stack

| Tool                       | Purpose                                 | Cost                                |
| -------------------------- | --------------------------------------- | ----------------------------------- |
| **n8n**                    | Workflow automation engine              | Free (self-hosted) or ~$20/mo cloud |
| **Telegram Bot**           | Communication channel (prototype)       | Free                                |
| **Claude API** (Anthropic) | Reads and understands incoming messages | Pay per use                         |
| **Google Calendar**        | Stores and manages appointment slots    | Free                                |
| **Airtable**               | Client database and booking records     | Free tier sufficient                |

### Production Additions (WhatsApp)

| Tool                           | Purpose                                   | Cost                           |
| ------------------------------ | ----------------------------------------- | ------------------------------ |
| **WhatsApp Business API**      | Replace Telegram as communication channel | Via Twilio or Africa's Talking |
| **Twilio or Africa's Talking** | WhatsApp API provider for East Africa     | Pay per message                |

---

## Airtable Schema

Before building any workflow, set up the Airtable base. This is the memory layer that all four workflows read from and write to.

### Table 1: `Clients`

| Field Name         | Field Type       | Description                           |
| ------------------ | ---------------- | ------------------------------------- |
| `client_id`        | Autonumber       | Unique ID auto-generated              |
| `name`             | Single line text | Client's first name                   |
| `phone`            | Phone number     | Client's Telegram or WhatsApp number  |
| `telegram_chat_id` | Single line text | Telegram chat ID for sending messages |
| `last_visit_date`  | Date             | Date of their most recent appointment |
| `total_visits`     | Number           | Count of completed visits             |
| `status`           | Single select    | Active / Inactive / Blocked           |
| `created_at`       | Created time     | Auto-filled when record is created    |

### Table 2: `Bookings`

| Field Name                 | Field Type       | Description                                   |
| -------------------------- | ---------------- | --------------------------------------------- |
| `booking_id`               | Autonumber       | Unique booking ID                             |
| `client`                   | Link to Clients  | Links to the Clients table                    |
| `appointment_date`         | Date             | Date of the appointment                       |
| `appointment_time`         | Single line text | Time as a string e.g. "10:00 AM"              |
| `service`                  | Single select    | Haircut / Shave / Both                        |
| `status`                   | Single select    | Confirmed / Completed / Cancelled / No-show   |
| `reminder_24hr_sent`       | Checkbox         | Tracks if 24hr reminder was sent              |
| `reminder_2hr_sent`        | Checkbox         | Tracks if 2hr reminder was sent               |
| `followup_sent`            | Checkbox         | Tracks if post-visit review request was sent  |
| `google_calendar_event_id` | Single line text | Stores Calendar event ID for cancellation use |
| `created_at`               | Created time     | Auto-filled                                   |

---

## Workflow 1: Inbound Message Handler

**Trigger:** Webhook fires every time a message is sent to the Telegram bot.

This workflow is always listening. It is the only workflow that has a real-time trigger.

---

### Step 1.1 — Receive the Message

**What happens:**
The Telegram bot receives a message from a client. n8n's webhook captures the message text and the sender's chat ID.

**What to configure in n8n:**

- Add a **Telegram Trigger** node
- Set it to listen for messages on your bot
- Output: `message.text`, `message.chat.id`, `message.from.first_name`

**How to set up the Telegram Bot:**

1. Open Telegram and search for `@BotFather`
2. Send `/newbot` and follow the prompts to name your bot
3. Copy the API token provided
4. In n8n, go to Credentials → Add Telegram API credential → paste the token
5. Use the bot token in your Telegram Trigger node

---

### Step 1.2 — Look Up the Client in Airtable

**What happens:**
Before doing anything else, check if this person already exists in the Clients table. Their Telegram chat ID is the identifier.

**What to configure in n8n:**

- Add an **Airtable node** set to **Search Records**
- Table: `Clients`
- Filter formula: `{telegram_chat_id} = "{{chat_id from step 1.1}}"`

**Branching logic:**

- If found → proceed with their name and record
- If not found → create a new client record first, then proceed

**New client record to create:**

- `name`: from `message.from.first_name`
- `telegram_chat_id`: from `message.chat.id`
- `status`: Active

---

### Step 1.3 — Send Message to Claude for Intent Detection

**What happens:**
The incoming message text is sent to Claude API. Claude reads it and returns structured JSON identifying what the client wants.

**What to configure in n8n:**

- Add an **HTTP Request** node
- Method: POST
- URL: `https://api.anthropic.com/v1/messages`
- Headers:
  - `x-api-key`: your Anthropic API key
  - `anthropic-version`: `2023-06-01`
  - `content-type`: `application/json`

**Request body to send to Claude:**

```json
{
  "model": "claude-3-5-haiku-20241022",
  "max_tokens": 300,
  "messages": [
    {
      "role": "user",
      "content": "You are a receptionist assistant for a barbershop. A client has sent the following message: '{{message text}}'. Classify their intent and extract details. Respond ONLY in valid JSON with this exact structure: { \"intent\": \"booking\" | \"cancellation\" | \"question\" | \"other\", \"requested_date\": \"YYYY-MM-DD or null\", \"requested_time\": \"HH:MM or null\", \"service\": \"haircut\" | \"shave\" | \"both\" | null }"
    }
  ]
}
```

**What Claude returns (example):**

```json
{
  "intent": "booking",
  "requested_date": "2026-06-20",
  "requested_time": null,
  "service": "haircut"
}
```

---

### Step 1.4 — Route by Intent

**What happens:**
Based on Claude's JSON response, the workflow splits into three paths.

**What to configure in n8n:**

- Add a **Switch** node
- Condition 1: `intent == "booking"` → go to Step 1.5
- Condition 2: `intent == "cancellation"` → go to Step 1.8
- Condition 3: `intent == "question"` → go to Step 1.9
- Default → send a polite "I didn't understand that" message

---

### Step 1.5 — Check Google Calendar for Available Slots

**What happens:**
Query Google Calendar to find free time slots on the date the client mentioned. If they didn't mention a date, default to the next available day.

**What to configure in n8n:**

- Add a **Google Calendar node** set to **Get Many Events**
- Calendar: the barbershop's Google Calendar
- Time Min: start of the requested date
- Time Max: end of the requested date
- This returns what's already booked

**Logic to determine free slots:**

- Define the shop's working hours (e.g. 8am–6pm)
- Define appointment duration (e.g. 45 minutes)
- Subtract booked slots from available hours
- Pick the first 3 open slots to offer the client

> You can handle this slot-calculation logic inside an n8n **Code node** using simple JavaScript.

---

### Step 1.6 — Send Slot Options to Client

**What happens:**
Send a Telegram message to the client with 3 available time options.

**What to configure in n8n:**

- Add a **Telegram node** set to **Send Message**
- Chat ID: from Step 1.1
- Message text example:

```
Hi James 👋 We have these slots open on Saturday:

1️⃣ 10:00 AM
2️⃣ 12:30 PM
3️⃣ 3:00 PM

Reply with 1, 2, or 3 to confirm your spot.
```

**Important:** After sending this message, the workflow ends here. The client's reply becomes a new incoming message that re-enters Workflow 1 from Step 1.1. Claude will then detect the intent as a slot selection (e.g. "1") and route accordingly.

> To handle this properly, store a `conversation_state` field in Airtable set to `"awaiting_slot_selection"` so the next message knows the context.

---

### Step 1.7 — Confirm the Booking

**What happens:**
Client replies with their slot choice. The workflow creates the calendar event, logs the booking in Airtable, and sends a confirmation.

**What to configure in n8n:**

**Google Calendar node — Create Event:**

- Title: `Haircut — James`
- Start time: selected slot
- Duration: 45 minutes
- Description: client phone number

**Airtable node — Create Record in Bookings:**

- `client`: linked to client record
- `appointment_date`: selected date
- `appointment_time`: selected time
- `service`: from Claude's extraction in Step 1.3
- `status`: Confirmed
- `reminder_24hr_sent`: unchecked
- `reminder_2hr_sent`: unchecked
- `followup_sent`: unchecked
- `google_calendar_event_id`: from the Calendar response

**Telegram node — Send Confirmation:**

```
✅ You're booked, James!

📅 Saturday, 21 June
⏰ 10:00 AM
✂️ Fade & Sharp Barbershop

We'll remind you the day before. See you then!
```

Also reset `conversation_state` in Airtable to `null`.

---

### Step 1.8 — Handle Cancellation

**What happens:**
If Claude detects a cancellation intent, find their next upcoming booking and cancel it.

**What to configure in n8n:**

- **Airtable node** — search for their most recent Confirmed booking
- **Google Calendar node** — delete the event using the stored `google_calendar_event_id`
- **Airtable node** — update booking `status` to Cancelled
- **Telegram node** — send confirmation:

```
Got it, your appointment has been cancelled. No problem at all — just message us when you're ready to rebook 👍
```

---

### Step 1.9 — Answer a Question

**What happens:**
Send the client's question back to Claude with context about the barbershop, and return the AI's answer.

**What to configure in n8n:**

- Add another **HTTP Request** node to Claude API
- System prompt: include barbershop details — opening hours, prices, location, services offered
- Claude returns a natural language reply
- **Telegram node** sends that reply to the client

---

## Workflow 2: Reminder Workflow

**Trigger:** Scheduled — runs every day at 8:00 AM.

---

### Step 2.1 — Fetch Upcoming Bookings

**What to configure in n8n:**

- Add a **Schedule Trigger** node — runs daily at 8:00 AM
- Add an **Airtable node** — search Bookings table
- Filter: `status = "Confirmed"`
- This returns all confirmed future bookings

---

### Step 2.2 — Check Which Reminders Need Sending

**What to configure in n8n:**

- Add a **Code node** to evaluate each booking:
  - If appointment is within the next 24–26 hours AND `reminder_24hr_sent` is unchecked → send 24hr reminder
  - If appointment is within the next 2–3 hours AND `reminder_2hr_sent` is unchecked → send 2hr reminder

---

### Step 2.3 — Send 24hr Reminder

**Telegram node — Message:**

```
Hi James 👋 Reminder: your haircut is tomorrow at 10:00 AM at Fade & Sharp.

Reply CANCEL if your plans change.
```

Then **Airtable node** — update `reminder_24hr_sent` to checked.

---

### Step 2.4 — Send 2hr Reminder

**Telegram node — Message:**

```
See you in 2 hours, James ✂️ We're getting ready for you!
```

Then **Airtable node** — update `reminder_2hr_sent` to checked.

---

## Workflow 3: Post-Visit Follow-Up

**Trigger:** Scheduled — runs every day at 5:00 PM.

---

### Step 3.1 — Find Completed Appointments

**What to configure in n8n:**

- **Schedule Trigger** — runs daily at 5:00 PM
- **Airtable node** — search Bookings
- Filter: `status = "Confirmed"` AND `appointment_date = today` AND `followup_sent = unchecked`

These are appointments that happened today and haven't been followed up yet.

---

### Step 3.2 — Mark as Completed and Send Review Request

**Airtable node** — update `status` to Completed and `last_visit_date` on the Clients record.

**Telegram node — Message:**

```
Hope the cut is looking fresh, James 🔥

If you enjoyed your visit, a quick Google review means a lot to us 🙏
👉 [Your Google Review Link Here]

See you next time!
```

**Airtable node** — update `followup_sent` to checked.

---

## Workflow 4: Re-engagement Workflow

**Trigger:** Scheduled — runs every Monday at 9:00 AM.

---

### Step 4.1 — Find Inactive Clients

**What to configure in n8n:**

- **Schedule Trigger** — runs every Monday
- **Airtable node** — search Clients
- Filter: `last_visit_date` is more than 21 days ago AND `status = "Active"`
- Also filter: no upcoming Confirmed booking exists for this client

---

### Step 4.2 — Send Re-engagement Message

**Telegram node — Message:**

```
Hey James, it's been a few weeks 👀

Time for a fresh cut? We've got slots open this week — just message us to book your spot ✂️
```

> Do not send this more than once per month per client. Add a `last_reengagement_sent` date field to the Clients table and check it before sending.

---

## Switching from Telegram to WhatsApp (Production)

When moving from prototype to production, the only changes are in the communication layer. The logic, Airtable schema, and Google Calendar integration stay exactly the same.

| What changes      | Telegram (Prototype)   | WhatsApp (Production)              |
| ----------------- | ---------------------- | ---------------------------------- |
| Trigger node      | Telegram Trigger       | Webhook from WhatsApp Business API |
| Send message node | Telegram: Send Message | HTTP Request to WhatsApp API       |
| Client identifier | `telegram_chat_id`     | `whatsapp_phone_number`            |
| API provider      | Telegram BotFather     | Twilio or Africa's Talking         |

### WhatsApp-specific setup steps:

1. Register a WhatsApp Business Account via Meta Business Suite
2. Choose an API provider — **Africa's Talking** is recommended for Kenya (local support, KES billing)
3. Get a dedicated phone number approved for WhatsApp Business API
4. In n8n, replace all Telegram nodes with HTTP Request nodes pointing to your provider's API endpoint
5. Update the `telegram_chat_id` field in Airtable to `whatsapp_phone_number`
6. Note: WhatsApp requires pre-approved **message templates** for all outbound messages (reminders, follow-ups). Submit these for approval before going live.

---

## Testing Checklist (Prototype)

Before showing this to a client, run through each scenario manually:

- [ ] Send "I want to book a haircut on Saturday" to the Telegram bot → does it offer slots?
- [ ] Reply with a slot number → does it confirm the booking in Airtable and Calendar?
- [ ] Send "Cancel my appointment" → does it cancel and confirm?
- [ ] Send "How much does a haircut cost?" → does it answer correctly?
- [ ] Manually trigger Workflow 2 for a booking within 24hrs → does reminder send?
- [ ] Manually trigger Workflow 3 for today's appointment → does review request send?
- [ ] Set a client's last visit to 22 days ago → does Workflow 4 send the nudge?

---

## Estimated Build Time

| Workflow                    | Estimated Time   |
| --------------------------- | ---------------- |
| Airtable schema setup       | 1–2 hours        |
| Workflow 1: Inbound Handler | 4–6 hours        |
| Workflow 2: Reminders       | 1–2 hours        |
| Workflow 3: Post-Visit      | 1 hour           |
| Workflow 4: Re-engagement   | 1 hour           |
| Testing and fixing          | 2–3 hours        |
| **Total**                   | **~10–14 hours** |

---

_Zubariq Ventures · Barbershop AI Receptionist Build Guide · June 2026_
