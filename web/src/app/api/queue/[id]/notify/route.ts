import { getCurrentStaff } from "@/lib/auth";
import { createAdminClient } from "@/lib/supabase/admin";
import { NextRequest, NextResponse } from "next/server";

// TODO: AUTOMATION_API_KEY auth — n8n will authenticate via this header in production.

export async function POST(
  _request: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  const staff = await getCurrentStaff();
  if (!staff) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }
  if (staff.role !== "owner" && staff.role !== "receptionist") {
    return NextResponse.json({ error: "Forbidden" }, { status: 403 });
  }

  const { id } = await params;
  const admin = createAdminClient();

  const { data: entry, error: entryErr } = await admin
    .from("queue_entries")
    .select("id, status")
    .eq("id", id)
    .single();

  if (entryErr || !entry) {
    return NextResponse.json({ error: "Queue entry not found" }, { status: 404 });
  }

  const { error: updateErr } = await admin
    .from("queue_entries")
    .update({ status: "notified", notified_at: new Date().toISOString() })
    .eq("id", id);

  if (updateErr) {
    return NextResponse.json({ error: updateErr.message }, { status: 500 });
  }

  // TODO: n8n sends the actual WhatsApp ping via webhook after this response.

  return NextResponse.json({ ok: true });
}
