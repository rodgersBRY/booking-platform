// Compile-time pin only — see staffDay.test.ts / staffAuth.test.ts for why
// this repo pins JSON shapes at the type level instead of executing tests.
// Pins GET /api/v1/staff/clients/[id] — profile, both note fields, and a
// visit timeline scoped to THIS staff member's own visits with the client.

type StaffClientVisit = {
  date: string;
  services: string[];
};

type StaffClientDetailResponse = {
  id: string;
  name: string;
  phone: string;
  visitCount: number;
  customerNotes: string | null;
  staffNotes: string | null;
  visits: StaffClientVisit[];
};

// Multi-service visit — reached via the booking_services join-through, not
// visits.service_id alone (which only ever holds the booking's primary
// service).
const withHistory: StaffClientDetailResponse = {
  id: "client-1",
  name: "Brian Mwangi",
  phone: "0700000000",
  visitCount: 14,
  customerNotes: "Prefers Skin Fade.",
  staffNotes: "Usually books every three weeks.",
  visits: [
    {
      date: "2026-07-10T09:00:00.000Z",
      services: ["Haircut", "Beard Trim"],
    },
  ],
};

// No notes recorded yet, single-service walk-in visit (no booking_id ->
// falls back to the visit's own service_id).
const noNotesYet: StaffClientDetailResponse = {
  id: "client-2",
  name: "Faith Wanjiru",
  phone: "0711111111",
  visitCount: 1,
  customerNotes: null,
  staffNotes: null,
  visits: [{ date: "2026-06-01T09:00:00.000Z", services: ["Shave"] }],
};

void withHistory;
void noNotesYet;
