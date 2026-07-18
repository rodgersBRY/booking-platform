import type { Notification } from "@/lib/db/types";

/** Maps a notification row to the client-facing wire shape. */
export function shapeNotification(row: Notification) {
  return {
    id: row.id,
    type: row.type,
    title: row.title,
    body: row.body,
    bookingId: row.booking_id,
    read: row.read,
    createdAt: row.created_at,
  };
}
