import { getStaffFromRequest } from "@/lib/staffAuth";
import { completeBooking } from "@/lib/booking/completeBooking";
import { isBookableRole } from "@/lib/staff/roles";
import { createAdminClient } from "@/lib/supabase/admin";
import { NextRequest, NextResponse } from "next/server";

// Token-authed in_chair -> completed transition for the mobile barber app.
// Delegates the transition itself to the same completeBooking() lib function
// the cookie-authed /api/bookings/[id]/complete route uses, so a booking has
// exactly one completion state machine no matter which app drove it. No
// owner/receptionist bypass here — this surface only ever resolves the
// caller's own staff row, so ownership is absolute.

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

  let body: { notes?: unknown } = {};
  try {
    body = await request.json();
  } catch {
    // Body is optional.
  }

  if (body.notes !== undefined && typeof body.notes !== "string") {
    return NextResponse.json(
      { error: "invalid_body", message: "notes must be a string." },
      { status: 400 },
    );
  }
  const notes = typeof body.notes === "string" ? body.notes : undefined;

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

  const result = await completeBooking(id, { notes });

  if (result.error === "not_found") {
    return NextResponse.json({ error: "Booking not found" }, { status: 404 });
  }
  if (result.error === "status_conflict") {
    return NextResponse.json(
      { error: "invalid_status", message: result.message },
      { status: 409 },
    );
  }
  if (result.error === "server_error") {
    return NextResponse.json(
      { error: "server_error", message: "Something went wrong. Please try again." },
      { status: 500 },
    );
  }

  return NextResponse.json({ visit: result.visit });
}
