# Barber "My Day" View Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a barber-facing "My Day" view that shows their schedule for today, lets them mark clients as arrived/seated/complete, and captures payment at completion.

**Architecture:** A new GET `/api/me/day` endpoint queries bookings and queue count scoped to the authenticated barber's `staff.id`. A `MyDayBoard` client component polls every 10 s and renders a next-client card, a schedule list with per-row action buttons, and a payment-capture modal. Three existing booking action routes (`arrive`, `seat`, `complete`) are extended to allow a barber to act on their own bookings.

**Tech Stack:** Next.js 16 App Router, TypeScript, Supabase (service-role client), Tailwind CSS with CSS variables matching the existing navy/brass theme.

---

## File Map

**Create:**
- `web/src/app/api/me/day/route.ts` — GET endpoint, barber-scoped day data
- `web/src/lib/api/me.ts` — typed fetch helpers for the barber view
- `web/src/components/me/MyDayBoard.tsx` — polling container component
- `web/src/components/me/NextClientCard.tsx` — next appointment hero card
- `web/src/components/me/ScheduleList.tsx` — full today schedule list
- `web/src/components/me/ScheduleRow.tsx` — single appointment row with action button
- `web/src/components/me/CompleteModal.tsx` — payment capture modal
- `docs/barber-view.md` — brief feature doc

**Modify:**
- `web/src/app/api/bookings/[id]/complete/route.ts` — add barber role + body parsing
- `web/src/app/api/bookings/[id]/arrive/route.ts` — add barber role + barber_id select
- `web/src/app/api/bookings/[id]/seat/route.ts` — add barber ownership check
- `web/src/app/me/page.tsx` — replace stub with `<MyDayBoard>`
- `web/README.md` — update status table

---

## Task 1: Create the branch

- [ ] **Step 1: Create and switch to the feature branch**

```bash
git checkout main
git checkout -b feature/barber-my-day
```

- [ ] **Step 2: Verify you are on the right branch**

```bash
git branch --show-current
```

Expected output: `feature/barber-my-day`

---

## Task 2: `GET /api/me/day` route

**Files:**
- Create: `web/src/app/api/me/day/route.ts`

- [ ] **Step 1: Create the file**

```typescript
// web/src/app/api/me/day/route.ts
import { getCurrentStaff } from "@/lib/auth";
import { createAdminClient } from "@/lib/supabase/admin";
import { NextResponse } from "next/server";

const TZ = "Africa/Nairobi";

function eatTodayBounds(): { start: string; end: string } {
  const now = new Date();
  const eatDate = new Intl.DateTimeFormat("en-CA", {
    timeZone: TZ,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).format(now);
  const start = new Date(`${eatDate}T00:00:00+03:00`).toISOString();
  const end = new Date(`${eatDate}T23:59:59+03:00`).toISOString();
  return { start, end };
}

function firstRel<T>(rel: unknown): T | null {
  if (rel == null) return null;
  if (Array.isArray(rel)) return (rel[0] as T) ?? null;
  return rel as T;
}

export async function GET() {
  const staff = await getCurrentStaff();
  if (!staff) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }
  if (staff.role !== "barber" && staff.role !== "owner") {
    return NextResponse.json({ error: "Forbidden" }, { status: 403 });
  }

  const admin = createAdminClient();
  const { start: todayStart, end: todayEnd } = eatTodayBounds();

  // Bookings for this barber today (active statuses only).
  const { data: bookingRows, error: bookErr } = await admin
    .from("bookings")
    .select("id, scheduled_start, status, clients(name), services(name)")
    .eq("barber_id", staff.id)
    .in("status", ["booked", "arrived", "in_chair", "late"])
    .gte("scheduled_start", todayStart)
    .lte("scheduled_start", todayEnd)
    .order("scheduled_start");

  if (bookErr) {
    return NextResponse.json({ error: bookErr.message }, { status: 500 });
  }

  type BookingRow = {
    id: unknown;
    scheduled_start: unknown;
    status: unknown;
    clients: unknown;
    services: unknown;
  };

  const schedule = (bookingRows ?? []).map((raw: unknown) => {
    const b = raw as BookingRow;
    const client = firstRel<{ name: string }>(b.clients);
    const service = firstRel<{ name: string }>(b.services);
    return {
      bookingId: b.id as string,
      clientName: client?.name ?? "Unknown",
      serviceName: service?.name ?? null,
      scheduledStart: b.scheduled_start as string,
      status: b.status as "booked" | "arrived" | "in_chair" | "late",
    };
  });

  const nextClient =
    schedule.find((s) => s.status === "booked" || s.status === "arrived") ??
    null;

  // Queue waiting count for this barber.
  const { count: queueWaitingCount } = await admin
    .from("queue_entries")
    .select("id", { count: "exact", head: true })
    .eq("barber_id", staff.id)
    .eq("status", "waiting");

  return NextResponse.json({
    barberId: staff.id,
    nextClient,
    schedule,
    queueWaitingCount: queueWaitingCount ?? 0,
  });
}
```

