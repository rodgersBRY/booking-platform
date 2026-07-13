import { assertAutomationKey } from "@/lib/auth/automation";
import { createAdminClient } from "@/lib/supabase/admin";
import { NextRequest, NextResponse } from "next/server";

export const dynamic = "force-dynamic";

const TZ = "Africa/Nairobi";

function eatTodayBounds(): { start: string; end: string } {
  const now = new Date();
  const eatDate = new Intl.DateTimeFormat("en-CA", {
    timeZone: TZ,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).format(now);
  return {
    start: new Date(`${eatDate}T00:00:00+03:00`).toISOString(),
    end: new Date(`${eatDate}T23:59:59+03:00`).toISOString(),
  };
}

export async function GET(request: NextRequest) {
  const authError = assertAutomationKey(request);
  if (authError) return authError;

  const period = (new URL(request.url).searchParams.get("period") ?? "daily") as "daily" | "weekly";

  const admin = createAdminClient();
  const now = new Date();
  const nowIso = now.toISOString();
  const { start: todayStart, end: todayEnd } = eatTodayBounds();

  // Visits today: count + revenue
  const { data: visitRows } = await admin
    .from("visits")
    .select("amount_charged")
    .gte("completed_at", todayStart)
    .lte("completed_at", todayEnd);

  const servedToday = (visitRows ?? []).length;
  const revenueToday = (visitRows ?? []).reduce(
    (sum: number, v: { amount_charged: number | null }) => sum + (v.amount_charged ?? 0),
    0,
  );

  // No-shows today
  const { count: noShowsToday } = await admin
    .from("bookings")
    .select("id", { count: "exact", head: true })
    .eq("status", "no_show")
    .gte("scheduled_start", todayStart)
    .lte("scheduled_start", todayEnd);

  // New clients today
  const { count: newClientsToday } = await admin
    .from("clients")
    .select("id", { count: "exact", head: true })
    .gte("created_at", todayStart)
    .lte("created_at", todayEnd);

  // At-risk clients: last_visit_at > 21 days ago, no upcoming booking
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
      (futureBooked ?? []).map((b: { client_id: string }) => b.client_id),
    );
    atRiskCount = atRiskIds.filter((id) => !notAtRisk.has(id)).length;
  }

  // Owner phone
  const { data: owner } = await admin
    .from("staff")
    .select("phone")
    .eq("role", "owner")
    .eq("status", "active")
    .single();

  return NextResponse.json({
    period,
    servedToday,
    revenueToday,
    noShowsToday: noShowsToday ?? 0,
    newClientsToday: newClientsToday ?? 0,
    atRiskCount,
    appLink: "/dashboard",
    ownerPhone: (owner as { phone: string | null } | null)?.phone ?? null,
  });
}
