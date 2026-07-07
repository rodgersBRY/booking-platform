// TODO: rate-limit / captcha for abuse before production.
import { createBooking } from "@/lib/booking/createBooking";
import { NextRequest, NextResponse } from "next/server";

export async function POST(request: NextRequest) {
  let body: {
    client?: { name: string; phone: string };
    barberId?: string;
    serviceId?: string;
    scheduledStart?: string;
  };

  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON body" }, { status: 400 });
  }

  const { client, barberId, serviceId, scheduledStart } = body;

  // Validate required fields.
  if (!client?.name || !client?.phone) {
    return NextResponse.json(
      { error: "Missing required fields: client.name, client.phone" },
      { status: 400 },
    );
  }

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

  // Online bookings require a concrete barber (from slot selection).
  if (!barberId) {
    return NextResponse.json(
      {
        error:
          "barberId is required for online bookings — select a slot to get a concrete barber",
      },
      { status: 400 },
    );
  }

  const result = await createBooking({
    client: {
      name: client.name,
      phone: client.phone,
      acquisitionSource: "website",
    },
    barberId,
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
