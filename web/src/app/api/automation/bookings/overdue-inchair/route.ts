import { assertAutomationKey } from "@/lib/auth/automation";
import { createAdminClient } from "@/lib/supabase/admin";
import { NextRequest, NextResponse } from "next/server";

export const dynamic = "force-dynamic";

function firstRel<T>(rel: unknown): T | null {
  if (rel == null) return null;
  if (Array.isArray(rel)) return (rel[0] as T) ?? null;
  return rel as T;
}

export async function GET(request: NextRequest) {
  const authError = assertAutomationKey(request);
  if (authError) return authError;

  const admin = createAdminClient();
  const now = new Date();

  const { data, error } = await admin
    .from("bookings")
    .select("id, scheduled_end, clients(name), services(name), staff!barber_id(name, phone)")
    .eq("status", "in_chair")
    .lt("scheduled_end", now.toISOString())
    .not("barber_id", "is", null);

  if (error) return NextResponse.json({ error: error.message }, { status: 500 });

  type Row = { id: unknown; scheduled_end: unknown; clients: unknown; services: unknown; staff: unknown };
  const bookings = (data ?? [])
    .map((raw: unknown) => {
      const b = raw as Row;
      const client = firstRel<{ name: string }>(b.clients);
      const service = firstRel<{ name: string }>(b.services);
      const barber = firstRel<{ name: string; phone: string | null }>(b.staff);
      if (!barber?.phone) return null;
      const scheduledEnd = b.scheduled_end as string;
      const minutesOverdue = Math.round((now.getTime() - new Date(scheduledEnd).getTime()) / 60000);
      return {
        bookingId: b.id as string,
        scheduledEnd,
        minutesOverdue,
        clientName: client?.name ?? "Unknown",
        serviceName: service?.name ?? null,
        barberName: barber.name,
        barberPhone: barber.phone,
      };
    })
    .filter(Boolean);

  return NextResponse.json({ bookings });
}
