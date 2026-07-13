import { assertAutomationKey } from "@/lib/auth/automation";
import { createAdminClient } from "@/lib/supabase/admin";
import { NextRequest, NextResponse } from "next/server";

export const dynamic = "force-dynamic";

export async function POST(request: NextRequest) {
  const authError = assertAutomationKey(request);
  if (authError) return authError;

  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON body" }, { status: 400 });
  }

  const {
    clientId,
    staffId,
    type,
    bookingId,
    channel = "whatsapp",
    status = "sent",
  } = body as {
    clientId?: string;
    staffId?: string;
    type?: string;
    bookingId?: string;
    channel?: string;
    status?: string;
  };

  if (!type) {
    return NextResponse.json({ error: "type is required" }, { status: 400 });
  }

  if (!clientId && !staffId) {
    return NextResponse.json(
      { error: "At least one of clientId or staffId is required" },
      { status: 400 },
    );
  }

  const validTypes = [
    "reminder_24h",
    "reminder_2h",
    "review_request",
    "reengagement",
    "queue_notify",
    "owner_alert",
  ];
  if (!validTypes.includes(type)) {
    return NextResponse.json(
      { error: `type must be one of: ${validTypes.join(", ")}` },
      { status: 400 },
    );
  }

  const admin = createAdminClient();

  const { data, error } = await admin
    .from("message_log")
    .insert({
      client_id: clientId ?? null,
      staff_id: staffId ?? null,
      type,
      booking_id: bookingId ?? null,
      channel,
      status,
    })
    .select("id, type, client_id, booking_id, sent_at")
    .single();

  if (error) return NextResponse.json({ error: error.message }, { status: 500 });

  type Row = {
    id: string;
    type: string;
    client_id: string | null;
    booking_id: string | null;
    sent_at: string;
  };
  const row = data as Row;

  return NextResponse.json(
    {
      id: row.id,
      type: row.type,
      clientId: row.client_id,
      bookingId: row.booking_id,
      sentAt: row.sent_at,
    },
    { status: 201 },
  );
}
