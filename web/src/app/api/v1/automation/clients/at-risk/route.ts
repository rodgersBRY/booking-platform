import { assertAutomationKey } from "@/lib/auth/automation";
import { createAdminClient } from "@/lib/supabase/admin";
import { NextRequest, NextResponse } from "next/server";

export const dynamic = "force-dynamic";

export async function GET(request: NextRequest) {
  const authError = assertAutomationKey(request);
  if (authError) return authError;

  const admin = createAdminClient();
  const now = new Date();
  const nowIso = now.toISOString();
  const cutoff21 = new Date(now.getTime() - 21 * 86400000).toISOString();
  const cutoff30 = new Date(now.getTime() - 30 * 86400000).toISOString();

  // Clients where last_visit_at < 21 days ago (or null with created_at < 21 days ago)
  const { data: candidates, error } = await admin
    .from("clients")
    .select("id, name, phone, last_visit_at, created_at")
    .eq("status", "active")
    .or(`last_visit_at.lt.${cutoff21},and(last_visit_at.is.null,created_at.lt.${cutoff21})`);

  if (error) return NextResponse.json({ error: error.message }, { status: 500 });

  const rows = candidates ?? [];
  if (rows.length === 0) return NextResponse.json({ clients: [] });

  type ClientRow = {
    id: string;
    name: string;
    phone: string;
    last_visit_at: string | null;
    created_at: string;
  };

  const clientIds = (rows as ClientRow[]).map((r) => r.id);

  // Exclude clients with an upcoming booked appointment
  const { data: futureBookings } = await admin
    .from("bookings")
    .select("client_id")
    .in("client_id", clientIds)
    .eq("status", "booked")
    .gte("scheduled_start", nowIso);

  const hasUpcoming = new Set(
    (futureBookings ?? []).map((b: { client_id: string }) => b.client_id),
  );

  // Exclude clients who received a reengagement message in the last 30 days
  const { data: reengagementLogs } = await admin
    .from("message_log")
    .select("client_id")
    .eq("type", "reengagement")
    .in("client_id", clientIds)
    .gte("sent_at", cutoff30);

  const recentlyMessaged = new Set(
    (reengagementLogs ?? []).map((r: { client_id: string }) => r.client_id),
  );

  const atRisk = (rows as ClientRow[])
    .filter((r) => !hasUpcoming.has(r.id) && !recentlyMessaged.has(r.id))
    .map((r) => {
      const referenceDate = r.last_visit_at ?? r.created_at;
      const daysSinceVisit = Math.floor(
        (now.getTime() - new Date(referenceDate).getTime()) / 86400000,
      );
      return {
        clientId: r.id,
        name: r.name,
        phone: r.phone,
        lastVisitAt: r.last_visit_at,
        daysSinceVisit,
      };
    });

  return NextResponse.json({ clients: atRisk });
}
