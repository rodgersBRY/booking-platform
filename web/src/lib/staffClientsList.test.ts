// Compile-time pin only — see staffDay.test.ts / staffAuth.test.ts for why
// this repo pins JSON shapes at the type level instead of executing tests.
// Pins GET /api/v1/staff/clients?q= ("My Customers" — clients THIS staff
// member has personally served, per-relationship visitCount/lastVisitAt,
// NOT the shop-wide clients.total_visits / last_visit_at).

type StaffClientListEntry = {
  id: string;
  name: string;
  phone: string;
  visitCount: number;
  lastVisitAt: string;
};

type StaffClientListResponse = { clients: StaffClientListEntry[] };

const withResults: StaffClientListResponse = {
  clients: [
    {
      id: "client-1",
      name: "Brian Mwangi",
      phone: "0700000000",
      visitCount: 14,
      lastVisitAt: "2026-07-10T09:00:00.000Z",
    },
  ],
};

// No q, or a q this staff member has no matching customers for — a real
// "no customers yet" state, unlike /v1/staff/clients/search's 2-char
// minimum gate.
const empty: StaffClientListResponse = { clients: [] };

void withResults;
void empty;