- [ ] **Step 2: Type-check**

```bash
cd web && npx tsc --noEmit 2>&1 | head -40
```

Expected: no errors related to `me/day/route.ts`.

---

## Task 3: Extend `complete` route — barber role + body parsing

**Files:**
- Modify: `web/src/app/api/bookings/[id]/complete/route.ts`

- [ ] **Step 1: Replace the file contents**

The new version adds:
1. Body parsing for `amountCharged` and `paymentMethod` before the role check.
2. Barber role allowed — but only if `booking.barber_id === staff.id`.
3. `amount_charged` and `payment_method` threaded into the `visits.insert`.

```typescript
// web/src/app/api/bookings/[id]/complete/route.ts
import { getCurrentStaff } from "@/lib/auth";
import { createAdminClient } from "@/lib/supabase/admin";
import { NextRequest, NextResponse } from "next/server";

// TODO: AUTOMATION_API_KEY auth — n8n will authenticate via this header in production.

export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  const staff = await getCurrentStaff();
  if (!staff) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  // Parse optional body first (before role check so we can reuse later).
  let body: { amountCharged?: number; paymentMethod?: string } = {};
  try {
    body = await request.json();
  } catch {
    // Body is optional.
  }
  const amountCharged = body.amountCharged ?? 0;
  const paymentMethod = body.paymentMethod ?? null;

  // Base role gate — barber ownership checked after fetching booking.
  if (
    staff.role !== "owner" &&
    staff.role !== "receptionist" &&
    staff.role !== "barber"
  ) {
    return NextResponse.json({ error: "Forbidden" }, { status: 403 });
  }

  const { id } = await params;
  const admin = createAdminClient();

  // Fetch booking.
  const { data: booking, error: bookErr } = await admin
    .from("bookings")
    .select("id, client_id, barber_id, service_id, status")
    .eq("id", id)
    .single();

  if (bookErr || !booking) {
    return NextResponse.json({ error: "Booking not found" }, { status: 404 });
  }

  // Barbers may only complete their own bookings.
  if (staff.role === "barber" && booking.barber_id !== staff.id) {
    return NextResponse.json({ error: "Forbidden" }, { status: 403 });
  }

  if (booking.status === "completed") {
    return NextResponse.json({ error: "Booking already completed" }, { status: 409 });
  }

  const now = new Date().toISOString();

  // Mark booking completed.
  const { error: updateErr } = await admin
    .from("bookings")
    .update({ status: "completed" })
    .eq("id", id);

  if (updateErr) {
    return NextResponse.json({ error: updateErr.message }, { status: 500 });
  }

  // Insert visit row.
  const { data: visit, error: visitErr } = await admin
    .from("visits")
    .insert({
      booking_id: id,
      client_id: booking.client_id as string,
      barber_id: booking.barber_id as string | null,
      service_id: booking.service_id as string,
      completed_at: now,
      amount_charged: amountCharged,
      payment_method: paymentMethod,
    })
    .select()
    .single();

  if (visitErr) {
    return NextResponse.json({ error: visitErr.message }, { status: 500 });
  }

  // Bump client total_visits and last_visit_at.
  const { data: client } = await admin
    .from("clients")
    .select("total_visits")
    .eq("id", booking.client_id as string)
    .single();

  await admin
    .from("clients")
    .update({
      total_visits: ((client?.total_visits as number | undefined) ?? 0) + 1,
      last_visit_at: now,
    })
    .eq("id", booking.client_id as string);

  return NextResponse.json({ visit });
}
```

- [ ] **Step 2: Type-check**

```bash
cd web && npx tsc --noEmit 2>&1 | head -40
```

