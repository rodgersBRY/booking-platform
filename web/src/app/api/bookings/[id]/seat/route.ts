import { getCurrentStaff } from "@/lib/auth";
import { seatBooking } from "@/lib/booking/seatBooking";
import { isBookableRole } from "@/lib/staff/roles";
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

  // Fetch just enough to enforce 404 / ownership before delegating the
  // transition itself to the shared seatBooking() lib function.
  const { data: booking, error: bookErr } = await admin
    .from("bookings")
    .select("id, staff_id")
    .eq("id", id)
    .single();

  if (bookErr || !booking) {
    return NextResponse.json({ error: "Booking not found" }, { status: 404 });
  }

  // Bookable staff may only seat their own bookings.
  if (isBookableRole(staff.role) && booking.staff_id !== staff.id) {
    return NextResponse.json({ error: "Forbidden" }, { status: 403 });
  }

  const result = await seatBooking(id);

  if (result.error === "not_found") {
    return NextResponse.json({ error: "Booking not found" }, { status: 404 });
  }
  if (result.error === "status_conflict") {
    return NextResponse.json({ error: result.message }, { status: 409 });
  }
  if (result.error === "staff_busy") {
    return NextResponse.json(
      { error: "staff_busy", message: result.message },
      { status: 409 },
    );
  }
  if (result.error === "server_error") {
    return NextResponse.json(
      { error: "Something went wrong. Please try again." },
      { status: 500 },
    );
  }

  return NextResponse.json({ booking: result.booking });
}
