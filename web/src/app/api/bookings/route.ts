import { getCurrentStaff } from "@/lib/auth";
import { createAdminClient } from "@/lib/supabase/admin";
import { getAvailability } from "@/lib/booking/availability";
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
    barberId?: string | null;
    serviceId: string;
    scheduledStart: string;
    channel: string;
  };

  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON body" }, { status: 400 });
  }

  const { clientId, client, barberId, serviceId, scheduledStart, channel } =
    body;

  if (!serviceId || !scheduledStart || !channel) {
    return NextResponse.json(
      { error: "Missing required fields: serviceId, scheduledStart, channel" },
      { status: 400 },
    );
  }

  const admin = createAdminClient();

  // Resolve or create client.
  let resolvedClientId: string;

  if (clientId) {
    resolvedClientId = clientId;
  } else if (client?.phone) {
    // Look up by phone first.
    const { data: existing } = await admin
      .from("clients")
      .select("id")
      .eq("phone", client.phone)
      .maybeSingle();

    if (existing) {
      resolvedClientId = existing.id as string;
    } else {
      // Create new client.
      const { data: newClient, error: clientErr } = await admin
        .from("clients")
        .insert({
          name: client.name,
          phone: client.phone,
          acquisition_source: client.acquisitionSource ?? null,
        })
        .select("id")
        .single();
      if (clientErr || !newClient) {
        return NextResponse.json(
          { error: clientErr?.message ?? "Failed to create client" },
          { status: 500 },
        );
      }
      resolvedClientId = newClient.id as string;
    }
  } else {
    return NextResponse.json(
      { error: "Provide either clientId or client.{name,phone}" },
      { status: 400 },
    );
  }

  // Fetch service duration.
  const { data: service, error: svcErr } = await admin
    .from("services")
    .select("duration_minutes")
    .eq("id", serviceId)
    .single();
  if (svcErr || !service) {
    return NextResponse.json({ error: "Service not found" }, { status: 404 });
  }

  const startDate = new Date(scheduledStart);
  const endDate = new Date(
    startDate.getTime() + (service.duration_minutes as number) * 60 * 1000,
  );

  // Insert booking; catch overlap exclusion constraint (Postgres code 23P01).
  const { data: booking, error: bookErr } = await admin
    .from("bookings")
    .insert({
      client_id: resolvedClientId,
      barber_id: barberId ?? null,
      service_id: serviceId,
      scheduled_start: startDate.toISOString(),
      scheduled_end: endDate.toISOString(),
      channel,
      status: "booked",
      created_by_staff_id: staff.id,
    })
    .select()
    .single();

  if (bookErr) {
    // Postgres exclusion constraint violation code.
    if (bookErr.code === "23P01") {
      // Return fresh availability for the same date.
      const date = scheduledStart.slice(0, 10);
      const slots = barberId
        ? await getAvailability({ barberId, serviceId, date })
        : await getAvailability({ barberId: "any", serviceId, date });

      return NextResponse.json(
        {
          error: "slot_taken",
          message:
            "That slot is no longer available. Here are the next open slots.",
          slots,
        },
        { status: 409 },
      );
    }
    return NextResponse.json({ error: bookErr.message }, { status: 500 });
  }

  return NextResponse.json({ booking }, { status: 201 });
}
