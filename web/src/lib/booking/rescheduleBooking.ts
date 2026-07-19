import "server-only";
import { createAdminClient } from "@/lib/supabase/admin";
import { getAvailability } from "@/lib/booking/availability";
import { shapeBooking } from "@/lib/booking/shapeBooking";
import { NAIROBI_DATE_FORMAT } from "@/lib/booking/createBooking";
import { createStaffNotification } from "@/lib/notifications/createStaffNotification";
import type { Slot } from "@/lib/booking/types";

export interface RescheduleBookingParams {
  bookingId: string;
  clientId: string;
  scheduledStart: string;
  /** Omit to keep the booking's current staff member. */
  staffId?: string;
}

export type RescheduleBookingResult =
  | { booking: ReturnType<typeof shapeBooking>; error?: never }
  | { error: "not_found"; message?: never; slots?: never; booking?: never }
  | {
      error: "not_reschedulable";
      message: string;
      slots?: never;
      booking?: never;
    }
  | { error: "role_mismatch"; message: string; slots?: never; booking?: never }
  | { error: "slot_taken"; message: string; slots: Slot[]; booking?: never }
  | { error: string; message?: string; slots?: never; booking?: never };

const BOOKING_SELECT =
  "*, staff:staff_id(id,name,role,avatar_url), services:service_id(id,name,category,duration_minutes,price)";

/**
 * Moves an existing "booked" appointment to a new slot, keeping its
 * original service (and staff member, unless a new one is passed).
 * Mirrors createBooking.ts's guarded-write pattern rather than
 * duplicating the role-eligibility / exclusion-constraint handling.
 */
export async function rescheduleBooking(
  params: RescheduleBookingParams,
): Promise<RescheduleBookingResult> {
  const { bookingId, clientId, scheduledStart, staffId } = params;
  const admin = createAdminClient();

  const { data: existing, error: fetchErr } = await admin
    .from("bookings")
    .select("id, client_id, status, service_id, staff_id")
    .eq("id", bookingId)
    .single();

  if (fetchErr || !existing || existing.client_id !== clientId) {
    return { error: "not_found" };
  }

  if (existing.status !== "booked") {
    return {
      error: "not_reschedulable",
      message: "This appointment can no longer be rescheduled.",
    };
  }

  const newStaffId = staffId ?? (existing.staff_id as string | null);

  if (newStaffId) {
    const { data: staffRow, error: staffErr } = await admin
      .from("staff")
      .select("role")
      .eq("id", newStaffId)
      .single();
    if (staffErr || !staffRow) {
      return { error: "Staff member not found" };
    }
    const { data: eligibleRows, error: rolesErr } = await admin
      .from("service_roles")
      .select("role")
      .eq("service_id", existing.service_id);
    if (rolesErr) {
      return { error: "Something went wrong. Please try again." };
    }
    const eligibleRoles = (eligibleRows ?? []).map((r) => r.role as string);
    if (!eligibleRoles.includes(staffRow.role as string)) {
      return {
        error: "role_mismatch",
        message: "This staff member cannot perform this service.",
      };
    }
  }

  const { data: service, error: svcErr } = await admin
    .from("services")
    .select("duration_minutes")
    .eq("id", existing.service_id)
    .single();

  if (svcErr || !service) {
    return { error: "Service not found" };
  }

  const startDate = new Date(scheduledStart);
  const endDate = new Date(
    startDate.getTime() + (service.duration_minutes as number) * 60 * 1000,
  );

  const { data: updated, error: updateErr } = await admin
    .from("bookings")
    .update({
      staff_id: newStaffId,
      scheduled_start: startDate.toISOString(),
      scheduled_end: endDate.toISOString(),
    })
    .eq("id", bookingId)
    .eq("client_id", clientId)
    .eq("status", "booked")
    .select(BOOKING_SELECT)
    .single();

  if (updateErr || !updated) {
    // Postgres exclusion constraint violation — slot is taken.
    if (updateErr?.code === "23P01") {
      const date = scheduledStart.slice(0, 10);
      const slots = await getAvailability({
        staffId: newStaffId ?? "any",
        serviceId: existing.service_id as string,
        date,
      });
      return {
        error: "slot_taken",
        message:
          "That slot is no longer available. Here are the next open slots.",
        slots,
      };
    }
    return { error: "Something went wrong. Please try again." };
  }

  const shaped = shapeBooking(updated);

  // This function is only ever reached from the client-owned reschedule
  // route (it requires clientId and enforces booking ownership above), so
  // every call here is genuinely client-initiated — no self-notification
  // concern like createBooking.ts has.
  if (newStaffId) {
    const { data: clientRow } = await admin
      .from("clients")
      .select("name")
      .eq("id", clientId)
      .single();
    const clientName = (clientRow?.name as string | undefined) ?? "A client";

    // Best-effort — never fail the reschedule itself over a notification write.
    await createStaffNotification({
      staffId: newStaffId,
      type: "booking_rescheduled",
      title: "Appointment rescheduled",
      body: `${clientName} rescheduled ${shaped.service?.name ?? "their appointment"} to ${NAIROBI_DATE_FORMAT.format(startDate)}.`,
      bookingId,
    });
  }

  return { booking: shaped };
}