Expected: no new errors.

---

## Task 4: Extend `arrive` route — barber role

**Files:**
- Modify: `web/src/app/api/bookings/[id]/arrive/route.ts`

- [ ] **Step 1: Replace the file contents**

Changes: fetch `barber_id` in select; widen role gate to include `barber`; add ownership check for barber role.

```typescript
// web/src/app/api/bookings/[id]/arrive/route.ts
import { getCurrentStaff } from "@/lib/auth";
import { createAdminClient } from "@/lib/supabase/admin";
import { NextRequest, NextResponse } from "next/server";

export async function POST(
  _request: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  const staff = await getCurrentStaff();
  if (!staff) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }
  if (!["owner", "receptionist", "barber"].includes(staff.role)) {
    return NextResponse.json({ error: "Forbidden" }, { status: 403 });
  }

  const { id } = await params;
  const admin = createAdminClient();

  const { data: booking, error: bookErr } = await admin
    .from("bookings")
    .select("id, status, barber_id")
    .eq("id", id)
    .single();

  if (bookErr || !booking) {
    return NextResponse.json({ error: "Booking not found" }, { status: 404 });
  }

  // Barbers may only mark arrived on their own bookings.
  if (staff.role === "barber" && booking.barber_id !== staff.id) {
    return NextResponse.json({ error: "Forbidden" }, { status: 403 });
  }

  if (booking.status !== "booked") {
    return NextResponse.json(
      { error: "Booking is not in booked status" },
      { status: 409 },
    );
  }

  const { error: updateErr } = await admin
    .from("bookings")
    .update({ status: "arrived" })
    .eq("id", id);

  if (updateErr) {
    return NextResponse.json({ error: updateErr.message }, { status: 500 });
  }

  return NextResponse.json({ ok: true });
}
```

- [ ] **Step 2: Type-check**

```bash
cd web && npx tsc --noEmit 2>&1 | head -40
```

Expected: no new errors.

---

## Task 5: Extend `seat` route — barber ownership check

**Files:**
- Modify: `web/src/app/api/bookings/[id]/seat/route.ts`

- [ ] **Step 1: Replace the file contents**

The existing select already fetches `barber_id`. Changes: widen role gate; add ownership check.

```typescript
// web/src/app/api/bookings/[id]/seat/route.ts
import { getCurrentStaff } from "@/lib/auth";
import { createAdminClient } from "@/lib/supabase/admin";
import { NextRequest, NextResponse } from "next/server";

export async function POST(
  _request: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  const staff = await getCurrentStaff();
  if (!staff) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }
  if (!["owner", "receptionist", "barber"].includes(staff.role)) {
    return NextResponse.json({ error: "Forbidden" }, { status: 403 });
  }

  const { id } = await params;
  const admin = createAdminClient();

  // Fetch booking with service for duration.
  const { data: booking, error: bookErr } = await admin
    .from("bookings")
    .select("id, status, barber_id, service_id, services(duration_minutes)")
    .eq("id", id)
    .single();

  if (bookErr || !booking) {
    return NextResponse.json({ error: "Booking not found" }, { status: 404 });
  }

  // Barbers may only seat their own bookings.
  if (staff.role === "barber" && booking.barber_id !== staff.id) {
    return NextResponse.json({ error: "Forbidden" }, { status: 403 });
  }

  if (!["booked", "arrived"].includes(booking.status as string)) {
    return NextResponse.json(
      { error: "Booking cannot be seated from its current status" },
      { status: 409 },
    );
  }

  // Resolve service duration — fall back to shortest active service.
  type ServiceRel = { duration_minutes: number } | null;
  const serviceRel = Array.isArray(booking.services)
    ? ((booking.services[0] as ServiceRel) ?? null)
    : ((booking.services as ServiceRel) ?? null);

  let duration: number = serviceRel?.duration_minutes ?? 0;

  if (!duration) {
    const { data: fallback } = await admin
      .from("services")
      .select("duration_minutes")
      .eq("active", true)
      .order("duration_minutes")
      .limit(1)
      .single();
    duration = (fallback?.duration_minutes as number | undefined) ?? 45;
  }

  const now = new Date();
  const nowIso = now.toISOString();
  const scheduledEnd = new Date(now.getTime() + duration * 60 * 1000).toISOString();

  const { data: updated, error: updateErr } = await admin
    .from("bookings")
    .update({
      status: "in_chair",
      scheduled_start: nowIso,
      scheduled_end: scheduledEnd,
    })
    .eq("id", id)
    .select()
    .single();

  if (updateErr) {
    // Postgres exclusion constraint violation — barber already in a booking.
    if (updateErr.code === "23P01") {
      return NextResponse.json(
        { error: "barber_busy", message: "That barber is busy right now." },
        { status: 409 },
      );
    }
    return NextResponse.json({ error: updateErr.message }, { status: 500 });
  }

  return NextResponse.json({ booking: updated });
}
```

