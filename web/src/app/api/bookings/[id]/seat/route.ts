import { getCurrentStaff } from "@/lib/auth";
import { isBookableRole } from "@/lib/staff/roles";
import { createAdminClient } from "@/lib/supabase/admin";
import { NextRequest, NextResponse } from "next/server";

export async function POST(
  _request: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  const staff = await getCurrentStaff();
  if (!staff) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }
  if (
    staff.role !== "owner" &&
    staff.role !== "receptionist" &&
    !isBookableRole(staff.role)
  ) {
    return NextResponse.json({ error: "Forbidden" }, { status: 403 });
  }

  const { id } = await params;
  const admin = createAdminClient();

  // Fetch booking with service for duration.
  const { data: booking, error: bookErr } = await admin
    .from("bookings")
    .select("id, status, barber_id, service_id, services(duration_minutes)")
    .eq("id", id)
    .single();

  if (bookErr || !booking) {
    return NextResponse.json({ error: "Booking not found" }, { status: 404 });
  }

  // Bookable staff may only seat their own bookings.
  if (isBookableRole(staff.role) && booking.barber_id !== staff.id) {
    return NextResponse.json({ error: "Forbidden" }, { status: 403 });
  }

  if (!["booked", "arrived"].includes(booking.status as string)) {
    return NextResponse.json(
      { error: "Booking cannot be seated from its current status" },
      { status: 409 },
    );
  }

  // Resolve service duration — fall back to shortest active service.
  type ServiceRel = { duration_minutes: number } | null;
  const serviceRel = Array.isArray(booking.services)
    ? ((booking.services[0] as ServiceRel) ?? null)
    : ((booking.services as ServiceRel) ?? null);

  let duration: number = serviceRel?.duration_minutes ?? 0;

  if (!duration) {
    const { data: fallback } = await admin
      .from("services")
      .select("duration_minutes")
      .eq("active", true)
      .order("duration_minutes")
      .limit(1)
      .single();
    duration = (fallback?.duration_minutes as number | undefined) ?? 45;
  }

  const now = new Date();
  const nowIso = now.toISOString();
  const scheduledEnd = new Date(now.getTime() + duration * 60 * 1000).toISOString();

  const { data: updated, error: updateErr } = await admin
    .from("bookings")
    .update({
      status: "in_chair",
      scheduled_start: nowIso,
      scheduled_end: scheduledEnd,
    })
    .eq("id", id)
    .select()
    .single();

  if (updateErr) {
    // Postgres exclusion constraint violation — barber already in a booking.
    if (updateErr.code === "23P01") {
      return NextResponse.json(
        { error: "barber_busy", message: "That barber is busy right now." },
        { status: 409 },
      );
    }
    return NextResponse.json(
      { error: "Something went wrong. Please try again." },
      { status: 500 },
    );
  }

  return NextResponse.json({ booking: updated });
}
