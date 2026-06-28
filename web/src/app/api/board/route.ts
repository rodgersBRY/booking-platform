import { getCurrentStaff } from "@/lib/auth";
import { createAdminClient } from "@/lib/supabase/admin";
import { NextResponse } from "next/server";
import type { ChairStatus, QueueItem, BoardStats } from "@/lib/booking/types";

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

export async function GET() {
  const staff = await getCurrentStaff();
  if (!staff) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const admin = createAdminClient();
  const now = new Date();
  const nowIso = now.toISOString();
  const { start: todayStart, end: todayEnd } = eatTodayBounds();

  // ── Active barbers ────────────────────────────────────────────────────────
  const { data: barbers, error: barberErr } = await admin
    .from("staff")
    .select("id, name")
    .eq("role", "barber")
    .eq("status", "active")
    .order("name");

  if (barberErr) {
    return NextResponse.json({ error: barberErr.message }, { status: 500 });
  }

  // ── In-chair bookings covering now ───────────────────────────────────────
  const { data: inChairBookings } = await admin
    .from("bookings")
    .select(
      "id, barber_id, scheduled_end, clients(name), services(name)",
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
      minutesLeft: number;
    }
  >();

  for (const b of inChairBookings ?? []) {
    const endMs = new Date(b.scheduled_end as string).getTime();
    const minutesLeft = Math.max(0, Math.round((endMs - now.getTime()) / 60000));
    // Supabase returns joined relations as arrays; pick the first element.
    const clientRel = b.clients as unknown as { name: string }[] | null;
    const serviceRel = b.services as unknown as { name: string }[] | null;
    inChairByBarber.set(b.barber_id as string, {
      bookingId: b.id as string,
      clientName: Array.isArray(clientRel) ? (clientRel[0]?.name ?? "Unknown") : "Unknown",
      serviceName: Array.isArray(serviceRel) ? (serviceRel[0]?.name ?? "Unknown") : "Unknown",
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
      "id, client_id, barber_id, joined_at, choice, status, clients(name), staff(name)",
    )
    .in("status", ["waiting", "notified"])
    .order("joined_at");

  if (queueErr) {
    return NextResponse.json({ error: queueErr.message }, { status: 500 });
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
    const clientRel = q.clients as { name: string }[] | null;
    const staffRel = q.staff as { name: string }[] | null;
    const clientName = Array.isArray(clientRel) ? (clientRel[0]?.name ?? "Unknown") : "Unknown";
    const preferredBarberName = Array.isArray(staffRel) ? (staffRel[0]?.name ?? null) : null;
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

  return NextResponse.json({ chairs, queue, stats });
}
