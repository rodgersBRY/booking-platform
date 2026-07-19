import type { BookingChannel } from "./db/types";

// Compile-time pin only — see staffDay.test.ts / staffAuth.test.ts for why
// this repo pins JSON shapes at the type level instead of executing tests.
// Pins GET/PATCH /api/v1/staff/bookings/[id].

type StaffBookingDetailResponse = {
  bookingId: string;
  status: "booked" | "arrived" | "in_chair" | "late" | "completed";
  channel: BookingChannel;
  scheduledStart: string;
  scheduledEnd: string;
  durationMinutes: number;
  services: string[];
  client: {
    name: string;
    phone: string | null;
    totalVisits: number;
    customerNotes: string | null;
  };
  staffNotes: string | null;
  canStart: boolean;
  canComplete: boolean;
};

const booked: StaffBookingDetailResponse = {
  bookingId: "booking-1",
  status: "booked",
  channel: "online",
  scheduledStart: "2026-07-19T07:30:00.000Z",
  scheduledEnd: "2026-07-19T08:15:00.000Z",
  durationMinutes: 45,
  services: ["Haircut", "Beard Trim"],
  client: {
    name: "Brian Mwangi",
    phone: "0700000000",
    totalVisits: 14,
    customerNotes: "Prefers Skin Fade.",
  },
  staffNotes: "Usually books every three weeks.",
  canStart: true,
  canComplete: false,
};

// No notes recorded yet, and mid-appointment (in_chair) — canComplete true,
// canStart false.
const inChairNoNotes: StaffBookingDetailResponse = {
  bookingId: "booking-2",
  status: "in_chair",
  channel: "barber",
  scheduledStart: "2026-07-19T09:00:00.000Z",
  scheduledEnd: "2026-07-19T09:45:00.000Z",
  durationMinutes: 45,
  services: ["Shave"],
  client: {
    name: "Faith Wanjiru",
    phone: null,
    totalVisits: 0,
    customerNotes: null,
  },
  staffNotes: null,
  canStart: false,
  canComplete: true,
};

type PatchBody = { customerNotes?: string; staffNotes?: string };
type PatchResponse = { customerNotes: string | null; staffNotes: string | null };

const patchBody: PatchBody = { staffNotes: "Prefers early morning slots." };
const patchResponse: PatchResponse = {
  customerNotes: "Prefers Skin Fade.",
  staffNotes: "Prefers early morning slots.",
};

void booked;
void inChairNoNotes;
void patchBody;
void patchResponse;
