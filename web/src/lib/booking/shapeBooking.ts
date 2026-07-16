import type { BookingStatus } from "@/lib/db/types";

interface BookingRow {
  id: string;
  status: BookingStatus;
  channel: string;
  scheduled_start: string;
  scheduled_end: string;
  services: {
    id: string;
    name: string;
    category: string | null;
    duration_minutes: number;
    price: number;
  } | null;
  staff: {
    id: string;
    name: string;
    role: string;
    avatar_url: string | null;
  } | null;
}

/** Maps a joined booking row (with embedded staff/services selects) to the client-facing wire shape. */
export function shapeBooking(row: BookingRow) {
  const cancellable = row.status === "booked";
  return {
    id: row.id,
    status: row.status,
    channel: row.channel,
    scheduledStart: row.scheduled_start,
    scheduledEnd: row.scheduled_end,
    service: row.services
      ? {
          id: row.services.id,
          name: row.services.name,
          category: row.services.category,
          durationMinutes: row.services.duration_minutes,
          price: row.services.price,
        }
      : null,
    staff: row.staff
      ? {
          id: row.staff.id,
          name: row.staff.name,
          role: row.staff.role,
          avatarUrl: row.staff.avatar_url,
        }
      : null,
    canCancel: cancellable,
    canReschedule: cancellable,
  };
}
