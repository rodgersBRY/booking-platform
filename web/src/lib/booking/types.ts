// Shared response types for the booking engine and console API.

export interface Slot {
  /** ISO 8601 with offset, e.g. "2026-06-28T09:00:00+03:00" */
  start: string;
  end: string;
  /** Formatted label for display, e.g. "9:00 AM" */
  label: string;
  /** The barber who is free for this slot */
  barberId: string;
}

export interface ChairStatus {
  barberId: string;
  barberName: string;
  status: "in_chair" | "free";
  /** Present when status === "in_chair" */
  bookingId?: string;
  currentClientName?: string;
  serviceName?: string;
  minutesLeft?: number;
}

export interface QueueItem {
  id: string;
  clientName: string;
  preferredBarberId: string | null;
  preferredBarberName: string | null;
  choice: string;
  status: string;
  waitedMinutes: number;
  estimatedWaitMinutes: number | null;
}

export interface BoardStats {
  waiting: number;
  servedToday: number;
  noShows: number;
}
