// Compile-time pin only — see staffDay.test.ts / staffAuth.test.ts for why
// this repo pins JSON shapes at the type level instead of executing tests.
// Pins POST /api/v1/staff/clients (quick client registration for the mobile
// barber app's create-booking flow — name + phone only, a real create, not
// find-or-create; see the comment in the route file).

// No cross-module identifiers needed, but an empty export forces this file
// to be treated as a module rather than a global script — without it, its
// top-level type/const names collide with same-named ones in other .test.ts
// files under a global scope.
export {};

type StaffClientCreateResponse = {
  client: {
    id: string;
    name: string;
    phone: string;
    totalVisits: number;
    lastVisitAt: string | null;
  };
};

const created: StaffClientCreateResponse = {
  client: {
    id: "client-1",
    name: "Brian Mwangi",
    phone: "0700000000",
    totalVisits: 0,
    lastVisitAt: null,
  },
};

// --- Error variants --------------------------------------------------------

type InvalidBody = { error: "invalid_body"; message: string };
type InvalidJson = { error: "invalid_json"; message: string };
type PhoneTaken = { error: "phone_taken"; message: string };
type ServerError = { error: "server_error"; message: string };

const invalidBody: InvalidBody = {
  error: "invalid_body",
  message: "name and phone are required.",
};

const invalidJson: InvalidJson = {
  error: "invalid_json",
  message: "Invalid JSON body.",
};

// Duplicate phone is a genuine conflict (409), not silently resolved — this
// is a real create, unlike createBooking.ts's find-or-create-by-phone path.
const phoneTaken: PhoneTaken = {
  error: "phone_taken",
  message: "A client with this phone number already exists.",
};

const serverError: ServerError = {
  error: "server_error",
  message: "Something went wrong. Please try again.",
};

void created;
void invalidBody;
void invalidJson;
void phoneTaken;
void serverError;
