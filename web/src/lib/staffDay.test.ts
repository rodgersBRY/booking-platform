import type { BookingChannel, StaffPresence } from "./db/types";

// This repo has no runtime test runner configured (no jest/vitest — see
// package.json), so this file is a compile-time check in the existing house
// style (see staffAuth.test.ts, availability.test.ts): it pins the JSON
// shape of GET /api/v1/staff/day and is exercised by `npm run build`'s
// type-checking pass, not by executed assertions.

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

type StaffDayResponse = {
  staffId: string;
  presence: StaffPresence;
  presenceUpdatedAt: string | null;
  workingHours: { start: string; end: string } | null;
  summary: { total: number; completed: number; remaining: number };
  nextAppointment: AppointmentEntry | null;
  schedule: AppointmentEntry[];
};

const example: StaffDayResponse = {
  staffId: "staff-1",
  presence: "available",
  presenceUpdatedAt: "2026-07-18T06:00:00.000Z",
  workingHours: { start: "09:00", end: "19:00" },
  summary: { total: 8, completed: 3, remaining: 5 },
  nextAppointment: {
    bookingId: "booking-1",
    clientName: "Brian Mwangi",
    services: ["Haircut", "Beard Trim"],
    scheduledStart: "2026-07-18T07:30:00.000Z",
    scheduledEnd: "2026-07-18T08:15:00.000Z",
    durationMinutes: 45,
    status: "booked",
    channel: "online",
  },
  schedule: [],
};

// workingHours and nextAppointment are both nullable — the empty-day and
// no-schedule-set cases must type-check too.
const emptyDay: StaffDayResponse = {
  staffId: "staff-1",
  presence: "off_duty",
  presenceUpdatedAt: null,
  workingHours: null,
  summary: { total: 0, completed: 0, remaining: 0 },
  nextAppointment: null,
  schedule: [],
};

void example;
void emptyDay;
