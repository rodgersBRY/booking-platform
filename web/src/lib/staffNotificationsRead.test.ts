// Compile-time pin only — see staffDay.test.ts / staffAuth.test.ts for why
// this repo pins JSON shapes at the type level instead of executing tests.
// Pins POST /api/v1/staff/notifications/read.

export {};

type Ok = { ok: true };

type InvalidBody = { error: "invalid_body"; message: string };
type InvalidJson = { error: "invalid_json"; message: string };
type NotFound = { error: "Notification not found" };
type ServerError = { error: "Something went wrong. Please try again." };

const ok: Ok = { ok: true };

const invalidBody: InvalidBody = {
  error: "invalid_body",
  message: "Provide exactly one of id or all:true.",
};

const invalidJson: InvalidJson = {
  error: "invalid_json",
  message: "Invalid JSON body.",
};

// Same id-not-found-vs-not-mine ambiguity as the account/bookings/[id]/cancel
// route: a 404 here never reveals whether the id belongs to another staff
// member's notification.
const notFound: NotFound = { error: "Notification not found" };

const serverError: ServerError = {
  error: "Something went wrong. Please try again.",
};

void ok;
void invalidBody;
void invalidJson;
void notFound;
void serverError;