- [ ] **Step 2: Type-check**

```bash
cd web && npx tsc --noEmit 2>&1 | head -40
```

Expected: no new errors.

---

## Task 6: `web/src/lib/api/me.ts` — typed fetch helpers

**Files:**
- Create: `web/src/lib/api/me.ts`

- [ ] **Step 1: Create the file**

```typescript
// web/src/lib/api/me.ts
// Typed fetch helpers for the barber "My Day" view.
// All functions called from client components.

export interface ScheduleItem {
  bookingId: string;
  clientName: string;
  serviceName: string | null;
  scheduledStart: string;
  status: "booked" | "arrived" | "in_chair" | "late";
}

export interface NextClientItem {
  bookingId: string;
  clientName: string;
  serviceName: string | null;
  scheduledStart: string;
  status: "booked" | "arrived";
}

export interface MyDayData {
  barberId: string;
  nextClient: NextClientItem | null;
  schedule: ScheduleItem[];
  queueWaitingCount: number;
}

async function apiFetch<T>(path: string, init?: RequestInit): Promise<T> {
  const res = await fetch(path, init);
  if (!res.ok) {
    const body = await res.json().catch(() => ({}));
    const err = new Error(
      (body as { error?: string }).error ?? `HTTP ${res.status}`
    );
    (err as Error & { status: number }).status = res.status;
    throw err;
  }
  return res.json() as Promise<T>;
}

export async function fetchMyDay(): Promise<MyDayData> {
  return apiFetch<MyDayData>("/api/me/day");
}

export async function arriveMyBooking(id: string): Promise<void> {
  await apiFetch(`/api/bookings/${id}/arrive`, { method: "POST" });
}

export async function startMyBooking(id: string): Promise<void> {
  await apiFetch(`/api/bookings/${id}/seat`, { method: "POST" });
}

export async function completeMyBooking(
  id: string,
  amountCharged: number,
  paymentMethod: string
): Promise<void> {
  await apiFetch(`/api/bookings/${id}/complete`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ amountCharged, paymentMethod }),
  });
}
```

- [ ] **Step 2: Type-check**

```bash
cd web && npx tsc --noEmit 2>&1 | head -40
```

Expected: no errors.

---

## Task 7: `CompleteModal` component

**Files:**
- Create: `web/src/components/me/CompleteModal.tsx`

- [ ] **Step 1: Create the file**

