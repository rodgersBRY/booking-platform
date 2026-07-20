import { getCurrentStaff } from "@/lib/auth";
import { isBookableRole } from "@/lib/staff/roles";
import { createStaffNotification } from "@/lib/notifications/createStaffNotification";
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
  
  if (
    staff.role !== "owner" &&
    staff.role !== "receptionist" &&
    !isBookableRole(staff.role)
  ) {
    return NextResponse.json({ error: "Forbidden" }, { status: 403 });
  }

  const { id } = await params;
  const admin = createAdminClient();

  const { data: booking, error: bookErr } = await admin
    .from("bookings")
    .select("id, status, staff_id, clients(name)")
    .eq("id", id)
    .single();

  if (bookErr || !booking) {
    return NextResponse.json({ error: "Booking not found" }, { status: 404 });
  }

  // Bookable staff (barber/beautician/masseuse) may only mark arrived on their own bookings.
  if (isBookableRole(staff.role) && booking.staff_id !== staff.id) {
    return NextResponse.json({ error: "Forbidden" }, { status: 403 });
  }

  if (booking.status !== "booked") {
    return NextResponse.json(
      { error: "Booking is not in booked status" },
      { status: 409 },
    );
  }

  const { error: updateErr } = await admin
    .from("bookings")
    .update({ status: "arrived" })
    .eq("id", id);

  if (updateErr) {
    return NextResponse.json(
      { error: "Something went wrong. Please try again." },
      { status: 500 },
    );
  }

  // Notify the assigned barber, unless they checked their own client in
  // themselves — no self-notification.
  if (booking.staff_id && booking.staff_id !== staff.id) {
    const clientRel = booking.clients as
      | { name: string }
      | { name: string }[]
      | null;
    const client = Array.isArray(clientRel) ? clientRel[0] : clientRel;

    await createStaffNotification({
      staffId: booking.staff_id,
      type: "customer_checked_in",
      title: "Customer checked in",
      body: `${client?.name ?? "A customer"} has checked in.`,
      bookingId: id,
    });
  }

  return NextResponse.json({ ok: true });
}
