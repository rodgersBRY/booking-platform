import { getClientFromRequest } from "@/lib/clientAuth";
import { createBooking } from "@/lib/booking/createBooking";
import { shapeBooking } from "@/lib/booking/shapeBooking";
import { createAdminClient } from "@/lib/supabase/admin";
import { NextRequest, NextResponse } from "next/server";

const UPCOMING_STATUSES = ["booked", "arrived", "in_chair", "late"];
const CANCELLED_STATUSES = ["cancelled", "no_show"];

export async function GET(request: NextRequest) {
  const client = await getClientFromRequest(request);
  if (!client) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const admin = createAdminClient();
  const { data, error } = await admin
    .from("bookings")
    .select(
      "*, staff:staff_id(id,name,role,avatar_url), services:service_id(id,name,category,duration_minutes,price)",
    )
    .eq("client_id", client.id);

  if (error) {
    return NextResponse.json(
      { error: "Something went wrong. Please try again." },
      { status: 500 },
    );
  }

  const bookings = (data ?? []).map(shapeBooking);

  const upcoming = bookings
    .filter((b) => UPCOMING_STATUSES.includes(b.status))
    .sort((a, b) => a.scheduledStart.localeCompare(b.scheduledStart));

  const completed = bookings
    .filter((b) => b.status === "completed")
    .sort((a, b) => b.scheduledStart.localeCompare(a.scheduledStart));

  const cancelled = bookings
    .filter((b) => CANCELLED_STATUSES.includes(b.status))
    .sort((a, b) => b.scheduledStart.localeCompare(a.scheduledStart));

  return NextResponse.json({ upcoming, completed, cancelled });
}

/** Creates a booking for the authenticated client directly — skips the
 * guest find-or-create-by-phone path entirely, so it's always the
 * signed-in client's own booking, not a lookalike guest record. */
export async function POST(request: NextRequest) {
  const client = await getClientFromRequest(request);
  if (!client) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  let body: { staffId?: string; serviceId?: string; scheduledStart?: string };
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON body" }, { status: 400 });
  }

  const { staffId, serviceId, scheduledStart } = body;

  if (!serviceId) {
    return NextResponse.json(
      { error: "Missing required field: serviceId" },
      { status: 400 },
    );
  }

  if (!scheduledStart) {
    return NextResponse.json(
      { error: "Missing required field: scheduledStart" },
      { status: 400 },
    );
  }

  if (!staffId) {
    return NextResponse.json(
      {
        error:
          "staffId is required for online bookings — select a slot to get a concrete barber",
      },
      { status: 400 },
    );
  }

  const result = await createBooking({
    clientId: client.id,
    staffId,
    serviceId,
    scheduledStart,
    channel: "online",
    createdByStaffId: null,
  });

  if (result.error === "slot_taken") {
    return NextResponse.json(
      { error: result.error, message: result.message, slots: result.slots },
      { status: 409 },
    );
  }

  if (result.error === "Service not found") {
    return NextResponse.json({ error: result.error }, { status: 404 });
  }

  if (result.error === "role_mismatch") {
    return NextResponse.json(
      { error: result.error, message: result.message },
      { status: 400 },
    );
  }

  if (result.error) {
    return NextResponse.json({ error: result.error }, { status: 500 });
  }

  return NextResponse.json({ booking: result.booking }, { status: 201 });
}