```typescript
// web/src/components/me/CompleteModal.tsx
'use client';

import { useEffect, useRef, useState } from 'react';
import { completeMyBooking } from '@/lib/api/me';

interface Props {
  bookingId: string;
  clientName: string;
  onClose: () => void;
  onComplete: () => void;
}

const PAYMENT_METHODS = [
  { value: 'cash', label: 'Cash' },
  { value: 'mpesa', label: 'M-Pesa' },
  { value: 'card', label: 'Card' },
];

export default function CompleteModal({ bookingId, clientName, onClose, onComplete }: Props) {
  const dialogRef = useRef<HTMLDialogElement>(null);
  const [amount, setAmount] = useState('');
  const [paymentMethod, setPaymentMethod] = useState('cash');
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    dialogRef.current?.showModal();
  }, []);

  function handleBackdropClick(e: React.MouseEvent<HTMLDialogElement>) {
    if (e.target === dialogRef.current) onClose();
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setSubmitting(true);
    setError(null);
    try {
      await completeMyBooking(bookingId, Number(amount) || 0, paymentMethod);
      onComplete();
      onClose();
    } catch (err) {
      setError((err as Error).message ?? 'Something went wrong. Try again.');
    } finally {
      setSubmitting(false);
    }
  }

  const inputClass =
    'w-full rounded-lg px-4 py-3 text-base border outline-none focus:ring-2 transition-shadow';
  const inputStyle = {
    border: '1.5px solid #d1d5db',
    background: 'var(--canvas)',
    color: 'var(--navy)',
  };

  return (
    <dialog
      ref={dialogRef}
      onClick={handleBackdropClick}
      className="rounded-2xl p-0 max-w-sm w-full shadow-2xl backdrop:bg-black/50 m-auto"
      style={{ background: 'var(--card)', color: 'var(--navy)' }}
    >
      <form onSubmit={handleSubmit} className="flex flex-col gap-5 p-7">
        <div className="flex items-center justify-between">
          <h2 className="text-xl font-semibold">Complete visit</h2>
          <button
            type="button"
            onClick={onClose}
            className="text-2xl leading-none opacity-40 hover:opacity-70 transition-opacity"
            aria-label="Close"
          >
            ×
          </button>
        </div>

        <p className="text-sm opacity-60">{clientName}</p>

        <div>
          <label className="block text-sm font-medium mb-1.5" htmlFor="cm-amount">
            Amount charged (KES)
          </label>
          <input
            id="cm-amount"
            type="number"
            min="0"
            step="1"
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
            placeholder="0"
            className={inputClass}
            style={inputStyle}
          />
        </div>

        <div>
          <label className="block text-sm font-medium mb-1.5" htmlFor="cm-method">
            Payment method
          </label>
          <select
            id="cm-method"
            value={paymentMethod}
            onChange={(e) => setPaymentMethod(e.target.value)}
            className={inputClass}
            style={inputStyle}
          >
            {PAYMENT_METHODS.map((m) => (
              <option key={m.value} value={m.value}>
                {m.label}
              </option>
            ))}
          </select>
        </div>

        {error && (
          <p className="text-sm font-medium" style={{ color: 'var(--late)' }}>
            {error}
          </p>
        )}

        <button
          type="submit"
          disabled={submitting}
          className="w-full py-4 rounded-xl text-base font-semibold transition-opacity hover:opacity-90 disabled:opacity-50"
          style={{ background: 'var(--brass)', color: '#fff' }}
        >
          {submitting ? 'Saving…' : 'Complete visit'}
        </button>
      </form>
    </dialog>
  );
}
```

- [ ] **Step 2: Type-check**

```bash
cd web && npx tsc --noEmit 2>&1 | head -40
```

Expected: no errors.

---

## Task 8: `ScheduleRow` component

**Files:**
- Create: `web/src/components/me/ScheduleRow.tsx`

- [ ] **Step 1: Create the file**

```typescript
// web/src/components/me/ScheduleRow.tsx
'use client';

import { useState } from 'react';
import type { ScheduleItem } from '@/lib/api/me';
import CompleteModal from './CompleteModal';

interface Props {
  item: ScheduleItem;
  onArrive: (id: string) => Promise<void>;
  onStart: (id: string) => Promise<void>;
  onComplete: () => void;
}

const STATUS_COLORS: Record<ScheduleItem['status'], string> = {
  booked: 'var(--amber, #f59e0b)',
  arrived: 'var(--in-chair, #3b82f6)',
  in_chair: 'var(--navy, #1e3a5f)',
  late: 'var(--late, #ef4444)',
};

const STATUS_LABELS: Record<ScheduleItem['status'], string> = {
  booked: 'Booked',
  arrived: 'Arrived',
  in_chair: 'In chair',
  late: 'Late',
};

function formatTime(iso: string): string {
  return new Intl.DateTimeFormat('en-KE', {
    timeZone: 'Africa/Nairobi',
    hour: '2-digit',
    minute: '2-digit',
    hour12: true,
  }).format(new Date(iso));
}

export default function ScheduleRow({ item, onArrive, onStart, onComplete }: Props) {
  const [busy, setBusy] = useState(false);
  const [showComplete, setShowComplete] = useState(false);

  async function handleAction() {
    setBusy(true);
    try {
      if (item.status === 'booked') await onArrive(item.bookingId);
      else if (item.status === 'arrived') await onStart(item.bookingId);
    } finally {
      setBusy(false);
    }
  }

  const actionLabel =
    item.status === 'booked'
      ? 'Mark arrived'
      : item.status === 'arrived'
      ? 'Start'
      : item.status === 'in_chair'
      ? 'Complete'
      : null;

  function handleActionClick() {
    if (item.status === 'in_chair') {
      setShowComplete(true);
    } else {
      handleAction();
    }
  }

  return (
    <>
      <div
        className="flex items-center justify-between gap-4 px-4 py-3 rounded-xl"
        style={{ background: 'var(--card)', border: '1.5px solid #e5e7eb' }}
      >
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2 mb-0.5">
            <span className="font-semibold text-sm" style={{ color: 'var(--navy)' }}>
              {item.clientName}
            </span>
            <span
              className="shrink-0 text-xs font-semibold px-2 py-0.5 rounded-full"
              style={{ background: STATUS_COLORS[item.status], color: '#fff' }}
            >
              {STATUS_LABELS[item.status]}
            </span>
          </div>
          <p className="text-xs opacity-60">
            {formatTime(item.scheduledStart)}
            {item.serviceName ? ` · ${item.serviceName}` : ''}
          </p>
        </div>

        {actionLabel && (
          <button
            type="button"
            onClick={handleActionClick}
            disabled={busy}
            className="shrink-0 px-4 py-2 rounded-lg text-sm font-semibold transition-opacity hover:opacity-90 disabled:opacity-50"
            style={{ background: 'var(--brass)', color: '#fff' }}
          >
            {busy ? '…' : actionLabel}
          </button>
        )}
      </div>

      {showComplete && (
        <CompleteModal
          bookingId={item.bookingId}
          clientName={item.clientName}
          onClose={() => setShowComplete(false)}
          onComplete={onComplete}
        />
      )}
    </>
  );
}
```

