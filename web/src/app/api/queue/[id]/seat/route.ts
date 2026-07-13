import { getCurrentStaff } from "@/lib/auth";
import { createAdminClient } from "@/lib/supabase/admin";
import { NextRequest, NextResponse } from "next/server";

// TODO: AUTOMATION_API_KEY auth — n8n will authenticate via this header in production.

export async function POST(
  _request: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  const staff = await getCurrentStaff();
  if (!staff) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }
  if (staff.role !== "owner" && staff.role !== "receptionist") {
    return NextResponse.json({ error: "Forbidden" }, { status: 403 });
  }

  const { id } = await params;
  const admin = createAdminClient();

  // Fetch the queue entry.
  const { data: entry, error: entryErr } = await admin
    .from("queue_entries")
    .select("id, client_id, barber_id, status")
    .eq("id", id)
    .single();

  if (entryErr || !entry) {
    return NextResponse.json({ error: "Queue entry not found" }, { status: 404 });
  }

  if (!["waiting", "notified"].includes(entry.status as string)) {
    return NextResponse.json(
      { error: "Queue entry is not in a seatablestate" },
      { status: 409 },
    );
  }

  const now = new Date();
  const nowIso = now.toISOString();

  // Determine barber: preferred first, then any free active barber.
  let seatBarberId: string | null = null;
  const preferredBarberId = entry.barber_id as string | null;

  const isFree = async (barberId: string): Promise<boolean> => {
    const { data } = await admin
      .from("bookings")
      .select("id")
      .eq("barber_id", barberId)
      .in("status", ["booked", "arrived", "in_chair"])
      .lte("scheduled_start", nowIso)
      .gte("scheduled_end", nowIso)
      .limit(1);
    return !data || data.length === 0;
  };

  if (preferredBarberId && (await isFree(preferredBarberId))) {
    seatBarberId = preferredBarberId;
  } else {
    // Try any active barber.
    const { data: barbers } = await admin
      .from("staff")
      .select("id")
      .eq("role", "barber")
      .eq("status", "active");

    for (const b of barbers ?? []) {
      if (await isFree(b.id as string)) {
        seatBarberId = b.id as string;
        break;
      }
    }
  }

  if (!seatBarberId) {
    return NextResponse.json(
      { error: "no_barber_free", message: "No barber is currently free." },
      { status: 409 },
    );
  }

  // We need a service to compute the end time. Look up the client's preferred service
  // via a recent booking or default to the shortest active service.
  // For simplicity: use the shortest active service duration as a fallback.
  const { data: service } = await admin
    .from("services")
    .select("id, duration_minutes")
    .eq("active", true)
    .order("duration_minutes")
    .limit(1)
    .single();

  const duration = (service?.duration_minutes as number | undefined) ?? 45;
  const serviceId = service?.id as string | undefined;

  const scheduledEnd = new Date(now.getTime() + duration * 60 * 1000);

  const { data: booking, error: bookErr } = await admin
    .from("bookings")
    .insert({
      client_id: entry.client_id as string,
      barber_id: seatBarberId,
      service_id: serviceId ?? null,
      scheduled_start: nowIso,
      scheduled_end: scheduledEnd.toISOString(),
      channel: "walkin",
      status: "in_chair",
      created_by_staff_id: staff.id,
    })
    .select()
    .single();

  if (bookErr) {
    return NextResponse.json(
      { error: "Something went wrong. Please try again." },
      { status: 500 },
    );
  }

  // Mirror the primary service into booking_services (full service list).
  if (serviceId) {
    const { error: bsErr } = await admin
      .from("booking_services")
      .insert({ booking_id: booking.id, service_id: serviceId });
    if (bsErr) {
      await admin.from("bookings").delete().eq("id", booking.id);
      return NextResponse.json(
        { error: "Something went wrong. Please try again." },
        { status: 500 },
      );
    }
  }

  // Mark queue entry as served.
  await admin
    .from("queue_entries")
    .update({ status: "served", booking_id: booking.id })
    .eq("id", id);

  return NextResponse.json({ booking });
}
