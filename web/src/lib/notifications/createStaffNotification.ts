import "server-only";
import { createAdminClient } from "@/lib/supabase/admin";
import type { StaffNotificationType } from "@/lib/db/types";

export interface CreateStaffNotificationParams {
  staffId: string;
  type: StaffNotificationType;
  title: string;
  body: string;
  bookingId?: string | null;
}

/**
 * Staff-facing parallel to createNotification.ts. Writes to
 * `staff_notifications`, not `notifications` — kept as a separate table and
 * writer to match this codebase's client/staff separation (clientAuth.ts vs
 * staffAuth.ts never cross; this is the same split for the notification
 * feed).
 *
 * Best-effort: failures are swallowed (logged) rather than thrown, since a
 * notification-feed write should never fail the booking action it's
 * attached to.
 */
export async function createStaffNotification(
  params: CreateStaffNotificationParams,
): Promise<void> {
  const admin = createAdminClient();
  const { error } = await admin.from("staff_notifications").insert({
    staff_id: params.staffId,
    type: params.type,
    title: params.title,
    body: params.body,
    booking_id: params.bookingId ?? null,
  });

  if (error) {
    console.error("createStaffNotification failed", error);
  }
}
