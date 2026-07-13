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

  const phone = new URL(request.url).searchParams.get("phone");
  if (!phone) {
    return NextResponse.json({ error: "phone query param is required" }, { status: 400 });
  }

  const admin = createAdminClient();

  const { data: client, error: clientError } = await admin
    .from("clients")
    .select("id")
    .eq("phone", phone)
    .maybeSingle();

  if (clientError) return NextResponse.json({ error: clientError.message }, { status: 500 });
  if (!client) return NextResponse.json({ found: false });

  type ClientRow = { id: string };
  const clientId = (client as ClientRow).id;

  const { data, error } = await admin
    .from("bookings")
    .select("id, scheduled_start, services(name)")
    .eq("client_id", clientId)
    .eq("status", "booked")
    .gte("scheduled_start", new Date().toISOString())
    .order("scheduled_start", { ascending: true })
    .limit(1)
    .maybeSingle();

  if (error) return NextResponse.json({ error: error.message }, { status: 500 });
  if (!data) return NextResponse.json({ found: false });

  type Row = { id: string; scheduled_start: string; services: unknown };
  const row = data as Row;
  const service = firstRel<{ name: string }>(row.services);

  return NextResponse.json({
    found: true,
    booking: {
      bookingId: row.id,
      scheduledStart: row.scheduled_start,
      serviceName: service?.name ?? null,
    },
  });
}
