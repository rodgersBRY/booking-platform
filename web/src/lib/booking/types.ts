// Shared response types for the booking engine and console API.

export interface Slot {
  /** ISO 8601 with offset, e.g. "2026-06-28T09:00:00+03:00" */
  start: string;
  end: string;
  /** Formatted label for display, e.g. "9:00 AM" */
  label: string;
  /** The barber who is free for this slot */
  staffId: string;
}

export interface ChairStatus {
  staffId: string;
  staffName: string;
  status: "in_chair" | "free";
  /** Present when status === "in_chair" */
  bookingId?: string;
  currentClientName?: string;
  serviceName?: string;
  servicePrice?: number | null;
  minutesLeft?: number;
}

export interface QueueItem {
  id: string;
  clientName: string;
  preferredStaffId: string | null;
  preferredStaffName: string | null;
  choice: string;
  status: string;
  waitedMinutes: number;
  estimatedWaitMinutes: number | null;
  isRegular: boolean;
}

export interface BoardStats {
  waiting: number;
  servedToday: number;
  noShows: number;
}

export interface Appointment {
  id: string;
  clientName: string;
  staffId: string | null;
  staffName: string | null;
  serviceName: string | null;
  serviceId: string | null;
  scheduledStart: string;
  status: "booked" | "arrived";
  channel: string;
  isRegular: boolean;
}
