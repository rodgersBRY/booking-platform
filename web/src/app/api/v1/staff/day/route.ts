import { getStaffFromRequest } from "@/lib/staffAuth";
import { isBookableRole } from "@/lib/staff/roles";
import { createAdminClient } from "@/lib/supabase/admin";
import type { BookingChannel, BookingStatus } from "@/lib/db/types";
import { NextRequest, NextResponse } from "next/server";

// Token-based port of /api/me/day (cookie-based, web console) for the mobile
// barber app. Same EAT day-boundary technique and the same PII-safe select
// discipline (client NAME only — no phone, no email). The two routes are
// intentionally not shared: lib/auth.ts (cookie) and lib/staffAuth.ts (Bearer
// token) are kept separate per the comment in staffAuth.ts.

const TZ = "Africa/Nairobi";

// Statuses that count toward today's schedule / summary. "completed" is
// included because the summary counts it and the timeline still shows it.
const SCHEDULE_STATUSES: BookingStatus[] = [
  "booked",
  "arrived",
  "in_chair",
  "late",
  "completed",
];

type ScheduleStatus = (typeof SCHEDULE_STATUSES)[number];

function eatTodayInfo(): { start: string; end: string; dateStr: string; weekday: number } {
  const now = new Date();
  const eatDate = new Intl.DateTimeFormat("en-CA", {
    timeZone: TZ,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).format(now);
  const start = new Date(`${eatDate}T00:00:00+03:00`).toISOString();
  const end = new Date(`${eatDate}T23:59:59+03:00`).toISOString();
  // Parsed as UTC midnight purely to read off the calendar weekday for
  // eatDate — never used as a timestamp, so the runtime's own timezone can't
  // skew it. staff_availability.weekday matches this convention: 0 = Sunday.
  const weekday = new Date(`${eatDate}T00:00:00Z`).getUTCDay();
  return { start, end, dateStr: eatDate, weekday };
}

function firstRel<T>(rel: unknown): T | null {
  if (rel == null) return null;
  if (Array.isArray(rel)) return (rel[0] as T) ?? null;
  return rel as T;
}

function hhmm(time: string): string {
  // Postgres `time` comes back as "HH:MM:SS" (or with fractional seconds).
  return time.slice(0, 5);
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

  const admin = createAdminClient();
  const { start: todayStart, end: todayEnd, weekday } = eatTodayInfo();

  // Today's bookings for this staff member — PII-safe select (client name
  // only, no phone/email). booking_services carries the full multi-service
  // list; bookings.service_id/services(name) is the fallback primary service.
  const { data: bookingRows, error: bookErr } = await admin
    .from("bookings")
    .select(
      "id, scheduled_start, scheduled_end, status, channel, clients(name), services(name), booking_services(services(name))",
    )
    .eq("staff_id", staff.id)
    .in("status", SCHEDULE_STATUSES)
    .gte("scheduled_start", todayStart)
    .lte("scheduled_start", todayEnd)
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

  const nextAppointment =
    schedule.find((s) => s.status === "booked" || s.status === "arrived") ??
    null;

  const completed = schedule.filter((s) => s.status === "completed").length;
  const total = schedule.length;

  // Today's working hours from staff_availability (the recurring weekly
  // schedule) — unrelated to `presence`, which is live status.
  const { data: availabilityRow, error: availErr } = await admin
    .from("staff_availability")
    .select("start_time, end_time")
    .eq("staff_id", staff.id)
    .eq("weekday", weekday)
    .maybeSingle();

  if (availErr) {
    return NextResponse.json(
      { error: "Something went wrong. Please try again." },
      { status: 500 },
    );
  }

  const workingHours = availabilityRow
    ? {
        start: hhmm(availabilityRow.start_time as string),
        end: hhmm(availabilityRow.end_time as string),
      }
    : null;

  return NextResponse.json({
    staffId: staff.id,
    presence: staff.presence,
    presenceUpdatedAt: staff.presence_updated_at,
    workingHours,
    summary: { total, completed, remaining: total - completed },
    nextAppointment,
    schedule,
  });
}
