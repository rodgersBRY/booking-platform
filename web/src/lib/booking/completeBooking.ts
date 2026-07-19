import "server-only";
import { createAdminClient } from "@/lib/supabase/admin";
import { createNotification } from "@/lib/notifications/createNotification";

// Core transition logic for in_chair -> completed (marks the booking
// completed, inserts a visit row, bumps the client's total_visits /
// last_visit_at, and writes the completion notification), shared by the
// cookie-authed web receptionist console (/api/bookings/[id]/complete) and
// the token-authed mobile barber app (/api/v1/staff/bookings/[id]/complete).
//
// NO auth or ownership logic lives here — callers resolve identity and
// ownership themselves before calling this, same as createBooking.ts does
// for the create-booking flow.

export interface CompleteBookingParams {
  amountCharged?: number;
  paymentMethod?: string | null;
  /**
   * Service notes written to bookings.notes as part of the same update.
   * New for the mobile flow — when omitted, behavior is byte-for-byte
   * identical to the pre-existing web route (no notes column touched).
   */
  notes?: string;
}

export type CompleteBookingResult =
  | { visit: Record<string, unknown>; error?: never; message?: never }
  | { error: "not_found"; message: string; visit?: never }
  | { error: "status_conflict"; message: string; visit?: never }
  | { error: "server_error"; message: string; visit?: never };

export async function completeBooking(
  bookingId: string,
  params: CompleteBookingParams = {},
): Promise<CompleteBookingResult> {
  const { amountCharged = 0, paymentMethod = null, notes } = params;

  const admin = createAdminClient();

  // Fetch booking.
  const { data: booking, error: bookErr } = await admin
    .from("bookings")
    .select("id, client_id, staff_id, service_id, status")
    .eq("id", bookingId)
    .single();

  if (bookErr || !booking) {
    return { error: "not_found", message: "Booking not found" };
  }

  if (booking.status === "completed") {
    return { error: "status_conflict", message: "Booking already completed" };
  }

  const now = new Date().toISOString();

  // Mark booking completed — only touch notes when the caller provided one,
  // so the omitted-notes path stays byte-for-byte identical to before.
  const updatePayload: Record<string, unknown> = { status: "completed" };
  if (notes !== undefined) {
    updatePayload.notes = notes;
  }

  const { error: updateErr } = await admin
    .from("bookings")
    .update(updatePayload)
    .eq("id", bookingId);

  if (updateErr) {
    return {
      error: "server_error",
      message: "Something went wrong. Please try again.",
    };
  }

  // Insert visit row.
  const { data: visit, error: visitErr } = await admin
    .from("visits")
    .insert({
      booking_id: bookingId,
      client_id: booking.client_id as string,
      staff_id: booking.staff_id as string | null,
      service_id: booking.service_id as string,
      completed_at: now,
      amount_charged: amountCharged,
      payment_method: paymentMethod,
    })
    .select()
    .single();

  if (visitErr) {
    return {
      error: "server_error",
      message: "Something went wrong. Please try again.",
    };
  }

  // Bump client total_visits and last_visit_at.
  const { data: client } = await admin
    .from("clients")
    .select("total_visits")
    .eq("id", booking.client_id as string)
    .single();

  await admin
    .from("clients")
    .update({
      total_visits: ((client?.total_visits as number | undefined) ?? 0) + 1,
      last_visit_at: now,
    })
    .eq("id", booking.client_id as string);

  await createNotification({
    clientId: booking.client_id as string,
    type: "booking_completed",
    title: "Visit complete",
    body: "Thanks for visiting Baberia Cuts! We hope you loved the result.",
    bookingId,
  });

  return { visit: visit as Record<string, unknown> };
}
