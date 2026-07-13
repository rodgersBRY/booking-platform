import { getCurrentStaff } from "@/lib/auth";
import { createBooking } from "@/lib/booking/createBooking";
import { NextRequest, NextResponse } from "next/server";

// TODO: AUTOMATION_API_KEY auth — n8n will authenticate via this header in production.

export async function POST(request: NextRequest) {
  const staff = await getCurrentStaff();
  if (!staff) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }
  
  if (staff.role !== "owner" && staff.role !== "receptionist") {
    return NextResponse.json({ error: "Forbidden" }, { status: 403 });
  }

  let body: {
    clientId?: string;
    client?: { name: string; phone: string; acquisitionSource?: string };
    staffId?: string | null;
    serviceId: string;
    scheduledStart: string;
    channel: string;
  };

  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON body" }, { status: 400 });
  }

  const { clientId, client, staffId, serviceId, scheduledStart, channel } =
    body;

  if (!serviceId || !scheduledStart || !channel) {
    return NextResponse.json(
      { error: "Missing required fields: serviceId, scheduledStart, channel" },
      { status: 400 },
    );
  }

  const result = await createBooking({
    clientId,
    client,
    staffId: staffId ?? null,
    serviceId,
    scheduledStart,
    channel,
    createdByStaffId: staff.id,
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
    // Client creation failure or DB error.
    const is400 =
      result.error === "Provide either clientId or client.{name,phone}";
    return NextResponse.json(
      { error: result.error },
      { status: is400 ? 400 : 500 },
    );
  }

  return NextResponse.json({ booking: result.booking }, { status: 201 });
}
