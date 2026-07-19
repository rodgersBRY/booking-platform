import { assertAutomationKey } from "@/lib/auth/automation";
import { createNotification } from "@/lib/notifications/createNotification";
import { createAdminClient } from "@/lib/supabase/admin";
import { NextRequest, NextResponse } from "next/server";

export const dynamic = "force-dynamic";

export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  const authError = assertAutomationKey(request);
  if (authError) return authError;

  const { id } = await params;
  const admin = createAdminClient();

  const { data: booking, error: fetchError } = await admin
    .from("bookings")
    .select("id, client_id, status")
    .eq("id", id)
    .maybeSingle();

  if (fetchError) return NextResponse.json({ error: fetchError.message }, { status: 500 });

  if (!booking) {
    return NextResponse.json({ error: "Booking not found" }, { status: 404 });
  }

  type BookingRow = { id: string; client_id: string; status: string };
  const row = booking as BookingRow;

  if (row.status !== "booked") {
    return NextResponse.json(
      { error: `Booking cannot be cancelled — current status is '${row.status}'` },
      { status: 409 },
    );
  }

  const { error: updateError } = await admin
    .from("bookings")
    .update({ status: "cancelled" })
    .eq("id", id);

  if (updateError) return NextResponse.json({ error: updateError.message }, { status: 500 });

  await createNotification({
    clientId: row.client_id,
    type: "booking_cancelled",
    title: "Appointment cancelled",
    body: "Your appointment has been cancelled.",
    bookingId: id,
  });

  return NextResponse.json({ cancelled: true, bookingId: id });
}
