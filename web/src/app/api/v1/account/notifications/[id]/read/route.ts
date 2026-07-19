import { getClientFromRequest } from "@/lib/clientAuth";
import { createAdminClient } from "@/lib/supabase/admin";
import { NextRequest, NextResponse } from "next/server";

export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  const client = await getClientFromRequest(request);
  if (!client) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const { id } = await params;
  const admin = createAdminClient();

  const { data: updated, error } = await admin
    .from("notifications")
    .update({ read: true })
    .eq("id", id)
    .eq("client_id", client.id)
    .select("id");

  if (error) {
    return NextResponse.json(
      { error: "Something went wrong. Please try again." },
      { status: 500 },
    );
  }

  // Not found or not this client's notification — same response either
  // way, matching the account/bookings ownership-check convention.
  if (!updated || updated.length === 0) {
    return NextResponse.json({ error: "Notification not found" }, { status: 404 });
  }

  return NextResponse.json({ ok: true });
}
