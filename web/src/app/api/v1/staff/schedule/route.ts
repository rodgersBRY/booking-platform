import { getStaffFromRequest } from "@/lib/staffAuth";
import { isBookableRole } from "@/lib/staff/roles";
import { createAdminClient } from "@/lib/supabase/admin";
import type { BookingChannel, BookingStatus } from "@/lib/db/types";
import { NextRequest, NextResponse } from "next/server";

// Token-based multi-day sibling of /v1/staff/day for the mobile barber app's
// Schedule tab (Today / Tomorrow / Week). Same EAT day-boundary technique,
// generalized here for an arbitrary day offset / span instead of copying the
// single-day math a third time (board's /api/board and /v1/staff/day each
// already have their own today-only copy). Same PII-safe select discipline
// (client NAME only — no phone, no email) and the same appointment-entry
// shape as /v1/staff/day's "schedule" key, so the mobile side can reuse one
// model for both.

const TZ = "Africa/Nairobi";

const SCHEDULE_STATUSES: BookingStatus[] = [
  "booked",
  "arrived",
  "in_chair",
  "late",
  "completed",
];

type ScheduleStatus = (typeof SCHEDULE_STATUSES)[number];

type ScheduleRange = "today" | "tomorrow" | "week";

function isScheduleRange(value: string): value is ScheduleRange {
  return value === "today" || value === "tomorrow" || value === "week";
}

/** EAT calendar date (YYYY-MM-DD) for `now` shifted by `dayOffset` days. */
function eatDateString(now: Date, dayOffset: number): string {
  const shifted = new Date(now.getTime() + dayOffset * 24 * 60 * 60 * 1000);
  return new Intl.DateTimeFormat("en-CA", {
    timeZone: TZ,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).format(shifted);
}

/** UTC ISO start/end covering the given EAT calendar date. */
function eatDayBounds(dateStr: string): { start: string; end: string } {
  return {
    start: new Date(`${dateStr}T00:00:00+03:00`).toISOString(),
    end: new Date(`${dateStr}T23:59:59+03:00`).toISOString(),
  };
}

/** UTC ISO start/end for a `range` starting today (EAT). */
function boundsForRange(range: ScheduleRange, now: Date): { start: string; end: string } {
  if (range === "today") {
    return eatDayBounds(eatDateString(now, 0));
  }
  if (range === "tomorrow") {
    return eatDayBounds(eatDateString(now, 1));
  }
  // week: the next 7 days inclusive, starting today.
  return {
    start: eatDayBounds(eatDateString(now, 0)).start,
    end: eatDayBounds(eatDateString(now, 6)).end,
  };
}

function firstRel<T>(rel: unknown): T | null {
  if (rel == null) return null;
  if (Array.isArray(rel)) return (rel[0] as T) ?? null;
  return rel as T;
}

type AppointmentEntry = {
  bookingId: string;
  clientName: string;
  services: string[];
  scheduledStart: string;
  scheduledEnd: string;
  durationMinutes: number;
  status: ScheduleStatus;
  channel: BookingChannel;
};

export async function GET(request: NextRequest) {
  const staff = await getStaffFromRequest(request);
  if (!staff) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  if (!isBookableRole(staff.role)) {
    return NextResponse.json(
      {
        error: "not_bookable_role",
        message: "This account doesn't have access to the barber app.",
      },
      { status: 403 },
    );
  }

  const rangeParam = request.nextUrl.searchParams.get("range") ?? "today";
  if (!isScheduleRange(rangeParam)) {
    return NextResponse.json(
      {
        error: "invalid_range",
        message: "range must be one of: today, tomorrow, week.",
      },
      { status: 400 },
    );
  }
  const range = rangeParam;

  const admin = createAdminClient();
  const { start, end } = boundsForRange(range, new Date());

  // Bookings for this staff member across the requested range — PII-safe
  // select (client name only, no phone/email), same join pattern as
  // /v1/staff/day: booking_services carries the full multi-service list,
  // bookings.service_id/services(name) is the fallback primary service.
  const { data: bookingRows, error: bookErr } = await admin
    .from("bookings")
    .select(
      "id, scheduled_start, scheduled_end, status, channel, clients(name), services(name), booking_services(services(name))",
    )
    .eq("staff_id", staff.id)
    .in("status", SCHEDULE_STATUSES)
    .gte("scheduled_start", start)
    .lte("scheduled_start", end)
    .order("scheduled_start");

  if (bookErr) {
    return NextResponse.json(
      { error: "Something went wrong. Please try again." },
      { status: 500 },
    );
  }

  type BookingRow = {
    id: unknown;
    scheduled_start: unknown;
    scheduled_end: unknown;
    status: unknown;
    channel: unknown;
    clients: unknown;
    services: unknown;
    booking_services: unknown;
  };

  const schedule: AppointmentEntry[] = (bookingRows ?? []).map(
    (raw: unknown) => {
      const b = raw as BookingRow;
      const client = firstRel<{ name: string }>(b.clients);
      const primaryService = firstRel<{ name: string }>(b.services);

      const joinedServices = Array.isArray(b.booking_services)
        ? (b.booking_services as unknown[])
            .map((bs) => firstRel<{ name: string }>((bs as { services: unknown }).services))
            .filter((s): s is { name: string } => s != null)
            .map((s) => s.name)
        : [];

      const services =
        joinedServices.length > 0
          ? joinedServices
          : primaryService
            ? [primaryService.name]
            : [];

      const scheduledStart = b.scheduled_start as string;
      const scheduledEnd = b.scheduled_end as string;
      const durationMinutes = Math.round(
        (new Date(scheduledEnd).getTime() - new Date(scheduledStart).getTime()) /
          60000,
      );

      return {
        bookingId: b.id as string,
        clientName: client?.name ?? "Unknown",
        services,
        scheduledStart,
        scheduledEnd,
        durationMinutes,
        status: b.status as ScheduleStatus,
        channel: b.channel as BookingChannel,
      };
    },
  );

  return NextResponse.json({ range, schedule });
}
