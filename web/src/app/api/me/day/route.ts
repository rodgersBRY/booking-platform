import { getCurrentStaff } from "@/lib/auth";
import { isBookableRole } from "@/lib/staff/roles";
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
  
  if (staff.role !== "owner" && !isBookableRole(staff.role)) {
    return NextResponse.json({ error: "Forbidden" }, { status: 403 });
  }

  const admin = createAdminClient();
  const { start: todayStart, end: todayEnd } = eatTodayBounds();

  // Bookings for this barber today — PII-safe select (name only, no phone/email).
  const { data: bookingRows, error: bookErr } = await admin
    .from("bookings")
    .select("id, scheduled_start, status, clients(name), services(name)")
    .eq("staff_id", staff.id)
    .in("status", ["booked", "arrived", "in_chair", "late"])
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
    .eq("staff_id", staff.id)
    .eq("status", "waiting");

  return NextResponse.json({
    staffId: staff.id,
    nextClient,
    schedule,
    queueWaitingCount: queueWaitingCount ?? 0,
  });
}
