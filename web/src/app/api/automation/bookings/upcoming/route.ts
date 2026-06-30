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
  const now = new Date().toISOString();
  const in24h = new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString();

  const { data, error } = await admin
    .from("bookings")
    .select("id, scheduled_start, client_id, clients(name, phone), services(name), staff!barber_id(name, phone)")
    .in("status", ["booked", "arrived"])
    .gte("scheduled_start", now)
    .lte("scheduled_start", in24h)
    .not("barber_id", "is", null);

  if (error) return NextResponse.json({ error: error.message }, { status: 500 });

  const appLink = `${process.env.NEXT_PUBLIC_APP_URL ?? ""}/me`;

  type Row = { id: unknown; scheduled_start: unknown; client_id: unknown; clients: unknown; services: unknown; staff: unknown };
  const bookings = (data ?? [])
    .map((raw: unknown) => {
      const b = raw as Row;
      const client = firstRel<{ name: string; phone: string | null }>(b.clients);
      const service = firstRel<{ name: string }>(b.services);
      const barber = firstRel<{ name: string; phone: string | null }>(b.staff);
      if (!barber?.phone) return null;
      return {
        bookingId: b.id as string,
        clientId: b.client_id as string,
        scheduledStart: b.scheduled_start as string,
        clientName: client?.name ?? "Unknown",
        clientPhone: client?.phone ?? null,
        serviceName: service?.name ?? null,
        barberName: barber.name,
        barberPhone: barber.phone,
        appLink,
      };
    })
    .filter(Boolean);

  return NextResponse.json({ bookings });
}