- [ ] **Step 2: Type-check**

```bash
cd web && npx tsc --noEmit 2>&1 | head -40
```

Expected: no errors.

---

## Task 9: `ScheduleList` component

**Files:**
- Create: `web/src/components/me/ScheduleList.tsx`

- [ ] **Step 1: Create the file**

```typescript
// web/src/components/me/ScheduleList.tsx
'use client';

import type { ScheduleItem } from '@/lib/api/me';
import ScheduleRow from './ScheduleRow';

interface Props {
  schedule: ScheduleItem[];
  onArrive: (id: string) => Promise<void>;
  onStart: (id: string) => Promise<void>;
  onComplete: () => void;
}

export default function ScheduleList({ schedule, onArrive, onStart, onComplete }: Props) {
  if (schedule.length === 0) {
    return (
      <p className="text-sm opacity-40 text-center py-6">
        No appointments scheduled for today.
      </p>
    );
  }

  return (
    <div className="flex flex-col gap-3">
      {schedule.map((item) => (
        <ScheduleRow
          key={item.bookingId}
          item={item}
          onArrive={onArrive}
          onStart={onStart}
          onComplete={onComplete}
        />
      ))}
    </div>
  );
}
```

- [ ] **Step 2: Type-check**

```bash
cd web && npx tsc --noEmit 2>&1 | head -40
```

Expected: no errors.

---

## Task 10: `NextClientCard` component

**Files:**
- Create: `web/src/components/me/NextClientCard.tsx`

- [ ] **Step 1: Create the file**

```typescript
// web/src/components/me/NextClientCard.tsx
'use client';

import type { NextClientItem } from '@/lib/api/me';

interface Props {
  next: NextClientItem | null;
}

const STATUS_LABELS: Record<NextClientItem['status'], string> = {
  booked: 'Booked',
  arrived: 'Arrived',
};

function formatTime(iso: string): string {
  return new Intl.DateTimeFormat('en-KE', {
    timeZone: 'Africa/Nairobi',
    hour: '2-digit',
    minute: '2-digit',
    hour12: true,
  }).format(new Date(iso));
}

export default function NextClientCard({ next }: Props) {
  if (!next) {
    return (
      <div
        className="rounded-2xl px-6 py-8 text-center"
        style={{ background: 'var(--free, #22c55e)', color: '#fff' }}
      >
        <p className="text-3xl font-bold mb-1">You&apos;re clear ✂</p>
        <p className="text-sm opacity-80">No upcoming appointments.</p>
      </div>
    );
  }

  return (
    <div
      className="rounded-2xl px-6 py-6"
      style={{ background: 'var(--card)', border: '2px solid var(--brass)' }}
    >
      <p className="text-xs font-semibold uppercase tracking-wide opacity-50 mb-3">
        Next client
      </p>
      <p className="text-2xl font-bold mb-1" style={{ color: 'var(--navy)' }}>
        {next.clientName}
      </p>
      <p className="text-sm opacity-60 mb-3">
        {formatTime(next.scheduledStart)}
        {next.serviceName ? ` · ${next.serviceName}` : ''}
      </p>
      <span
        className="inline-block text-xs font-semibold px-3 py-1 rounded-full"
        style={{
          background: next.status === 'arrived' ? 'var(--in-chair, #3b82f6)' : 'var(--amber, #f59e0b)',
          color: '#fff',
        }}
      >
        {STATUS_LABELS[next.status]}
      </span>
    </div>
  );
}
```

