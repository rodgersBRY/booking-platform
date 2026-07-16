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

  const { data: booking, error: bookErr } = await admin
    .from("bookings")
    .select("id, client_id, status")
    .eq("id", id)
    .single();

  // Not found or not this client's booking — same response either way, so
  // we never reveal whether a booking id belongs to someone else.
  if (bookErr || !booking || booking.client_id !== client.id) {
    return NextResponse.json({ error: "Booking not found" }, { status: 404 });
  }

  if (booking.status !== "booked") {
    return NextResponse.json(
      {
        error: "not_cancellable",
        message: "This appointment can no longer be cancelled.",
      },
      { status: 409 },
    );
  }

  const { data: updated, error: updateErr } = await admin
    .from("bookings")
    .update({ status: "cancelled" })
    .eq("id", id)
    .eq("client_id", client.id)
    .eq("status", "booked")
    .select("id");

  if (updateErr || !updated || updated.length === 0) {
    return NextResponse.json(
      { error: "Something went wrong. Please try again." },
      { status: 500 },
    );
  }

  return NextResponse.json({ ok: true });
}
