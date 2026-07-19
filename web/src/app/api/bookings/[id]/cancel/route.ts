import { getCurrentStaff } from "@/lib/auth";
import { createNotification } from "@/lib/notifications/createNotification";
import { createAdminClient } from "@/lib/supabase/admin";
import { NextRequest, NextResponse } from "next/server";

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

  const { data: booking, error: bookErr } = await admin
    .from("bookings")
    .select("id, client_id, status")
    .eq("id", id)
    .single();

  if (bookErr || !booking) {
    return NextResponse.json({ error: "Booking not found" }, { status: 404 });
  }

  const { error: updateErr } = await admin
    .from("bookings")
    .update({ status: "cancelled" })
    .eq("id", id);

  if (updateErr) {
    return NextResponse.json(
      { error: "Something went wrong. Please try again." },
      { status: 500 },
    );
  }

  await createNotification({
    clientId: booking.client_id as string,
    type: "booking_cancelled",
    title: "Appointment cancelled",
    body: "Your appointment has been cancelled.",
    bookingId: id,
  });

  return NextResponse.json({ ok: true });
}