- [ ] **Step 2: Type-check**

```bash
cd web && npx tsc --noEmit 2>&1 | head -40
```

Expected: no errors.

---

## Task 11: `MyDayBoard` component

**Files:**
- Create: `web/src/components/me/MyDayBoard.tsx`

- [ ] **Step 1: Create the file**

```typescript
// web/src/components/me/MyDayBoard.tsx
'use client';

import { useEffect, useState } from 'react';
import type { MyDayData } from '@/lib/api/me';
import { fetchMyDay, arriveMyBooking, startMyBooking } from '@/lib/api/me';
import NextClientCard from './NextClientCard';
import ScheduleList from './ScheduleList';

const POLL_INTERVAL_MS = 10_000;

interface Props {
  staffId: string;
}

export default function MyDayBoard({ staffId: _staffId }: Props) {
  const [data, setData] = useState<MyDayData | null>(null);
  const [loading, setLoading] = useState(true);
  const [fetchError, setFetchError] = useState<string | null>(null);
  const [refreshTick, setRefreshTick] = useState(0);

  useEffect(() => {
    let cancelled = false;

    function poll() {
      fetchMyDay()
        .then((d) => {
          if (!cancelled) {
            setData(d);
            setFetchError(null);
            setLoading(false);
          }
        })
        .catch(() => {
          if (!cancelled) {
            setFetchError('Could not reach the server. Retrying…');
            setLoading(false);
          }
        });
    }

    poll();
    const id = setInterval(poll, POLL_INTERVAL_MS);
    return () => {
      cancelled = true;
      clearInterval(id);
    };
  }, [refreshTick]);

  function refresh() {
    setRefreshTick((t) => t + 1);
  }

  async function handleArrive(id: string) {
    await arriveMyBooking(id);
    refresh();
  }

  async function handleStart(id: string) {
    await startMyBooking(id);
    refresh();
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center py-24">
        <p className="text-sm opacity-40">Loading your day…</p>
      </div>
    );
  }

  if (fetchError && !data) {
    return (
      <div className="flex items-center justify-center py-24">
        <p className="text-sm" style={{ color: 'var(--late)' }}>
          {fetchError}
        </p>
      </div>
    );
  }

  return (
    <div className="flex flex-col gap-8">
      {/* Next client hero card */}
      <NextClientCard next={data?.nextClient ?? null} />

      {/* Queue waiting badge */}
      {(data?.queueWaitingCount ?? 0) > 0 && (
        <div
          className="rounded-xl px-4 py-3 flex items-center gap-2"
          style={{ background: 'var(--canvas)', border: '1.5px solid #e5e7eb' }}
        >
          <span
            className="text-sm font-semibold px-2.5 py-0.5 rounded-full"
            style={{ background: 'var(--brass)', color: '#fff' }}
          >
            {data!.queueWaitingCount}
          </span>
          <span className="text-sm opacity-60">
            {data!.queueWaitingCount === 1
              ? 'client waiting for you'
              : 'clients waiting for you'}
          </span>
        </div>
      )}

      {/* Full schedule */}
      <div>
        <h2 className="text-lg font-semibold mb-4" style={{ color: 'var(--navy)' }}>
          Today&apos;s schedule
        </h2>
        <ScheduleList
          schedule={data?.schedule ?? []}
          onArrive={handleArrive}
          onStart={handleStart}
          onComplete={refresh}
        />
      </div>

      {/* Stale data warning */}
      {fetchError && data && (
        <p className="text-xs text-center opacity-50" style={{ color: 'var(--late)' }}>
          {fetchError}
        </p>
      )}
    </div>
  );
}
```

- [ ] **Step 2: Type-check**

