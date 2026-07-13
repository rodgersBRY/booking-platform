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
  const since = new Date(Date.now() - 5 * 60 * 1000).toISOString();
  const appLink = `${process.env.NEXT_PUBLIC_APP_URL ?? ""}/me`;

  const { data, error } = await admin
    .from("bookings")
    .select("id, scheduled_start, channel, clients(name), services(name), staff!staff_id(name, phone)")
    .eq("status", "booked")
    .gte("created_at", since)
    .not("staff_id", "is", null);

  if (error) return NextResponse.json({ error: error.message }, { status: 500 });

  type Row = { id: unknown; scheduled_start: unknown; channel: unknown; clients: unknown; services: unknown; staff: unknown };
  const bookings = (data ?? [])
    .map((raw: unknown) => {
      const b = raw as Row;
      const client = firstRel<{ name: string }>(b.clients);
      const service = firstRel<{ name: string }>(b.services);
      const barber = firstRel<{ name: string; phone: string | null }>(b.staff);
      if (!barber?.phone) return null;
      return {
        bookingId: b.id as string,
        scheduledStart: b.scheduled_start as string,
        channel: (b.channel as string) ?? "unknown",
        clientName: client?.name ?? "Unknown",
        serviceName: service?.name ?? null,
        staffName: barber.name,
        staffPhone: barber.phone,
        appLink,
      };
    })
    .filter(Boolean);

  return NextResponse.json({ bookings });
}
