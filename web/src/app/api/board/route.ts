import { getCurrentStaff } from "@/lib/auth";
import { BOOKABLE_ROLES } from "@/lib/staff/roles";
import { createAdminClient } from "@/lib/supabase/admin";
import { NextResponse } from "next/server";
import type { ChairStatus, QueueItem, BoardStats, Appointment } from "@/lib/booking/types";

const TZ = "Africa/Nairobi";

/** Return the start/end of today (EAT) as UTC ISO strings for Postgres queries. */
function eatTodayBounds(): { start: string; end: string } {
  const now = new Date();
  // Get today's date string in EAT.
  const eatDate = new Intl.DateTimeFormat("en-CA", {
    timeZone: TZ,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).format(now);
  // Build midnight EAT = UTC-3h.
  const startUtc = new Date(`${eatDate}T00:00:00+03:00`);
  const endUtc = new Date(`${eatDate}T23:59:59+03:00`);
  return { start: startUtc.toISOString(), end: endUtc.toISOString() };
}

/**
 * PostgREST embeds a to-one relation as a single object (and a to-many as an array).
 * Normalize either shape to the first row so name lookups don't fall through to "Unknown".
 */
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

  const admin = createAdminClient();
  const now = new Date();
  const nowIso = now.toISOString();
  const { start: todayStart, end: todayEnd } = eatTodayBounds();

  // ── Active bookable staff (barbers, beauticians, masseuses) ────────────────
  const { data: barbers, error: barberErr } = await admin
    .from("staff")
    .select("id, name")
    .in("role", BOOKABLE_ROLES)
    .eq("status", "active")
    .order("name");

  if (barberErr) {
    return NextResponse.json(
      { error: "Something went wrong. Please try again." },
      { status: 500 },
    );
  }

  // ── In-chair bookings covering now ───────────────────────────────────────
  const { data: inChairBookings } = await admin
    .from("bookings")
    .select(
      "id, barber_id, scheduled_end, clients(name), services(name, price)",
    )
    .eq("status", "in_chair")
    .lte("scheduled_start", nowIso)
    .gte("scheduled_end", nowIso);

  // Index by barber_id for O(1) lookup.
  const inChairByBarber = new Map<
    string,
    {
      bookingId: string;
      clientName: string;
      serviceName: string;
      servicePrice: number | null;
      minutesLeft: number;
    }
  >();

  for (const b of inChairBookings ?? []) {
    const endMs = new Date(b.scheduled_end as string).getTime();
    const minutesLeft = Math.max(0, Math.round((endMs - now.getTime()) / 60000));
    const client = firstRel<{ name: string }>(b.clients);
    const service = firstRel<{ name: string; price: number }>(b.services);
    inChairByBarber.set(b.barber_id as string, {
      bookingId: b.id as string,
      clientName: client?.name ?? "Unknown",
      serviceName: service?.name ?? "Unknown",
      servicePrice: service?.price ?? null,
      minutesLeft,
    });
  }

  // ── Build chair statuses ──────────────────────────────────────────────────
  const chairs: ChairStatus[] = (barbers ?? []).map(
    (barber: { id: string; name: string }) => {
      const active = inChairByBarber.get(barber.id);
      if (active) {
        return {
          barberId: barber.id,
          barberName: barber.name,
          status: "in_chair",
          bookingId: active.bookingId,
          currentClientName: active.clientName,
          serviceName: active.serviceName,
          servicePrice: active.servicePrice,
          minutesLeft: active.minutesLeft,
        };
      }
      return { barberId: barber.id, barberName: barber.name, status: "free" };
    },
  );

  // ── Queue entries ─────────────────────────────────────────────────────────
  const { data: queueRows, error: queueErr } = await admin
    .from("queue_entries")
    .select(
      "id, client_id, barber_id, joined_at, choice, status, clients(name, total_visits), staff(name)",
    )
    .in("status", ["waiting", "notified"])
    .order("joined_at");

  if (queueErr) {
    return NextResponse.json(
      { error: "Something went wrong. Please try again." },
      { status: 500 },
    );
  }

  // For estimated wait: gather in_chair remaining minutes per barber.
  // Supabase returns joined relations as arrays; use unknown cast.
  type QueueRow = {
    id: unknown;
    client_id: unknown;
    barber_id: unknown;
    joined_at: unknown;
    choice: unknown;
    status: unknown;
    clients: unknown;
    staff: unknown;
  };
  const queue: QueueItem[] = (queueRows ?? []).map((qRaw: unknown) => {
    const q = qRaw as QueueRow;
    const client = firstRel<{ name: string; total_visits: number }>(q.clients);
    const staffRel = firstRel<{ name: string }>(q.staff);
    const clientName = client?.name ?? "Unknown";
    const totalVisits = client?.total_visits ?? 0;
    const preferredBarberName = staffRel?.name ?? null;
    const barberId = q.barber_id as string | null;
    const waitedMinutes = Math.round(
      (now.getTime() - new Date(q.joined_at as string).getTime()) / 60000,
    );
    // Estimated wait: remaining time for the preferred barber's current client.
    let estimatedWaitMinutes: number | null = null;
    if (barberId) {
      const current = inChairByBarber.get(barberId);
      estimatedWaitMinutes = current ? current.minutesLeft : 0;
    }
    return {
      id: q.id as string,
      clientName,
      preferredBarberId: barberId,
      preferredBarberName,
      choice: q.choice as string,
      status: q.status as string,
      waitedMinutes,
      estimatedWaitMinutes,
      isRegular: totalVisits >= 5,
    };
  });

  // ── Stats ─────────────────────────────────────────────────────────────────
  const { count: waiting } = await admin
    .from("queue_entries")
    .select("id", { count: "exact", head: true })
    .in("status", ["waiting", "notified"]);

  const { count: servedToday } = await admin
    .from("visits")
    .select("id", { count: "exact", head: true })
    .gte("completed_at", todayStart)
    .lte("completed_at", todayEnd);

  const { count: noShows } = await admin
    .from("bookings")
    .select("id", { count: "exact", head: true })
    .eq("status", "no_show")
    .gte("scheduled_start", todayStart)
    .lte("scheduled_start", todayEnd);

  const stats: BoardStats = {
    waiting: waiting ?? 0,
    servedToday: servedToday ?? 0,
    noShows: noShows ?? 0,
  };

  // ── Today's scheduled appointments (booked or arrived) ───────────────────
  const { data: apptRows, error: apptErr } = await admin
    .from("bookings")
    .select(
      "id, barber_id, service_id, scheduled_start, status, channel, clients(name, total_visits), staff!barber_id(name), services(name)",
    )
    .in("status", ["booked", "arrived"])
    .gte("scheduled_start", todayStart)
    .lte("scheduled_start", todayEnd)
    .order("scheduled_start");

  if (apptErr) {
    return NextResponse.json(
      { error: "Something went wrong. Please try again." },
      { status: 500 },
    );
  }

  type ApptRow = {
    id: unknown;
    barber_id: unknown;
    service_id: unknown;
    scheduled_start: unknown;
    status: unknown;
    channel: unknown;
    clients: unknown;
    staff: unknown;
    services: unknown;
  };

  const appointments: Appointment[] = (apptRows ?? []).map((aRaw: unknown) => {
    const a = aRaw as ApptRow;
    const client = firstRel<{ name: string; total_visits: number }>(a.clients);
    const barber = firstRel<{ name: string }>(a.staff);
    const service = firstRel<{ name: string }>(a.services);
    return {
      id: a.id as string,
      clientName: client?.name ?? "Unknown",
      barberId: (a.barber_id as string | null) ?? null,
      barberName: barber?.name ?? null,
      serviceName: service?.name ?? null,
      serviceId: (a.service_id as string | null) ?? null,
      scheduledStart: a.scheduled_start as string,
      status: a.status as "booked" | "arrived",
      channel: (a.channel as string) ?? "unknown",
      isRegular: (client?.total_visits ?? 0) >= 5,
    };
  });

  return NextResponse.json({ chairs, queue, appointments, stats });
}
