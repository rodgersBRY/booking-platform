import type { StaffNotification } from "@/lib/db/types";

/** Maps a staff_notifications row to the staff-facing wire shape. */
export function shapeStaffNotification(row: StaffNotification) {
  return {
    id: row.id,
    type: row.type,
    title: row.title,
    body: row.body,
    bookingId: row.booking_id,
    readAt: row.read_at,
    createdAt: row.created_at,
  };
}
