import "server-only";
import { createAdminClient } from "@/lib/supabase/admin";
import type { NotificationType } from "@/lib/db/types";

export interface CreateNotificationParams {
  clientId: string;
  type: NotificationType;
  title: string;
  body: string;
  bookingId?: string | null;
}

/**
 * Writes a notification row. Called from the same code paths that change a
 * booking's status (create/cancel/complete) — that's also the natural hook
 * point for a future push-notification send, so keep new call sites there
 * rather than deriving notifications from booking state after the fact.
 *
 * Best-effort: failures are swallowed (logged) rather than thrown, since a
 * notification-feed write should never fail the booking action itself.
 */
export async function createNotification(
  params: CreateNotificationParams,
): Promise<void> {
  const admin = createAdminClient();
  const { error } = await admin.from("notifications").insert({
    client_id: params.clientId,
    type: params.type,
    title: params.title,
    body: params.body,
    booking_id: params.bookingId ?? null,
  });

  if (error) {
    console.error("createNotification failed", error);
  }
}
