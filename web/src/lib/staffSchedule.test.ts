import type { BookingChannel } from "./db/types";

// Compile-time pin only — see staffDay.test.ts / staffAuth.test.ts for why
// this repo pins JSON shapes at the type level instead of executing tests.
// Pins GET /api/v1/staff/schedule?range=today|tomorrow|week.

type AppointmentEntry = {
  bookingId: string;
  clientName: string;
  services: string[];
  scheduledStart: string;
  scheduledEnd: string;
  durationMinutes: number;
  status: "booked" | "arrived" | "in_chair" | "late" | "completed";
  channel: BookingChannel;
};

type ScheduleRange = "today" | "tomorrow" | "week";

type StaffScheduleResponse = {
  range: ScheduleRange;
  schedule: AppointmentEntry[];
};

const today: StaffScheduleResponse = {
  range: "today",
  schedule: [
    {
      bookingId: "booking-1",
      clientName: "Brian Mwangi",
      services: ["Haircut", "Beard Trim"],
      scheduledStart: "2026-07-19T07:30:00.000Z",
      scheduledEnd: "2026-07-19T08:15:00.000Z",
      durationMinutes: 45,
      status: "booked",
      channel: "online",
    },
  ],
};

// The new channel values (mobile_app, reception, barber) must type-check
// alongside the existing four — that's the whole point of this pin.
const week: StaffScheduleResponse = {
  range: "week",
  schedule: [
    {
      bookingId: "booking-2",
      clientName: "Faith Wanjiru",
      services: ["Shave"],
      scheduledStart: "2026-07-24T09:00:00.000Z",
      scheduledEnd: "2026-07-24T09:30:00.000Z",
      durationMinutes: 30,
      status: "completed",
      channel: "barber",
    },
  ],
};

const emptyRange: StaffScheduleResponse = {
  range: "tomorrow",
  schedule: [],
};

void today;
void week;
void emptyRange;
