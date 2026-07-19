import { getStaffFromRequest } from "@/lib/staffAuth";
import { seatBooking } from "@/lib/booking/seatBooking";
import { isBookableRole } from "@/lib/staff/roles";
import { createAdminClient } from "@/lib/supabase/admin";
import { NextRequest, NextResponse } from "next/server";

// Token-authed booked/arrived -> in_chair transition for the mobile barber
// app. Delegates the transition itself to the same seatBooking() lib
// function the cookie-authed /api/bookings/[id]/seat route uses, so a
// booking has exactly one seat-transition state machine no matter which app
// drove it. No owner/receptionist bypass here — this surface only ever
// resolves the caller's own staff row, so ownership is absolute.

export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  const staff = await getStaffFromRequest(request);
  if (!staff) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  if (!isBookableRole(staff.role)) {
    return NextResponse.json(
      {
        error: "not_bookable_role",
        message: "This account doesn't have access to the barber app.",
      },
      { status: 403 },
    );
  }

  const { id } = await params;
  const admin = createAdminClient();

  const { data: booking, error: bookErr } = await admin
    .from("bookings")
    .select("id, staff_id")
    .eq("id", id)
    .single();

  if (bookErr || !booking) {
    return NextResponse.json({ error: "Booking not found" }, { status: 404 });
  }

  if (booking.staff_id !== staff.id) {
    return NextResponse.json({ error: "Forbidden" }, { status: 403 });
  }

  const result = await seatBooking(id);

  if (result.error === "not_found") {
    return NextResponse.json({ error: "Booking not found" }, { status: 404 });
  }
  if (result.error === "status_conflict") {
    return NextResponse.json(
      { error: "invalid_status", message: result.message },
      { status: 409 },
    );
  }
  if (result.error === "staff_busy") {
    return NextResponse.json(
      { error: "staff_busy", message: "That barber is busy right now." },
      { status: 409 },
    );
  }
  if (result.error === "server_error") {
    return NextResponse.json(
      { error: "server_error", message: "Something went wrong. Please try again." },
      { status: 500 },
    );
  }

  return NextResponse.json({ booking: result.booking });
}
