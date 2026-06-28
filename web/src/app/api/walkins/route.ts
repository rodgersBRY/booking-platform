import { getCurrentStaff } from "@/lib/auth";
import { createAdminClient } from "@/lib/supabase/admin";
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
    name: string;
    phone: string;
    preferredBarberId?: string;
    serviceId: string;
    acquisitionSource?: string;
  };

  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON body" }, { status: 400 });
  }

  const { name, phone, preferredBarberId, serviceId, acquisitionSource } = body;

  if (!name || !phone || !serviceId) {
    return NextResponse.json(
      { error: "Missing required fields: name, phone, serviceId" },
      { status: 400 },
    );
  }

  const admin = createAdminClient();

  // Resolve or create client by phone.
  let clientId: string;
  const { data: existing } = await admin
    .from("clients")
    .select("id")
    .eq("phone", phone)
    .maybeSingle();

  if (existing) {
    clientId = existing.id as string;
  } else {
    const { data: newClient, error: clientErr } = await admin
      .from("clients")
      .insert({
        name,
        phone,
        acquisition_source: acquisitionSource ?? null,
      })
      .select("id")
      .single();
    if (clientErr || !newClient) {
      return NextResponse.json(
        { error: clientErr?.message ?? "Failed to create client" },
        { status: 500 },
      );
    }
    clientId = newClient.id as string;
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
  const duration = service.duration_minutes as number;

  const now = new Date();
  const nowIso = now.toISOString();

  // Determine which barber to try seating.
  // If preferredBarberId given, check if that barber is free now.
  // Otherwise try any active barber.
  let seatBarberId: string | null = null;

  if (preferredBarberId) {
    // Check if preferred barber has an active booking covering now.
    const { data: active } = await admin
      .from("bookings")
      .select("id")
      .eq("barber_id", preferredBarberId)
      .in("status", ["booked", "arrived", "in_chair"])
      .lte("scheduled_start", nowIso)
      .gte("scheduled_end", nowIso)
      .limit(1);

    if (!active || active.length === 0) {
      seatBarberId = preferredBarberId;
    }
  } else {
    // Find any free active barber.
    const { data: barbers } = await admin
      .from("staff")
      .select("id")
      .eq("role", "barber")
      .eq("status", "active");

    for (const b of barbers ?? []) {
      const { data: active } = await admin
        .from("bookings")
        .select("id")
        .eq("barber_id", b.id)
        .in("status", ["booked", "arrived", "in_chair"])
        .lte("scheduled_start", nowIso)
        .gte("scheduled_end", nowIso)
        .limit(1);

      if (!active || active.length === 0) {
        seatBarberId = b.id as string;
        break;
      }
    }
  }

  if (seatBarberId) {
    // Seat the client immediately.
    const scheduledEnd = new Date(now.getTime() + duration * 60 * 1000);
    const { data: booking, error: bookErr } = await admin
      .from("bookings")
      .insert({
        client_id: clientId,
        barber_id: seatBarberId,
        service_id: serviceId,
        scheduled_start: nowIso,
        scheduled_end: scheduledEnd.toISOString(),
        channel: "walkin",
        status: "in_chair",
        created_by_staff_id: staff.id,
      })
      .select()
      .single();

    if (bookErr) {
      return NextResponse.json({ error: bookErr.message }, { status: 500 });
    }
    return NextResponse.json({ seated: true, booking }, { status: 201 });
  }

  // No barber free — add to queue.
  const { data: queueEntry, error: queueErr } = await admin
    .from("queue_entries")
    .insert({
      client_id: clientId,
      barber_id: preferredBarberId ?? null,
      choice: "waiting",
      status: "waiting",
    })
    .select()
    .single();

  if (queueErr) {
    return NextResponse.json({ error: queueErr.message }, { status: 500 });
  }
  return NextResponse.json({ seated: false, queueEntry }, { status: 201 });
}
