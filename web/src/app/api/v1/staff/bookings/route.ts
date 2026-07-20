import { getStaffFromRequest } from "@/lib/staffAuth";
import { isBookableRole } from "@/lib/staff/roles";
import { createBooking } from "@/lib/booking/createBooking";
import { NextRequest, NextResponse } from "next/server";

// Token-authed booking creation for the mobile barber app: a barber
// creating a booking for a client from their own Schedule tab. staffId is
// ALWAYS the caller's own id and channel is ALWAYS "barber" — neither is
// client-supplied, unlike the cookie-authed /api/bookings route which lets
// a receptionist pick any staffId/channel. Reuses createBooking.ts so the
// existing overlap guard, find-or-create-by-phone, service-duration lookup,
// and service_roles eligibility check all apply unchanged.

type Body = {
  clientId?: unknown;
  client?: unknown;
  serviceId?: unknown;
  scheduledStart?: unknown;
};

function isValidClientObject(value: unknown): value is { name: string; phone: string } {
  if (typeof value !== "object" || value === null) return false;
  const v = value as Record<string, unknown>;
  return (
    typeof v.name === "string" &&
    v.name.trim().length > 0 &&
    typeof v.phone === "string" &&
    v.phone.trim().length > 0
  );
}

export async function POST(request: NextRequest) {
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

  let body: Body;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json(
      { error: "invalid_json", message: "Invalid JSON body." },
      { status: 400 },
    );
  }

  const serviceId = typeof body.serviceId === "string" ? body.serviceId : "";
  const scheduledStart =
    typeof body.scheduledStart === "string" ? body.scheduledStart : "";

  if (!serviceId || !scheduledStart) {
    return NextResponse.json(
      {
        error: "invalid_body",
        message: "serviceId and scheduledStart are required.",
      },
      { status: 400 },
    );
  }

  const hasClientId = typeof body.clientId === "string" && body.clientId.trim().length > 0;
  const hasClientObject = isValidClientObject(body.client);

  if (hasClientId === hasClientObject) {
    // Both provided or neither provided — exactly one is required.
    return NextResponse.json(
      {
        error: "invalid_body",
        message: "Provide exactly one of clientId or client.{name,phone}.",
      },
      { status: 400 },
    );
  }

  const result = await createBooking({
    clientId: hasClientId ? (body.clientId as string) : undefined,
    client: hasClientObject ? (body.client as { name: string; phone: string }) : undefined,
    staffId: staff.id,
    serviceId,
    scheduledStart,
    channel: "barber",
    createdByStaffId: staff.id,
  });

  if (result.error === "slot_taken") {
    return NextResponse.json(
      { error: result.error, message: result.message, slots: result.slots },
      { status: 409 },
    );
  }

  if (result.error === "role_mismatch") {
    return NextResponse.json(
      { error: result.error, message: result.message },
      { status: 409 },
    );
  }

  if (result.error === "Service not found") {
    return NextResponse.json({ error: result.error }, { status: 404 });
  }

  if (result.error === "Staff member not found") {
    return NextResponse.json({ error: result.error }, { status: 404 });
  }

  if (result.error === "Provide either clientId or client.{name,phone}") {
    return NextResponse.json({ error: result.error }, { status: 400 });
  }

  if (result.error) {
    return NextResponse.json(
      { error: "server_error", message: result.error },
      { status: 500 },
    );
  }

  return NextResponse.json({ booking: result.booking }, { status: 201 });
}