```bash
cd web && npx tsc --noEmit 2>&1 | head -40
```

Expected: no errors.

---

## Task 12: Update `me/page.tsx`

**Files:**
- Modify: `web/src/app/me/page.tsx`

- [ ] **Step 1: Replace the stub with the real page**

```typescript
// web/src/app/me/page.tsx
import { requireRole } from "@/lib/auth";
import { signOut } from "@/app/login/actions";
import MyDayBoard from "@/components/me/MyDayBoard";

export const metadata = { title: "My day — Fade & Sharp" };

export default async function MePage() {
  const staff = await requireRole("owner", "barber");

  return (
    <div className="min-h-screen bg-zinc-50 p-8">
      <div className="max-w-2xl mx-auto">
        <div className="flex items-center justify-between mb-8">
          <div>
            <h1 className="text-2xl font-semibold text-zinc-900">My day</h1>
            <p className="text-sm text-zinc-500 mt-1">
              Signed in as {staff.name} &middot; {staff.role}
            </p>
          </div>
          <form action={signOut}>
            <button
              type="submit"
              className="text-sm text-zinc-500 hover:text-zinc-900 underline underline-offset-2 transition-colors"
            >
              Sign out
            </button>
          </form>
        </div>
        <MyDayBoard staffId={staff.id} />
      </div>
    </div>
  );
}
```

- [ ] **Step 2: Type-check**

```bash
cd web && npx tsc --noEmit 2>&1 | head -40
```

Expected: no errors.

---

## Task 13: `docs/barber-view.md`

**Files:**
- Create: `docs/barber-view.md`

- [ ] **Step 1: Create the doc**

```markdown
# Barber "My Day" View

## What it shows

A barber (or owner previewing their own day) visits `/me` to see:

- **Next client card** — the next upcoming appointment (status `booked` or `arrived`), or a "You're clear" message.
- **Queue waiting badge** — how many walk-in queue clients are waiting specifically for this barber.
- **Today's schedule** — all appointments for today (statuses: `booked`, `arrived`, `in_chair`, `late`) sorted by scheduled time, each with an action button.

## Action buttons

| Status   | Button        | Effect                           |
| -------- | ------------- | -------------------------------- |
| booked   | Mark arrived  | Calls `POST /api/bookings/{id}/arrive` |
| arrived  | Start         | Calls `POST /api/bookings/{id}/seat`   |
| in_chair | Complete      | Opens payment modal → `POST /api/bookings/{id}/complete` |
| late     | —             | No action                        |

## API endpoint

`GET /api/me/day` — requires an authenticated session with role `barber` or `owner`. Returns `{ barberId, nextClient, schedule, queueWaitingCount }`.

## PII enforcement

The endpoint selects only `id, scheduled_start, status, clients(name), services(name)` — phone and email are never fetched server-side.

## Polling

`MyDayBoard` polls every 10 seconds. Future improvement: swap for Supabase Realtime.
```

---

## Task 14: Update `web/README.md` status table

**Files:**
- Modify: `web/README.md`

- [ ] **Step 1: Change the Barber "My day" row**

Find this exact line in the table:
```
| Barber "My day" view     | 🔲 Stub only                                                 |
```

Replace with:
```
| Barber "My day" view     | ✅ Done — `/me`, `/api/me/day`, `src/components/me/`         |
```

---

## Task 15: Final type-check and commit

- [ ] **Step 1: Full type-check**

```bash
cd web && npx tsc --noEmit
```

Expected: zero errors. Fix any before committing.

- [ ] **Step 2: Stage files**

```bash
git add \
  web/src/app/api/me/day/route.ts \
  "web/src/app/api/bookings/[id]/complete/route.ts" \
  "web/src/app/api/bookings/[id]/arrive/route.ts" \
  "web/src/app/api/bookings/[id]/seat/route.ts" \
  web/src/lib/api/me.ts \
  web/src/app/me/page.tsx \
  web/src/components/me/MyDayBoard.tsx \
  web/src/components/me/NextClientCard.tsx \
  web/src/components/me/ScheduleList.tsx \
  web/src/components/me/ScheduleRow.tsx \
  web/src/components/me/CompleteModal.tsx \
  docs/barber-view.md \
  web/README.md
```

- [ ] **Step 3: Commit**

```bash
git commit -m "FEAT: add barber My Day view with schedule, actions, and payment capture"
```
