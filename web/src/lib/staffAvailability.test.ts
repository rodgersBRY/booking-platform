import type { Slot } from "./booking/types";

// Compile-time pin only — see staffDay.test.ts / staffAuth.test.ts for why
// this repo pins JSON shapes at the type level instead of executing tests.
// Pins GET /api/v1/staff/availability?service=&date= — the token-authed
// sibling of /v1/public/availability, scoped to the caller's own staffId
// (never "any", unlike the public route which accepts staffId="any").
// Not to be confused with src/lib/staff/availability.test.ts, which pins
// defaultAvailabilityForBarber(), an unrelated seeding helper.

type StaffAvailabilityResponse = {
  date: string;
  slots: Slot[];
};

const withSlots: StaffAvailabilityResponse = {
  date: "2026-07-25",
  slots: [
    {
      start: "2026-07-25T09:00:00+03:00",
      end: "2026-07-25T09:45:00+03:00",
      label: "9:00 AM",
      staffId: "staff-1",
    },
  ],
};

const noSlots: StaffAvailabilityResponse = { date: "2026-07-25", slots: [] };

// --- Error variants — the three 400s share this exact shape ----------------

type MissingService = { error: "missing_service"; message: string };
type MissingDate = { error: "missing_date"; message: string };
type InvalidDate = { error: "invalid_date"; message: string };

const missingService: MissingService = {
  error: "missing_service",
  message: "service query param is required.",
};

const missingDate: MissingDate = {
  error: "missing_date",
  message: "date query param is required.",
};

const invalidDate: InvalidDate = {
  error: "invalid_date",
  message: "date must be in YYYY-MM-DD format.",
};

void withSlots;
void noSlots;
void missingService;
void missingDate;
void invalidDate;
