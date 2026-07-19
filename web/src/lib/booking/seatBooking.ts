import "server-only";
import { createAdminClient } from "@/lib/supabase/admin";

// Core transition logic for booked/arrived -> in_chair, shared by the
// cookie-authed web receptionist console (/api/bookings/[id]/seat) and the
// token-authed mobile barber app (/api/v1/staff/bookings/[id]/start).
//
// NO auth or ownership logic lives here — callers resolve identity and
// ownership themselves before calling this, same as createBooking.ts does
// for the create-booking flow. Keeping both callers on this single function
// means a booking only ever has one seat-transition state machine, no
// matter which app performed the action.

export type SeatBookingResult =
  | { booking: Record<string, unknown>; error?: never; message?: never }
  | { error: "not_found"; message: string; booking?: never }
  | { error: "status_conflict"; message: string; booking?: never }
  | { error: "staff_busy"; message: string; booking?: never }
  | { error: "server_error"; message: string; booking?: never };

export async function seatBooking(bookingId: string): Promise<SeatBookingResult> {
  const admin = createAdminClient();

  // Fetch booking with service for duration.
  const { data: booking, error: bookErr } = await admin
    .from("bookings")
    .select("id, status, staff_id, service_id, services(duration_minutes)")
    .eq("id", bookingId)
    .single();

  if (bookErr || !booking) {
    return { error: "not_found", message: "Booking not found" };
  }

  if (!["booked", "arrived"].includes(booking.status as string)) {
    return {
      error: "status_conflict",
      message: "Booking cannot be seated from its current status",
    };
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
    .eq("id", bookingId)
    .select()
    .single();

  if (updateErr) {
    // Postgres exclusion constraint violation — barber already in a booking.
    if (updateErr.code === "23P01") {
      return { error: "staff_busy", message: "That barber is busy right now." };
    }
    return {
      error: "server_error",
      message: "Something went wrong. Please try again.",
    };
  }

  return { booking: updated as Record<string, unknown> };
}
