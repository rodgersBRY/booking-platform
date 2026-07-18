import "server-only";
import { createAdminClient } from "@/lib/supabase/admin";
import { getAvailability } from "@/lib/booking/availability";
import { createNotification } from "@/lib/notifications/createNotification";
import type { Slot } from "@/lib/booking/types";

const NAIROBI_DATE_FORMAT = new Intl.DateTimeFormat("en-US", {
  timeZone: "Africa/Nairobi",
  weekday: "short",
  month: "short",
  day: "numeric",
  hour: "numeric",
  minute: "2-digit",
});

export interface CreateBookingParams {
  clientId?: string;
  client?: { name: string; phone: string; acquisitionSource?: string };
  /** Concrete barber UUID, or null to let the DB assign (walk-in). */
  staffId: string | null;
  serviceId: string;
  /** ISO 8601 string for the booking start time. */
  scheduledStart: string;
  channel: string;
  createdByStaffId?: string | null;
}

export type CreateBookingResult =
  | { booking: Record<string, unknown>; error?: never }
  | {
      error: "slot_taken";
      message: string;
      slots: Slot[];
      booking?: never;
    }
  | { error: "role_mismatch"; message: string; slots?: never; booking?: never }
  | { error: string; message?: string; slots?: never; booking?: never };

/**
 * Shared guarded path for creating a booking.
 *
 * Caller is responsible for auth / channel enforcement BEFORE calling this.
 * This helper:
 *   1. Resolves or creates the client by id or phone (find-or-create).
 *   2. Persists preferred_staff_id when the client has none and a barber is chosen.
 *   3. Fetches service duration.
 *   4. Inserts the booking with status "booked".
 *   5. On Postgres exclusion violation (23P01) returns { error: "slot_taken", slots }.
 */
export async function createBooking(
  params: CreateBookingParams,
): Promise<CreateBookingResult> {
  const {
    clientId,
    client,
    staffId,
    serviceId,
    scheduledStart,
    channel,
    createdByStaffId = null,
  } = params;

  const admin = createAdminClient();

  // ── 1. Resolve or create the client ───────────────────────────────────────
  let resolvedClientId: string;

  if (clientId) {
    resolvedClientId = clientId;
  } else if (client?.phone) {
    const { data: existing } = await admin
      .from("clients")
      .select("id, preferred_staff_id")
      .eq("phone", client.phone)
      .maybeSingle();

    if (existing) {
      resolvedClientId = existing.id as string;

      // Persist preferred barber if the client hasn't had one recorded yet.
      if (staffId && !existing.preferred_staff_id) {
        await admin
          .from("clients")
          .update({ preferred_staff_id: staffId })
          .eq("id", resolvedClientId);
      }
    } else {
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
        return { error: "Something went wrong. Please try again." };
      }
      resolvedClientId = newClient.id as string;
    }
  } else {
    return { error: "Provide either clientId or client.{name,phone}" };
  }

  // ── 2. Fetch service duration ──────────────────────────────────────────────
  const { data: service, error: svcErr } = await admin
    .from("services")
    .select("name, duration_minutes")
    .eq("id", serviceId)
    .single();

  if (svcErr || !service) {
    return { error: "Service not found" };
  }

  // ── Defensive role-eligibility check ────────────────────────────────────────
  // Authoritative guard: even if every UI upstream already filters staff by
  // service eligibility, this is the one place every booking path funnels through.
  if (staffId) {
    const { data: staffRow, error: staffErr } = await admin
      .from("staff")
      .select("role")
      .eq("id", staffId)
      .single();
    if (staffErr || !staffRow) {
      return { error: "Staff member not found" };
    }
    const { data: eligibleRows, error: rolesErr } = await admin
      .from("service_roles")
      .select("role")
      .eq("service_id", serviceId);
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

  const startDate = new Date(scheduledStart);
  const endDate = new Date(
    startDate.getTime() + (service.duration_minutes as number) * 60 * 1000,
  );

  // ── 3. Insert booking ──────────────────────────────────────────────────────
  const { data: booking, error: bookErr } = await admin
    .from("bookings")
    .insert({
      client_id: resolvedClientId,
      staff_id: staffId ?? null,
      service_id: serviceId,
      scheduled_start: startDate.toISOString(),
      scheduled_end: endDate.toISOString(),
      channel,
      status: "booked",
      created_by_staff_id: createdByStaffId ?? null,
    })
    .select()
    .single();

  if (bookErr) {
    // Postgres exclusion constraint violation — slot is taken.
    if (bookErr.code === "23P01") {
      const date = scheduledStart.slice(0, 10);
      const slots = staffId
        ? await getAvailability({ staffId, serviceId, date })
        : await getAvailability({ staffId: "any", serviceId, date });

      return {
        error: "slot_taken",
        message:
          "That slot is no longer available. Here are the next open slots.",
        slots,
      };
    }
    return { error: "Something went wrong. Please try again." };
  }

  // ── 4. Mirror the primary service into booking_services ────────────────────
  // booking_services is the full service list for the appointment; every
  // booking starts with its primary service. Additional services are appended
  // later (e.g. in-chair upsell) via /api/bookings/[id]/add-service.
  const bookingRow = booking as { id: string };
  const { error: bsErr } = await admin
    .from("booking_services")
    .insert({ booking_id: bookingRow.id, service_id: serviceId });

  if (bsErr) {
    // Roll back the orphaned booking so the two never diverge.
    await admin.from("bookings").delete().eq("id", bookingRow.id);
    return { error: "Something went wrong. Please try again." };
  }

  // Best-effort — never fail the booking itself over a notification write.
  await createNotification({
    clientId: resolvedClientId,
    type: "booking_confirmed",
    title: "Appointment confirmed",
    body: `Your ${service.name as string} appointment is confirmed for ${NAIROBI_DATE_FORMAT.format(startDate)}.`,
    bookingId: bookingRow.id,
  });

  return { booking: booking as Record<string, unknown> };
}
