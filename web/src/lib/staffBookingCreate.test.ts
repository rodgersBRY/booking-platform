import type { Booking } from "./db/types";
import type { CreateBookingResult } from "./booking/createBooking";

// Compile-time pin only — see staffDay.test.ts / staffAuth.test.ts for why
// this repo pins JSON shapes at the type level instead of executing tests.
// Pins POST /api/v1/staff/bookings — token-authed booking creation for the
// mobile barber app. staffId is ALWAYS the caller's own id and channel is
// ALWAYS "barber" (never client-supplied, unlike the cookie-authed
// /api/bookings route). Delegates to createBooking.ts, so the error variants
// below are pinned via CreateBookingResult (imported from the source of
// truth) rather than hand-typed, to catch drift if that union changes.

type StaffBookingCreateResponse = { booking: Booking };

const created: StaffBookingCreateResponse = {
  booking: {
    id: "booking-1",
    client_id: "client-1",
    staff_id: "staff-1",
    service_id: "service-1",
    scheduled_start: "2026-07-25T06:00:00.000Z",
    scheduled_end: "2026-07-25T06:45:00.000Z",
    channel: "barber",
    status: "booked",
    created_by_staff_id: "staff-1",
    notes: null,
    created_at: "2026-07-19T06:00:00.000Z",
    updated_at: "2026-07-19T06:00:00.000Z",
  },
};

// --- Error variants, derived from createBooking.ts's own result union ------

type SlotTaken = Extract<CreateBookingResult, { error: "slot_taken" }>;
type RoleMismatch = Extract<CreateBookingResult, { error: "role_mismatch" }>;

// Route maps { error: result.error, message: result.message, slots: result.slots } -> 409
const slotTaken: { error: SlotTaken["error"]; message: string; slots: SlotTaken["slots"] } = {
  error: "slot_taken",
  message: "That slot is no longer available. Here are the next open slots.",
  slots: [
    {
      start: "2026-07-25T09:00:00+03:00",
      end: "2026-07-25T09:45:00+03:00",
      label: "9:00 AM",
      staffId: "staff-1",
    },
  ],
};

// Route maps { error: result.error, message: result.message } -> 409
const roleMismatch: { error: RoleMismatch["error"]; message: string } = {
  error: "role_mismatch",
  message: "This staff member cannot perform this service.",
};

// 404s — route maps { error: result.error }
type ServiceNotFound = { error: "Service not found" };
type StaffNotFound = { error: "Staff member not found" };
const serviceNotFound: ServiceNotFound = { error: "Service not found" };
const staffNotFound: StaffNotFound = { error: "Staff member not found" };

// This route's own request-shape validation (before createBooking is ever
// called) — exactly one of clientId or client.{name,phone} is required.
type InvalidBody = { error: "invalid_body"; message: string };
const invalidBody: InvalidBody = {
  error: "invalid_body",
  message: "Provide exactly one of clientId or client.{name,phone}.",
};

type InvalidJson = { error: "invalid_json"; message: string };
const invalidJson: InvalidJson = {
  error: "invalid_json",
  message: "Invalid JSON body.",
};

// Any other createBooking.ts error string is wrapped as a generic 500.
type ServerError = { error: "server_error"; message: string };
const serverError: ServerError = {
  error: "server_error",
  message: "Something went wrong. Please try again.",
};

void created;
void slotTaken;
void roleMismatch;
void serviceNotFound;
void staffNotFound;
void invalidBody;
void invalidJson;
void serverError;
