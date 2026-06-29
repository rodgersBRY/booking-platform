import { getCurrentStaff } from "@/lib/auth";
import { createAdminClient } from "@/lib/supabase/admin";
import { NextResponse } from "next/server";

const TZ = "Africa/Nairobi";

function eatBounds(offsetDays = 0): { start: string; end: string } {
  const now = new Date();
  const target = new Date(now.getTime() + offsetDays * 86400000);
  const eatDate = new Intl.DateTimeFormat("en-CA", {
    timeZone: TZ,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).format(target);
  return {
    start: new Date(`${eatDate}T00:00:00+03:00`).toISOString(),
    end: new Date(`${eatDate}T23:59:59+03:00`).toISOString(),
  };
}

/** Return Monday–Sunday bounds for the current EAT week. */
function eatWeekBounds(): { start: string; end: string } {
  const now = new Date();
  const eatDate = new Intl.DateTimeFormat("en-CA", {
    timeZone: TZ,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).format(now);
  const todayEat = new Date(`${eatDate}T00:00:00+03:00`);
  // JS getDay(): 0=Sun, 1=Mon... shift so Mon=0
  const dow = (todayEat.getDay() + 6) % 7;
  const monday = new Date(todayEat.getTime() - dow * 86400000);
  const sunday = new Date(monday.getTime() + 6 * 86400000);
  const fmt = (d: Date) =>
    new Intl.DateTimeFormat("en-CA", {
      timeZone: TZ,
      year: "numeric",
      month: "2-digit",
      day: "2-digit",
    }).format(d);
  return {
    start: new Date(`${fmt(monday)}T00:00:00+03:00`).toISOString(),
    end: new Date(`${fmt(sunday)}T23:59:59+03:00`).toISOString(),
  };
}

/** Return 1st of current EAT month to end of today. */
function eatMonthBounds(): { start: string; end: string } {
  const now = new Date();
  const eatDate = new Intl.DateTimeFormat("en-CA", {
    timeZone: TZ,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).format(now);
  const [year, month] = eatDate.split("-");
  return {
    start: new Date(`${year}-${month}-01T00:00:00+03:00`).toISOString(),
    end: new Date(`${eatDate}T23:59:59+03:00`).toISOString(),
  };
}

function firstRel<T>(rel: unknown): T | null {
  if (rel == null) return null;
  if (Array.isArray(rel)) return (rel[0] as T) ?? null;
  return rel as T;
}

export async function GET() {
  const staff = await getCurrentStaff();
  if (!staff) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  if (staff.role !== "owner") return NextResponse.json({ error: "Forbidden" }, { status: 403 });

  const admin = createAdminClient();
  const now = new Date();
  const nowIso = now.toISOString();

  const { start: todayStart, end: todayEnd } = eatBounds(0);
  const { start: weekStart, end: weekEnd } = eatWeekBounds();
  const { start: monthStart, end: monthEnd } = eatMonthBounds();

  // ── 1. Visits for the month window (one query, bucket in JS) ───────────────
  type VisitRow = {
    id: string;
    barber_id: string | null;
    service_id: string | null;
    amount_charged: number | null;
    completed_at: string;
    clients: unknown;
    services: unknown;
  };

  const { data: monthVisits, error: visitsErr } = await admin
    .from("visits")
    .select(
      "id, barber_id, service_id, amount_charged, completed_at, clients(id, created_at), services(name)"
    )
    .gte("completed_at", monthStart)
    .lte("completed_at", monthEnd);

  if (visitsErr) return NextResponse.json({ error: visitsErr.message }, { status: 500 });

  const visits = (monthVisits ?? []) as VisitRow[];

  function inRange(iso: string, start: string, end: string) {
    return iso >= start && iso <= end;
  }

  function bucketNewVsReturning(start: string, end: string) {
    let newCount = 0;
    let returning = 0;
    for (const v of visits) {
      if (!inRange(v.completed_at, start, end)) continue;
      const client = firstRel<{ id: string; created_at: string }>(v.clients);
      if (!client) {
        returning++;
        continue;
      }
      if (client.created_at >= start) newCount++;
      else returning++;
    }
    return { new: newCount, returning };
  }

  function sumRevenue(start: string, end: string) {
    return visits
      .filter((v) => inRange(v.completed_at, start, end))
      .reduce((acc, v) => acc + (v.amount_charged ?? 0), 0);
  }

  const newVsReturning = {
    today: bucketNewVsReturning(todayStart, todayEnd),
    week: bucketNewVsReturning(weekStart, weekEnd),
    month: bucketNewVsReturning(monthStart, monthEnd),
  };

  const revenue = {
    today: sumRevenue(todayStart, todayEnd),
    week: sumRevenue(weekStart, weekEnd),
  };

  // ── 2. At-risk clients (2 queries) ─────────────────────────────────────────
  const cutoff = new Date(now.getTime() - 21 * 86400000).toISOString();

  const { data: atRiskRows } = await admin
    .from("clients")
    .select("id")
    .eq("status", "active")
    .lt("last_visit_at", cutoff);

  const atRiskIds = (atRiskRows ?? []).map((r: { id: string }) => r.id);
  let atRiskCount = atRiskIds.length;

  if (atRiskIds.length > 0) {
    const { data: futureBooked } = await admin
      .from("bookings")
      .select("client_id")
      .in("client_id", atRiskIds)
      .eq("status", "booked")
      .gte("scheduled_start", nowIso);

    const notAtRisk = new Set(
      (futureBooked ?? []).map((b: { client_id: string }) => b.client_id)
    );
    atRiskCount = atRiskIds.filter((id) => !notAtRisk.has(id)).length;
  }

  // ── 3. Active barbers for name lookup ──────────────────────────────────────
  const { data: barberRows } = await admin
    .from("staff")
    .select("id, name")
    .eq("role", "barber")
    .eq("status", "active");

  const barberMap = new Map<string, string>(
    (barberRows ?? []).map((b: { id: string; name: string }) => [b.id, b.name])
  );

  // ── 4. Per-barber week stats (from visits already fetched) ─────────────────
  const weekVisits = visits.filter((v) => inRange(v.completed_at, weekStart, weekEnd));

  const barberStats = new Map<string, { visits: number; revenue: number }>();
  for (const v of weekVisits) {
    if (!v.barber_id) continue;
    const cur = barberStats.get(v.barber_id) ?? { visits: 0, revenue: 0 };
    cur.visits++;
    cur.revenue += v.amount_charged ?? 0;
    barberStats.set(v.barber_id, cur);
  }

  const perBarber = Array.from(barberStats.entries()).map(([barberId, s]) => ({
    barberId,
    barberName: barberMap.get(barberId) ?? "Unknown",
    visits: s.visits,
    revenue: s.revenue,
  }));

  // ── 5. Top 3 services week ──────────────────────────────────────────────────
  const serviceMap = new Map<string, { name: string; count: number; revenue: number }>();
  for (const v of weekVisits) {
    if (!v.service_id) continue;
    const svc = firstRel<{ name: string }>(v.services);
    const existing = serviceMap.get(v.service_id) ?? {
      name: svc?.name ?? "Unknown",
      count: 0,
      revenue: 0,
    };
    existing.count++;
    existing.revenue += (v.amount_charged as number) ?? 0;
    serviceMap.set(v.service_id, existing);
  }

  const topServices = [...serviceMap.entries()]
    .sort((a, b) => b[1].count - a[1].count)
    .slice(0, 3)
    .map(([sid, val]) => ({ serviceId: sid, serviceName: val.name, count: val.count, revenue: val.revenue }));

  // ── 6. Channel mix week ─────────────────────────────────────────────────────
  const { data: weekBookingRows } = await admin
    .from("bookings")
    .select("channel")
    .gte("created_at", weekStart)
    .lte("created_at", weekEnd);

  const channelCounts = new Map<string, number>();
  for (const b of weekBookingRows ?? []) {
    const ch = (b as { channel: string | null }).channel ?? "unknown";
    channelCounts.set(ch, (channelCounts.get(ch) ?? 0) + 1);
  }
  const channelMix = Array.from(channelCounts.entries()).map(([channel, count]) => ({
    channel,
    count,
  }));

  // ── 7. No-show rate week (2 head queries) ──────────────────────────────────
  const { count: noShows } = await admin
    .from("bookings")
    .select("id", { count: "exact", head: true })
    .eq("status", "no_show")
    .gte("scheduled_start", weekStart)
    .lte("scheduled_start", weekEnd);

  const { count: terminalBookings } = await admin
    .from("bookings")
    .select("id", { count: "exact", head: true })
    .in("status", ["no_show", "completed", "cancelled"])
    .gte("scheduled_start", weekStart)
    .lte("scheduled_start", weekEnd);

  const noShowRate =
    terminalBookings && terminalBookings > 0 ? (noShows ?? 0) / terminalBookings : 0;

  return NextResponse.json({
    kpis: {
      newVsReturning,
      revenue,
      atRiskClients: atRiskCount,
    },
    week: {
      perBarber,
      topServices,
      channelMix,
      noShowRate,
    },
  });
}
