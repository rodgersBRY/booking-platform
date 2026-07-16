import { getClientFromRequest } from "@/lib/clientAuth";
import { rescheduleBooking } from "@/lib/booking/rescheduleBooking";
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

  let body: { scheduledStart?: string; staffId?: string };
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON body" }, { status: 400 });
  }

  if (!body.scheduledStart) {
    return NextResponse.json(
      { error: "Missing required field: scheduledStart" },
      { status: 400 },
    );
  }

  const result = await rescheduleBooking({
    bookingId: id,
    clientId: client.id,
    scheduledStart: body.scheduledStart,
    staffId: body.staffId,
  });

  if (result.error === "not_found") {
    return NextResponse.json({ error: "Booking not found" }, { status: 404 });
  }

  if (result.error === "not_reschedulable") {
    return NextResponse.json(
      { error: result.error, message: result.message },
      { status: 409 },
    );
  }

  if (result.error === "slot_taken") {
    return NextResponse.json(
      { error: result.error, message: result.message, slots: result.slots },
      { status: 409 },
    );
  }

  if (result.error === "role_mismatch") {
    return NextResponse.json(
      { error: result.error, message: result.message },
      { status: 400 },
    );
  }

  if (result.error === "Service not found" || result.error === "Staff member not found") {
    return NextResponse.json({ error: result.error }, { status: 404 });
  }

  if (result.error) {
    return NextResponse.json({ error: result.error }, { status: 500 });
  }

  return NextResponse.json({ booking: result.booking });
}
